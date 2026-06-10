SET NOCOUNT ON;

DECLARE @EndYear INT = CASE 
    WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
    ELSE YEAR(GETDATE())
END;

WITH TargetCalendars AS (
  SELECT calendarID
  FROM dbo.Calendar
  WHERE endYear = @EndYear
),
QualifiedStudents AS (
  SELECT s.personID, s.calendarID, s.studentNumber, s.schoolID
  FROM dbo.Student s
  JOIN TargetCalendars tc ON s.calendarID = tc.calendarID
  WHERE s.serviceType = 'P'
    AND ISNULL(s.noShow, 0) = 0
    AND s.startDate <= CAST(GETDATE() AS date)
    AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),
InstructionDays AS (
  SELECT d.calendarID, COUNT(*) AS TotalInstructionDays
  FROM dbo.Day d
  JOIN TargetCalendars c ON d.calendarID = c.calendarID
  WHERE d.instruction = 1
  GROUP BY d.calendarID
)
SELECT
    qs.studentNumber AS [StudentID],
    COUNT(*) AS [DaysEnrolled],
    ROUND(SUM(
        CASE
            WHEN COALESCE(ada.scheduledMinutes, 0) <= 0 THEN 0
            ELSE CAST(1 - ada.absentMinutes * 1.0 / ada.scheduledMinutes AS DECIMAL(5, 2))
        END), 0) AS [DaysAttended],
    ROUND(SUM(
        CASE
            WHEN COALESCE(ada.scheduledMinutes, 0) > 0 THEN CAST(ada.absentMinutes * 1.0 / ada.scheduledMinutes AS DECIMAL(5, 2))
            ELSE 0
        END), 0) AS [DaysAbsentTotal],
    ROUND(
        (SUM(ada.absentMinutes) - SUM(ada.unexcusedAbsentMinutes)) / NULLIF(MAX(ada.scheduledMinutes), 0),
        0
    ) AS [DaysAbsentExcused],
    ROUND(SUM(
        CASE
            WHEN COALESCE(ada.absentMinutes, 0) > 0 THEN CAST(ada.unexcusedAbsentMinutes * 1.0 / ada.scheduledMinutes AS DECIMAL(5, 2))
            ELSE 0
        END), 0) AS [DaysAbsentUnexcused],
    ROUND(SUM(
        CASE
            WHEN COALESCE(ada.scheduledMinutes, 0) - ada.absentMinutes >= 0 THEN (
                COALESCE(ada.scheduledMinutes, 0) - ada.absentMinutes
            ) / 60.0
            ELSE 0
        END
    ), 2) AS [HoursAttended],
    ROUND((SUM(ada.absentMinutes) - SUM(ada.unexcusedAbsentMinutes)) / 60.0, 2) AS [HoursAbsentExcused],
    ROUND(SUM(
        CASE
            WHEN COALESCE(ada.scheduledMinutes, 0) > 0 THEN ada.unexcusedAbsentMinutes * 1.0 / 60.0
            ELSE 0
        END), 2) AS [HoursAbsentUnexcused],
    MAX(id.TotalInstructionDays) AS [MaxEnrollment],
    FLOOR(0.10 * COUNT(*)) AS [MaxAllowedAbsences],
    ROUND(SUM(
        CASE
            WHEN COALESCE(ada.scheduledMinutes, 0) > 0 THEN CAST(ada.absentMinutes * 1.0 / ada.scheduledMinutes AS DECIMAL(5, 2))
            ELSE 0
        END), 0) AS [CurrentAbsences],
    CAST(ROUND(
        SUM(
            CASE
                WHEN COALESCE(ada.scheduledMinutes, 0) <= 0 THEN 0
                ELSE 1 - ada.absentMinutes * 1.0 / ada.scheduledMinutes
            END
        ) / NULLIF(MAX(id.TotalInstructionDays), 0), 2
    ) AS DECIMAL(4, 2)) AS [ADA (Average Daily Attendance)],
    NULL AS [Recoverability]
FROM dbo.AttDayAggregation ada
JOIN QualifiedStudents qs ON qs.personID = ada.personID AND qs.calendarID = ada.calendarID
JOIN InstructionDays id ON id.calendarID = ada.calendarID
GROUP BY
    qs.studentNumber
ORDER BY
    qs.studentNumber;