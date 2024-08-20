/*
	Title:Panorama - Roster File  (student file)
	
	Description:

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/
WITH ContactSelf AS (
	SELECT DISTINCT
		c.personID, c.lastName, c.firstName, c.email, c.householdPhone, c.seq, c.relationship, c.city, c.zip, c.state, c.addressline1,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)

SELECT
   student.personid, student.stateID, student.studentNumber, student.lastName, student.firstName, student.middleName,
   student.gender, student.birthdate, student.grade, student.activeToday, pcontact.email, cal.calendarid, 
   cal.number AS 'cal.schoolID', cal.name
FROM v_adhocstudent student
	INNER JOIN Calendar cal ON student.calendarid = cal.calendarid
	INNER JOIN ContactSelf pcontact ON pcontact.personid = student.personid AND pcontact.rowNumber = 1


WHERE cal.calendarId=student.calendarId
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (student.endDate IS NULL or student.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND student.stateid IS NOT NULL
   AND student.stateid <> ''
	
	
