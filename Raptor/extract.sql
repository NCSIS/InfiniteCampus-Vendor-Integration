/*
	Title: Raptor Students
	
	Description: 
                 
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/03/2024		Initial creation of this template

*/

SELECT
	stu.firstName AS 'First Name',
	stu.lastName AS 'Last Name',
	stu.middleName AS 'Middle Name',
	FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'Date of Birth',
	stu.stateID AS 'ID Number',
	stu.gender AS 'Gender',
	stu.grade AS 'Grade'
	
FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL

