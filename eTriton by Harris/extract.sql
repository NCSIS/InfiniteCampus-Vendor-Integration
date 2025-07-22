/*
	Title: E-Triton
	
	Description:
        Based on the E-Triton Data Import Specification Sheet 
        https://drive.google.com/file/d/1DCau6XDwhy6nCr0eccujBgl-RuFjDhU7/view?usp=sharing
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	07/22/2025 - Initial Creation


*/


-- Go through the contacts table and remove any duplicates.  Usually caused by the same contact being associated with the student more than once.
WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, cg.contactPersonID, cg.lastName, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, 
		cg.addressLine1, cg.addressLine2, cg.city, cg.state, cg.zip, cg.seq, cg.relationship,cg.guardian
FROM  v_CensusContactSummary cg WITH (NOLOCK)
GROUP BY cg.personID,cg.contactPersonID,cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.addressLine1, cg.addressLine2, cg.city, cg.zip, cg.seq, cg.relationship, cg.state,cg.guardian
),


-- Go through the Contacts Table and find the two contacts with the highest emergency priority.
-- See Below to only pull Contacts marked as guardians.  This is the preferred method but requires every student to have a guardian.
ContactsOrdered AS (
	SELECT DISTINCT
		co.personID, co.contactPersonID, co.lastName, co.firstName, co.email, co.homePhone, co.cellPhone, co.addressLine1,
		co.addressLine2, co.city, co.state, co.zip, co.seq, co.relationship,co.guardian,
		ROW_NUMBER() OVER (PARTITION BY co.personID ORDER BY co.seq) AS rowNumber
    FROM 
		contactsGrouped co WITH (NOLOCK)
    WHERE 
                co.relationship <> 'Self' AND co.seq IS NOT NULL

-- Uncomment the line below to only pull guardians. 
	AND co.guardian = 1
),

-- Pull the contact for the student and not anyone else associated.
ContactSelf AS (
	SELECT DISTINCT
		c.personID, c.lastName, c.firstName, c.email, c.householdPhone, c.seq, c.relationship, c.householdid, c.AddressLine1, c.city, c.state, c.zip,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)



--
--
--  SQL export starts below here
--
--




SELECT
   stu.stateId as 'Patron Number',
   stu.firstName as 'Patron First Name',
   stu.middleName as 'Patron Middle Name',
   stu.lastName as 'Patron Last Name',
--   stu.raceEthnicityFed as 'Ethnicity',
   stu.gender AS 'Gender',
--   format(stu.birthdate, 'MM/dd/yyyy') as 'Birthdate',


/* Only use one of the two lines below */
   sch.number AS 'School', -- School number
--   sch.name AS 'School', -- School name
   
      
   stu.grade AS 'Grade',
   FORMAT(stu.startdate, 'MM/dd/yyyy') AS 'Enrollment Start Date',
   FORMAT(stu.enddate, 'MM/dd/yyyy') AS 'Enrollment Drop Date',
   ahs.homeroomTeacher AS 'Homeroom',

/* STATUS is not an *OFFICIAL FIELD* if it breaks the import let Jeremiah know */  
	CASE 
	    WHEN stu.endDate IS NULL OR stu.endDate >= GETDATE() THEN 'Active'
		WHEN stu.endDate < GETDATE() THEN 'Inactive'
		ELSE 'Inactive'
	END AS 'Status',


   cs.householdID AS 'Household ID',
   c1.firstName AS 'Household First Name',
   c1.lastName AS 'Household Last Name',
   c1.email AS 'Email',
   CASE when stu.homeprimarylanguage IS NULL THEN 'eng' ELSE stu.homeprimarylanguage END AS 'Language',
   COALESCE(c1.homePhone, c1.cellPhone) AS 'Phone Number',
   cs.AddressLine1 AS 'Address',
   cs.city AS 'City',
   cs.state AS 'State',
   cs.zip as 'Zip'

 



FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
   LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
   LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
   LEFT OUTER JOIN v_AdHocStudent ahs ON stu.personID = ahs.personID and ahs.calendarID = stu.calendarid

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000') --Charter schools might need to remove this line.
   AND stu.stateid IS NOT NULL
   AND stu.servicetype = 'P'  -- Only choose primary school
   
   /* uncomment below to restrict the file to only active students */
--   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date


   
   
