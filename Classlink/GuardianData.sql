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
        cg.relationship,
        cg.relatedby,
    ROW_NUMBER() OVER (PARTITION BY cg.contactpersonid, cg.personid ORDER BY cg.contactPersonID DESC) AS rowNumber
    FROM 
        v_CensusContactSummary cg WITH (NOLOCK)
INNER JOIN student stu ON cg.personid = stu.personid
    WHERE 
        cg.guardian = '1' -- Filter guardians early to reduce data volume
     AND (stu.endDate IS NULL OR stu.endDate >= GETDATE()) -- Include active students
),

StudentData AS (
    SELECT
    cg1.contactpersonid,
STRING_AGG(CONCAT('s', cg1.PersonID), ',') AS studentIds
FROM contactsgrouped cg1
where cg1.rownumber = 1
Group by cg1.contactpersonid
),

OrgData AS (
SELECT
cg2.contactpersonid,
STRING_AGG(CONVERT(VARCHAR(36), sch.schoolGUID), ',') as orgids
FROM contactsgrouped cg2
INNER JOIN student stu ON cg2.personid = stu.personid
INNER JOIN school sch ON sch.schoolid = stu.schoolid
INNER JOIN calendar cal ON cal.calendarid = stu.calendarid
where cg2.rownumber = 1
	AND cal.startDate <= GETDATE() 	
	AND cal.endDate >= GETDATE() -- Filter current academic year
	AND (stu.endDate IS NULL OR stu.endDate >= GETDATE()) -- Include active students
	AND (
		CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 
		OR SUBSTRING(sch.number, 4, 3) = '000'
	) -- Filter schools based on number
	AND stu.stateID IS NOT NULL -- Exclude students without a state ID
group by cg2.contactpersonid
),



FinishedData AS (
Select 
	CONCAT('g', cg.contactPersonID) AS sourcedId,
	'' AS status,
	'' AS dateLastModified,
	'TRUE' AS enabledUser,
	od.orgids AS orgSourcedIds,
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
	sd.studentIds AS agentSourceIds,
	'' AS grades,
	'' AS password,
	cg.relationship AS relation,
        ROW_NUMBER() OVER (PARTITION BY cg.contactpersonid ORDER BY cg.contactPersonID DESC) AS rowNumber
from ContactsGrouped cg
INNER JOIN studentdata sd ON cg.contactpersonid = sd.contactpersonid
INNER JOIN orgdata od ON od.contactpersonid = cg.contactpersonid
INNER JOIN student stu on cg.personid = stu.personid
INNER JOIN calendar cal on stu.calendarid = cal.calendarid
INNER JOIN school sch on stu.schoolid = sch.schoolid
where cg.rownumber = 1
	AND cal.startDate <= GETDATE() 	
	AND cal.endDate >= GETDATE() -- Filter current academic year
	AND (stu.endDate IS NULL OR stu.endDate >= GETDATE()) -- Include active students
	AND (
		CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 
		OR SUBSTRING(sch.number, 4, 3) = '000'
	) -- Filter schools based on number
	AND stu.stateID IS NOT NULL -- Exclude students without a state ID
)

select * 
FROM FinishedData fd
WHERE fd.rownumber = 1
