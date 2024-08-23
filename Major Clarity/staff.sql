/*
	Title: Major Clarity - Staff File
	
	Description:
	Major Clarity - Staff File	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	08/23/2024		Initial creation of this template

*/


SELECT sch.number as school_id,
sta.staffStateID as staff_id,
c.email as email,
sta.firstname as first_name,
sta.lastName as last_name,
CASE
	WHEN sta.teacher='1' THEN 'advisor'
	WHEN sta.counselor='1' OR sta.advisor='1' OR sta.supervisor='1' THEN 'school_admin'
	WHEN sch.number='000' THEN 'district_admin'
	ELSE 'staff'
END as role
FROM staffMember sta,
school sch,
contact c
WHERE sch.schoolID=sta.schoolID
AND c.personID=sta.personID
AND sta.startDate<=GETDATE() AND (sta.endDate IS NULL OR sta.endDate>=GETDATE()) --Get only calendars for the current year