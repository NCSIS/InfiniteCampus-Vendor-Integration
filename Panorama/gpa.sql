/*
	Title:Panorama - GPA
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/

SELECT
	student.personID, student.stateID, student.studentNumber, student.lastName, student.firstName, 
	gpa.cumGpaBasic, gpa.cumGpaUnweighted, 
	cal.calendarID, sch.number as 'cal.schoolID', cal.name
FROM v_CumGPAFull gpa
	INNER JOIN v_adhocStudent student ON student.personID = gpa.personID
	INNER JOIN school sch ON school.schoolID = student.schoolID
	INNER JOIN calendar cal ON cal.calendarID = student.calendarID
