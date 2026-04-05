/*
	Title: School Nutrition POS Linker
	
	Description:
	Point-of-Sale Linker file for school nutrition point-of-sale system
	
	Author: Rutherford County Schools
	Edited: Jeremiah Jackson NCDPI
	
	Revision History:
	07/12/2024		Initial creation of this template
	08/17/2024		Changed SQL to allow for missing data and contacts by Emergency Contact #
	08/17/2024 		Filtered Mother/Father/Guardian to be in the correct fields.  Must have guardian checked in NCSIS
	08/17/2024		Changed over to the calendar based method of filtering and added contact de-duplication
	08/18/2024		Change HH phone to student contact, and removed the joins for householdmember and household to fix duplicates
 	08/20/2024		Filter out Cross Enrolled Schools,  Inactive/Active based on Student End Date, Include inactive students in the sync
	08/22/2024		Fixed some duplicate and filter issues
	08/28/2024		Optimized the code to use less CPU -  Removed the NOLOCK, Removed the dedundant DISTINCT, USED a single ContactsOrdered
	10/15/2024		Fixed duplicates by filtering student enddate
	12/03/2024		Changed Address to use Household Addresses
	03/25/2025		Changed to Allow Inactive Students (Just comment out the last line at the bottom of the file s.enddate with a --
					EX: --   AND (s.endDate IS NULL or s.endDate>=GETDATE())
	09/15/2025		Changed Date Format for birthdate (yyyyMMdd) and removed extraneous characters in Homeroom
	09/17/2025		Included no-shows as inactive students

*/



--Rutherford County Schools, NC, Infinite Campus MealsPlus query, JMT 7/2024
--Followed and recreated previous NC Meals Plus Linker Header from State Report / PowerSchool
--Unused fields as shown in the Meals Plus Import are just the header recreated with no data
--JMT 7/31/2024 Removed NOLOCK per Infinite Campus KB https://kb.infinitecampus.com/help/nolock-faq
--Also added AND sch.name <> 'NCDPI' to filter out NCDPI users from export, cuts down on errors in Meals Plus import log. 

WITH ContactsGrouped AS (
	SELECT 
		cg.personID, 
		cg.contactPersonID, 
		cg.lastName, 
		cg.firstName, 
		cg.email, 
		cg.homePhone, 
		cg.cellPhone, 
		cg.seq, 
		cg.relationship,
		cg.AddressLine1,
		cg.State,
		cg.city,
		cg.zip,
		cg.guardian
	FROM  v_CensusContactSummary cg 
	GROUP BY cg.personID, cg.contactPersonID, cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship, cg.AddressLine1, cg.state, cg.city, cg.zip, cg.guardian
),

-- Consolidated Contact Ordering
ContactsOrdered AS (
	SELECT 
		co.personID, 
		co.contactPersonID, 
		co.lastName, 
		co.firstName, 
		co.email, 
		co.homePhone, 
		co.cellPhone, 
		co.seq, 
		co.relationship, 
		co.AddressLine1,
		co.city,
		co.state,
		co.zip,
		ROW_NUMBER() OVER (PARTITION BY co.personID, co.relationship ORDER BY co.seq) AS rowNumber
	FROM ContactsGrouped co 
	WHERE co.seq IS NOT NULL AND co.guardian = 1 AND co.relationship IN ('Mother', 'Father', 'Guardian')
),

ContactSelf AS (
	SELECT 
		c.personID, 
		c.householdPhone, 
		c.seq,
		c.relationship,
		c.email,
		c.lastName,
		c.firstName,
		c.birthdate,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c 
	WHERE c.relationship = 'Self'
),


LatestEnrollment AS (
 SELECT e.enrollmentID,
        e.personID, 
        p.stateID,
        c.schoolID,
        c.calendarID,
        e.serviceType,
        e.startDate,
        e.endDate,
        e.NoShow,
        e.grade,
        ROW_NUMBER() OVER (
            PARTITION BY e.personID 
            ORDER BY 
                CASE WHEN e.endDate IS NULL THEN 0 ELSE 1 END,  -- Prioritize NULL dates first
                e.endDate DESC                                -- Then order by date descending
        ) AS rowNumber
    FROM enrollment e, person p, calendar c
    WHERE p.personID=e.personid
    AND c.calendarID=e.calendarID
    AND c.startDate <= GETDATE() AND c.endDate >= GETDATE()
),


StudentHouse AS (
SELECT
	stu.personid, 
	CONCAT(addr.number, ' ',addr.street, ' ',addr.tag) AS streetaddress,
	addr.apt,
	addr.city,
	addr.state,
	addr.zip,
	ROW_NUMBER() OVER (PARTITION BY stu.personID ORDER BY stu.personid) AS rowNumber
FROM student stu
INNER JOIN school sch ON stu.schoolid = sch.schoolid
INNER JOIN calendar cal ON stu.calendarID = cal.calendarID
LEFT OUTER JOIN householdmember hm ON stu.personid = hm.personid and hm.secondary = 0
INNER JOIN householdlocation hl ON hl.householdid = hm.householdID and hl.secondary = 0 and hl.private = 0 
INNER JOIN address addr ON addr.addressID = hl.addressID AND addr.postOfficeBox = 0
WHERE 	
	cal.startDate <= GETDATE()
	AND cal.endDate >= GETDATE()
    AND (hl.endDate IS NULL OR hl.endDate >= GETDATE()) -- Filter out addresses that have ended
	AND (stu.endDate IS NULL OR stu.endDate >= GETDATE()) -- Include active students
	AND (
		CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 
		OR SUBSTRING(sch.number, 4, 3) = '000'
	) -- Filter schools based on number
	AND stu.stateID IS NOT NULL -- Exclude students without a state ID
)

SELECT
	s.stateid AS 'NCWISE_ID', 
	'' AS 'SSN',
	cs.lastName AS 'Last Name',
	cs.firstName AS 'First Name', 
	FORMAT(cs.birthdate,'yyyyMMdd') AS 'Birth Date',
	le.startDate AS 'Entry Date',
	CASE 
	    WHEN le.endDate IS NULL OR le.endDate >= GETDATE() THEN 'A'
		WHEN le.endDate < GETDATE() THEN 'I'
		ELSE 'I'
	END AS 'Current Status',
	le.endDate AS 'Exit Date',
	le.grade AS 'Grade',
	sch.name AS 'School Name',
	SUBSTRING(sch.number, 4, LEN(sch.number) - 3) AS 'School Number',
	hrm.teacherDisplay as 'Homeroom',
	sh.streetaddress AS 'Mailing Address',
	'' AS 'Mailing Apt',
	'' AS 'Mailing PO Box',
	sh.city AS 'Mailing City',
	sh.state AS 'Mailing State',
	sh.zip AS 'Mailing ZipCode',
	'' AS 'Address',
	'' AS 'APT',
	'' AS 'City',
	'' AS 'State',
	'' AS 'Zip',
	c1.lastName AS 'Mother Last',
	c1.firstName AS 'Mother First',
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c1.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c1.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Mother Day Phone',
	c1.email AS 'Mother Email',
	c2.lastName AS 'Father Last',
	c2.firstName AS 'Father First',
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c2.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c2.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Father Day Phone',
	c2.email AS 'Father Email',
	c3.lastName AS 'Guardian Last',
	c3.firstName AS 'Guardian First',
    COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c3.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c3.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Guardian Day Phone',
	c3.email AS 'Guardian Email',
	REPLACE(REPLACE(REPLACE(REPLACE(cs.householdphone, ' ', ''), '(', ''), ')', ''), '-', '') AS 'Student Phone',
	cs.email AS 'Student Email'

FROM person s
	INNER JOIN LatestEnrollment le ON s.personID = le.personID AND le.rowNumber = 1
	LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1 AND c1.relationship = 'Mother'
	LEFT OUTER JOIN ContactsOrdered c2 ON s.personID = c2.personID AND c2.rowNumber = 1 AND c2.relationship = 'Father'
	LEFT OUTER JOIN ContactsOrdered c3 ON s.personID = c3.personID AND c3.rowNumber = 1 AND c3.relationship = 'Guardian'
	INNER JOIN ContactSelf cs ON s.personID = cs.personID AND cs.rowNumber = 1
	INNER JOIN school sch ON sch.schoolid = le.schoolID
	INNER JOIN Calendar cal ON le.calendarID = cal.calendarID
	LEFT OUTER JOIN StudentHouse sh ON sh.personid = le.personid AND sh.rownumber = 1
	LEFT OUTER JOIN v_StudentHomeroom hrm on hrm.studentPersonID=s.personID


WHERE le.calendarId = cal.calendarid
    AND cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')

    AND (s.stateid IS NOT NULL OR s.stateid <> '')
