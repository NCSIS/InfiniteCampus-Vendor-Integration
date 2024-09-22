/*
	Title: GearUP Absence File
	
	Description:
	Daily attendance data - pulls total number of daily absences for all grade levels.
	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	09/16/2024		Initial creation of this template

*/


SELECT sch.number as school_id,
stu.stateID as student_number,
stu.lastName as last_name,
stu.firstName as first_name,
stu.grade as grade_level,
abs.daysAbsent as days_absent
FROM student stu,
school sch,
calendar cal,
SchoolYear yr,
CalculatedAbsenteeValues abs
WHERE  cal.calendarID=stu.calendarID
AND sch.schoolID=cal.schoolID
AND cal.endYear=yr.endYear
AND yr.active=1 
AND abs.personID = stu.personID
AND abs.calendarID = stu.calendarID