/*
	Title:   Destiny Patrons
	
	Description:
        For use with the DPI standard DEstiney properties file. 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template
	08/28/2024		Made more efficient for larger school districts.
	08/11/2025 		Outer APPLY to ensure students without a self record are included.
	09/04/2025		Add parent accounts as secondary and tertiary contacts (Mark Samberg - Chatham County Schools)


*/




--
--
--  SQL export starts below here
--
--

WITH ContactsGrouped AS (
	SELECT 
		cg.personID, 
		cg.contactPersonID, 
		cg.lastName, 
		cg.firstName, 
		cg.email, 
		cg.homePhone, 
		cg.cellPhone, 
		cg.seq, 
		cg.relationship,
		cg.AddressLine1,
		cg.State,
		cg.city,
		cg.zip,
		cg.guardian
	FROM  v_CensusContactSummary cg 
	GROUP BY cg.personID, cg.contactPersonID, cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship, cg.AddressLine1, cg.state, cg.city, cg.zip, cg.guardian
),

-- Consolidated Contact Ordering
ContactsOrdered AS (
	SELECT 
		co.personID, 
		co.contactPersonID, 
		co.lastName, 
		co.firstName, 
		co.email, 
		co.homePhone, 
		co.cellPhone, 
		co.seq, 
		co.relationship, 
		co.AddressLine1,
		co.city,
		co.state,
		co.zip,
		ROW_NUMBER() OVER (PARTITION BY co.personID, co.relationship ORDER BY co.seq) AS rowNumber
	FROM ContactsGrouped co 
	WHERE co.seq IS NOT NULL AND co.guardian = 1
)


SELECT DISTINCT
   stu.stateId as 'Student_number', -- 1
   sch.number AS 'SchoolId', -- 2
   stu.lastName as 'Last Name', -- 3
   stu.firstName as 'First Name', -- 4
   stu.middleName as 'Middle Name', -- 5
   stu.gender AS 'Gender', -- 6
   stu.grade AS 'Grade_Level', -- 7
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
  END AS Sched_YearOfGraduation, -- 8
  FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'DOB', --Change the birthdate format -- 9
    cs.addressLine1 AS 'street', -- 10
    cs.city as 'City', -- 11
    cs.state as 'State', -- 12
	cs.zip as 'Zip', -- 13
    cs.householdPhone as 'home_phone', -- 14
	ahs.homeroomTeacher AS 'Home_room', -- 15
	'' AS 'userDefined3', -- 16
	cs.email AS 'Email', -- 17
	c1.email as 'parent_contact_1_email', --18
	c2.email as 'parent_contact_2_email', --19
	c3.email as 'parent_contact_3_email' --20
FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
    OUTER APPLY (
        SELECT TOP 1 * 
        FROM v_CensusContactSummary cs 
        WHERE cs.personID = stu.personID 
        AND cs.relationship = 'Self' 
        ORDER BY cs.contactID DESC
    ) cs
   LEFT OUTER JOIN v_AdHocStudent ahs ON stu.personID = ahs.personID and ahs.calendarID = stu.calendarid
   LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.seq=1
   LEFT OUTER JOIN ContactsOrdered c2 ON stu.personID = c2.personID AND c2.seq=2
   LEFT OUTER JOIN ContactsOrdered c3 ON stu.personID = c3.personID AND c3.seq=3

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
   AND stu.servicetype = 'P'
