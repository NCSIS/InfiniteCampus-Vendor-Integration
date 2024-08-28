
/*
	Title: Clever Sections
	
	Description: 
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/



select 
    sch.schoolGUID AS 'School_id',
    s.sectionID AS 'Section_id',
    ident.identityGUID AS 'Teacher_id',
    s.number AS 'Section_number',
    c.name AS 'Course_name',
    p.name AS 'Period',
    sp.termName AS 'Term_name',
    sp.termStartDate AS 'Term_start',
    sp.termEndDate AS 'Term_end'

from v_OneRosterSectionPlacement sp
INNER JOIN section s ON sp.sectionID = s.sectionID
INNER JOIN course c ON c.courseID = s.CourseID
INNER JOIN v_OneRosterCourse orc ON c.courseID = orc.courseID
INNER JOIN period p ON p.periodID = sp.periodID
INNER JOIN calendar cal ON cal.calendarID = c.calendarID
INNER JOIN School sch ON sch.schoolID = orc.schoolID
INNER JOIN "identity" ident ON ident.personid = s.teacherpersonid

WHERE cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
     
