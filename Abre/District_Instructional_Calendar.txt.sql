/* Returns: end_year, date, day_of_week, school_day, term, grade_range, school_code
   - Uses dbo.Day (schoolDay already 0/1)
   - Excludes schools with no primary enrollments in the target endYear
   - Term matched by Day.structureID -> TermSchedule.structureID -> Term.termScheduleID AND date
*/

DECLARE @TargetEndYear int =
  CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1 ELSE YEAR(GETDATE()) END;

DECLARE @YearStart date = DATEFROMPARTS(@TargetEndYear - 1, 7, 1);
DECLARE @YearEnd   date = DATEFROMPARTS(@TargetEndYear,     6, 30);

;WITH TargetCalendars AS (
  SELECT c.calendarID, c.schoolID, c.endYear
  FROM dbo.Calendar c
  WHERE c.endYear = @TargetEndYear
),
DaysThisYear AS (
  SELECT
    tc.endYear,
    d.calendarID,
    tc.schoolID,
    d.structureID,
    CAST(d.[date] AS date) AS cal_date,
    d.schoolDay            -- already 0/1
  FROM dbo.[Day] d
  JOIN TargetCalendars tc
    ON tc.calendarID = d.calendarID
),
/* Term by (structureID + date): Day.structureID -> TermSchedule.structureID -> Term.termScheduleID */
TermPick AS (
  SELECT
    dy.calendarID,
    dy.cal_date,
    tp.term_name
  FROM DaysThisYear dy
  OUTER APPLY (
    SELECT TOP (1) t.name AS term_name
    FROM dbo.Term t
    JOIN dbo.TermSchedule ts
      ON ts.termScheduleID = t.termScheduleID
    WHERE ts.structureID = dy.structureID
      AND dy.cal_date BETWEEN CAST(t.startDate AS date) AND CAST(t.endDate AS date)
    ORDER BY t.startDate DESC
  ) tp
),
/* Grades present among enrolled students at each school in the active calendars */
GradesPerSchool AS (
  SELECT
    tc.schoolID,
    MIN(CASE
          WHEN e.grade IN ('PK','PR','IT') THEN -1
          WHEN e.grade IN ('KG','K','KDG')  THEN 0
          WHEN TRY_CONVERT(int, e.grade) IS NOT NULL THEN TRY_CONVERT(int, e.grade)
          ELSE NULL
        END) AS min_grade_val,
    MAX(CASE
          WHEN e.grade IN ('PK','PR','IT') THEN -1
          WHEN e.grade IN ('KG','K','KDG')  THEN 0
          WHEN TRY_CONVERT(int, e.grade) IS NOT NULL THEN TRY_CONVERT(int, e.grade)
          ELSE NULL
        END) AS max_grade_val
  FROM dbo.Enrollment e
  JOIN TargetCalendars tc
    ON tc.calendarID = e.calendarID
  WHERE e.serviceType = 'P'
    AND e.startDate <= @YearEnd
    AND (e.endDate IS NULL OR e.endDate >= @YearStart)
  GROUP BY tc.schoolID
),
GradeRange AS (
  SELECT
    gps.schoolID,
    CONCAT(
      CASE gps.min_grade_val WHEN -1 THEN 'PK' WHEN 0 THEN 'KG' ELSE CAST(gps.min_grade_val AS varchar(2)) END,
      '-',
      CASE gps.max_grade_val WHEN -1 THEN 'PK' WHEN 0 THEN 'KG' ELSE CAST(gps.max_grade_val AS varchar(2)) END
    ) AS grade_range
  FROM GradesPerSchool gps
)
SELECT
  dy.endYear                                        AS end_year,
  dy.cal_date                                       AS [date],
  DATENAME(weekday, dy.cal_date)                    AS day_of_week,
  dy.schoolDay                                      AS school_day,      -- already 0/1
  tp.term_name                                      AS term,
  gr.grade_range,
  s.number                                          AS school_code
FROM DaysThisYear dy
LEFT JOIN TermPick tp
       ON tp.calendarID = dy.calendarID
      AND tp.cal_date   = dy.cal_date
JOIN dbo.Calendar c
  ON c.calendarID = dy.calendarID
JOIN dbo.School s
  ON s.schoolID = c.schoolID
-- Exclude schools without enrolled students:
INNER JOIN GradeRange gr
        ON gr.schoolID = dy.schoolID
ORDER BY s.number, dy.cal_date;