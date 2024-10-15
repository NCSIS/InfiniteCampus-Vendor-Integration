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
        08/28/2024              Optimized the code to use less CPU -  Removed the NOLOCK, Removed the dedundant DISTINCT, USED a single ContactsOrdered
        10/15/2024		Fixed duplicates by filtering student enddate

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
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c 
	WHERE c.relationship = 'Self'
)

SELECT 
	s.stateid AS 'NCWISE_ID', 
	'' AS 'SSN',
	s.lastName AS 'Last Name',
	s.firstName AS 'First Name', 
	FORMAT(s.birthdate,'MM/dd/yyyy') AS 'Birth Date',
	'' AS 'Entry Date',
	CASE 
	    WHEN s.endDate IS NULL OR s.endDate >= GETDATE() THEN 'A'
		WHEN s.endDate <= GETDATE() THEN 'I'
		ELSE 'I'
	END AS 'Current Status',
	'' AS 'Exit Date',
	s.grade AS 'Grade',
	sch.name AS 'School Name',
	SUBSTRING(sch.number, 4, LEN(sch.number) - 3) AS 'School Number',
	s.homeroomTeacher AS 'Homeroom',
	c1.addressLine1 AS 'Mailing Address',
	'' AS 'Mailing Apt',
	'' AS 'Mailing PO Box',
	c1.city AS 'Mailing City',
	c1.state AS 'Mailing State',
	c1.zip AS 'Mailing ZipCode',
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

FROM v_AdHocStudent s
	LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1 AND c1.relationship = 'Mother'
	LEFT OUTER JOIN ContactsOrdered c2 ON s.personID = c2.personID AND c2.rowNumber = 1 AND c2.relationship = 'Father'
	LEFT OUTER JOIN ContactsOrdered c3 ON s.personID = c3.personID AND c3.rowNumber = 1 AND c3.relationship = 'Guardian'
	INNER JOIN ContactSelf cs ON s.personID = cs.personID AND cs.rowNumber = 1
	INNER JOIN school sch ON sch.schoolid = s.schoolID
	INNER JOIN Calendar cal ON s.calendarID = cal.calendarID

WHERE s.calendarId = cal.calendarid
    AND cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')
    AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
    AND s.servicetype = 'P'
    AND (s.stateid IS NOT NULL OR s.stateid <> '')
