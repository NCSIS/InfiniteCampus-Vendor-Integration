/*
	Title:Panorama - GPA
	
	Description: This pulls GPA As of this school year only
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/

SELECT DISTINCT
	student.personID, student.stateID, student.studentNumber, student.lastName, student.firstName, 
	gpa.cumGpaBasic, gpa.cumGpaUnweighted, 
	cal.calendarID, sch.number as 'cal.schoolID', cal.name

FROM v_CumGPAFull gpa
	INNER JOIN v_adhocStudent student ON student.personID = gpa.personID
	INNER JOIN school sch ON sch.schoolID = student.schoolID
	INNER JOIN calendar cal ON cal.calendarID = student.calendarID

WHERE
    cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
