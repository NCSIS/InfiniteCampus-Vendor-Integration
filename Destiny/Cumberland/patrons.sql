/*
	Title: Cumberland County Schools - Destiny Patrons
	
	Description:
        There is no standard format for destiny.  This export matches the file format used in the past by cumberland.
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template


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



--
--
--  SQL export starts below here
--
--




SELECT
   sch.number AS 'SchoolId',
   stu.stateId as 'Student_number',
   stu.firstName as 'First Name',
   stu.middleName as 'Middle Name',
   stu.lastName as 'Last Name',
   FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'DOB', --Change the birthdate format
   stu.gender AS 'Gender',


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
  END AS Sched_YearOfGraduation,

   stu.grade AS 'Grade_Level',
   cs.email AS 'Email',
   cs.addressLine1 AS 'street',
   cs.city as 'City',
   cs.state as 'State',
   cs.zip as 'Zip',
   cs.householdPhone as 'home_phone',
   ahs.homeroomTeacher AS 'Home_room'
 

FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
   LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
   LEFT OUTER JOIN v_AdHocStudent ahs ON stu.personID = ahs.personID and ahs.calendarID = stu.calendarid

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND CAST(substring(sch.number,4,3) AS INTEGER) >= 300
   AND stu.stateid IS NOT NULL

   
   
