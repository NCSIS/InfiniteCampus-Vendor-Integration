SELECT DISTINCT
  cs.teacherpersonID AS [StaffID],               -- from ClassSection
  sch.number         AS [SchoolCode],
  cs.coursenumber    AS [CourseCode],
  cs.sectionID AS [SectionCode],
  tm.name            AS [TermCode],
  ss.periodStart     AS [Period],
  CAST(cs.coursenumber AS varchar(10)) + '-' + CAST(cs.sectionnumber AS varchar(10)) + ' ' + cs.coursename AS [CourseName],
  i.lastName + ', ' + i.firstName AS [TeacherName]   -- current identity
FROM dbo.v_ClassSection AS cs
INNER JOIN dbo.Calendar      AS cl  ON cl.calendarID = cs.calendarID
INNER JOIN dbo.School        AS sch ON sch.schoolID  = cs.schoolID

-- ensure most current identity for the teacher
INNER JOIN dbo.Person        AS p   ON p.personID    = cs.teacherpersonID
INNER JOIN dbo.[Identity]    AS i   ON i.identityID  = p.currentIdentityID

LEFT  JOIN dbo.v_SectionSchedule AS ss ON ss.sectionID = cs.sectionID
LEFT  JOIN dbo.SectionPlacement  AS sp ON ss.sectionID = sp.sectionID
LEFT  JOIN dbo.[Term]            AS tm ON tm.termID    = sp.termID
LEFT  JOIN dbo.Room              AS rm ON rm.roomID    = cs.roomID
LEFT  JOIN dbo.SchoolYear        AS sy ON sy.endyear   = cl.endyear
WHERE
  sy.endyear = CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                    ELSE YEAR(GETDATE())
               END;