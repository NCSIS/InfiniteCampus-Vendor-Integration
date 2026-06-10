/* Student roster snapshot with resilient noShow handling
   - If dbo.Student.noShow exists -> use it
   - Else if dbo.Student.NoShow exists -> use it
   - Else -> proceed without a noShow filter
   - FIX: FRL now uses a column-agnostic existence check (no date columns referenced).
   - Ethnicity_Description is conversion-safe.
*/

IF COL_LENGTH('dbo.Student','noShow') IS NOT NULL
BEGIN
  ;WITH TargetCalendars AS (
      SELECT c.calendarID
      FROM dbo.Calendar c
      WHERE c.endYear = CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1 ELSE YEAR(GETDATE()) END
  ),
  StudentsThisYear AS (
      SELECT
          s.personID, s.calendarID, s.schoolID, s.studentNumber,
          s.firstName, s.middleName, s.lastName,
          s.birthdate, s.gender, s.raceEthnicityFed, s.raceEthnicity,
          s.grade, s.serviceType, s.stateID
      FROM dbo.v_AdHocStudent s
      JOIN TargetCalendars tc ON tc.calendarID = s.calendarID
      JOIN dbo.Student st ON st.personID = s.personID AND st.calendarID = s.calendarID
      WHERE s.serviceType = 'P'
        AND ISNULL(st.noShow, 0) = 0
  ),
  ContactSelf AS (
    SELECT
      c.personID, c.email,
      ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM v_CensusContactSummary c
    WHERE c.relationship = 'Self'
  )
  SELECT
      sty.studentNumber                                                                 AS [Student_ID],
      sty.firstName                                                                     AS [Student_First_Name],
      sty.middleName                                                                    AS [Student_Middle_Name],
      sty.lastName                                                                      AS [Student_Last_Name],
      sty.gender                                                                        AS [Gender],
      sty.raceEthnicityFed                                                              AS [Ethnicity_Code],
      COALESCE(
        CASE TRY_CONVERT(int, sty.raceEthnicity)
          WHEN 1 THEN 'Hispanic/Latino'
          WHEN 2 THEN 'American Indian or Alaskan Native'
          WHEN 3 THEN 'Asian'
          WHEN 4 THEN 'Black or African American'
          WHEN 5 THEN 'Native Hawaiian/Other Pacific Islander'
          WHEN 6 THEN 'White'
          WHEN 7 THEN 'Two or more races'
          ELSE NULL
        END,
        CASE UPPER(NULLIF(LTRIM(RTRIM(sty.raceEthnicityFed)), ''))
          WHEN 'H' THEN 'Hispanic/Latino'
          WHEN 'I' THEN 'American Indian or Alaskan Native'
          WHEN 'A' THEN 'Asian'
          WHEN 'B' THEN 'Black or African American'
          WHEN 'P' THEN 'Native Hawaiian/Other Pacific Islander'
          WHEN 'W' THEN 'White'
          WHEN 'M' THEN 'Two or more races'
          ELSE NULL
        END
      )                                                                                 AS [Ethnicity_Description],
      CONVERT(varchar(10), sty.birthdate, 23)                                           AS [Date_of_Birth],
      cs.email                                                                          AS [Email],
      sty.stateID                                                                       AS [SSID],
      ses.primaryDisability                                                             AS [IEP_Status],
      CASE WHEN aig1.personID IS NOT NULL THEN 'Y' ELSE 'N' END                         AS [Gifted_Status],

      /* FRL current: existence in v_POSEligibilityCurrent (no date columns) */
      CASE WHEN frlcur.personid IS NOT NULL THEN 'Y' ELSE 'N' END                       AS [Economically_Disadvantaged],

      NULL                                                                              AS [Title_1],
      NULL                                                                              AS [Title_3],
      CASE WHEN mlcur.ProgramStatus = 'LEP' THEN 'Y' ELSE 'N' END                       AS [ELL_Status],
      sch.number                                                                        AS [School_Code],
      sch.name                                                                          AS [School_Name],
      sty.grade                                                                         AS [Current_Grade],
      CASE 
        WHEN e.startDate <= CAST(GETDATE() AS date)
         AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date))
        THEN 'A' ELSE 'I'
      END                                                                               AS [Status],
      CASE WHEN cs.email LIKE '%@%' THEN LEFT(cs.email, CHARINDEX('@', cs.email) - 1)
           ELSE cs.email END                                                            AS [Username],
      NULL                                                                              AS [Password],
      CASE WHEN s504cur.personid IS NOT NULL THEN 'Y' ELSE 'N' END                      AS [504_Status],
      CASE WHEN ferpa.directoryquestion = 'N' THEN 'Y' ELSE '' END                      AS [Ok_to_Publish],
      CONVERT(varchar(10), d_enr.District_Date_Enrolled, 23)                            AS [District_Date_Enrolled],
      CONVERT(varchar(10),
              CASE WHEN cur_any.IsCurrent = 1 THEN NULL ELSE last_wd.LastEndDate END,23)AS [District_Date_Withdrawn],
      CONVERT(varchar(10), e.startDate, 23)                                             AS [School_Date_Enrolled],
      CONVERT(varchar(10), e.endDate, 23)                                               AS [School_Date_Withdrawn],
      CASE 
        WHEN e.startDate <= CAST(GETDATE() AS date)
         AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date))
        THEN NULL
        ELSE CASE COALESCE(e.endStatus,'')
               WHEN 'W1'  THEN 'W1: Transfer Withdrawal'
               WHEN 'W2'  THEN 'W2: Early Leaver Withdrawal'
               WHEN 'W2T' THEN 'W2T: Early Leaver Withdrawal (With Proof of Enrollment in an Adult High School Program)'
               WHEN 'W3'  THEN 'W3: Death Withdrawal'
               WHEN 'W4'  THEN 'W4: Early Completer Withdrawal'
               WHEN 'W6'  THEN 'W6: High School Graduate'
               ELSE NULLIF(e.endStatus,'')
             END
      END                                                                               AS [Withdrawal_Reason]
  FROM StudentsThisYear sty
  JOIN dbo.Enrollment e        ON e.personID = sty.personID
  JOIN TargetCalendars tc      ON tc.calendarID = e.calendarID AND e.serviceType = 'P'
  JOIN dbo.Calendar cal        ON cal.calendarID = e.calendarID
  JOIN dbo.School sch          ON sch.schoolID = cal.schoolID
  LEFT JOIN ContactSelf cs     ON cs.personID = sty.personID AND cs.rowNumber = 1
  LEFT JOIN dbo.Ferpa ferpa    ON ferpa.personid = sty.personid

  OUTER APPLY ( SELECT TOP (1) ses.*
                FROM dbo.SpecialEdState ses
                WHERE ses.personID = sty.personID
                  AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
                  AND ses.exitReason IS NULL
                ORDER BY ses.specialEDStateID ASC ) ses

  OUTER APPLY ( SELECT TOP (1) s504_2.personid, s504_2.endDate
                FROM dbo.Section504 s504_2
                WHERE s504_2.personid = sty.personid
                  AND (s504_2.endDate IS NULL OR s504_2.endDate >= CAST(GETDATE() AS date))
                ORDER BY s504_2.endDate DESC ) s504cur

  /* FRL current (no date columns referenced) */
  OUTER APPLY ( SELECT TOP (1) frl.personid
                FROM dbo.v_POSEligibilityCurrent frl
                WHERE frl.personid = sty.personid ) frlcur

  OUTER APPLY ( SELECT TOP (1) ml.*
                FROM dbo.LEP ml
                WHERE ml.personid = sty.personID
                  AND (ml.exitDate IS NULL OR ml.exitDate >= GETDATE())
                  AND ml.programStatus = 'LEP'
                ORDER BY ml.identifieddate DESC ) mlcur

  OUTER APPLY ( SELECT MIN(e2.startDate) AS District_Date_Enrolled
                FROM dbo.Enrollment e2 WHERE e2.personID = sty.personID ) d_enr

  OUTER APPLY ( SELECT TOP (1) e3.endDate AS LastEndDate
                FROM dbo.Enrollment e3
                WHERE e3.personID = sty.personID AND e3.endDate IS NOT NULL
                ORDER BY e3.endDate DESC ) last_wd

  OUTER APPLY ( SELECT CASE WHEN EXISTS (
                  SELECT 1
                  FROM dbo.Enrollment ec
                  JOIN TargetCalendars tc2 ON tc2.calendarID = ec.calendarID
                  WHERE ec.personID = sty.personID
                    AND ec.startDate <= CAST(GETDATE() AS date)
                    AND (ec.endDate IS NULL OR ec.endDate >= CAST(GETDATE() AS date))
                ) THEN 1 ELSE 0 END AS IsCurrent ) cur_any

  OUTER APPLY ( SELECT TOP (1) g.personID
                FROM dbo.Gifted g WITH (NOLOCK)
                WHERE g.personID = sty.personID
                ORDER BY g.startDate DESC ) aig1

  WHERE ISNULL(sty.stateID, '') <> ''
  ORDER BY sty.studentNumber,
           CASE WHEN e.startDate <= CAST(GETDATE() AS date)
                  AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date)) THEN 1 ELSE 0 END DESC,
           e.startDate;
END
ELSE IF COL_LENGTH('dbo.Student','NoShow') IS NOT NULL
BEGIN
  ;WITH TargetCalendars AS (
      SELECT c.calendarID
      FROM dbo.Calendar c
      WHERE c.endYear = CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1 ELSE YEAR(GETDATE()) END
  ),
  StudentsThisYear AS (
      SELECT
          s.personID, s.calendarID, s.schoolID, s.studentNumber,
          s.firstName, s.middleName, s.lastName,
          s.birthdate, s.gender, s.raceEthnicityFed, s.raceEthnicity,
          s.grade, s.serviceType, s.stateID
      FROM dbo.v_AdHocStudent s
      JOIN TargetCalendars tc ON tc.calendarID = s.calendarID
      JOIN dbo.Student st ON st.personID = s.personID AND st.calendarID = s.calendarID
      WHERE s.serviceType = 'P'
        AND ISNULL(st.NoShow, 0) = 0
  ),
  ContactSelf AS (
    SELECT c.personID, c.email,
           ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM v_CensusContactSummary c WHERE c.relationship = 'Self'
  )
  SELECT
      sty.studentNumber AS [Student_ID],
      sty.firstName     AS [Student_First_Name],
      sty.middleName    AS [Student_Middle_Name],
      sty.lastName      AS [Student_Last_Name],
      sty.gender        AS [Gender],
      sty.raceEthnicityFed AS [Ethnicity_Code],
      COALESCE(
        CASE TRY_CONVERT(int, sty.raceEthnicity)
          WHEN 1 THEN 'Hispanic/Latino'
          WHEN 2 THEN 'American Indian or Alaskan Native'
          WHEN 3 THEN 'Asian'
          WHEN 4 THEN 'Black or African American'
          WHEN 5 THEN 'Native Hawaiian/Other Pacific Islander'
          WHEN 6 THEN 'White'
          WHEN 7 THEN 'Two or more races'
          ELSE NULL
        END,
        CASE UPPER(NULLIF(LTRIM(RTRIM(sty.raceEthnicityFed)), ''))
          WHEN 'H' THEN 'Hispanic/Latino'
          WHEN 'I' THEN 'American Indian or Alaskan Native'
          WHEN 'A' THEN 'Asian'
          WHEN 'B' THEN 'Black or African American'
          WHEN 'P' THEN 'Native Hawaiian/Other Pacific Islander'
          WHEN 'W' THEN 'White'
          WHEN 'M' THEN 'Two or more races'
          ELSE NULL
        END
      ) AS [Ethnicity_Description],
      CONVERT(varchar(10), sty.birthdate, 23) AS [Date_of_Birth],
      cs.email                                AS [Email],
      sty.stateID                             AS [SSID],
      ses.primaryDisability                   AS [IEP_Status],
      CASE WHEN aig1.personID IS NOT NULL THEN 'Y' ELSE 'N' END AS [Gifted_Status],

      /* FRL current: existence in v_POSEligibilityCurrent */
      CASE WHEN frlcur.personid IS NOT NULL THEN 'Y' ELSE 'N' END AS [Economically_Disadvantaged],

      NULL AS [Title_1],
      NULL AS [Title_3],
      CASE WHEN mlcur.ProgramStatus = 'LEP' THEN 'Y' ELSE 'N' END AS [ELL_Status],
      sch.number AS [School_Code],
      sch.name   AS [School_Name],
      sty.grade  AS [Current_Grade],
      CASE WHEN e.startDate <= CAST(GETDATE() AS date)
             AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date))
           THEN 'A' ELSE 'I' END AS [Status],
      CASE WHEN cs.email LIKE '%@%' THEN LEFT(cs.email, CHARINDEX('@', cs.email) - 1) ELSE cs.email END AS [Username],
      NULL AS [Password],
      CASE WHEN s504cur.personid IS NOT NULL THEN 'Y' ELSE 'N' END AS [504_Status],
      CASE WHEN ferpa.directoryquestion = 'N' THEN 'Y' ELSE '' END AS [Ok_to_Publish],
      CONVERT(varchar(10), d_enr.District_Date_Enrolled, 23) AS [District_Date_Enrolled],
      CONVERT(varchar(10), CASE WHEN cur_any.IsCurrent = 1 THEN NULL ELSE last_wd.LastEndDate END, 23) AS [District_Date_Withdrawn],
      CONVERT(varchar(10), e.startDate, 23) AS [School_Date_Enrolled],
      CONVERT(varchar(10), e.endDate, 23)   AS [School_Date_Withdrawn],
      CASE WHEN e.startDate <= CAST(GETDATE() AS date)
             AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date))
           THEN NULL
           ELSE CASE COALESCE(e.endStatus,'')
                  WHEN 'W1'  THEN 'W1: Transfer Withdrawal'
                  WHEN 'W2'  THEN 'W2: Early Leaver Withdrawal'
                  WHEN 'W2T' THEN 'W2T: Early Leaver Withdrawal (With Proof of Enrollment in an Adult High School Program)'
                  WHEN 'W3'  THEN 'W3: Death Withdrawal'
                  WHEN 'W4'  THEN 'W4: Early Completer Withdrawal'
                  WHEN 'W6'  THEN 'W6: High School Graduate'
                  ELSE NULLIF(e.endStatus,'') END
      END AS [Withdrawal_Reason]
  FROM StudentsThisYear sty
  JOIN dbo.Enrollment e   ON e.personID = sty.personID
  JOIN TargetCalendars tc ON tc.calendarID = e.calendarID AND e.serviceType = 'P'
  JOIN dbo.Calendar cal   ON cal.calendarID = e.calendarID
  JOIN dbo.School sch     ON sch.schoolID = cal.schoolID
  LEFT JOIN ContactSelf cs ON cs.personID = sty.personID AND cs.rowNumber = 1
  LEFT JOIN dbo.Ferpa ferpa ON ferpa.personid = sty.personid

  OUTER APPLY (SELECT TOP (1) ses.* FROM dbo.SpecialEdState ses
               WHERE ses.personID = sty.personID
                 AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
                 AND ses.exitReason IS NULL
               ORDER BY ses.specialEDStateID ASC) ses
  OUTER APPLY (SELECT TOP (1) s504_2.personid, s504_2.endDate
               FROM dbo.Section504 s504_2
               WHERE s504_2.personid = sty.personid
                 AND (s504_2.endDate IS NULL OR s504_2.endDate >= CAST(GETDATE() AS date))
               ORDER BY s504_2.endDate DESC) s504cur
  OUTER APPLY ( SELECT TOP (1) frl.personid
                FROM dbo.v_POSEligibilityCurrent frl
                WHERE frl.personid = sty.personid ) frlcur
  OUTER APPLY (SELECT TOP (1) ml.*
               FROM dbo.LEP ml
               WHERE ml.personid = sty.personID
                 AND (ml.exitDate IS NULL OR ml.exitDate >= GETDATE())
                 AND ml.programStatus = 'LEP'
               ORDER BY ml.identifieddate DESC) mlcur
  OUTER APPLY (SELECT MIN(e2.startDate) AS District_Date_Enrolled
               FROM dbo.Enrollment e2 WHERE e2.personID = sty.personID) d_enr
  OUTER APPLY (SELECT TOP (1) e3.endDate AS LastEndDate
               FROM dbo.Enrollment e3 WHERE e3.personID = sty.personID AND e3.endDate IS NOT NULL
               ORDER BY e3.endDate DESC) last_wd
  OUTER APPLY (SELECT CASE WHEN EXISTS (
                 SELECT 1 FROM dbo.Enrollment ec
                 JOIN TargetCalendars tc2 ON tc2.calendarID = ec.calendarID
                 WHERE ec.personID = sty.personID
                   AND ec.startDate <= CAST(GETDATE() AS date)
                   AND (ec.endDate IS NULL OR ec.endDate >= CAST(GETDATE() AS date))
               ) THEN 1 ELSE 0 END AS IsCurrent) cur_any
  OUTER APPLY (SELECT TOP (1) g.personID
               FROM dbo.Gifted g WITH (NOLOCK)
               WHERE g.personID = sty.personID
               ORDER BY g.startDate DESC) aig1
  WHERE ISNULL(sty.stateID, '') <> ''
  ORDER BY sty.studentNumber,
           CASE WHEN e.startDate <= CAST(GETDATE() AS date)
                  AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date)) THEN 1 ELSE 0 END DESC,
           e.startDate;
END
ELSE
BEGIN
  ;WITH TargetCalendars AS (
      SELECT c.calendarID
      FROM dbo.Calendar c
      WHERE c.endYear = CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1 ELSE YEAR(GETDATE()) END
  ),
  StudentsThisYear AS (
      SELECT
          s.personID, s.calendarID, s.schoolID, s.studentNumber,
          s.firstName, s.middleName, s.lastName,
          s.birthdate, s.gender, s.raceEthnicityFed, s.raceEthnicity,
          s.grade, s.serviceType, s.stateID
      FROM dbo.v_AdHocStudent s
      JOIN TargetCalendars tc ON tc.calendarID = s.calendarID
      WHERE s.serviceType = 'P'
  ),
  ContactSelf AS (
    SELECT c.personID, c.email,
           ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM v_CensusContactSummary c WHERE c.relationship = 'Self'
  )
  SELECT
      sty.studentNumber AS [Student_ID],
      sty.firstName     AS [Student_First_Name],
      sty.middleName    AS [Student_Middle_Name],
      sty.lastName      AS [Student_Last_Name],
      sty.gender        AS [Gender],
      sty.raceEthnicityFed AS [Ethnicity_Code],
      COALESCE(
        CASE TRY_CONVERT(int, sty.raceEthnicity)
          WHEN 1 THEN 'Hispanic/Latino'
          WHEN 2 THEN 'American Indian or Alaskan Native'
          WHEN 3 THEN 'Asian'
          WHEN 4 THEN 'Black or African American'
          WHEN 5 THEN 'Native Hawaiian/Other Pacific Islander'
          WHEN 6 THEN 'White'
          WHEN 7 THEN 'Two or more races'
          ELSE NULL
        END,
        CASE UPPER(NULLIF(LTRIM(RTRIM(sty.raceEthnicityFed)), ''))
          WHEN 'H' THEN 'Hispanic/Latino'
          WHEN 'I' THEN 'American Indian or Alaskan Native'
          WHEN 'A' THEN 'Asian'
          WHEN 'B' THEN 'Black or African American'
          WHEN 'P' THEN 'Native Hawaiian/Other Pacific Islander'
          WHEN 'W' THEN 'White'
          WHEN 'M' THEN 'Two or more races'
          ELSE NULL
        END
      ) AS [Ethnicity_Description],
      CONVERT(varchar(10), sty.birthdate, 23) AS [Date_of_Birth],
      cs.email                                AS [Email],
      sty.stateID                             AS [SSID],
      ses.primaryDisability                   AS [IEP_Status],
      CASE WHEN aig1.personID IS NOT NULL THEN 'Y' ELSE 'N' END AS [Gifted_Status],

      /* FRL current: existence in v_POSEligibilityCurrent */
      CASE WHEN frlcur.personid IS NOT NULL THEN 'Y' ELSE 'N' END AS [Economically_Disadvantaged],

      NULL AS [Title_1],
      NULL AS [Title_3],
      CASE WHEN mlcur.ProgramStatus = 'LEP' THEN 'Y' ELSE 'N' END AS [ELL_Status],
      sch.number AS [School_Code],
      sch.name   AS [School_Name],
      sty.grade  AS [Current_Grade],
      CASE WHEN e.startDate <= CAST(GETDATE() AS date)
             AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date))
           THEN 'A' ELSE 'I' END AS [Status],
      CASE WHEN cs.email LIKE '%@%' THEN LEFT(cs.email, CHARINDEX('@', cs.email) - 1) ELSE cs.email END AS [Username],
      NULL AS [Password],
      CASE WHEN s504cur.personid IS NOT NULL THEN 'Y' ELSE 'N' END AS [504_Status],
      CASE WHEN ferpa.directoryquestion = 'N' THEN 'Y' ELSE '' END AS [Ok_to_Publish],
      CONVERT(varchar(10), d_enr.District_Date_Enrolled, 23) AS [District_Date_Enrolled],
      CONVERT(varchar(10), CASE WHEN cur_any.IsCurrent = 1 THEN NULL ELSE last_wd.LastEndDate END, 23) AS [District_Date_Withdrawn],
      CONVERT(varchar(10), e.startDate, 23) AS [School_Date_Enrolled],
      CONVERT(varchar(10), e.endDate, 23)   AS [School_Date_Withdrawn],
      CASE WHEN e.startDate <= CAST(GETDATE() AS date)
             AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date))
           THEN NULL
           ELSE CASE COALESCE(e.endStatus,'')
                  WHEN 'W1'  THEN 'W1: Transfer Withdrawal'
                  WHEN 'W2'  THEN 'W2: Early Leaver Withdrawal'
                  WHEN 'W2T' THEN 'W2T: Early Leaver Withdrawal (With Proof of Enrollment in an Adult High School Program)'
                  WHEN 'W3'  THEN 'W3: Death Withdrawal'
                  WHEN 'W4'  THEN 'W4: Early Completer Withdrawal'
                  WHEN 'W6'  THEN 'W6: High School Graduate'
                  ELSE NULLIF(e.endStatus,'') END
      END AS [Withdrawal_Reason]
  FROM StudentsThisYear sty
  JOIN dbo.Enrollment e   ON e.personID = sty.personID
  JOIN TargetCalendars tc ON tc.calendarID = e.calendarID AND e.serviceType = 'P'
  JOIN dbo.Calendar cal   ON cal.calendarID = e.calendarID
  JOIN dbo.School sch     ON sch.schoolID = cal.schoolID
  LEFT JOIN ContactSelf cs ON cs.personID = sty.personID AND cs.rowNumber = 1
  LEFT JOIN dbo.Ferpa ferpa ON ferpa.personid = sty.personid

  OUTER APPLY (SELECT TOP (1) ses.* FROM dbo.SpecialEdState ses
               WHERE ses.personID = sty.personID
                 AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
                 AND ses.exitReason IS NULL
               ORDER BY ses.specialEDStateID ASC) ses
  OUTER APPLY (SELECT TOP (1) s504_2.personid, s504_2.endDate
               FROM dbo.Section504 s504_2
               WHERE s504_2.personid = sty.personid
                 AND (s504_2.endDate IS NULL OR s504_2.endDate >= CAST(GETDATE() AS date))
               ORDER BY s504_2.endDate DESC) s504cur
  OUTER APPLY ( SELECT TOP (1) frl.personid
                FROM dbo.v_POSEligibilityCurrent frl
                WHERE frl.personid = sty.personid ) frlcur
  OUTER APPLY (SELECT TOP (1) ml.*
               FROM dbo.LEP ml
               WHERE ml.personid = sty.personID
                 AND (ml.exitDate IS NULL OR ml.exitDate >= GETDATE())
                 AND ml.programStatus = 'LEP'
               ORDER BY ml.identifieddate DESC) mlcur
  OUTER APPLY (SELECT MIN(e2.startDate) AS District_Date_Enrolled
               FROM dbo.Enrollment e2 WHERE e2.personID = sty.personID) d_enr
  OUTER APPLY (SELECT TOP (1) e3.endDate AS LastEndDate
               FROM dbo.Enrollment e3 WHERE e3.personID = sty.personID AND e3.endDate IS NOT NULL
               ORDER BY e3.endDate DESC) last_wd
  OUTER APPLY (SELECT CASE WHEN EXISTS (
                 SELECT 1 FROM dbo.Enrollment ec
                 JOIN TargetCalendars tc2 ON tc2.calendarID = ec.calendarID
                 WHERE ec.personID = sty.personID
                   AND ec.startDate <= CAST(GETDATE() AS date)
                   AND (ec.endDate IS NULL OR ec.endDate >= CAST(GETDATE() AS date))
               ) THEN 1 ELSE 0 END AS IsCurrent) cur_any
  OUTER APPLY (SELECT TOP (1) g.personID
               FROM dbo.Gifted g WITH (NOLOCK)
               WHERE g.personID = sty.personID
               ORDER BY g.startDate DESC) aig1
  WHERE ISNULL(sty.stateID, '') <> ''
  ORDER BY sty.studentNumber,
           CASE WHEN e.startDate <= CAST(GETDATE() AS date)
                  AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS date)) THEN 1 ELSE 0 END DESC,
           e.startDate;
END