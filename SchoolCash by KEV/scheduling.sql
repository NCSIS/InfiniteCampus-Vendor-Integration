/*
	Title: SchoolCash by KEV - Scheduling File
	
	Description:  Pull the schedule from NCSIS.  
	Determines the Semester/YearLong based on number of classes. 
	Determines the start date based on earliest Term Date and latest End Date.

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


WITH SectionsGrouped AS(
SELECT sg.sectionID, sg.termname, sg.termstartdate, sg.termenddate
  FROM v_OneRosterSectionPlacement sg
  GROUP By sg.sectionID, sg.termname,sg.termstartdate, sg.termenddate
  ),

  SixWeekSemester AS (
  SELECT COUNT(sg2.sectionid) as TCount,
  sg2.sectionID
  FROM SectionsGrouped sg2
  WHERE sg2.termname IN ('T1', 'T2', 'T3', 'T4', 'T5', 'T6')
  Group By sg2.sectionID
  ),

NineWeekSemester AS (
  SELECT COUNT(sg1.sectionid) as NCount,
  sg1.sectionID
  FROM SectionsGrouped sg1
  WHERE sg1.termname IN ('N1', 'N2', 'N3', 'N4')
  Group By sg1.sectionID
),

SemesterDate AS (
   SELECT sg3.sectionID,
   MIN(sg3.termstartdate) AS 'SemesterStart',
   MAX(sg3.termenddate) AS 'SemesterEnd'
   FROM SectionsGrouped sg3
   GROUP By sg3.sectionID
)
  

select DISTINCT
    sch.number AS 'Student_School_Number',
	orc.CourseCode AS 'Course_Code',
	orc.title AS 'Course_Name',
	'' AS 'Reserved-5',
	s.sectionID AS 'Course_Code_Section',
	CASE
		WHEN nws.NCount = 4 THEN 'YL'
		WHEN nws.NCount = 2 AND (sp.termname = 'N1' or sp.termname = 'N2') THEN 'S1'
		WHEN nws.NCount = 2 AND (sp.termname = 'N3' or sp.termname = 'N4') THEN 'S2'
		WHEN tws.TCount = 6 THEN 'YL'
		WHEN tws.TCount = 3 AND (sp.termname = 'T1' or sp.termname = 'T2' or sp.termname = 'T3') THEN 'S1'
		WHEN tws.TCount = 3 AND (sp.termname = 'T4' or sp.termname = 'T5' or sp.termname = 'T6') THEN 'S2'	
	ELSE 'Other'
	END AS 'Course_Semester',
	sd.semesterstart AS 'Semester_Start_Date',
	sd.semesterend AS 'Semester_End_Date',
	sp.termname AS 'Course_Term',
	sp.termStartDate AS 'Course_Term_Start_Date',
	sp.termEndDate AS 'Course_Term_End_Date',
	cal.endYear AS 'Course_School_Year',
	t.staffStateID AS 'Course_Teacher_ID_Number',
	'' AS 'Reserved-6',
	t.familyName AS 'Course_Teacher_Last_Name',
	t.givenname AS 'Course_Teacher_First_Name',
	stu.stateid as 'Student_Number'

from roster en
INNER JOIN section s ON s.sectionID = en.sectionID
INNER JOIN course c ON c.courseID = s.CourseID
INNER JOIN v_OneRosterCourse orc ON c.courseID = orc.courseID
INNER JOIN v_OneRosterSectionPlacement sp ON s.SectionID = sp.sectionID
INNER JOIN v_OneRosterTeacher t ON t.personID = s.teacherPersonID
INNER JOIN calendar cal ON cal.calendarID = c.calendarID
INNER JOIN School sch ON sch.schoolID = orc.schoolID
INNER JOIN Student stu ON stu.personid = en.personid
LEFT OUTER JOIN NineWeekSemester nws ON en.sectionID = nws.sectionID
LEFT OUTER JOIN SixWeekSemester tws ON en.sectionID = tws.sectionID
LEFT OUTER JOIN SemesterDate sd ON sd.sectionID = en.sectionID

WHERE cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
     
