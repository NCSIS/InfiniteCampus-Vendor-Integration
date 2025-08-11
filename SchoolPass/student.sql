/*
	Title: SchoolPass Student
	
	Description:     

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        08/10/2025 - Original
		08/10/2025 - Removed Duplicates
		08/11/2025 - Sort Parents by Priority

*/




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

OUTER APPLY (
    SELECT TOP 1 c.*
    FROM v_CensusContactSummary c
    WHERE c.personID = stu.personID
      AND c.relationship = 'Self'
    ORDER BY c.seq
) cs
OUTER APPLY (
    SELECT TOP 1 cg.*
    FROM v_CensusContactSummary cg
    WHERE cg.personID = stu.personID
      AND cg.guardian = '1'
    ORDER BY cg.seq ASC
) cg1


WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
