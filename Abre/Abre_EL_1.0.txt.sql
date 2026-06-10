-- Resolve "this school year" EndYear from today's date
DECLARE @TargetEndYear INT =
    CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
         ELSE YEAR(GETDATE()) END;

;WITH TargetCalendars AS (
    SELECT c.calendarID
    FROM dbo.Calendar c
    WHERE c.endYear = @TargetEndYear
),
ActiveEnrollment AS (
    SELECT
        s.personID,
        s.calendarID,
        s.schoolID,
        s.studentNumber,
        s.firstName, s.lastName,
        s.stateID,
        s.startDate, s.endDate,
        ROW_NUMBER() OVER (
          PARTITION BY s.personID
          ORDER BY
            CASE WHEN s.endDate IS NULL THEN 1 ELSE 0 END DESC,
            s.endDate DESC,
            s.startDate DESC
        ) AS rn
    FROM dbo.v_AdHocStudent s
    JOIN TargetCalendars tc
      ON tc.calendarID = s.calendarID
    -- JOIN base Student to access noShow flag
    JOIN dbo.Student st
      ON st.personID  = s.personID
     AND st.calendarID = s.calendarID
    WHERE s.serviceType = 'P'
      AND ISNULL(st.noShow, 0) = 0   -- << moved noShow filter here
      AND s.startDate <= CAST(GETDATE() AS date)
      AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),
QualifiedStudents AS (
    SELECT * FROM ActiveEnrollment WHERE rn = 1
)
SELECT
    qs.studentNumber                                                          AS [Student ID],
    qs.firstName                                                              AS [Student First Name],
    qs.lastName                                                               AS [Student Last Name],

    -- EL status with monitoring windows (based on aggregated LEP snapshot)
    CASE 
      WHEN GETDATE() BETWEEN leps.exitDate AND leps.FirstYearMonitoring
        THEN CONCAT(REPLACE(leps.programStatus, 'Exited EL', 'EL'), ': First Year Monitoring')
      WHEN GETDATE() BETWEEN leps.FirstYearMonitoring AND leps.SecondYearMonitoring
        THEN CONCAT(REPLACE(leps.programStatus, 'Exited EL', 'EL'), ': Second Year Monitoring')
      WHEN GETDATE() BETWEEN leps.SecondYearMonitoring AND leps.ThirdYearMonitoring
        THEN CONCAT(REPLACE(leps.programStatus, 'Exited EL', 'EL'), ': Third Year Monitoring')
      WHEN GETDATE() BETWEEN leps.ThirdYearMonitoring AND leps.FourthYearMonitoring
        THEN CONCAT(REPLACE(leps.programStatus, 'Exited EL', 'EL'), ': Fourth Year Monitoring')
      WHEN GETDATE() BETWEEN leps.FifthYearMonitoring AND DATEADD(YEAR, 1, leps.FifthYearMonitoring)
        THEN CONCAT(REPLACE(leps.programStatus, 'Exited EL', 'EL'), ': Fifth Year Monitoring')
      ELSE REPLACE(leps.programStatus, 'Exited EL', 'EL')
    END                                                                        AS [ELStatus],

    -- YYYY-MM-DD
    CONVERT(varchar(10), leps.identifiedDate, 23)                              AS [Date Identified],

    NULL                                                                       AS [Home Language],
    i.homePrimaryLanguage                                                      AS [Home Language Code],
    NULL                                                                       AS [Native Language],
    i.homePrimaryLanguage                                                      AS [Native Language Code],
    i.birthState                                                               AS [Place of Birth],
    NULL                                                                       AS [Country of Birth],
    i.birthCountry                                                             AS [Country of Birth Code],

    -- YYYY-MM-DD
    CONVERT(varchar(10), i.dateEnteredUSSchool, 23)                            AS [US Start Date],

    NULL                                                                       AS [English Proficiency]

FROM QualifiedStudents qs

-- Collapse LEP to a single "current snapshot" per student
OUTER APPLY (
    SELECT
        MAX(lep.programStatus)             AS programStatus,
        MAX(lep.exitDate)                  AS exitDate,
        MAX(lep.firstYearMonitoring)       AS FirstYearMonitoring,
        MAX(lep.secondYearMonitoring)      AS SecondYearMonitoring,
        MAX(lep.thirdYearMonitoring)       AS ThirdYearMonitoring,
        MAX(lep.fourthYearMonitoring)      AS FourthYearMonitoring,
        MAX(lep.fifthYearMonitoring)       AS FifthYearMonitoring,
        MAX(lep.identifiedDate)            AS identifiedDate
    FROM dbo.LEP lep
    WHERE lep.personID = qs.personID
) leps

-- Optional program linkage (kept from your sketch)
LEFT JOIN dbo.ProgramParticipation propar
    ON propar.personID = qs.personID
   AND propar.endDate IS NULL
LEFT JOIN dbo.Program prog
    ON prog.programID = propar.programID

-- Identity (for language & birth fields)
LEFT JOIN dbo.Person p
    ON p.personID = qs.personID
LEFT JOIN dbo.[Identity] i
    ON i.identityID = p.currentIdentityID

WHERE
    -- Active LEP now OR in monitoring window
    (
        (leps.programStatus = 'LEP' AND (leps.exitDate IS NULL OR leps.exitDate >= GETDATE()))
        OR
        (leps.programStatus LIKE 'Exited EL%' AND (
             (leps.exitDate IS NOT NULL AND GETDATE() BETWEEN leps.exitDate AND ISNULL(leps.FirstYearMonitoring, leps.exitDate)) OR
             (leps.FirstYearMonitoring   IS NOT NULL AND GETDATE() BETWEEN leps.FirstYearMonitoring   AND ISNULL(leps.SecondYearMonitoring,   DATEADD(DAY, 0, leps.FirstYearMonitoring))) OR
             (leps.SecondYearMonitoring  IS NOT NULL AND GETDATE() BETWEEN leps.SecondYearMonitoring  AND ISNULL(leps.ThirdYearMonitoring,    DATEADD(DAY, 0, leps.SecondYearMonitoring))) OR
             (leps.ThirdYearMonitoring   IS NOT NULL AND GETDATE() BETWEEN leps.ThirdYearMonitoring   AND ISNULL(leps.FourthYearMonitoring,   DATEADD(DAY, 0, leps.ThirdYearMonitoring))) OR
             (leps.FourthYearMonitoring  IS NOT NULL AND GETDATE() BETWEEN leps.FourthYearMonitoring  AND ISNULL(leps.FifthYearMonitoring,    DATEADD(DAY, 0, leps.FourthYearMonitoring))) OR
             (leps.FifthYearMonitoring   IS NOT NULL AND GETDATE() BETWEEN leps.FifthYearMonitoring   AND DATEADD(YEAR, 1, leps.FifthYearMonitoring))
        ))
    )
    AND ISNULL(qs.stateID, '') <> '';