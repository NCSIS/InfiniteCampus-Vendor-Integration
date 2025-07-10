/*
	Title: One to One Plus
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	07/25/2024		Initial creation of this template
        07/09/2025		Updated to allow enrolled students before their start date

*/


WITH ContactsOrdered AS (
SELECT
c.personID,
c.contactPersonID,
c.lastName,
c.firstName,
c.email,
c.homePhone,
c.cellPhone,
c.addressLine1,
c.addressLine2,
c.city,
c.state,
c.zip,
ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.contactPersonID) AS rowNumber
FROM
v_CensusContactSummary c WITH (NOLOCK)
WHERE
c.guardian = 1
)
SELECT
s.firstName AS 'first_name',
s.lastName AS 'last_name',
s.studentNumber AS 'external_id',
s.grade,
s.gender,
s.middleName AS 'middle_name',
s.homeroomTeacher,
c.email AS 'student_email',
c1.addressLine1,
c1.city,
c1.state,
c1.zip,
c1.lastName AS 'guardian1_lastName',
c1.firstName AS 'guardian1_firstName',
c1.email AS 'guardian1_email',
c1.homePhone AS 'guardian1_homePhone',
c1.cellPhone AS 'guardian1_cellPhone',
c2.lastName AS 'guardian2_lastName',
c2.firstName AS 'guardian2_firstName',
c2.email AS 'guardian2_email',
c2.homePhone AS 'guardian2_homePhone',
c2.cellPhone AS 'guardian2_cellPhone',
	CASE 
	    WHEN s.endDate IS NULL OR s.endDate >= GETDATE() THEN 'Active'
		WHEN s.endDate < GETDATE() THEN 'Inactive'
		ELSE 'I'
	END AS 'Status',
sch.number AS 'School_number'

FROM v_AdHocStudent s
LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1
LEFT OUTER JOIN ContactsOrdered c2 ON s.personID = c2.personID AND c2.rowNumber = 2
JOIN school sch ON sch.schoolid = s.schoolID
JOIN contact c ON c.personID = s.personID
JOIN calendar cal ON cal.calendarID = s.calendarId

WHERE s.calendarId = cal.calendarid
    AND cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')
    AND s.servicetype = 'P'
    AND (s.stateid IS NOT NULL OR s.stateid <> '')
    AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
