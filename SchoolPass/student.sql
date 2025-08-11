/*
	Title: SchoolPass Student
	
	Description:     

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        08/10/2025 - Original

*/

WITH ContactCombined AS (
    SELECT
        c.personid, c.email, c.homephone, c.workphone, c.cellphone, c.pager, c.communicationLanguage, 
        a.city, a.state, a.zip, a.postOfficeBox, a.number, a.street, a.tag, a.apt, 
        hh.phone, 
        i.homePrimaryLanguage, i.gender, i.lastName, i.firstName, i.middleName, i.birthdate,
        ROW_NUMBER() OVER (PARTITION BY c.personid ORDER BY c.personid) AS rowNumber
    FROM person p 
        INNER JOIN contact c ON p.personid = c.personid
        INNER JOIN [Identity] i ON p.currentIdentityID = i.identityID 
        LEFT OUTER JOIN householdmember hm ON hm.personid = p.personid AND (hm.enddate IS NULL OR hm.enddate >= GETDATE()) AND hm.secondary = '0'
        LEFT OUTER JOIN household hh ON hh.householdid = hm.householdid
        LEFT OUTER JOIN householdlocation hl ON hl.householdid = hh.householdid AND (hl.enddate IS NULL OR hl.enddate >= GETDATE()) AND hl.secondary = '0'
        LEFT OUTER JOIN address a ON hl.addressid = a.addressid
),

ContactSelf AS (
	SELECT 
		c.personID, 
		c.cellphone,
		c.householdPhone, 
		c.seq,
		c.relationship,
		c.email,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c 
	WHERE c.relationship = 'Self'
)



SELECT DISTINCT
	stu.stateid AS 'ExternalId',
	stu.firstName AS 'FirstName',
	stu.lastName AS 'LastName',
	cs.email AS 'Email', 
	cs.cellphone AS 'PhoneNumber',
	CASE 
	    WHEN stu.endDate IS NULL OR stu.endDate >= GETDATE() THEN 'TRUE'
		WHEN stu.endDate < GETDATE() THEN 'FALSE'
		ELSE 'FALSE'
	END AS 'ActiveStatus',
	stu.grade AS 'Grade',
	'' AS 'DismissalLocation',
	sch.number AS 'Site',
	cg1.personid AS 'P1_ID',
	'' AS 'Optional_P1_ID',
	'' AS 'QuickPin'
	
FROM
    v_adhocstudent stu
    JOIN Calendar cal ON cal.calendarID = stu.calendarID
    JOIN School sch ON sch.schoolID = cal.schoolID
    LEFT JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
    LEFT OUTER JOIN ContactCombined cg1 ON cg1.personid = stu.personID AND cg1.rowNumber = '1'


WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
