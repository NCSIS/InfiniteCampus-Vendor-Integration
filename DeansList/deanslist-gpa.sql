/*
	Title:DeansList - GPA
	
	Description: This pulls GPA As of this school year only
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/17/2025		Initial creation of this template

*/

SELECT DISTINCT
	student.stateID AS [StudentID],
	gpa.cumGpaBasic AS [GPA]

FROM v_CumGPAFull gpa
	INNER JOIN v_adhocStudent student ON student.personID = gpa.personID
	INNER JOIN school sch ON sch.schoolID = student.schoolID
	INNER JOIN calendar cal ON cal.calendarID = student.calendarID

WHERE
    cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
