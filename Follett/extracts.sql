/*
	Title: Follett Student Extract
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	07/25/2024		Initial creation of this template

*/



SELECT
sch.number,
stu.lastName,
stu.firstName,
stu.stateId as studentNumber,
stu.grade,
c.email
FROM student stu LEFT JOIN contact c ON stu.personId=c.personId,
calendar cal,
school sch
WHERE cal.calendarId=stu.calendarId
AND sch.schoolID=cal.SchoolID
AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE()
AND (stu.endDate IS NULL or stu.endDate>=GETDATE())
ORDER BY lastName, firstName, middleName;