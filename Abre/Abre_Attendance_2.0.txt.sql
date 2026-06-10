SET NOCOUNT ON;

DECLARE @TargetEndYear INT = CASE 
  WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
  ELSE YEAR(GETDATE())
END;

WITH TargetCalendars AS (
  SELECT calendarID
  FROM dbo.Calendar
  WHERE endYear = @TargetEndYear
),
QualifiedStudents AS (
  SELECT s.personID, s.calendarID, s.studentNumber, s.schoolID
  FROM dbo.Student s
  JOIN TargetCalendars tc ON s.calendarID = tc.calendarID
  WHERE 
    s.serviceType = 'P'
    AND ISNULL(s.noShow, 0) = 0
    AND s.startDate <= CAST(GETDATE() AS date)
    AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),
FilteredAttendance AS (
  SELECT 
    a.personID,
    a.calendarID,
    a.date,
    a.code,
    a.description,
    a.excuse,
    a.status,
    a.periodID,
    a.presentMinutes
  FROM dbo.v_AttendanceDetail a
  INNER JOIN TargetCalendars tc ON a.calendarID = tc.calendarID
  WHERE 
    a.status <> 'P'
    AND a.code IS NOT NULL
    AND a.code <> '1L'
)
SELECT
  qs.studentNumber AS [StudentID],
  sc.number        AS [SchoolCode],
  CONVERT(VARCHAR(10), fa.date, 23) AS [AbsenceDate],
  MAX(fa.code)        AS [AbsenceReasonCode],
  MAX(fa.description) AS [AbsenceReasonDescription],
  MAX(fa.excuse)      AS [AbsenceCategoryCode],
  ROUND(SUM(CAST(p.periodMinutes - ISNULL(fa.presentMinutes, 0) AS FLOAT)) / 60.0, 2) AS [HoursMissed],
  NULL AS [AttendanceLevel]
FROM FilteredAttendance fa
INNER JOIN QualifiedStudents qs 
    ON fa.personID = qs.personID 
   AND fa.calendarID = qs.calendarID
INNER JOIN dbo.School sc 
    ON sc.schoolID = qs.schoolID
INNER JOIN dbo.Period p 
    ON p.periodID = fa.periodID
GROUP BY
  qs.studentNumber,
  sc.number,
  fa.date
ORDER BY
  fa.date DESC;