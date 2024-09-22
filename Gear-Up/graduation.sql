/*
	Title: GearUP Graduation File
	
	Description:
	Graduation data for GEARUP. 
	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	09/16/2024		Initial creation of this template

*/


WITH student_latest_year AS (
SELECT stu.personID,
MAX(stu.calendarID) as calendar_id,
MAX(cal.endYear) as end_year
FROM student stu,
calendar cal,
school sch
WHERE cal.calendarID=stu.calendarID
AND sch.schoolID=cal.schoolID
GROUP BY stu.personID
)
SELECT concat(sl.end_year-1,'-',sl.end_year) as school_year,
sch.number as school_id,
stu.stateID as student_number,
stu.lastName as last_name,
stu.firstName as first_name,
stu.grade as grade_level,
g.diplomaDate as diploma_issued_date
FROM student_latest_year sl,
student stu,
school sch,
calendar cal,
graduation g
WHERE stu.personID=sl.personID
AND stu.calendarID=sl.calendar_id
AND cal.calendarID=sl.calendar_id
AND sch.schoolID=cal.schoolID
AND stu.personID = g.personID
AND g.diplomaDate IS NOT NULL;