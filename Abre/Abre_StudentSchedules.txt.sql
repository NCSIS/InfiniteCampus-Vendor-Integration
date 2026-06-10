-- Target school-year (EndYear) based on today's date
DECLARE @TargetEndYear INT =
CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1 ELSE YEAR(GETDATE()) END;

;WITH TargetCalendars AS (
  SELECT c.calendarID
  FROM dbo.Calendar c
  WHERE c.endYear = @TargetEndYear
),
ActiveEnrollment AS (
  SELECT
      s.personID, s.calendarID, s.schoolID, s.studentNumber,
      s.firstName, s.lastName, s.stateID, s.startDate, s.endDate,
      ROW_NUMBER() OVER (
        PARTITION BY s.personID
        ORDER BY
          CASE WHEN s.endDate IS NULL THEN 1 ELSE 0 END DESC,
          s.endDate DESC, s.startDate DESC
      ) AS rn
  FROM dbo.v_AdHocStudent s
  JOIN TargetCalendars tc ON tc.calendarID = s.calendarID
  JOIN dbo.Student st ON st.personID = s.personID AND st.calendarID = s.calendarID
  WHERE s.serviceType = 'P'
    AND ISNULL(st.noShow, 0) = 0
    AND s.startDate <= CAST(GETDATE() AS date)
    AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
),
QualifiedStudents AS (
  SELECT * FROM ActiveEnrollment WHERE rn = 1
),
ActiveStudents AS (
  SELECT qs.personID FROM QualifiedStudents qs
),
ActiveRoster AS (
  SELECT
      r.personID, r.sectionID, r.trialID,
      ROW_NUMBER() OVER (
        PARTITION BY r.personID, r.sectionID
        ORDER BY
          CASE WHEN r.endDate IS NULL THEN 1 ELSE 0 END DESC,
          r.endDate DESC, r.startDate DESC
      ) AS rn
  FROM dbo.Roster r
  WHERE r.startDate <= CAST(GETDATE() AS date)
    AND (r.endDate IS NULL OR r.endDate >= CAST(GETDATE() AS date))
),
-- Pick a deterministic placement per section/trial without using dates
UniquePlacement AS (
  SELECT
      sp.sectionID,
      sp.trialID,
      MAX(sp.termID)   AS termID,
      MAX(sp.periodID) AS periodID,
      ROW_NUMBER() OVER (
        PARTITION BY sp.sectionID, sp.trialID
        ORDER BY MAX(sp.termID) DESC, MAX(sp.periodID) DESC
      ) AS rn
  FROM dbo.SectionPlacement sp
  GROUP BY sp.sectionID, sp.trialID
)
SELECT
  qs.studentNumber                                   AS [Student ID],
  qs.firstName                                       AS [Student First Name],
  qs.lastName                                        AS [Student Last Name],
  sch.number                                         AS [School Code],
  vcs.coursenumber                                   AS [Course Code],
  CAST(vcs.sectionID AS varchar(50))                 AS [Section Code],
  vcs.coursename                                     AS [Course Name],

  COALESCE(NULLIF(CAST(vcls.teacherpersonID AS varchar(20)), ''),
           NULLIF(NULLIF(vcs.staffnumber,'0'), ''))  AS [Staff ID],

  /* CSV-safe: FirstName LastName (no comma) */
  LTRIM(RTRIM(
    CASE 
      WHEN vcls.teacherpersonID IS NOT NULL AND vcls.teacherpersonID <> 0
        THEN (tid.firstName + ' ' + tid.lastName)
      WHEN vcs.staffnumber IS NOT NULL AND vcs.staffnumber <> '0'
        THEN REPLACE(vcs.teacherdisplay, ',', ' ')
      ELSE ''
    END
  ))                                                AS [Teacher Name],

  tm.name                                            AS [Term Code],
  pd.name                                            AS [Period],

  CASE WHEN ses.primarydisability IS NOT NULL
            AND (ses.exitdate IS NULL OR ses.exitdate >= CAST(GETDATE() AS date))
       THEN 'Y' ELSE 'N' END                         AS [Student IEP Status],
  CASE WHEN aig1.personID IS NOT NULL THEN 'Y' ELSE 'N' END AS [Student Gifted Status],
  CASE WHEN mlcur.programStatus = 'LEP' THEN 'Y' ELSE 'N' END AS [Student ELL Status],
  vcs.roomname                                       AS [Room Number]

FROM ActiveRoster ar
JOIN dbo.ActiveTrial at
  ON ar.trialID = at.trialID AND at.endYear = @TargetEndYear
JOIN dbo.v_CourseSection  vcs ON vcs.sectionID = ar.sectionID
JOIN dbo.v_ClassSection   vcls ON vcls.sectionID = vcs.sectionID
JOIN dbo.School           sch  ON sch.schoolID   = vcls.schoolID
JOIN UniquePlacement up
  ON up.sectionID = ar.sectionID
 AND up.trialID   = ar.trialID
 AND up.rn        = 1
JOIN dbo.Term   tm ON tm.termID   = up.termID
JOIN dbo.Period pd ON pd.periodID = up.periodID
JOIN ActiveStudents   ast ON ast.personID = ar.personID
JOIN QualifiedStudents qs  ON qs.personID  = ast.personID
LEFT JOIN dbo.Person     tper ON tper.personID  = vcls.teacherpersonID
LEFT JOIN dbo.[Identity] tid  ON tid.identityID = tper.currentIdentityID

OUTER APPLY (
  SELECT TOP (1) ses.*
  FROM dbo.SpecialEdState ses
  WHERE ses.personID = qs.personID
    AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
    AND ses.exitReason IS NULL
  ORDER BY ses.specialEDStateID ASC
) ses

OUTER APPLY (
  SELECT TOP (1) ml.*
  FROM dbo.LEP ml
  WHERE ml.personid = qs.personID
    AND (ml.exitDate IS NULL OR ml.exitDate >= CAST(GETDATE() AS date))
    AND ml.programStatus = 'LEP'
  ORDER BY ml.identifieddate DESC
) mlcur

OUTER APPLY (
  SELECT TOP (1) g.personID
  FROM dbo.Gifted g WITH (NOLOCK)
  WHERE g.personID = qs.personID
  ORDER BY g.startDate DESC
) aig1

WHERE ar.rn = 1
  AND ISNULL(qs.stateID,'') <> '';