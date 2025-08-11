/*
	Title: SchoolStatus - Student
	
	
	Author: Jeremiah Jackson NCDPI
	
	IMPORTANT:  Lots of field are intentially left blank, but there is also EC and ML status in here.  Make sure you need to send these to the vendor.  If not we can remove them.
	
	Revision History:
	08/10/2025		Initial creation of this template

*/



SELECT 
    sch.number AS [siteCode],
    s.stateID      AS [ssid],
    s.stateID      AS [studentNumber],
    s.stateID      AS [studentid],
    s.lastName     AS [lastName],
    s.firstName    AS [firstName],
    FORMAT(s.birthdate,'MM/dd/yyyy') AS [dob],
    s.grade        AS [grade],
    s.gender       AS [gender],
    s.raceEthnicity AS [Ethnicity],
    '' AS [counselor],
    '' AS [track],
    CASE 
        WHEN s.endDate IS NULL OR s.endDate >= GETDATE() THEN 'Active'
        ELSE 'Inactive'
    END AS [enrollmentStatus],
    s.startDate AS [entryDate],
    s.endDate   AS [exitDate],
    s.hispanicEthnicity AS [hispanicFlag],
    CASE
        WHEN s.raceEthnicityFed = '1' THEN '2000' -- Hispanic/Latino (Clever mapping)
        WHEN s.raceEthnicityFed = '2' THEN '5000' -- AmericanIndian/Native
        WHEN s.raceEthnicityFed = '3' THEN '4000' -- Asian
        WHEN s.raceEthnicityFed = '4' THEN '3000' -- African-American/Black
        WHEN s.raceEthnicityFed = '5' THEN '7500' -- Hawaiian/PacificIslander
        WHEN s.raceEthnicityFed = '6' THEN '1000' -- Caucasian/White
        WHEN s.raceEthnicityFed = '7' THEN '8000' -- MultiRacial
        ELSE s.raceEthnicityFed
    END AS [Race1],
    '' AS [Race2],
    '' AS [Race3],
    '' AS [Race4],
    '' AS [Race5],
    ml.programStatus AS [LanguageFluency],
    ml.elpaTier      AS [EldLevel],
    '' AS [LunchStatus], -- typically not populated from IC
    '' AS [FosterCare],
    CASE
        WHEN ses.primaryDisability IS NOT NULL 
             AND ses.primaryDisability <> '' 
             AND ses.exitDate IS NULL
        THEN 'Y' ELSE 'N'
    END AS [SpecialEd],
    '' AS [Homeless],
    '' AS [Migrant]
	
FROM v_AdHocStudent s
	INNER JOIN Calendar cal ON s.calendarID = cal.calendarID
	INNER JOIN School   sch ON sch.schoolID   = s.schoolID
	OUTER APPLY (
		SELECT TOP (1) ml.*
		FROM dbo.LEP ml 
		WHERE ml.personid = s.personID
			AND (ml.exitDate IS NULL OR ml.exitDate >= GETDATE())
			AND ml.programStatus = 'LEP'
		ORDER BY ml.identifieddate DESC
	) ml
	OUTER APPLY (
		SELECT TOP (1) ses.*
		FROM dbo.SpecialEdState ses
		WHERE ses.personID = s.personID
			AND (ses.endDate IS NULL OR ses.endDate >= GETDATE())
			AND ses.exitReason IS NULL
		ORDER BY ses.specialEDStateID ASC
	) ses
	
WHERE sch.schoolID = cal.schoolID
  AND cal.startDate <= GETDATE()
  AND cal.endDate   >= GETDATE()          -- current-year calendars only
  AND (
        TRY_CAST(SUBSTRING(sch.number,4,3) AS int) >= 300
        OR SUBSTRING(sch.number,4,3) = '000'
      )
  AND s.stateID IS NOT NULL
  AND s.stateID <> ''
  AND s.serviceType = 'P';                 -- primary school only
