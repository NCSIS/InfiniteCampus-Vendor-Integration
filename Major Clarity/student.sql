/*
	Title: Major Clarity - Student File
	
	Description:
	Major Clarity - Student File	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	08/23/2024		Initial creation of this template

*/


SELECT sch.number as school_id,
stu.stateID as student_id,
c.email as email,
stu.firstname as first_name,
stu.lastName as last_name,
stu.grade as grade_level,
format(stu.birthdate, 'MM/dd/yyyy') as dob
FROM school sch,
calendar cal,
student stu,
contact c
WHERE sch.schoolID=cal.schoolID
AND cal.calendarID=stu.calendarID
AND c.personID=stu.personID
AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date