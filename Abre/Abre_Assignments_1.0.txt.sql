SET NOCOUNT ON;

-- Step 1: Declare dynamic EndYear
DECLARE @TargetEndYear INT =
CASE 
  WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
  ELSE YEAR(GETDATE())
END;

-- Step 2: Scope to this school year's calendars
WITH TargetCalendars AS (
  SELECT c.calendarID
  FROM dbo.Calendar c
  WHERE c.endYear = @TargetEndYear
),

-- Active students: primary service, not no-show, within date window (no specific enrollment codes)
ActiveStudents AS (
  SELECT
      s.personID,
      s.studentNumber,
      s.calendarID
  FROM dbo.Student s
  JOIN TargetCalendars tc
    ON tc.calendarID = s.calendarID
  WHERE s.serviceType = 'P'
    AND ISNULL(s.noShow, 0) = 0
    AND s.startDate <= CAST(GETDATE() AS date)
    AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),

-- Active class sections in this school year, collapsed to ONE row per section
ActiveClassSections AS (
  SELECT 
      cs.sectionID, 
      cs.courseNumber, 
      cs.teacherPersonID, 
      MAX(sp.termID)   AS termID,    -- collapse multiple placements
      MAX(sp.periodID) AS periodID
  FROM dbo.v_ClassSection cs
  LEFT JOIN dbo.SectionPlacement sp
    ON cs.sectionID = sp.sectionID
  WHERE cs.endYear = @TargetEndYear
  GROUP BY
      cs.sectionID,
      cs.courseNumber,
      cs.teacherPersonID
),

-- Assignments limited to active sections
FilteredAssignments AS (
  SELECT *
  FROM dbo.v_AssignmentScoresPortal asp
  WHERE asp.sectionID IN (SELECT sectionID FROM ActiveClassSections)
)

-- Step 3: Final query
SELECT DISTINCT
  stu.studentNumber                                    AS [StudentID],
  cs.courseNumber                                      AS [CourseCode],
  asp.sectionID                                        AS [SectionCode],
  sch.number                                           AS [SchoolCode],
  cs.teacherpersonID                                   AS [StaffID],
  t.name                                               AS [Term Code],
  p.name                                               AS [Period],
  REPLACE(REPLACE(REPLACE(REPLACE(asp.name, ',', ''), CHAR(9), ' '), CHAR(13), ''), CHAR(10), '') AS [Title],
  NULL                                                 AS [Description],
  CONVERT(VARCHAR(10), asp.duedate, 23)                AS [DueDate],     -- YYYY-MM-DD
  lpg.name                                             AS [Category],
  CASE 
    WHEN asp.dropped = 1     THEN 'Dropped'
    WHEN asp.exempt = 1      THEN 'Exempt'
    WHEN asp.cheated = 1     THEN 'Cheated'
    WHEN asp.missing = 1     THEN 'Missing'
    WHEN asp.incomplete = 1  THEN 'Incomplete'
    ELSE CAST(asp.scorepoints AS VARCHAR(50))
  END                                                  AS [EarnedPoints],
  asp.totalpoints                                      AS [PossiblePoints],
  asp.weight                                           AS [Weight],
  REPLACE(REPLACE(REPLACE(REPLACE(asp.comments, ',', ''), CHAR(9), ' '), CHAR(13), ''), CHAR(10), '') AS [Comment],
  CASE WHEN asp.draft = 'T' THEN 'Y' ELSE 'N' END      AS [Published]
FROM FilteredAssignments      asp
JOIN ActiveStudents           stu ON asp.personID = stu.personID
JOIN ActiveClassSections      cs  ON asp.sectionID = cs.sectionID
LEFT JOIN dbo.Term            t   ON cs.termID   = t.termID
LEFT JOIN dbo.Period          p   ON cs.periodID = p.periodID
LEFT JOIN dbo.LessonPlanGroup lpg ON asp.groupid = lpg.groupid
LEFT JOIN dbo.Calendar        cal ON stu.calendarID = cal.calendarID
LEFT JOIN dbo.School          sch ON cal.schoolID   = sch.schoolID;