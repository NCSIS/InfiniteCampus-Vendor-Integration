/*
	Title:Panorama - Attendance
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/

SELECT
	student.personID, student.stateID, student.studentNumber, student.firstName, student.lastName,
	attendanceDetail.calendarID,
--	attendanceDetail.structureID, attendanceDetail.termID, attendanceDetail.termName,
	attendanceDetail.periodID, 
--	attendanceDetail.periodName, attendanceDetail.periodSeq, 	
	attendanceDetail.sectionID, attendanceDetail.sectionNumber, attendanceDetail.date, attendanceDetail.status, attendanceDetail.excuse, 
	attendanceDetail.code, attendanceDetail.stateCode, attendanceDetail.description, attendanceDetail.courseNumber,
	cal.calendarID, sch.number AS 'cal.schoolID', cal.name

FROM v_AttendanceDetail attendanceDetail
	INNER JOIN calendar cal ON attendanceDetail.calendarID = cal.calendarID
	INNER JOIN v_AdhocStudent student ON student.personID = attendanceDetail.personID
	INNER JOIN school sch ON sch.schoolID = student.schoolID
