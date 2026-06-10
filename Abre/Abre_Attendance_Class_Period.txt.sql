SET NOCOUNT ON;

DECLARE @TargetEndYear INT = CASE 
    WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
    ELSE YEAR(GETDATE())
END;

WITH TargetCalendars AS (
    SELECT calendarID
    FROM Calendar
    WHERE endYear = @TargetEndYear
),
QualifiedStudents AS (
    SELECT 
        s.personID,
        s.calendarID,
        s.studentNumber,
        s.schoolID
    FROM Student s
    JOIN TargetCalendars tc 
      ON s.calendarID = tc.calendarID
    WHERE 
        s.serviceType = 'P'                  -- primary enrollment
        AND ISNULL(s.noShow, 0) = 0
        AND s.startDate <= CAST(GETDATE() AS date)
        AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
)
SELECT
    qs.studentNumber                                      AS [Student ID],
    qs.schoolID                                           AS [School Code],
    CAST(a.date AS date)                                  AS [Absence Date],

    ae.code                                               AS [Absence Reason Code],
    ae.description                                        AS [Absence Reason Description],
    a.excuse                                              AS [Absence Category Code],

    -- For now, treat each marked record as 1.0 hour
    CAST(1.0 AS DECIMAL(10,2))                            AS [Hours Missed],

    -- Period label from Period table, fallback to periodID if needed
    COALESCE(p.name,
             CAST(a.periodID AS varchar(10)))             AS [Period Missed],

    ''                                                    AS [Course Code]   -- placeholder
FROM Attendance a
JOIN QualifiedStudents qs
  ON a.personID   = qs.personID
 AND a.calendarID = qs.calendarID
LEFT JOIN AttendanceExcuse ae
  ON ae.excuseID = a.excuseID
LEFT JOIN Period p
  ON p.periodID = a.periodID
  -- AND p.calendarID = a.calendarID   -- add this if Period has calendarID and you want to scope it
WHERE 
    ae.code IS NOT NULL       -- no null attendance code
    AND ae.code <> '1L'       -- exclude 1L
ORDER BY
    [Student ID],
    [Absence Date],
    [Period Missed];