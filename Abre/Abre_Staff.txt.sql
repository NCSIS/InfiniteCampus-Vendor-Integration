;WITH FirstMailingAddress AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY personID ORDER BY addressLine1, city) AS rn
    FROM v_MailingAddress
),
FirstPhone AS (
    SELECT personID,
           phone,
           ROW_NUMBER() OVER (PARTITION BY personID ORDER BY phone) AS rn
    FROM v_MailingAddress
),
ActiveStaff AS (
    SELECT *
    FROM dbo.StaffMember
    WHERE startDate <= CAST(GETDATE() AS DATE)
      AND (endDate IS NULL OR endDate >= CAST(GETDATE() AS DATE))
),
SchoolSummary AS (
    SELECT personID,
           CASE 
               WHEN COUNT(DISTINCT schoolNumber) > 1 THEN 0
               ELSE MAX(schoolNumber)
           END AS schoolNumber
    FROM ActiveStaff
    GROUP BY personID
)
SELECT DISTINCT
  sm.personID                                   AS [Staff ID],
  ss.schoolNumber                               AS [School Code],

  COALESCE(i.firstName,  sm.firstName)          AS [First Name],
  COALESCE(i.middleName, sm.middleName)         AS [Middle Name],
  COALESCE(i.lastName,   sm.lastName)           AS [Last Name],
  COALESCE(i.gender,     sm.gender)             AS [Gender],
  CONVERT(date, COALESCE(i.birthdate, sm.birthdate)) AS [Date of Birth],

  ma.addressLine1                               AS [Address Line 1],
  ma.addressLine2                               AS [Address Line 2],
  ma.city                                       AS [City],
  ma.state                                      AS [State],
  ma.zip                                        AS [Zip Code],
  ph.phone                                      AS [Phone],
  c.email                                       AS [Email],
  NULL                                          AS [Hiring Date]
FROM SchoolSummary ss
JOIN ActiveStaff sm
  ON sm.personID = ss.personID
INNER JOIN dbo.Person p
  ON p.personID = sm.personID
INNER JOIN dbo.[Identity] i
  ON i.personID = p.personID
 AND i.identityID = p.currentIdentityID
LEFT JOIN dbo.Contact c
  ON c.personID = sm.personID
LEFT JOIN FirstMailingAddress ma
  ON ma.personID = p.personID AND ma.rn = 1
LEFT JOIN FirstPhone ph
  ON ph.personID = p.personID AND ph.rn = 1
WHERE
  sm.personID <> 1
  AND UPPER(LTRIM(RTRIM(COALESCE(i.firstName, sm.firstName)))) <> 'VACANCY'
  AND c.email IS NOT NULL
  AND LTRIM(RTRIM(c.email)) <> ''
  AND c.email LIKE '%@hertford.k12.nc.us'
  AND EXISTS (
    SELECT 1
    FROM dbo.Employment e
    WHERE e.personID = sm.personID
      AND e.startDate <= CAST(GETDATE() AS DATE)
      AND (e.endDate IS NULL OR e.endDate >= CAST(GETDATE() AS DATE))
  )
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.StaffMember sm2
    WHERE sm2.personID = sm.personID
      AND sm2.schoolNumber = 0
      AND sm2.startDate <= CAST(GETDATE() AS DATE)
      AND (sm2.endDate IS NULL OR sm2.endDate >= CAST(GETDATE() AS DATE))
      AND sm.schoolNumber <> 0
  );