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
        09/3/2024		Fix to only select primary school, Added Allergies
	09/6/2024		Fixed Start and End date formatting

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
),

-- Process health conditions to pull food allergies
StudentAllergies AS (
	SELECT
		hc.personID, hc.code, hc.description, hc.startDate, hc.endDate, hc.status, hc.comments, hc.userWarning, hc.instructions, hc.typeID,
		ROW_NUMBER() OVER (PARTITION BY hc.personID ORDER BY hc.conditionID) AS rowNumber
	FROM healthcondition hc 
	WHERE (hc.endDate IS NULL OR hc.endDate >= GETDATE())
		AND hc.typeID IN ('44', '221', '240', '766', '1109', '1299', '1302', '1305', '3264', '3275', '3290')
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
   FORMAT(stu.startdate, 'MM/dd/yyyy') AS 'Start Date',
   FORMAT(stu.enddate, 'MM/dd/yyyy') AS 'Drop Date',
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
   c1.relationship AS 'Head of Household Relationship',

     -- Concatenated Allergies in CSV format
    CONCAT(
        COALESCE(LEFT(sa1.description,16), ''), 
        CASE WHEN sa2.description IS NOT NULL THEN CONCAT(',', LEFT(sa2.description,16)) ELSE '' END, 
        CASE WHEN sa3.description IS NOT NULL THEN CONCAT(',', LEFT(sa3.description,16)) ELSE '' END
    ) AS 'Allergies',

    -- Concatenated UserWarnings in CSV format
    LEFT(CONCAT(
        COALESCE(sa1.userWarning, ''), 
        CASE WHEN sa2.userWarning IS NOT NULL THEN CONCAT(',', sa2.userWarning) ELSE '' END, 
        CASE WHEN sa3.userWarning IS NOT NULL THEN CONCAT(',', sa3.userWarning) ELSE '' END
    ),150) AS 'Tags'


FROM student stu
   INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
   INNER JOIN school sch ON sch.schoolID = cal.schoolID
   LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
   LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID AND cs.rowNumber = 1
   LEFT OUTER JOIN v_AdHocStudent ahs ON stu.personID = ahs.personID and ahs.calendarID = stu.calendarid
    LEFT OUTER JOIN StudentAllergies sa1 ON stu.personID = sa1.personID AND sa1.rowNumber = 1
    LEFT OUTER JOIN StudentAllergies sa2 ON stu.personID = sa2.personID AND sa2.rowNumber = 2
    LEFT OUTER JOIN StudentAllergies sa3 ON stu.personID = sa3.personID AND sa3.rowNumber = 3

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000') --Charter schools might need to remove this line.
   AND stu.stateid IS NOT NULL
   AND stu.servicetype = 'P'  -- Only choose primary school
-- AND stu.startstatus <> 'X1' -- Uncomment if the above doesn't fix cross enrollment

   
   
