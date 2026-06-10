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
  SELECT 
    s.personID,
    s.studentNumber,
    s.firstName,
    s.lastName,
    s.enrollmentID,
    s.calendarID,
    c.schoolID
  FROM dbo.Student s
  INNER JOIN TargetCalendars tc ON tc.calendarID = s.calendarID
  INNER JOIN dbo.Calendar c ON c.calendarID = s.calendarID
  WHERE s.serviceType = 'P'
    AND ISNULL(s.noShow, 0) = 0
    AND s.startDate <= CAST(GETDATE() AS date)
    AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
)
SELECT
  i.firstName AS [StudentFirstName],
  i.lastName AS [StudentLastName],
  qs.studentNumber AS [StudentID],
  e.grade AS [GradeLevel],
  'A' AS [StudentStatus],

  CASE
    WHEN ses.primaryDisability IS NOT NULL
         AND ses.primaryDisability <> ''
         AND ses.exitDate IS NULL
    THEN 'Y' ELSE 'N'
  END AS [IEP],

  -- Gifted Y/N (Clever-style: latest Gifted row by startDate; Y if any row exists)
  CASE WHEN aig1.personID IS NOT NULL THEN 'Y' ELSE 'N' END AS [Gifted],

  CASE 
    WHEN mlcur.programStatus = 'LEP' THEN 'Y' ELSE 'N'
  END AS [ELStatus],

  tmc.firstName AS [CounselorFirstName],
  tmc.lastName AS [CounselorLastName],
  tmc.personID AS [CounselorStaffID],
  s.number AS [StudentSchoolCode]
FROM QualifiedStudents qs
INNER JOIN dbo.Enrollment e ON qs.enrollmentID = e.enrollmentID
INNER JOIN dbo.Person p ON qs.personID = p.personID
INNER JOIN dbo.[Identity] i ON i.identityID = p.currentIdentityID
LEFT JOIN dbo.School s ON qs.schoolID = s.schoolID

-- IEP current
OUTER APPLY (
  SELECT TOP (1) ses.*
  FROM dbo.SpecialEdState ses
  WHERE ses.personID = qs.personID
    AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
    AND ses.exitReason IS NULL
  ORDER BY ses.specialEDStateID ASC
) ses

-- ELL current
OUTER APPLY (
  SELECT TOP (1) ml.*
  FROM dbo.LEP ml
  WHERE ml.personID = qs.personID
    AND (ml.exitDate IS NULL OR ml.exitDate >= GETDATE())
    AND ml.programStatus = 'LEP'
  ORDER BY ml.identifieddate DESC
) mlcur

-- Counselor (current)
OUTER APPLY (
  SELECT TOP (1) tm.*
  FROM dbo.TeamMember tm
  WHERE tm.personID = p.personID
    AND tm.role = 'Counselor'
    AND tm.startDate <= GETDATE()
    AND (tm.endDate IS NULL OR tm.endDate >= GETDATE())
  ORDER BY tm.startDate DESC
) tmc

-- Gifted latest-by-startDate (Clever-style)
OUTER APPLY (
  SELECT TOP (1) g.personID
  FROM dbo.Gifted g WITH (NOLOCK)
  WHERE g.personID = qs.personID
  ORDER BY g.startDate DESC
) aig1

ORDER BY
  qs.studentNumber;