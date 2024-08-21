/*
	Title:Panorama - Sections
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


SELECT
	courseInfo.courseID, courseinfo.courseNumber, courseinfo.courseName,
	gradingTaskCredit.credit,
	sectioninfo.sectionID, sectioninfo.sectionNumber, sectioninfo.teacherDisplay, sectioninfo.teacher2Display, sectioninfo.teacher3Display, sectioninfo.teacher4Display,
	sectionSchedule.termStart, sectionSchedule.termEnd, sectionSchedule.terms, sectionSchedule.schedules,
	courseInfo.departmentID, courseInfo.departmentName, sectionSchedule.periodStart, sectionSchedule.periodEnd,
	sectionInfo.teacherPersonID, sectionInfo.teacher2PersonID, sectionInfo.teacher3PersonID, sectionInfo.teacher4PersonID,
	cal.calendarID, sch.number AS 'cal.schoolID', cal.name
	
FROM v_SectionInfo sectioninfo
	INNER JOIN v_CourseInfo courseInfo ON sectioninfo.courseID = courseinfo.courseID
	INNER JOIN calendar cal ON cal.calendarid = sectioninfo.calendarID
    	INNER JOIN v_GradingTaskCredit gradingTaskCredit ON sectioninfo.courseID = gradingTaskCredit.courseID
	INNER JOIN v_SectionSchedule sectionSchedule ON sectionschedule.sectionid = sectioninfo.sectionID
	INNER JOIN school sch ON courseinfo.schoolID = sch.schoolID
WHERE cal.calendarId=sectioninfo.calendarId
   	AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() 
ORDER BY sectioninfo.sectionID 
	
	
	
	
	
