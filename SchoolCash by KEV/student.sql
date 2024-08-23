
/*
	Title: SchoolCash by KEV - Students File
	
	Description: This is a tab delimited file.  Instructions from KEV can be found here.
  https://drive.google.com/file/d/1AninXfxUsRe_I_D-_2rK7JU7bnKjx7LE/view?usp=sharing

** Make sure you set this up as a tab delimted file not a CSV.
  Filename = Mass_YourDistrictName_Students.txt

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/19/2024		Initial creation of this template

*/

-- Go through the contacts table and remove any duplicates.  Usually caused by the same contact being associated with the student more than once.
WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, cg.contactPersonID, cg.lastName, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship,cg.AddressLine1,cg.State,cg.city,cg.zip,cg.guardian
FROM  v_CensusContactSummary cg WITH (NOLOCK)
GROUP BY cg.personID,cg.contactPersonID,cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship,cg.AddressLine1,cg.state,cg.city,cg.zip,cg.guardian
),

-- Go through the Contacts Table and find the contact with the highest emergency priority 
-- See Below to only pull Contacts marked as guardians.  If you are sure you have guardians' checked in NCSIS, uncomment this line.
ContactsOrdered AS (
	SELECT DISTINCT
		co.personID, co.contactPersonID, co.lastName, co.firstName, co.email, co.homePhone, co.cellPhone, co.seq, co.relationship, co.AddressLine1,co.city,co.state,co.zip,
		ROW_NUMBER() OVER (PARTITION BY co.personID ORDER BY co.seq) AS rowNumber
    FROM contactsGrouped co WITH (NOLOCK)
    WHERE co.relationship <> 'Self' AND co.seq IS NOT NULL and co.relationship = 'Mother' AND co.guardian = 1

),

ContactSelf AS (
	SELECT DISTINCT
		c.personID, 
		c.householdPhone, 
		c.seq,
		c.relationship,
		c.email,
		c.AddressLine1,
		c.city,
		c.state,
		c.zip,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)


SELECT

	sch.name AS 'Student_School_Name',
	sch.number AS 'Student_School_Number',
	stu.firstName AS 'Student_First_Name',
	stu.middleName AS 'Student_Middle_Name',
	stu.lastName AS 'Student_Last_Name',
	stu.stateid AS 'Student_Number',
	cs.AddressLine1 AS 'Student_Address',
	cs.city AS 'Student_City',
	cs.state AS 'Student_State',
	cs.zip AS 'Student_Zip_Code',
	cs.householdphone AS 'Student_Phone',
	'' AS 'Reserved-1',
	ahs.homeroomTeacher AS 'Student_Classroom/Homeroom',
	stu.grade AS 'Student_Grade',
	c1.firstName AS 'Student_Parent/Guardian1_First_Name',
	c1.lastName AS 'Student_Parent/Guarduan1_Last_Name',
	'' AS 'Student_Parent/Guardian2_First_Name',
	'' AS 'Student_Partent/Guardian2_Last_Name',
	FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'Student_DOB',
	'' AS 'Reserved-2',
	c1.email AS 'Student_Parent/Guardian_Email',
	'' AS 'Reserved-3',
	'' AS 'Reserved-4'
	
FROM student stu
	INNER JOIN school sch ON sch.schoolid = stu.schoolID
	INNER JOIN Calendar cal ON stu.calendarID = cal.calendarID
	INNER JOIN ContactSelf cs ON stu.personID = cs.personID and cs.rowNumber = 1
	LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1 
	LEFT OUTER JOIN v_AdhocStudent ahs ON stu.personID = ahs.personID AND ahs.calendarid = stu.calendarid	
	
	

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND CAST(substring(sch.number,4,3) AS INTEGER) >= 300
   AND stu.stateid IS NOT NULL


	
