WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, 
		cg.contactPersonID, 
		cg.guardian,
		cg.firstName,
		cg.lastName,
		cg.cellPhone,
		cg.homePhone,
		cg.householdPhone,
		cg.email,
		cg.relationship
	FROM 
		v_CensusContactSummary cg WITH (NOLOCK)
	WHERE 
		cg.guardian = '1' -- Filter guardians early to reduce data volume
),

GuardianData AS (
	SELECT
		cg1.contactPersonID,
		STRING_AGG(CONCAT('s', cg1.PersonID), ',') AS studentIds
	FROM 
		ContactsGrouped cg1
	GROUP BY 
		cg1.contactPersonID
)

SELECT
	CONCAT('g', cg.contactPersonID) AS sourcedId,
	'' AS status,
	'' AS dateLastModified,
	'TRUE' AS enabledUser,
	'' AS orgSourcedIds,
	'guardian' AS role,
	CONCAT('g', cg.contactPersonID) AS username,
	CONCAT('{Fed:g', cg.contactPersonID, '}') AS userIds,
	cg.lastName AS lastName,
	cg.firstName AS firstName,
	'' AS middleName,
	CONCAT('g', cg.contactPersonID) AS identifier,
	COALESCE(cg.email, '') AS email, -- Ensure no NULL values for email
	cg.cellPhone AS sms,
	COALESCE(cg.cellPhone, cg.homePhone, cg.householdPhone) AS phone,
	gd.studentIds AS agentSourceIds,
	'' AS grades,
	'' AS password,
	cg.relationship AS relation
FROM ContactsGrouped cg
INNER JOIN GuardianData gd ON gd.contactPersonID = cg.contactPersonID
INNER JOIN student stu ON stu.personID = cg.personID
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
