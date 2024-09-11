/*
	Title: Classlink Classes
	
	Description: 
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/



select 

    s.sectionid as 'sourceId',
    concat(c.number, ' ', s.number, ' ', c.name) AS 'title',
    '' AS 'grades',
    c.courseId AS 'courseSourceId',
    s.teacherDisplay AS 'classCode',
    CASE
         WHEN s.homeroomSection = '1' THEN 'homeroom'
         ELSE 'scheduled'
    END AS 'classType',
    r.Name AS 'location',
    sch.schoolGUID AS 'schoolSourceId',
    sp.termID AS 'termSourceIds',
    CONCAT(t.name,'-',ps.name, '-',p.name) AS 'periods'
    
    

from SectionPlacement sp
INNER JOIN section s ON sp.sectionID = s.sectionID
INNER JOIN course c ON c.courseID = s.CourseID
INNER JOIN period p ON p.periodID = sp.periodID
INNER JOIN calendar cal ON cal.calendarID = c.calendarID
INNER JOIN School sch ON sch.schoolID = cal.schoolID
INNER JOIN term t ON t.termid = sp.termid
INNER JOIN PeriodSchedule ps ON ps.periodScheduleID = p.periodScheduleID
LEFT JOIN room r ON s.roomid = r.roomid

WHERE cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year

