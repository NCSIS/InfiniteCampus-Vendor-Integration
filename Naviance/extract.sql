/*
	Title: Naviance 
	
	Description:  This is based on the Naviance Template.  


  Current missing fields from the template are the following:
    AP_Courses   -- Count of AP Classes
    Graduation_Date
    Diploma_Type
 

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/26/2024		Initial creation of this template

*/

-- Pull the contact for the student and not anyone else associated.
WITH ContactSelf AS (
	SELECT DISTINCT
		c.personID, c.lastName, c.firstName, c.email, c.householdPhone, c.seq, c.relationship, c.AddressLine1, c.city, c.state, c.zip,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)



SELECT
	stu.stateid AS 'Student_ID',
	CASE
      WHEN stu.grade = '13' THEN CONVERT(numeric,cal.endyear)
      WHEN stu.grade = 'OS' THEN Convert(numeric,cal.endyear)
      WHEN stu.grade = '12' THEN Convert(numeric,cal.endyear)
      WHEN stu.grade = '11' THEN (Convert(numeric,cal.endyear)+1)
      WHEN stu.grade = '10' THEN (Convert(numeric,cal.endyear)+2)
      WHEN stu.grade = '9' THEN (Convert(numeric,cal.endyear)+3)
      WHEN stu.grade = '8' THEN (Convert(numeric,cal.endyear)+4)
      WHEN stu.grade = '7' THEN (Convert(numeric,cal.endyear)+5)
      WHEN stu.grade = '6' THEN (Convert(numeric,cal.endyear)+6)
      WHEN stu.grade = '5' THEN (Convert(numeric,cal.endyear)+7)
      WHEN stu.grade = '4' THEN (Convert(numeric,cal.endyear)+8)
      WHEN stu.grade = '3' THEN (Convert(numeric,cal.endyear)+9)
      WHEN stu.grade = '2' THEN (Convert(numeric,cal.endyear)+10)
      WHEN stu.grade = '1' THEN (Convert(numeric,cal.endyear)+11)
      WHEN stu.grade = 'KG' THEN (Convert(numeric,cal.endyear)+12)
      WHEN stu.grade = 'PK' THEN (Convert(numeric,cal.endyear)+13)
      WHEN stu.grade = 'IT' THEN (Convert(numeric,cal.endyear)+14)
      WHEN stu.grade = 'PR' THEN (Convert(numeric,cal.endyear)+15)
	END AS Class_Year, 
	stu.lastName AS 'Last_Name',
	sch.number AS 'School_ID',
	stu.firstName AS 'First_Name',
	stu.birthdate AS 'Date_of_Birth',
	cs.email AS 'Student_Email',
	stu.stateID as 'Federated_ID',
	left(cs.email, charindex('@', cs.email) -1),
	stu.middleName AS 'Middle_Name',
	stu.stateid AS 'State_Student_ID',
	stu.gender AS 'Gender',
	stu.raceEthnicityFed AS 'Ethnicity',
	cs.AddressLine1 AS 'Street_Address_1',
	cs.city AS 'City',
	cs.state AS 'State',
	cs.zip AS 'Zip_Code',
	'US' AS 'Country',
	gpa.cumGpaUnweighted AS 'GPA',
	gpa.cumGpaBasic AS 'Weighted_GPA',
	gpastats.rank AS 'Rank',
	CEILING((gpastats.rank * 1.0 / NULLIF(gpastats.out_of,0)) * 10) AS decile,
	cs.householdphone as 'Home_Phone',

-- This is based on whether parents allow data to be shared with colleges.  If directory information is needed instead use directoryquestion instead.
	ferpa.collegesQuestion AS 'FERPA_Block_Requested'
	
FROM student stu
	INNER JOIN calendar cal ON stu.calendarID = cal.calendarid
	INNER JOIN school sch ON sch.schoolid = cal.schoolid
	LEFT OUTER JOIN v_cumgpafull gpa ON gpa.personid = stu.personid and stu.calendarid = gpa.calendarID
	LEFT OUTER JOIN v_CumGPAStats gpastats ON gpastats.personid = stu.personid and gpastats.calendarID = stu.calendarid
	INNER JOIN ContactSelf cs ON cs.personid = stu.personid and rowNumber = 1
    LEFT OUTER JOIN FERPA ferpa ON stu.personID = ferpa.personID
	
WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL

	
	
	
	
