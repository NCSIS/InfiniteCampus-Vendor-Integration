/*
	Title:Panorama - Course Grading File
	
	Description:  This is set as a INNER JOIN which only pulls records with data. 
If it needs to pull all grading records including Final scores that can be changed by changing gradingscore comment lines below.
Comment out the INNER JOIN gradingscore and uncomment the LEFT OUTER JOIN gradingscore line.

USe -- to comment out a line

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


SELECT
	student.personID, student.stateID, student.studentNumber,
	grading.sectionID, grading.sectionNumber, grading.termID, grading.termName, grading.task, grading.score, grading."percent", 
	student.firstName, student.lastName,
	grading.courseName, grading.teacherDisplay, gs.progressScore AS 'grading.progressScore', grading.progressPercent, grading.scoreID,
	cal.calendarID, sch.number AS 'cal.schoolID', cal.name, 
	grading.taskID, grading.taskSeq, grading.standardID, grading.abbreviation

FROM v_GradingDetail grading
	INNER JOIN v_AdhocStudent student ON grading.personID = student.personID
	INNER JOIN calendar cal ON cal.calendarid = grading.calendarid
	INNER JOIN gradingscore gs ON gs.scoreid = grading.scoreid
	INNER JOIN school sch on sch.schoolID = student.schoolID
-- LEFT OUTER JOIN gradingscore gs ON gs.scoreid = grading.scoreid

WHERE cal.calendarId=grading.calendarId
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND student.stateid IS NOT NULL
   AND student.stateid <> ''
	
	
	
	
