/*
	Title: SNAP by Promed - Attedance File
	
	Description:
        Attendance File for ProMed SNAP
		
	Author: Jeremiah Jackson - NCDPI  
	
	Revision History:
	08/17/2024		Initial creation of this template

*/

SELECT DISTINCT
	stu.stateid as 'Reference ID',
	attEx.description AS 'Reason',
	FORMAT(att.date,'MM/dd/yyyy') as 'Date',
	att.comments as 'Comments',
	att.status as 'Status'

FROM attendance att
	LEFT OUTER JOIN attendanceExcuse attEx ON att.excuseID = attex.excuseID
	inner join student stu ON att.personID = stu.personID
	INNER JOIN Calendar cal ON stu.calendarID = cal.calendarID
	INNER JOIN school sch ON sch.schoolid = stu.schoolID

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND CAST(substring(sch.number,4,3) AS INTEGER) >= 300
   AND stu.stateid IS NOT NULL
   AND stu.stateid <> ''
