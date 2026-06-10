;WITH RelevantCalendars AS (
  SELECT calendarID
  FROM dbo.Calendar y
  WHERE y.endYear = CASE
                      WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                      ELSE YEAR(GETDATE())
                    END
),
QualifiedStudents AS (
  SELECT s.personID, s.studentNumber
  FROM dbo.Student s
  JOIN RelevantCalendars rc ON s.calendarID = rc.calendarID
  WHERE 
      s.serviceType = 'P'
  AND ISNULL(s.noShow, 0) = 0
  AND s.startDate <= CAST(GETDATE() AS date)
  AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
)

SELECT
  s.studentNumber      AS [StudentID],      -- << switched from personID
  gs.coursenumber      AS [CourseCode],
  gs.sectionID         AS [SectionCode],
  sch.number           AS [SchoolID],
  gs.teacherpersonID   AS [StaffID],
gs.termname AS [Term Code],
  gs.periodName        AS [Period],
  gs.courseName        AS [ClassName],
  gs.teacherDisplay    AS [TeacherName],

  -- LetterGrade: value before slash
  CASE
    WHEN CHARINDEX('/', COALESCE(gs.progressScore, gs.score)) > 0
      THEN LEFT(COALESCE(gs.progressScore, gs.score),
                CHARINDEX('/', COALESCE(gs.progressScore, gs.score)) - 1)
    ELSE NULL
  END                  AS [LetterGrade],

  -- Percentage: numeric after slash (or progressPercent)
  COALESCE(
    TRY_CAST(gs.progressPercent AS DECIMAL(5,2)),
    CASE
      WHEN CHARINDEX('/', gs.score) > 0 AND TRY_CAST(
             SUBSTRING(gs.score, CHARINDEX('/', gs.score) + 1,
                       LEN(gs.score) - CHARINDEX('/', gs.score)) AS DECIMAL(5,2)
           ) IS NOT NULL
      THEN SUBSTRING(gs.score, CHARINDEX('/', gs.score) + 1,
                     LEN(gs.score) - CHARINDEX('/', gs.score))
      ELSE NULL
    END
  )                    AS [Percentage],

  NULL                 AS [Performance]

FROM v_GradingScores gs
JOIN RelevantCalendars rc
  ON rc.calendarID = gs.calendarID
JOIN QualifiedStudents s
  ON s.personID = gs.personID
JOIN dbo.Calendar c
  ON c.calendarID = gs.calendarID
JOIN dbo.School sch
  ON sch.schoolID = c.schoolID

ORDER BY s.studentNumber;
