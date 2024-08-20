/*
	Title: SNAP by ProMed - Contacts File
	
	Description:
	Creates a row for email and phone for each 2 contacts associated with each student
	I am 100% sure there is a better way to do this, but their file format requires a new row
	for each type of data and this was the way I knew how to do that. 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/17/2024		Initial creation of this template
	08/20/2024		Change contacts to require the guardian checkbox

*/

-- Go through the contacts table and remove any duplicates.  Usually caused by the same contact being associated with the student more than once.
WITH ContactsGrouped AS (
	SELECT DISTINCT
		cg.personID, cg.contactPersonID, cg.lastName, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship, cg.guardian
FROM  v_CensusContactSummary cg WITH (NOLOCK)
GROUP BY cg.personID,cg.contactPersonID,cg.lastname, cg.firstName, cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship, cg.guardian
),

-- Go through the Contacts Table and find the contact with the highest emergency priority 
-- See Below to only pull Contacts marked as guardians.  If you are sure you have guardians' checked in NCSIS, uncomment this line.
ContactsOrdered AS (
	SELECT DISTINCT
		co.personID, co.contactPersonID, co.lastName, co.firstName, co.email, co.homePhone, co.cellPhone, co.seq, co.relationship, co.guardian,
		ROW_NUMBER() OVER (PARTITION BY co.personID ORDER BY co.seq) AS rowNumber
    FROM contactsGrouped co WITH (NOLOCK)
    WHERE co.relationship <> 'Self' AND co.seq IS NOT NULL

-- Uncomment the line below to only pull guardians. 
	AND co.guardian = 1
),
-- Pull the contact for the student and not anyone else associated.
ContactSelf AS (
	SELECT DISTINCT
		c.personID, 
		c.householdPhone, 
		c.seq,
		c.relationship,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)


select -- Select Contact1 
	stu.stateid AS 'Reference ID',
	CONCAT(c1.firstName, ' ', c1.lastName) AS 'Name',
	c1.relationship AS 'Relationship',
	'"HouseholdPhone","E-Mail","CellPhone","HomePhone"' AS 'Type',
	CONCAT('"',cs.householdPhone, '", "',c1.email, '", "', c1.cellphone, '", "', c1.homephone,'"') AS 'Data'
from student stu
	INNER JOIN Calendar cal ON stu.calendarID = cal.calendarID
	INNER JOIN school sch ON sch.schoolid = stu.schoolID
	LEFT OUTER JOIN ContactsOrdered c1 ON stu.personID = c1.personID AND c1.rowNumber = 1
	LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID and cs.rowNumber = 1

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND CAST(substring(sch.number,4,3) AS INTEGER) >= 300
   AND stu.stateid IS NOT NULL
   AND stu.stateid <> ''
   AND c1.relationship IS NOT NULL;
