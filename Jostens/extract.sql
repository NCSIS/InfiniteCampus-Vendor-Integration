/*
	Title: Jostens

-- Change the school number at the bottom of the file or Comment it out -- to pull all schools.

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/28/2024		Initial creation of this template

*/


-- Go through the contacts table and remove any duplicates.  Usually caused by the same contact being associated with the student more than once.
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
)


SELECT
	ahs.lastname as 'Last_Name',
	ahs.firstName as 'First_Name',
	ahs.middleName as 'Middle_Name',
	cs.addressline1 AS 'Mailing_Street',
	cs.city AS 'Mailing_City',
	cs.state AS 'Mailing_State',
	cs.Zip	AS 'Mailing_Zip',
	cs.householdPhone AS 'Home_Phone',
	c1.cellPhone AS 'Parent_Cell',
	'' AS 'Student_Cell',
	CASE
      WHEN ahs.grade = '13' THEN CONVERT(numeric,cal.endyear)
      WHEN ahs.grade = 'OS' THEN Convert(numeric,cal.endyear)
      WHEN ahs.grade = '12' THEN Convert(numeric,cal.endyear)
      WHEN ahs.grade = '11' THEN (Convert(numeric,cal.endyear)+1)
      WHEN ahs.grade = '10' THEN (Convert(numeric,cal.endyear)+2)
      WHEN ahs.grade = '9' THEN (Convert(numeric,cal.endyear)+3)
      WHEN ahs.grade = '8' THEN (Convert(numeric,cal.endyear)+4)
      WHEN ahs.grade = '7' THEN (Convert(numeric,cal.endyear)+5)
      WHEN ahs.grade = '6' THEN (Convert(numeric,cal.endyear)+6)
      WHEN ahs.grade = '5' THEN (Convert(numeric,cal.endyear)+7)
      WHEN ahs.grade = '4' THEN (Convert(numeric,cal.endyear)+8)
      WHEN ahs.grade = '3' THEN (Convert(numeric,cal.endyear)+9)
      WHEN ahs.grade = '2' THEN (Convert(numeric,cal.endyear)+10)
      WHEN ahs.grade = '1' THEN (Convert(numeric,cal.endyear)+11)
      WHEN ahs.grade = 'KG' THEN (Convert(numeric,cal.endyear)+12)
      WHEN ahs.grade = 'PK' THEN (Convert(numeric,cal.endyear)+13)
      WHEN ahs.grade = 'IT' THEN (Convert(numeric,cal.endyear)+14)
      WHEN ahs.grade = 'PR' THEN (Convert(numeric,cal.endyear)+15)
	END AS 'Grad_Year',
	c1.email AS 'Guardian_Email',
	cs.email AS 'Student_Email'

	
FROM v_AdhocStudent ahs
	LEFT OUTER JOIN ContactsOrdered c1 ON ahs.personID = c1.personID AND c1.rowNumber = 1
	INNER JOIN calendar cal ON cal.calendarid = ahs.calendarid
	INNER JOIN school sch ON sch.schoolID = cal.schoolid
	CROSS APPLY (
        SELECT TOP 1 * 
        FROM v_CensusContactSummary cs 
        WHERE cs.personID = ahs.personID 
        AND cs.relationship = 'Self' 
        ORDER BY cs.contactID DESC
    ) cs
	
WHERE cal.calendarId=ahs.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (ahs.endDate IS NULL or ahs.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND ahs.stateid IS NOT NULL	
   AND sch.number = '440320'
   
