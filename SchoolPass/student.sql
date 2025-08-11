/*
	Title: SchoolPass Student
	
	Description:     

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        08/10/2025 - Original
		08/10/2025 - Fixed parent ContactsGrouped

*/

WITH ContactsGrouped AS (
    SELECT DISTINCT
        cg.personID, 
        cg.contactPersonID, 
        cg.guardian,
        cg.firstName,
        cg.lastName,
        cg.cellPhone,
        cg.homePhone,
        cg.householdPhone,
        cg.email,
        cg.relationship,
        cg.relatedby,
    ROW_NUMBER() OVER (PARTITION BY cg.contactpersonid, cg.personid ORDER BY cg.contactPersonID DESC) AS rowNumber
    FROM 
        v_CensusContactSummary cg WITH (NOLOCK)
INNER JOIN student stu ON cg.personid = stu.personid
    WHERE 
        cg.guardian = '1' -- Filter guardians early to reduce data volume
     AND (stu.endDate IS NULL OR stu.endDate >= GETDATE()) -- Include active students
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
    LEFT OUTER JOIN ContactsGrouped cg1 ON cg1.personid = stu.personID AND cg1.rowNumber = '1'


WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
