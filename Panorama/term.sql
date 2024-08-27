/*
	Title:Panorama - Term
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


SELECT DISTINCT
term.termID,
term.name,
term.startDate,
term.endDate,
cal.calendarID,
cal.schoolID,
cal.name
FROM Calendar AS cal 
LEFT JOIN ScheduleStructure AS ss ON ss.calendarID = cal.calendarID
LEFT JOIN TermSchedule AS ts ON ts.structureID = ss.structureID
INNER JOIN Term AS term ON term.termScheduleID = ts.termScheduleID
INNER JOIN school sch on sch.schoolid = cal.schoolid
WHERE cal.calendarId=ss.calendarId
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() 
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
