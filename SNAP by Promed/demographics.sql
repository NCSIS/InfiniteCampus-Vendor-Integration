/*
	Title: SNAP by Promed
	
	Description:
        Student File for ProMed SNAP
		
	Author: Jeremiah Jackson - NCDPI  
	
	Revision History:
	08/17/2024		Initial creation of this template
	08/22/2024		Fixed Filters WHERE

*/


-- Pull the contact for the student and not anyone else associated.
WITH ContactSelf AS (
	SELECT DISTINCT
		c.personID, c.lastName, c.firstName, c.email, c.householdPhone, c.seq, c.relationship, c.city, c.zip, c.state, c.addressline1,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)


SELECT 
	s.stateID AS 'Reference ID',
	s.lastName AS 'Last_name',
	s.firstName AS 'First_name', 
	s.middleName AS 'Middle_name',
	s.grade AS 'Grade',
	sch.number AS 'School',
	s.homeroomTeacher AS 'Teacher',
	s.gender AS 'Gender',
	FORMAT(s.birthdate,'MM/dd/yyyy') AS 'DOB'
	
-- End of Required Fields.

/*
	CASE
		WHEN s.homeprimarylanguage IS NULL THEN 'eng'
		ELSE s.homeprimarylanguage 
	END AS 'Primary Language',	
*/
	
/*
	CASE
		WHEN s.raceEthnicityFed = '1' THEN 'Hispanic/Latino'
		WHEN s.raceEthnicityFed = '2' THEN 'AmericanIndian/Native'
		WHEN s.raceEthnicityFed = '3' THEN 'Asian'
		WHEN s.raceEthnicityFed = '4' THEN 'African-American/Black'
		WHEN s.raceEthnicityFed = '5' THEN 'Hawaiian/PacificIslander'
		WHEN s.raceEthnicityFed = '6' THEN 'Caucasian/White'
		WHEN s.raceEthnicityFed = '7' THEN 'MultiRacial'
		ELSE s.raceEthnicityFed
	END AS 'Race',  
*/

-- Student Home Address.  Uncomment if you need.
-- ===============================================
--	cs.city AS 'city',
--	cs.state AS 'state',
--	cs.AddressLine1 AS 'street',
--	cs.zip AS 'Zip',



FROM v_AdHocStudent s
INNER JOIN Calendar cal ON s.calendarID = cal.calendarID
INNER JOIN school sch ON sch.schoolid = s.schoolID
LEFT OUTER JOIN ContactSelf cs ON cs.personID = s.personID and cs.rowNumber = 1



WHERE cal.calendarId=s.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 OR substring(sch.number,4,3) = '000')
   AND (s.stateid IS NOT NULL or s.stateid <> '')
