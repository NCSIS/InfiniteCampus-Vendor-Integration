/*
	Title: Major Clarity - Course File
	
	Description:
	Major Clarity - Course File	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	08/23/2024		Initial creation of this template

*/


SELECT DISTINCT sch.schoolID as school_id,
crs.courseNumber as course_id,
crs.courseName as course_name,
crs.departmentName as subject,
crs.gpaWeight as credit_hours
FROM calendar cal,
school sch,
v_courseSection crs
WHERE cal.calendarID=crs.calendarID
AND sch.schooLID=cal.schoolID
AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year