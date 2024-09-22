/*
	Title: GearUP GPA File
	
	Description:
	GPA demographic data for GEARUP. 
	
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
gpa.cumGpaBasic as weighted_gpa,
gpa.cumGpaUnweighted as unweighted_gpa
FROM student_latest_year sl,
student stu,
school sch,
calendar cal,
v_CumGPAFull as gpa
WHERE stu.personID=sl.personID
AND stu.calendarID=sl.calendar_id
AND cal.calendarID=sl.calendar_id
AND sch.schoolID=cal.schoolID
AND gpa.personID=sl.personID
AND gpa.calendarID=sl.calendar_id