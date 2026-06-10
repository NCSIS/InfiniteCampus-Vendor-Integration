;WITH TargetCalendars AS (
    SELECT c.calendarID
    FROM dbo.Calendar c
    WHERE c.endYear = CASE 
                          WHEN MONTH(GETDATE()) >= 7 
                              THEN YEAR(GETDATE()) + 1
                          ELSE YEAR(GETDATE()) 
                      END
),
ActiveEnrollment AS (
    SELECT
        s.personID,
        s.calendarID,
        s.schoolID,
        s.studentNumber,
        s.firstName, 
        s.middleName, 
        s.lastName,
        s.birthdate, 
        s.gender,
        s.raceEthnicityFed,
        s.raceEthnicity,              -- may be numeric
        s.grade,
        s.serviceType,
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
    FROM dbo.v_AdHocStudent s
    JOIN TargetCalendars tc
      ON tc.calendarID = s.calendarID
    JOIN dbo.Student st
      ON st.personID   = s.personID
     AND st.calendarID = s.calendarID
    WHERE s.serviceType = 'P'
      AND ISNULL(st.noShow, 0) = 0
      AND s.startDate <= CAST(GETDATE() AS date)
      AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),
QualifiedStudents AS (
    SELECT * 
    FROM ActiveEnrollment 
    WHERE rn = 1
),
ContactSelf AS (
  SELECT
    c.personID,
    c.email,
    ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
  FROM dbo.v_CensusContactSummary c WITH (NOLOCK)
  WHERE c.relationship = 'Self'
)
SELECT
    qs.studentNumber                                                           AS [Student ID],
    qs.firstName                                                               AS [Student First Name],
    qs.middleName                                                              AS [Student Middle Name],
    qs.lastName                                                                AS [Student Last Name],
    qs.gender                                                                  AS [Gender],
    qs.raceEthnicityFed                                                        AS [Ethnicity Code],

    /* Ethnicity description mapping (numeric from raceEthnicity or raceEthnicityFed only) */
    COALESCE(
        -- numeric code in raceEthnicity
        CASE 
            WHEN TRY_CONVERT(int, qs.raceEthnicity) IS NOT NULL THEN
                CASE TRY_CONVERT(int, qs.raceEthnicity)
                    WHEN 1 THEN 'Hispanic/Latino'
                    WHEN 2 THEN 'American Indian or Alaskan Native'
                    WHEN 3 THEN 'Asian'
                    WHEN 4 THEN 'Black or African American'
                    WHEN 5 THEN 'Native Hawaiian/Other Pacific Islander'
                    WHEN 6 THEN 'White'
                    WHEN 7 THEN 'Two or more races'
                END
        END,
        -- numeric code in raceEthnicityFed
        CASE 
            WHEN TRY_CONVERT(int, qs.raceEthnicityFed) IS NOT NULL THEN
                CASE TRY_CONVERT(int, qs.raceEthnicityFed)
                    WHEN 1 THEN 'Hispanic/Latino'
                    WHEN 2 THEN 'American Indian or Alaskan Native'
                    WHEN 3 THEN 'Asian'
                    WHEN 4 THEN 'Black or African American'
                    WHEN 5 THEN 'Native Hawaiian/Other Pacific Islander'
                    WHEN 6 THEN 'White'
                    WHEN 7 THEN 'Two or more races'
                END
        END
    )                                                                           AS [Ethnicity Description],

    CONVERT(varchar(10), qs.birthdate, 23)                                      AS [BirthDate],      -- yyyy-mm-dd
    cs.email                                                                    AS [Email],
    qs.stateID                                                                  AS [SSID],

    -- IEP Y/N
    CASE 
        WHEN ses.primarydisability IS NOT NULL
             AND (ses.exitdate IS NULL OR ses.exitdate >= CAST(GETDATE() AS date))
        THEN 'Y' ELSE 'N'
    END                                                                          AS [IEP Status],

    -- Gifted Y/N (latest row by startDate; Y if any row exists)
    CASE WHEN aig1.personID IS NOT NULL THEN 'Y' ELSE 'N' END                   AS [Gifted Status],

    -- FRL existence (column-agnostic)
    CASE WHEN frlcur.personid IS NOT NULL THEN 'Y' ELSE 'N' END                 AS [Economically Disadvantaged],
    NULL                                                                        AS [Title 1],
    NULL                                                                        AS [Title 3],

    CASE WHEN mlcur.ProgramStatus = 'LEP' THEN 'Y' ELSE 'N' END                 AS [ELL Status],

    sch.number                                                                  AS [School Code],
    sch.name                                                                    AS [School Name],
    qs.grade                                                                    AS [Grade],

    CASE
        WHEN qs.endDate IS NULL OR qs.endDate >= GETDATE() THEN 'A'
        WHEN qs.endDate < GETDATE() THEN 'I'
        ELSE 'I'
    END                                                                          AS [Status],

    CASE
        WHEN cs.email LIKE '%@%' THEN LEFT(cs.email, CHARINDEX('@', cs.email) - 1)
        ELSE cs.email
    END                                                                          AS [Username],

    NULL                                                                        AS [Password],

    CASE WHEN s504cur.personid IS NOT NULL THEN 'Y' ELSE 'N' END                AS [504 Status],

    CASE WHEN ferpa.directoryquestion = 'N' THEN 'Y' ELSE '' END                AS [Ok to Publish]

FROM QualifiedStudents qs
JOIN dbo.School        sch   ON sch.schoolID    = qs.schoolID
LEFT JOIN ContactSelf  cs    ON cs.personID     = qs.personID 
                             AND cs.rowNumber   = 1
LEFT JOIN dbo.Ferpa    ferpa ON ferpa.personid  = qs.personid

-- IEP (Special Education) — status only
OUTER APPLY (
    SELECT TOP (1) ses.*
    FROM dbo.SpecialEdState ses
    WHERE ses.personID = qs.personID
      AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
      AND ses.exitReason IS NULL
    ORDER BY ses.specialEDStateID ASC
) ses

-- 504 current
OUTER APPLY (
    SELECT TOP (1) s504_2.personid, s504_2.endDate
    FROM dbo.Section504 s504_2
    WHERE s504_2.personid = qs.personid
      AND (s504_2.endDate IS NULL OR s504_2.endDate >= CAST(GETDATE() AS date))
    ORDER BY s504_2.endDate DESC
) s504cur

-- FRL / POSE existence only (no date columns referenced)
OUTER APPLY (
    SELECT TOP (1) frl.personid
    FROM dbo.v_POSEligibilityCurrent frl
    WHERE frl.personid = qs.personid
) frlcur

-- ELL current for Y/N status
OUTER APPLY (
    SELECT TOP (1) ml.*
    FROM dbo.LEP ml
    WHERE ml.personid = qs.personID
      AND (ml.exitDate IS NULL OR ml.exitDate >= GETDATE())
      AND ml.programStatus = 'LEP'
    ORDER BY ml.identifieddate DESC
) mlcur

-- Gifted latest-by-startDate
OUTER APPLY (
    SELECT TOP (1) g.personID
    FROM dbo.Gifted g WITH (NOLOCK)
    WHERE g.personID = qs.personID
    ORDER BY g.startDate DESC
) aig1

WHERE ISNULL(qs.stateID, '') <> '';