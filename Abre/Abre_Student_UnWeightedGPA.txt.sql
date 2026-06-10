WITH TargetCalendars AS (
    SELECT c.calendarID
    FROM dbo.Calendar c
    WHERE c.endYear = CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                           ELSE YEAR(GETDATE()) END
),
ActiveEnrollment AS (
    SELECT
        s.personID,
        s.calendarID,
        s.schoolID,
        s.studentNumber,
        s.firstName,
        s.lastName,
        s.stateID,
        s.startDate,
        s.endDate,
        ROW_NUMBER() OVER (
            PARTITION BY s.personID
            ORDER BY
                CASE WHEN s.endDate IS NULL THEN 1 ELSE 0 END DESC,
                s.endDate DESC,
                s.startDate DESC
        ) AS rn
    FROM dbo.Student s
    JOIN TargetCalendars tc ON tc.calendarID = s.calendarID
    WHERE s.serviceType = 'P'
      AND ISNULL(s.noShow, 0) = 0        -- if this errors in your site, remove this line
      AND s.startDate <= CAST(GETDATE() AS date)
      AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),
QualifiedStudents AS (
    SELECT *
    FROM ActiveEnrollment
    WHERE rn = 1
)
SELECT
    qs.studentNumber            AS [Student ID],
    qs.firstName                AS [First Name],
    qs.lastName                 AS [Last Name],
    gpa.cumGpaUnweighted        AS [GPA],
    sch.number                  AS [School Building]
FROM QualifiedStudents qs
JOIN dbo.School sch
  ON sch.schoolID = qs.schoolID
LEFT JOIN dbo.v_cumgpafull gpa
  ON gpa.personid = qs.personID
 AND gpa.calendarID = qs.calendarID
WHERE ISNULL(qs.stateID, '') <> '';