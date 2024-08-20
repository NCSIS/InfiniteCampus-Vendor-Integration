/*
	Title:Panorama - Enrollments
	
	Description: 
	This is showing all active students and all enrollment changes. 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


SELECT
	student.personid, student.stateid, student.studentnumber, student.firstName, student.lastName,
	roster.rosterID, roster.trialID, roster.sectionID, roster.startDate, roster.EndDate,
	cal.calendarID, cal.number, cal.name
	
FROM roster
	INNER JOIN v_AdhocStudent student ON student.personID = roster.personid
	INNER JOIN calendar cal ON cal.calendarid = student.calendarid
	

WHERE cal.calendarId=student.calendarId
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND student.stateid IS NOT NULL
   AND student.stateid <> ''
