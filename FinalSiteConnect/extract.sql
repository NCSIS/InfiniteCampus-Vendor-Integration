/*
	Title: FinalSite Connect (aka: ConnectED, Blackboard Connect)
	
	Description:
	Create CSV for student contacts to be uploaded into FinalSite Connect.
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/06/2024		Initial creation of this template.
	08/22/2024		Fixed a student filter issue and added '000' schools to support charters.
        08/28/2024		Streamlined and only selecting guardians
*/

-- Remove duplicates from contacts based on key attributes.
WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, 
		cg.contactPersonID, 
		cg.lastName, 
		cg.firstName, 
		cg.email,
		cg.homePhone, 
		cg.cellPhone, 
        cg.addressLine1,
		cg.addressLine2, 
		cg.city, 
		cg.state, 
		cg.zip,
		cg.seq,
		cg.relationship,
		cg.guardian
	FROM  
		v_CensusContactSummary cg WITH (NOLOCK)
	GROUP BY 
		cg.personID, cg.contactPersonID, cg.lastName, cg.firstName, cg.email, 
		cg.homePhone, cg.cellPhone, cg.addressLine1, cg.addressLine2, 
		cg.city, cg.state, cg.zip, cg.seq, cg.relationship, cg.guardian
),

-- Get contacts with the highest emergency priority, excluding 'Self' relationships.
ContactsOrdered AS (
	SELECT DISTINCT
		co.personID, 
		co.contactPersonID, 
		co.lastName, 
		co.firstName, 
		co.email,
		co.homePhone, 
		co.cellPhone, 
        co.addressLine1,
		co.addressLine2, 
		co.city, 
		co.state, 
		co.zip,
		co.seq,
		co.relationship,
		ROW_NUMBER() OVER (PARTITION BY co.personID ORDER BY co.seq) AS rowNumber
	FROM 
		ContactsGrouped co WITH (NOLOCK)
	WHERE 
		co.relationship <> 'Self'
		AND co.seq IS NOT NULL
		AND co.guardian = 1  -- Uncomment this line to pull only guardians.
),

-- Get contact information for the student themselves.
ContactSelf AS (
	SELECT DISTINCT
		c.personID, 
		c.lastName, 
		c.firstName, 
		c.email,
		c.householdPhone, 
		c.seq,
		c.relationship,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c WITH (NOLOCK)
	WHERE 
		c.relationship = 'Self'
)

-- Final output query
SELECT 
    sch.number AS 'INSTITUTION',
	'student' AS 'CONTACTTYPE',
	stu.stateID AS 'REFERENCECODE',
	stu.firstname AS 'FIRSTNAME',
	stu.lastname AS 'LASTNAME',
	stu.grade AS 'GRADE',
	CASE
	   WHEN stu.homeprimarylanguage = 'eng' THEN 'English'
	   WHEN stu.homeprimarylanguage = 'spa' THEN 'Spanish'
	   ELSE 'English' 
	END AS 'LANGUAGE',
	COALESCE(cs.householdphone, c1.homePhone, c1.cellPhone, c2.homePhone, c2.cellPhone) AS 'PRIMARYPHONE',
	c1.cellPhone AS 'MOBILEPHONE',
	c1.homePhone AS 'HOMEPHONE',
	c2.cellPhone AS 'MOBILEPHONEALT',
	c2.homePhone AS 'HOMEPHONEALT',
	c1.email AS 'EMAILADDRESS',
	c2.email AS 'EMAILADDRESSALT'
FROM 
	v_AdHocStudent stu
LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
LEFT OUTER JOIN ContactsOrdered c2 ON stu.personID = c2.personID AND c2.rowNumber = 2
LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
LEFT OUTER JOIN school sch ON sch.schoolID = stu.schoolID
INNER JOIN calendar cal ON cal.calendarID = stu.calendarID
WHERE 
    cal.startDate <= GETDATE() 
    AND cal.endDate >= GETDATE()  -- Get only calendars for the current year.
    AND (stu.endDate IS NULL OR stu.endDate >= GETDATE())  -- Get students with no end-date or future-dated end date.
    AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')
    AND (ISNUMERIC(stu.grade) = 1 OR stu.grade = 'KG' OR stu.grade = 'OS')
    AND stu.stateID IS NOT NULL;
