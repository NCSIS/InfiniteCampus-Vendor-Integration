/*
	Title: Educators Handbook

	Author: Clinton City Schools
	
	Revision History:
	07/25/2024		Initial creation of this template

*/


-- EducatorsHandbook.com Incidents+ Student Query Version 1.0.0, 2024-07-01
-- Questions about this file should be sent to support@educatorshandbook.com.

WITH GUARDIANS AS (
  SELECT
	  rp.personID1
	, rp.personID2
	, i.firstName
	, i.lastName
	, c.cellPhone
	, c.homePhone
	, c.workPhone
	, c.email
	, [rowNum] = ROW_NUMBER() OVER (PARTITION BY rp.personID1 ORDER BY IIF(rp.seq IS NULL, 99, rp.seq))
  FROM RelatedPair rp
	LEFT OUTER JOIN Person p on p.personID = rp.personID2
	  LEFT OUTER JOIN [Identity] i on p.currentIdentityID = i.identityID
	  LEFT OUTER JOIN Contact c on p.personID = c.personID
  WHERE
	rp.guardian = 1
	AND (rp.startDate IS NULL OR rp.startDate <= GETDATE())
	AND (rp.endDate IS NULL OR rp.endDate >= GETDATE())
),

MailingAddress AS (
  SELECT
	  p.personID
	, [AddressLine1] = IIF(a.postOfficeBox = 1, 
		'P.O. Box ' + ISNULL(a.number, ''),
		ISNULL(a.number, '') + ' ' + ISNULL(a.prefix + ' ', '') + ISNULL(a.street + ' ', '') + ISNULL(a.tag + ' ', '') + ISNULL(a.dir + ' ', '') + ISNULL(IIF(ISNULL(a.apt, '') <> '' AND LEFT(a.apt, 1) <> '#', '#' + a.apt, a.apt), '')
	  )
	, a.city
	, a.state
	, a.zip
	, ROW_NUMBER() OVER (PARTITION BY p.personID ORDER BY a.addressID DESC) rowNum
  FROM Person P
	INNER JOIN HouseholdMember hm on p.personID = hm.personID
	  LEFT JOIN Household h on hm.householdID = h.householdID
		LEFT JOIN HouseholdLocation hl on h.householdID = hl.householdID AND hl.mailing = 1 AND (hl.startDate IS NULL OR hl.startDate <= GETDATE()) AND (hl.endDate IS NULL OR hl.endDate >= GETDATE())
		  LEFT JOIN Address a on hl.addressID = a.addressID
  WHERE
	(hm.startDate IS NULL OR hm.startDate <= GETDATE())
	AND (hm.endDate IS NULL OR hm.endDate >= GETDATE())
)

SELECT
	[Student Number] = COALESCE(RTRIM(LTRIM(stu.studentNumber)), '')
  , [Last Name] = COALESCE(RTRIM(LTRIM(stu.lastName)), '')
  , [First Name] = COALESCE(RTRIM(LTRIM(stu.firstName)), '')
  , [School Code] = COALESCE(RTRIM(LTRIM(sch.number)), '')
  , [Grade Level] = COALESCE(RTRIM(LTRIM(e.grade)), '')

  , [Gender] = COALESCE(RTRIM(LTRIM(stu.gender)), '')
  , [Race] = CASE
	  WHEN i.raceEthnicityFed = 1 THEN 'H'
	  WHEN i.raceEthnicityFed = 2 THEN 'I'
	  WHEN i.raceEthnicityFed = 3 THEN 'A'
	  WHEN i.raceEthnicityFed = 4 THEN 'B'
	  WHEN i.raceEthnicityFed = 5 THEN 'P'
	  WHEN i.raceEthnicityFed = 6 THEN 'W'
	  WHEN i.raceEthnicityFed = 7 THEN 'M'
	  ELSE ''
	END
  , [Ethnicity] = IIF(stu.hispanicEthnicity = 'Y', 'Hispanic', 'Not Hispanic')
  , [IEP] = COALESCE(RTRIM(LTRIM(e.specialEdStatus)), '')
  , [504 Plan] = COALESCE(RTRIM(LTRIM(e.section504)), '')
  , [ELL] = ''

  , [Birthdate] = COALESCE(RTRIM(LTRIM(CONVERT(varchar, stu.birthdate, 101))), '')

  , [Street Address] = COALESCE(RTRIM(LTRIM(ma.addressLine1)), '')
  , [City] = COALESCE(RTRIM(LTRIM(ma.city)), '')
  , [State] = COALESCE(RTRIM(LTRIM(ma.[state])), '')
  , [Zip] = COALESCE(RTRIM(LTRIM(ma.zip)), '')

  , [Primary Contact] = COALESCE(RTRIM(LTRIM(G1.firstName + ' ' + G1.lastName)), '')
  , [Primary Contact Cell Phone] = COALESCE(RTRIM(LTRIM(G1.cellPhone)), '')
  , [Primary Contact Secondary Phone] = COALESCE(RTRIM(LTRIM(G1.homePhone)), RTRIM(LTRIM(G1.workPhone)))
  , [Secondary Contact] = COALESCE(RTRIM(LTRIM(G2.firstName + ' ' + G2.lastName)), '')
  , [Secondary Contact Cell Phone] = COALESCE(RTRIM(LTRIM(G2.cellPhone)), '')
  , [Secondary Contact Secondary Phone] = COALESCE(RTRIM(LTRIM(G2.homePhone)), RTRIM(LTRIM(G2.workPhone)))
  , [Tertiary Contact] = COALESCE(RTRIM(LTRIM(G3.firstName + ' ' + G3.lastName)), '')
  , [Tertiary Contact Cell Phone] = COALESCE(RTRIM(LTRIM(G3.cellPhone)), '')
  , [Tertiary Contact Secondary Phone] = COALESCE(RTRIM(LTRIM(G3.homePhone)), RTRIM(LTRIM(G3.workPhone)))
FROM student stu WITH (NOEXPAND)
  JOIN Person p on p.personID = stu.personID
	JOIN [Identity] i on p.personID = i.personID AND p.currentIdentityID = i.identityID
  JOIN Enrollment e on e.calendarID = stu.calendarID AND e.personID = stu.personID
  LEFT JOIN School sch on stu.schoolID = sch.schoolID
  LEFT JOIN MailingAddress ma on stu.personID = ma.personID AND ma.rowNum = 1
  LEFT JOIN GUARDIANS G1 on G1.personID1 = stu.personID AND G1.rowNum = 1
  LEFT JOIN GUARDIANS G2 on G2.personID1 = stu.personID AND G2.rowNum = 2
  LEFT JOIN GUARDIANS G3 on G3.personID1 = stu.personID AND G3.rowNum = 3
WHERE
  stu.activeYear = 1
  -- AND sch.number NOT IN ()
  AND e.startDate <= GETDATE()
  AND (e.endDate IS NULL OR e.endDate >= GETDATE())
ORDER BY stu.studentNumber
