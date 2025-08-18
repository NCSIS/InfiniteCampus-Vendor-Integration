
/*
	Title:Deanslist - Class Attendance 
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/17/2025		Initial creation of this template

*/

SELECT
	student.stateID AS [StudentID],
	attendanceDetail.date AS [AttDate],
	attendanceDetail.code AS [AttCode],
	attendanceDetail.courseNumber AS [CourseID],
	attendanceDetail.sectionID AS [SectionID],
	attendanceDetail.periodName AS [Period],
	attendanceDetail.description AS [AttNotes],
	sch.number AS [BuildingCode]


FROM v_AttendanceDetail attendanceDetail
	INNER JOIN calendar cal ON attendanceDetail.calendarID = cal.calendarID
	INNER JOIN v_AdhocStudent student ON student.personID = attendanceDetail.personID
	INNER JOIN school sch ON sch.schoolID = student.schoolID


WHERE 
    cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
