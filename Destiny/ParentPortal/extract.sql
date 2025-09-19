/*
	Title: Destiny Parent Portal

	Author: Jeremiah Jackson - NCDPI | Erin Bradley - Orange County Schools
	Revision History:
	08/22/2025		Initial creation of this template


-- Change the school number at the bottom of the file or Comment it out -- to pull all schools.
-- This is only pulling guardians for the email address.  Make sure guardian is checked.  
-- You can comment out co.guardian = 1 in the Contacts Ordered area to pull just the 1st contact for the student.


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
        sch.name AS 'School Name',
	ahs.stateID as 'Student ID#',
	ahs.lastname as 'Last Name',
	ahs.firstName as 'First Name',
	ahs.grade as 'Grade',
	c1.email as 'Parent/Guardian Email'
	
FROM v_AdhocStudent ahs
	LEFT OUTER JOIN ContactsOrdered c1 ON ahs.personID = c1.personID AND c1.rowNumber = 1
	INNER JOIN calendar cal ON cal.calendarid = ahs.calendarid
	INNER JOIN school sch ON sch.schoolID = cal.schoolid
	
WHERE cal.calendarId=ahs.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (ahs.endDate IS NULL or ahs.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND ahs.stateid IS NOT NULL
   AND ahs.stateid <> ''	
