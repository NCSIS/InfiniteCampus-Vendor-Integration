/*
	Title: Student Data Most Fields
	
	Description:
	Template for most used and needed Student Fields. 
        To change what the export headers change the AS 'FieldName' on each line.

        To TURNOFF a field just add -- to the beginning of the line.
	
	Author: Jeremiah Jackson - NCDPI  
        (Based on Rutherford County Schools Meals Plus Export - JMT)
	
	Revision History:
	07/28/2024		Initial creation of this template


Table LIST
-------------------
s = v_AdHocStudent (Students)
c = v_CensusContactSummary (Contacts, Parents Guardians)
sch = school
hh = Household
ec = SpecialEdState (Exceptional Children)
ml = LEP
aig = gifted
*/




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
		c.personID, 
		c.contactPersonID, 
		c.lastName, 
		c.firstName, 
		c.email,
		c.homePhone, 
		c.cellPhone, 
        c.addressLine1,
		c.addressLine2, 
		c.city, 
		c.state, 
		c.zip,
		c.seq,
		c.relationship,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		contactsGrouped c WITH (NOLOCK)
    WHERE 
                c.relationship <> 'Self'
                AND c.seq IS NOT NULL

-- Uncomment the line below to only pull guardians. 
--		AND c.guardian = 1
),


-- Go through the AIG table and take the latest AIG startDate to remove duplicates.
AIGOrdered AS (
	SELECT 
		aig.personID, 
		aig.programStatus, 
		aig.identificationArea, 
		aig.startDate, 
		ROW_NUMBER() OVER (PARTITION BY aig.personID ORDER BY aig.startDate DESC) AS rowNumber
    FROM 
		gifted aig WITH (NOLOCK)
)



SELECT 

	s.studentNumber AS 'STUDENTS.Student_Number', 
        s.personID AS 'STUDENTS.ID',
	s.lastName AS 'STUDENTS.Last_Name',
	s.firstName AS 'STUDENTS.First_Name', 
        s.middleName AS 'STUDENTS.Middle_Name',
    LEFT(s.middleName, 1)  AS 'Middle_Initial',
	s.homeroomTeacher AS 'Home_Room',
	s.gender AS 'STUDENTS.Gender',

--	s.startDate AS 'startDate',
--    s.startStatus AS 'startStatus',
--    s.endDate AS 'endDate',
--    s.endStatus AS 'endStatus',
	ec.PrimaryDisability AS 'S_NC_EC.ec_primary_dis',
--        ml.programStatus AS 'ML_Status',
--        ml.identifiedDate AS 'ML_EntryDate',
--        ml.exitDate AS 'ML_ExitDate',
--    aig1.programStatus AS 'AIG_Status',
--    aig1.identificationArea AS 'AIG_Area',


-- In Infinite Campus 0=Inactive & 1=Active (Which is the exact opposite of PowerSchool)
       s.activeToday AS 'Status',

-- Set StatusName to Inactive and Active
	CASE 
		WHEN s.activeToday = 0 THEN '1'
		WHEN s.activeToday = 1 THEN '0'
		ELSE 'Unknown'
	END AS 'STUDENTS.Enroll_Status',

-- Grade in IC using PK, KG, 1, 2 ,3, 4, etc
        s.grade AS 'Grade_Level',

-- Change Grade to number format
	CASE
		WHEN s.grade = 'KG' THEN '0'
                WHEN s.grade = 'PK' THEN  '-1'
                WHEN s.grade = 'IT' THEN '-2'
                WHEN s.grade = 'PR' THEN '-3'
                WHEN s.grade = 'OS' THEN '-9'
		ELSE s.grade  
	END AS 'STUDENTS.Grade_Level',  

CASE
      WHEN s.grade = '13' THEN '2025'
      WHEN s.grade = 'OS' THEN '2025'
      WHEN s.grade = '12' THEN '2025'
      WHEN s.grade = '11' THEN '2026'
      WHEN s.grade = '10' THEN '2027'
      WHEN s.grade = '9' THEN '2028'
      WHEN s.grade = '8' THEN '2029'
      WHEN s.grade = '7' THEN '2030'
      WHEN s.grade = '6' THEN '2031'
      WHEN s.grade = '5' THEN '2032'
      WHEN s.grade = '4' THEN '2033'
      WHEN s.grade = '3' THEN '2034'
      WHEN s.grade = '2' THEN '2035'
      WHEN s.grade = '1' THEN '2036'
      WHEN s.grade = 'KG' THEN '2037'
      ELSE '2037'
  END AS 'STUDENTS.ClassOf',

-- Change Birthday Format into MM/DD/YYYY
	FORMAT(s.birthdate,'MM/dd/yyyy') AS 'STUDENTS.DOB',
	
-- School in 3 different formats depending on your need.  Comment out the one you don't want.
	sch.name AS 'School Name',
    sch.number AS 'STUDENTS.SchoolID',
--	  SUBSTRING(sch.number, 4, LEN(sch.number) - 3) AS 'School_3Digit',

-- Student Email
	c.email AS 'S_NC_STUDENTDEMO.email_address',
	
	s.raceEthnicityFed AS 'STUDENTS.Ethnicity',
-- Change Ethnicity to number word format
	CASE
		WHEN s.raceEthnicityFed = '1' THEN 'Hispanic/Latino'
                WHEN s.raceEthnicityFed = '2' THEN  'AmericanIndian/Native'
                WHEN s.raceEthnicityFed = '3' THEN 'Asian'
                WHEN s.raceEthnicityFed = '4' THEN 'African-American/Black'
                WHEN s.raceEthnicityFed = '5' THEN 'Hawaiian/PacificIslander'
                WHEN s.raceEthnicityFed = '6' THEN 'Caucasian/White'
                WHEN s.raceEthnicityFed = '7' THEN 'MultiRacial'
		ELSE s.raceEthnicityFed
	END AS 'EthnicityName',  

      f.directoryQuestion AS 'S_NC_STUDENTINFO.release_of_info',
      f.comments AS 'S_NC_STUDENTINFO.release_of_info_desc',

-- c1 is guardian with lowest emergency priority. 
	c1.addressLine1 AS 'STUDENTS.Street',
	c1.city AS 'STUDENTS.City',
	c1.state AS 'STUDENTS.State',
	c1.zip AS 'STUDENTS.Zip',
	c1.lastName AS 'Guardian1_Last',
	c1.firstName AS 'Guardian1_First',
	CONCAT(c1.firstName, c1.lastName) AS 'Guardian1_FullName',
-- If HomePhone is blank then use CellPhone
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c1.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c1.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Guardian1_DayPhone',
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c1.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c1.cellPhone, '(', ''), ')', ''), '-', '')) AS 'STUDENTS.Home_Phone',
	c1.email AS 'Guardian1_Email',
	c1.relationship AS 'Guardian1_Relationship',

-- c2 is guardian with next emergency priority	
	c2.lastName AS 'Guardian2_Last',
	c2.firstName AS 'Guradian2_First',
	CONCAT(c2.firstName, c2.lastName) AS 'Guardian2_FullName',	
	c2.addressLine1 AS 'Guardian2_Street',
	c2.city AS 'Guardian2_City',
	c2.state AS 'Guardian2_State',
	c2.zip AS 'Guardian2_Zip',
-- If HomePhone is blank then use CellPhone
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c2.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c2.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Guardian2_DayPhone',
	c2.email AS 'Guardian2_Email',
	c2.relationship AS 'Guardian2_Relationship'


FROM v_AdHocStudent s
INNER JOIN Calendar cal on s.calendarID = cal.calendarID
INNER JOIN school sch ON sch.schoolid = s.schoolID
LEFT OUTER JOIN SpecialEdState ec ON ec.personID = s.personID
LEFT OUTER JOIN contact c ON c.personID = s.personID
LEFT OUTER JOIN LEP ml ON ml.personID = s.personID
LEFT OUTER JOIN aigOrdered aig1 ON aig1.personID = s.personID AND aig1.rowNumber = 1
LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1
LEFT OUTER JOIN ContactsOrdered c2 ON s.personID = c2.personID AND c2.rowNumber = 2 
LEFT OUTER JOIN FERPA f ON s.personID = f.personID AND f.schoolyear = cal.endyear




WHERE cal.calendarId=s.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND (s.stateid IS NOT NULL or s.stateid <> '')
   AND s.servicetype = 'P'  -- Only choose primary school
