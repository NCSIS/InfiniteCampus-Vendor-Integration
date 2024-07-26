/*
	Title: Ellevation Student Schedules 
	
	
	Author: Clinton City Schools
	
	Revision History:
	07/25/2024		Initial creation of this template

*/

SELECT DISTINCT p.studentnumber AS LocalStudentID 
,p.stateid AS StateTestingID 
,sm.staffstateid 
,sm.personID
,sm.firstname AS TeacherFirstName 
,sm.lastname AS TeacherLastName 
,ssh.stafftype AS TeacherAssignment
,c.NAME AS CourseName 
,c.number AS CourseCode 
,tm.NAME AS Term
,tm.startDate AS TermStart
,tm.endDate AS TermEnd
,s.sectionid AS SectionID 
,s.number as SectionNumber
,pd.NAME AS CoursePeriod
,sc.name
,sc.number [LEA School Code]
,tr.trialID as TrialID
FROM person p
INNER JOIN enrollment e on e.personID = p.personID
inner join calendar ca on ca.calendarid=e.calendarid
inner join school sc on sc.schoolid=ca.schoolid
INNER JOIN schoolyear sy on e.endyear = sy.endyear
INNER JOIN roster r ON p.personid = r.personid 
INNER JOIN section s ON r.sectionid = s.sectionid 
INNER JOIN teacher t ON s.sectionid = t.sectionid
INNER JOIN course c ON s.courseid = c.courseid 
INNER JOIN sectionplacement sp ON s.sectionid = sp.sectionid 
INNER JOIN term tm ON sp.termid = tm.termid 
INNER JOIN staffmember sm ON t.personid = sm.personid 
INNER JOIN SectionStaffHistory ssh on sm.personid = ssh.personid
INNER JOIN period pd ON sp.periodid = pd.periodid 
INNER JOIN calendar cr ON c.calendarid = cr.calendarid
INNER JOIN trial tr on tr.trialID = s.trialID
WHERE sy.active = 1 and e.endDate is null
and tm.startDate >= GETDATE()-190
and tr.active=1
and r.endDate is NULL
