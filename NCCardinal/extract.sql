/*
	Title: NC Cardinal
	
	Description:
        Student File for SFTP upload to NC Cardinal

SchoolNumbers 300+ and 000
Grades KG - 12
Excludes parents who do not want directory information shared
	
	Author: Jeremiah Jackson - NCDPI  
	
	Revision History:
	10/08/2024		Initial creation of this template

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
     stu.stateid AS 'Student ID',
     stu.lastName AS 'Last Name',
     stu.firstName AS 'First Name',
     stu.middleName AS 'Middle Name',
     FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'Date of Birth',
     cs.AddressLine1 AS 'Street',
     cs.city AS 'Student_city',
     cs.state AS 'Student_state',
     cs.zip AS 'Student_zip',    
     CONCAT(c1.firstName, ' ', c1.lastName) AS 'Guardian',
     cs.email AS 'Email address',
     cs.householdphone AS 'Phone number',
     stu.gender AS 'Gender',
     sch.name AS 'School',
     ferpa.directoryquestion

FROM v_adhocstudent stu
   INNER JOIN Calendar cal ON stu.calendarID = cal.calendarID
   INNER JOIN school sch on stu.schoolid = sch.schoolid
   LEFT OUTER JOIN ContactSelf cs ON cs.personID = stu.personID and cs.rowNumber = 1
   LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
   LEFT OUTER JOIN ferpa ON stu.personid = ferpa.personid

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
   AND stu.servicetype = 'P'  -- Only choose primary school
   AND (ferpa.directoryquestion IS NULL or ferpa.directoryquestion = 'YES')
   AND (ISNUMERIC(stu.grade) = 1 OR stu.grade = 'KG')
