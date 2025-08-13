
/*
	Title: Heartland Mosaic
	
	Description: 
                 
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/13/2025		Initial creation of this template


*/

SELECT
	stu.stateID AS 'Student ID',
	stu.firstName AS 'First Name',
	stu.lastName AS 'Last Name',
	FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'Birthdate',
	stu.grade AS 'Grade',
	sch.number AS 'School Number',
	CASE 
	    WHEN stu.endDate IS NULL OR stu.endDate >= GETDATE() THEN 'A'
		WHEN stu.endDate < GETDATE() THEN 'I'
		ELSE 'I'
	END AS 'Active/Enrollment status'

	
FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
--   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
