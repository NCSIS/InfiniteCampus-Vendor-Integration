
/*
	Title: Clever Student GUID
	
	Description:
        Student File for SFTP upload to clever.
		Contacts, AIG, IEP, ML and others are able to be included by removing the --
	
	Author: Jeremiah Jackson - NCDPI  
	
	Revision History:
	08/16/2024		Initial creation of this template
        08/20/2024              Fixed Guardians to be selected
	08/21/2024		Only choose primary school 


Table LIST
-------------------
s = v_AdHocStudent (Students)
c = v_CensusContactSummary (Contacts, Parents Guardians)
cs = Student contact
c1 = Student Emergency Contact 1 in NCSIS
sch = school
hh = Household
ec = SpecialEdState (Exceptional Children)
ml = LEP
aig = gifted
*/



-- Go through the contacts table and remove any duplicates.  Usually caused by the same contact being associated with the student more than once.
WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personGUID,cg.personID, cg.contactPersonID, cg.lastName, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, 
		cg.addressLine1, cg.addressLine2, cg.city, cg.state, cg.zip, cg.seq, cg.relationship, cg.guardian
FROM  v_CensusContactSummary cg WITH (NOLOCK)
GROUP BY cg.personGUID,cg.personID,cg.contactPersonID,cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.addressLine1, cg.addressLine2, cg.city, cg.zip, cg.seq, cg.relationship, cg.state, cg.guardian
),


-- Go through the Contacts Table and find the contact with the highest emergency priority.
ContactsOrdered AS (
	SELECT DISTINCT
		co.personGUID,co.personID, co.contactPersonID, co.lastName, co.firstName, co.email, co.homePhone, co.cellPhone, co.addressLine1,
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
),

-- Go through the AIG table and take the latest AIG startDate to remove duplicates.
AIGOrdered AS (
	SELECT 
		aig.personID, aig.programStatus, aig.identificationArea, aig.startDate, 
		ROW_NUMBER() OVER (PARTITION BY aig.personID ORDER BY aig.startDate DESC) AS rowNumber
    FROM 
		gifted aig WITH (NOLOCK)
)

SELECT 
	sch.schoolGUID AS 'School_ID',
    s.personGUID AS 'Student_ID', -- NCSIS ID used to combine with Sections and Enrollments
	s.studentNumber AS 'Student_number', 
	s.stateID AS 'State_id',
	s.lastName AS 'Last_name',
	s.middleName AS 'Middle_name',
	s.firstName AS 'First_name', 
-- Change Grade to Clever Format
	CASE
		WHEN s.grade = 'KG' THEN 'Kindergarten'
		WHEN s.grade = 'PK' THEN 'PreKindergarten'
		WHEN s.grade = 'IT' THEN 'InfantToddler'
		WHEN s.grade = 'PR' THEN 'PreSchool'
		WHEN s.grade = 'OS' THEN 'Ungraded'
		ELSE s.grade  
	END AS 'Grade',  
	s.gender AS 'Gender',
-- Convert Grade to Graduation Year
	CASE
      WHEN s.grade = '13' THEN CONVERT(numeric,cal.endyear)
      WHEN s.grade = 'OS' THEN Convert(numeric,cal.endyear)
      WHEN s.grade = '12' THEN Convert(numeric,cal.endyear)
      WHEN s.grade = '11' THEN (Convert(numeric,cal.endyear)+1)
      WHEN s.grade = '10' THEN (Convert(numeric,cal.endyear)+2)
      WHEN s.grade = '9' THEN (Convert(numeric,cal.endyear)+3)
      WHEN s.grade = '8' THEN (Convert(numeric,cal.endyear)+4)
      WHEN s.grade = '7' THEN (Convert(numeric,cal.endyear)+5)
      WHEN s.grade = '6' THEN (Convert(numeric,cal.endyear)+6)
      WHEN s.grade = '5' THEN (Convert(numeric,cal.endyear)+7)
      WHEN s.grade = '4' THEN (Convert(numeric,cal.endyear)+8)
      WHEN s.grade = '3' THEN (Convert(numeric,cal.endyear)+9)
      WHEN s.grade = '2' THEN (Convert(numeric,cal.endyear)+10)
      WHEN s.grade = '1' THEN (Convert(numeric,cal.endyear)+11)
      WHEN s.grade = 'KG' THEN (Convert(numeric,cal.endyear)+12)
      WHEN s.grade = 'PK' THEN (Convert(numeric,cal.endyear)+13)
      WHEN s.grade = 'PR' THEN (Convert(numeric,cal.endyear)+14)
	  WHEN s.grade = 'IT' THEN (Convert(numeric,cal.endyear)+15)
	END AS GraduationYear,
-- Change Birthday Format into MM/DD/YYYY
	FORMAT(s.birthdate,'MM/dd/yyyy') AS 'Dob',
-- Change Ethnicity to Clever Format
	CASE
		WHEN s.raceEthnicityFed = '1' THEN 'W' -- 'Hispanic/Latino' Clever doesn't appear to support FedRace Code 1
		WHEN s.raceEthnicityFed = '2' THEN 'I' -- 'AmericanIndian/Native'
		WHEN s.raceEthnicityFed = '3' THEN 'A' -- 'Asian'
		WHEN s.raceEthnicityFed = '4' THEN 'B' -- 'African-American/Black'
		WHEN s.raceEthnicityFed = '5' THEN 'P' -- 'Hawaiian/PacificIslander'
		WHEN s.raceEthnicityFed = '6' THEN 'W' -- 'Caucasian/White'
		WHEN s.raceEthnicityFed = '7' THEN 'M' -- 'MultiRacial'
		ELSE s.raceEthnicityFed
	END AS 'Race',  	
	s.hispanicEthnicity AS 'Hispanic_Latino',	



-- The fields below are commented out for privacy reasons.
-- Remove the comment if you need these fields
-- ======================================================
--	ml.programStatus AS 'Ell_status',
--	CASE WHEN ec.PlanType = 'IEP' THEN 'Y' ELSE 'N' END AS 'IEP_status',

-- Student Home Address.  Uncomment if you need.
-- ===============================================
--	cs.AddressLine1 AS 'Student_street',
--	cs.city AS 'Student_city',
--	cs.state AS 'Student_state',
--	cs.zip AS 'Student_zip',

-- Student Email
	cs.email AS 'Student_email'
	
-- Only uncomment if needed.  This is guardian contact info.
-- c1 is guardian with lowest emergency priority. 
-- ==============================================================
--	c1.relationship AS 'Contact_relationship',
--	'guardian' AS 'Contact_type', -- Conact Type is required.  Setting everyone to guardian
--	CONCAT(c1.firstName, ' ', c1.lastName) AS 'Contact_name',
--	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c1.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c1.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Contact_phone',
--	c1.email AS 'Contact_email',
--  c1.personGUID AS 'Contact_sis_id'



	


FROM v_AdHocStudent s
INNER JOIN Calendar cal ON s.calendarID = cal.calendarID
INNER JOIN school sch ON sch.schoolid = s.schoolID
LEFT OUTER JOIN SpecialEdState ec ON ec.personID = s.personID
LEFT OUTER JOIN ContactSelf cs ON cs.personID = s.personID and cs.rowNumber = 1
LEFT OUTER JOIN LEP ml ON ml.personID = s.personID
LEFT OUTER JOIN aigOrdered aig1 ON aig1.personID = s.personID AND aig1.rowNumber = 1
LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1



WHERE cal.calendarId=s.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND (s.stateid IS NOT NULL or s.stateid <> '')
   AND s.servicetype = 'P'  -- Only choose primary school
