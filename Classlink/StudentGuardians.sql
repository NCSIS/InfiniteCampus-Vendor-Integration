WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, 
		cg.contactPersonID, 
		cg.guardian
	FROM 
		v_CensusContactSummary cg WITH (NOLOCK)
	WHERE 
		cg.guardian = '1' -- Filter guardians early to reduce data volume
),

GuardianData AS (
	SELECT
		cg1.personID,
		STRING_AGG(CONCAT('g', cg1.contactPersonID), ',') AS guardianIds
	FROM 
		ContactsGrouped cg1
	GROUP BY 
		cg1.personID
)

SELECT
	CONCAT('s', gd.personID) AS sourcedId,
	CONCAT('"', gd.guardianIds, '"') AS agentSourceIds,
	CASE 
		WHEN NULLIF(stu.homeprimarylanguage, '') IS NULL THEN 'eng'
		ELSE stu.homeprimarylanguage
	END AS homelanguage
FROM 
	GuardianData gd
	INNER JOIN student stu ON stu.personID = gd.personID
	INNER JOIN school sch ON stu.schoolID = sch.schoolID
	INNER JOIN calendar cal ON cal.calendarID = stu.calendarID
WHERE 
	cal.startDate <= GETDATE() 
	AND cal.endDate >= GETDATE() -- Filter current academic year
	AND (stu.endDate IS NULL OR stu.endDate >= GETDATE()) -- Include active students
	AND (
		CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 
		OR SUBSTRING(sch.number, 4, 3) = '000'
	) -- Filter schools based on number
	AND stu.stateID IS NOT NULL; -- Exclude students without a state ID
