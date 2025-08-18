
/*
	Title: DeansList Student
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/17/2025 - Initial Version
	
	*Based on :https://drive.google.com/file/d/1mpDeEuXBjn2-hACZ2ylgtEWbg9aB8iKy/view?usp=sharing

*/


WITH ContactsOrdered AS (
SELECT
c.personID,
c.contactPersonID,
c.lastName,
c.firstName,
c.email,
c.homePhone,
c.cellPhone,
c.addressLine1,
c.addressLine2,
c.relationship,
c.city,
c.state,
c.zip,
ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.contactPersonID) AS rowNumber
FROM
v_CensusContactSummary c WITH (NOLOCK)
WHERE
c.guardian = 1
),

ContactSelf AS (
	SELECT 
		c.personID, 
		c.cellphone,
		c.householdPhone, 
		c.seq,
		c.relationship,
		c.addressline1,
		c.city,
		c.state,
		c.zip,
		c.email,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c 
	WHERE c.relationship = 'Self'
)



SELECT
	s.studentNumber AS 'StudentID',
	s.studentNumber AS 'StateID',
	s.firstName AS 'FirstName',
	s.middleName AS 'MiddleName',
	s.lastName AS 'LastName',
	c.email AS 'StudentEmail',
	s.grade AS 'Grade',
	s.homeroomTeacher AS 'Homeroom',
	sch.number AS 'BuildingCode',
	format(s.birthdate, 'MM/dd/yyyy') as 'BirthDate',
	s.gender AS 'Gender',
	s.raceEthnicityFed AS 'Ethnicity',
	c.addressLine1 AS 'Street Address Line 1',
	c.city AS 'City',
	c.state AS 'State',
	c.zip AS 'ZipCode',
	CASE when s.homeprimarylanguage IS NULL THEN 'eng' ELSE s.homeprimarylanguage END AS 'Home Language',
	

/*
	-- REMOVED FOR PRIVACY
	-- REMOVE / * above if you need these fields.
	
	-- Multi Lingual
	CASE 
		WHEN mlcur.ProgramStatus = 'LEP' THEN 'Y' ELSE 'N'
	END AS [ELLStatus],
	mlcur.elpaTier AS [ELL],          -- ELPA TIER
	
	--Special Ed
	CASE 
		WHEN spedcur.primarydisability IS NOT NULL
			AND (spedcur.exitdate IS NULL OR spedcur.exitdate >= CAST(GETDATE() AS date))
		THEN 'Y' ELSE 'N'
	END AS [SPEDStatus],
	spedcur.primarydisability AS [SPEDPlan],
	
	--504
	CASE 
		WHEN s504cur.personid IS NOT NULL 
		AND (s504cur.endDate IS NULL OR s504cur.endDate >= CAST(GETDATE() AS date))
		THEN 'Y' ELSE 'N'
	END AS [504Status],
	
	-- FRL 
	CASE 
		WHEN frlcur.personid IS NOT NULL 
		THEN 'Y' 
		ELSE 'N' 
	END AS [FRLStatus],

-- REMOVE * / below to include the data above
*/

	CASE 
	    WHEN s.endDate IS NULL OR s.endDate >= GETDATE() THEN 'Active'
		WHEN s.endDate < GETDATE() THEN 'Inactive'
		ELSE 'I'
	END AS 'Status'


FROM v_AdHocStudent s
	LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1
	JOIN school sch ON sch.schoolid = s.schoolID
	JOIN contactself c ON c.personID = s.personID  and c.rowNumber = 1
	JOIN calendar cal ON cal.calendarID = s.calendarId
	
	
	
/*
-- REMOVING PRIVATE INFO - Contact Jeremiah Jackson for help using these fields

	OUTER APPLY (
  SELECT TOP (1) ml2.elpaTier, ml2.ProgramStatus
  FROM LEP ml2
  WHERE ml2.personid = s.personid
        -- If LEP has effective dates, add them here:
        -- AND ml2.startDate <= CAST(GETDATE() AS date)
        -- AND (ml2.endDate IS NULL OR ml2.endDate >= CAST(GETDATE() AS date))
  ORDER BY ml2.elpaTier DESC
) mlcur

-- One current SPED row
OUTER APPLY (
  SELECT TOP (1) sped2.primarydisability, sped2.exitdate
  FROM SpecialEdState sped2
  WHERE sped2.personid = s.personid
    AND (sped2.exitdate IS NULL OR sped2.exitdate >= CAST(GETDATE() AS date))
  ORDER BY sped2.exitdate DESC
) spedcur

-- One current 504 row
OUTER APPLY (
  SELECT TOP (1) s504_2.endDate, s504_2.personid
  FROM Section504 s504_2
  WHERE s504_2.personid = s.personid
    AND (s504_2.endDate IS NULL OR s504_2.endDate >= CAST(GETDATE() AS date))
  ORDER BY s504_2.endDate DESC
) s504cur
	
OUTER APPLY (
  SELECT TOP (1) frl.personid, frl.enroll_startDate, frl.enroll_endDate, frl.personid
  FROM v_POSEligibilityCurrent frl
  WHERE frl.personid = s.personid
    AND frl.enroll_startDate <= CAST(GETDATE() AS date)
    AND (frl.enroll_endDate IS NULL OR frl.enroll_endDate >= CAST(GETDATE() AS date))
  ORDER BY frl.enroll_startDate DESC
) frlcur

*/


WHERE s.calendarId = cal.calendarid
    AND cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')
    AND s.servicetype = 'P'
    AND (s.stateid IS NOT NULL OR s.stateid <> '')
    AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
