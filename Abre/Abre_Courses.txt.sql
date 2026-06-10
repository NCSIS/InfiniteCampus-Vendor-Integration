SELECT DISTINCT
  s.number AS [SchoolCode],
  cs.coursenumber AS [CourseCode],
  CAST(cs.coursenumber AS VARCHAR(50)) + '.' + CAST(cs.sectionnumber AS VARCHAR(50)) AS [SectionCode],
  cs.teacherPersonID AS [StaffID],
  t.name AS [TermCode],
  p.name AS [Period]
FROM
  dbo.v_ClassSection cs
  INNER JOIN dbo.Calendar c ON cs.CalendarID = c.CalendarID
  INNER JOIN dbo.School s ON cs.schoolID = s.schoolID 
  INNER JOIN dbo.SchoolYear y ON y.endYear = c.endYear
  INNER JOIN dbo.Section sec ON cs.SectionID = sec.SectionID
  INNER JOIN dbo.SectionPlacement sp ON cs.SectionID = sp.SectionID
  INNER JOIN dbo.Term t ON sp.termID = t.termID
  INNER JOIN dbo.Period p ON sp.periodID = p.periodID
WHERE
  y.endYear = CASE 
                WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                ELSE YEAR(GETDATE())
             END;
