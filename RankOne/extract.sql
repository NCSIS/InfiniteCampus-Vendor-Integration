/*
	Title:RankOne Sports
	
	Description:   YOU MUST CHANGE THIS FILE.  It is specific to LEA 280.  If you need to use this please contact me.
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/27/2024		Initial creation of this template

*/


WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, cg.contactPersonID, cg.lastName, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, 
		cg.addressLine1, cg.addressLine2, cg.city, cg.state, cg.zip, cg.seq, cg.relationship, cg.guardian
FROM  v_CensusContactSummary cg WITH (NOLOCK)
GROUP BY cg.personID,cg.contactPersonID,cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.addressLine1, cg.addressLine2, cg.city, cg.zip, cg.seq, cg.relationship, cg.state, cg.guardian
),


-- Go through the Contacts Table and find the contact with the highest emergency priority.
ContactsOrdered AS (
	SELECT DISTINCT
		co.personID, co.contactPersonID, co.lastName, co.firstName, co.email, co.homePhone, co.cellPhone, co.addressLine1,
		co.addressLine2, co.city, co.state, co.zip, co.seq, co.relationship, co.guardian,
		ROW_NUMBER() OVER (PARTITION BY co.personID ORDER BY co.seq) AS rowNumber
    FROM 
		contactsGrouped co WITH (NOLOCK)
    WHERE 
		co.relationship <> 'Self' AND co.seq IS NOT NULL

-- Comment out the line below to pull contacts even if guardian is not checked in NCSIS. 
		AND co.guardian = 1
),

-- Pull the contact for the student and not anyone else associated.
ContactSelf AS (
	SELECT DISTINCT
		c.personID, c.lastName, c.firstName, c.email, c.householdPhone, c.seq, c.relationship, c.city, c.zip, c.state, c.addressline1,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)


SELECT
	CASE
		WHEN sch.number = '280304' and stu.grade IN ('6','7','8') THEN '7957'
		WHEN sch.number = '280304' and stu.grade IN ('9','10','11','12','13','OS') THEN '7956'
		WHEN sch.number = '280330' THEN '7954'
		WHEN sch.number = '280328' THEN '7955'
		WHEN sch.number = '280316' THEN '7952'
		WHEN sch.number = '280320' THEN '7953'
	END AS '*Campus ID',
	stu.lastName AS '*Last Name',
	stu.firstName AS '*First Name',
	stu.middleName AS '*Middle Name',
	'' AS '*Active',
	stu.gender AS '*Gender',
	FORMAT(stu.birthdate,'MM/dd/yyyy') AS '*DOB',
	'' AS 'Age',
	stu.grade AS '*Grade',
	stu.stateID AS '*Student ID',
	cs.AddressLine1 AS '*Address',
	cs.city AS '*City',
	cs.state AS '*State',
	cs.zip AS '*ZIP',
	cs.email AS 'Student Email Address',
	'' AS 'Student Cell Phone #',
	CONCAT(c1.firstName, ' ', c1.lastName) AS 'Guardian 1 Name',
	c1.homePhone AS 'Guard. 1 Phone',
	c1.cellPhone AS 'Guard. 1 Cell',
	c1.email AS 'Guard 1 Email',
	'' AS 'Guard 1 Employer',
	'' AS 'Guard 1 Employer Phone',
	CONCAT(c2.firstName, ' ', c2.lastName) AS 'Guardian 2 Name',
	c2.homePhone AS 'Guard 2 Phone',
	c1.cellPhone AS 'Guard. 2 cell',
	c1.email AS 'Guard 2 Email',
	'' AS 'Guard 2 Employer',
	'' AS 'Guard. 2 Employer Phone',	
	'' AS 'Emergency Contact',
	'' AS 'Emergency Phone',
	'' AS 'Emergency Relationship',
	'' AS 'Insurance Company',
	'' AS 'Insurance Phone',
	'' AS 'Insurance Policy Number',
	'' AS 'Primary Physician',
	'' AS 'Primary Pys. Phone',
	'' AS 'Primary Policy Number',
	'' AS 'Height',
	'' AS 'Weight',
	'' AS 'Blood Pressure',
	'' AS 'Pulse',
	'' AS 'Vision',
	'' AS 'Medications',
	'' AS 'Allergies',
	'' AS 'Notes',

	CASE
		WHEN stu.raceEthnicityFed = '1' THEN '4' -- 'Hispanic/Latino' Clever doesn't appear to support FedRace Code 1
		WHEN stu.raceEthnicityFed = '2' THEN '2' -- 'AmericanIndian/Native'
		WHEN stu.raceEthnicityFed = '3' THEN '3' -- 'Asian'
		WHEN stu.raceEthnicityFed = '4' THEN '1' -- 'African-American/Black'
		WHEN stu.raceEthnicityFed = '5' THEN '6' -- 'Hawaiian/PacificIslander'
		WHEN stu.raceEthnicityFed = '6' THEN '5' -- 'Caucasian/White'
		WHEN stu.raceEthnicityFed = '7' THEN '6' -- 'MultiRacial'
		ELSE stu.raceEthnicityFed
	END AS 'Ethnicity'  --Having to change codes to meet their format instead of the federal codes

FROM
	student stu
	INNER JOIN calendar cal ON cal.calendarid = stu.calendarid
	INNER JOIN school sch ON sch.schoolid = stu.schoolid 
	LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
	LEFT OUTER JOIN ContactsOrdered c2 ON stu.personID = c2.personID AND c2.rowNumber = 1
	INNER JOIN ContactSelf cs ON cs.personid = stu.personid AND cs.rowNumber = 1
	
WHERE cal.calendarId=stu.calendarId
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND stu.stateid IS NOT NULL
   AND sch.number IN ('280304', '280330', '280328', '280316', '280320')
