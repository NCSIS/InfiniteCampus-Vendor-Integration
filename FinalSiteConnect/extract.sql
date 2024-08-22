/*
	Title: FinalSite Connect (aka: ConnectED, Blackboard Connect)
	
	Description:
	Create CSV for student contacts to be uploaded into FinalSite Connect
	
	Author: Haywood County Schools - JJ
	
	Revision History:
	08/06/2024		Initial creation of this template
	08/22/2024		Fixed a student filter issue and added '000' schools to support charters

*/



--



-- Go through the contacts table and remove any duplicates.  Usually caused by the same contact being associated with the student more than once.
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
		cg.relationship
FROM  v_CensusContactSummary cg WITH (NOLOCK)
GROUP BY cg.personID,cg.contactPersonID,cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.addressLine1, cg.addressLine2, cg.city, cg.zip, cg.seq, cg.relationship, cg.state
),


-- Go through the Contacts Table and find the two contacts with the highest emergency priority (usually #1 and #2 but if no #1 it starts at the next number.)  and put their data into c1, c2
-- See Below to only pull Contacts marked as guardians.  This is the preferred method but requires every student to have a guardian.
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
		contactsGrouped co WITH (NOLOCK)
    WHERE 
                co.relationship <> 'Self'
                AND co.seq IS NOT NULL

-- Uncomment the line below to only pull guardians. 
--		AND c.guardian = 1
),

-- Pull the contact for the student and not anyone else associated.
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




-- The script starts here.  The above it to remove duplicates and filter the contacts table.


select 
    sch.number AS 'INSTITUTION',
	'student' AS 'CONTACTTYPE',
	stu.stateID AS 'REFERENCECODE',
	stu.firstname AS 'FIRSTNAME',
	stu.lastname AS 'LASTNAME',
	stu.grade AS 'GRADE',
	
-- Use homeprimarylanguage.  If blank set to english.  Finaliste only supports english and spanish
	CASE
	   WHEN stu.homeprimarylanguage = 'eng' THEN 'English'
	   WHEN stu.homeprimarylanguage = 'spa' THEN 'Spanish'
	   ELSE 'English' 
	END AS 'LANGUAGE',

	'CLIENT' AS 'DATAPROVIDER',
	-- The first non blank field will be chosen in this order for primary phone
	COALESCE(cs.householdphone,c1.homePhone, c1.cellphone, c2.homephone, c2.cellphone) AS 'PRIMARYPHONE',
	c1.cellphone AS 'MOBILEPHONE',
	c1.homephone AS 'HOMEPHONE',
	c2.cellphone AS 'MOBILEPHONEALT',
	c2.homephone AS 'HOMEPHONEALT',
--	COALESCE(cs.householdphone,c1.homePhone, c1.cellphone, c2.homephone, c2.cellphone) AS 'ATTENDANCEPHONE',
    c1.email AS 'EMAILADDRESS',
	c2.email AS 'EMAILADDRESSALT'


from v_AdHocStudent stu
LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
LEFT OUTER JOIN ContactsOrdered c2 ON stu.personID = c2.personID AND c2.rowNumber = 2
LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
LEFT OUTER JOIN school sch ON sch.schoolID = stu.schoolID
WHERE 
-- Select the current school year
	stu.activeYear = 1
	AND (stu.studentNumber IS NOT NULL or stu.studentNumber <> '')
	AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
	AND (ISNUMERIC(stu.grade) = '1' OR stu.grade = 'KG' OR stu.grade = 'OS')
    AND stu.activeToday = 1
