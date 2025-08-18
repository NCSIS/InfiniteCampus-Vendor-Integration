
/*
	Title:Deanslist - Daily Attendance 
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/17/2025		Initial creation of this template

*/

SELECT DISTINCT
	student.stateID AS [StudentID],
	attendance.date AS [AttDate],
	attendanceExcuse.code AS [AttCode],
	attendance.comments AS [AttNotes]


FROM Attendance 
	INNER JOIN attendanceExcuse ON attendanceExcuse.excuseid = attendance.excuseid
	INNER JOIN calendar cal ON attendance.calendarID = cal.calendarID
	INNER JOIN v_AdhocStudent student ON student.personID = attendance.personID
	INNER JOIN school sch ON sch.schoolID = student.schoolID


WHERE 
    cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
