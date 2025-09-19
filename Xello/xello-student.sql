
/*
	Title: Xello Student
	
	Description: 
                 
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/03/2025		Initial creation of this template
	09/03/2025		Changed STUDENTID to UID


*/

SELECT
	stu.stateid AS [StudentID],
	stu.firstName AS [FirstName],
	stu.lastName AS [Last Name],
	stu.gender AS [Gender],
	stu.grade AS [CurrentGrade],
	sch.number AS [CurrentSchoolCode],
	'' AS [PreRegSchoolCode], -- Blank for now, if needed let me know.
	FORMAT(stu.birthdate,'MM/dd/yyyy') AS [DateOfBirth],
	stu.stateid AS [StateProvNumber],
	cs.email AS [Email]
	
FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
   
   OUTER APPLY (
    SELECT TOP 1 c.*
    FROM v_CensusContactSummary c
    WHERE c.personID = stu.personID
      AND c.relationship = 'Self'
    ORDER BY c.seq
) cs

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
