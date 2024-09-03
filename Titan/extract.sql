/*
	Title: Titan Nutrition Student Export  (a Linq Solution)
	
	Description:
        Based on the Titan Data Import Specification Sheet 
        https://drive.google.com/file/d/1oii2GeMHPslkXiHbNXRti3_feCoxRDPO/view?usp=sharing
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/15/2024		Initial creation of this template
	08/20/2024		Fixes Guardian selection
	08/20/2024		Added Optional Fields
	08/22/2024		Added a few more optional fields based on feedback from Titan
        09/3/2024		Fix to only select primary school

        Make sure to check the box for:
        Include Header Row and Include Double quotes in IC Data Extract Utility

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
   stu.stateId as 'Student Identifier',
   stu.firstName as 'First Name',
   stu.middleName as 'Middle Name',
   stu.lastName as 'Last Name',
   stu.suffix as 'suffix',
   cs.email AS 'Email',
   FORMAT(stu.birthdate,'MM/dd/yyyy') AS 'Date of Birth', --Change the birthdate format
   stu.gender AS 'Gender',
   c1.cellphone AS 'Cell Phone',
   sch.number AS 'School (Site)',
   cal.name AS 'Calendar',
   stu.grade AS 'Grade',
   stu.startdate AS 'Start Date',
   stu.enddate AS 'Drop Date',
   ahs.homeroomTeacher AS 'Homeroom (Teacher Name)',
   cs.householdID AS 'Household ID',
   CASE when stu.homeprimarylanguage IS NULL THEN 'eng' ELSE stu.homeprimarylanguage END AS 'Home Language',
   cs.AddressLine1 AS 'Home Address (Street)',
   cs.city AS 'City',
   cs.state AS 'State',
   cs.zip as 'Zip',
   c1.firstName AS 'Head of Household First Name',
   c1.lastName AS 'Head of Household Last Name',
   COALESCE(c1.homePhone, c1.cellPhone) AS 'Head of Household Home Phone',
   c1.email AS 'Head of Household Email',
   c1.relationship AS 'Head of Household Relationship'

 


FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
   LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
   LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
   LEFT OUTER JOIN v_AdHocStudent ahs ON stu.personID = ahs.personID and ahs.calendarID = stu.calendarid

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND CAST(substring(sch.number,4,3) AS INTEGER) >= 300 --Charter schools need to remove this line.
   AND stu.stateid IS NOT NULL
   AND stu.servicetype = 'P'  -- Only choose primary school
-- AND stu.startstatus <> 'X1' -- Uncomment if the above doesn't fix cross enrollment

   
   
