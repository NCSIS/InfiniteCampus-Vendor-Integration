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
    SELECT s.personID, s.firstName, s.lastName
    FROM dbo.Student s
    JOIN TargetCalendars tc ON s.calendarID = tc.calendarID
    WHERE s.serviceType = 'P'
      AND ISNULL(s.noShow, 0) = 0
      AND s.startDate <= CAST(GETDATE() AS date)
      AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
)
SELECT
    qs.personID AS StudentID,
    qs.lastName AS StudentLastName,
    qs.firstName AS StudentFirstName,
    t.name AS CategoryName,
    CONVERT(VARCHAR, ts.date, 23) AS TestingDate,
    ts.scalescore AS Score
FROM dbo.TestScore ts
INNER JOIN dbo.Test t 
    ON ts.testid = t.testid
INNER JOIN QualifiedStudents qs 
    ON qs.personID = ts.personID
WHERE 
    t.act = 1
    AND (ts.date IS NOT NULL OR ts.scalescore IS NOT NULL);