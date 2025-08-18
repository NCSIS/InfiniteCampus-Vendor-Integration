/*
	Title: Deanslist Roster
	
	Description: 
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/17/2025		Initial creation of this template

** This could be optimized.  If a large PSU needs this let me know and I'll fix it.  

*/

select
	stu.stateid AS 'StudentID',
	c.number AS 'CourseID',
	c.name	AS 'CoursenName',
	r.sectionid AS 'SectionID',
	orc.title AS 'SectionName',
	p.name AS 'Period',
	sp.termName AS 'TERM'
	
FROM roster r
	INNER JOIN section s on s.sectionID = r.sectionID
	INNER JOIN course c on c.courseID = s.courseID
	INNER JOIN calendar cal on c.calendarID = cal.calendarID
	INNER JOIN v_onerostersectionplacement sp ON sp.sectionid = r.sectionid
	INNER JOIN period p ON p.periodid = sp.periodid
	INNER JOIN student stu ON r.personid = stu.personid
	INNER JOIN v_OneRosterClass orc ON orc.sectionid = s.sectionid
	
WHERE 
	cal.startDate<=GETDATE() 
	AND cal.endDate>=GETDATE()
	AND (r.endDate IS NULL OR r.enddate > getdate())
	
