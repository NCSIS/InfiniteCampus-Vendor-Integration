
/*
	Title: PrimeroEdge
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/17/2025 - Initial Version
	
	*Based on : http://docs.primeroedge.com/Implementation/StudentInformationDataExchange.pdf

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
c.relationship,
c.city,
c.state,
c.zip,
ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.contactPersonID) AS rowNumber
FROM
v_CensusContactSummary c WITH (NOLOCK)
WHERE
c.guardian = 1
),

ContactSelf AS (
	SELECT 
		c.personID, 
		c.cellphone,
		c.householdPhone, 
		c.seq,
		c.relationship,
		c.addressline1,
		c.city,
		c.state,
		c.zip,
		c.email,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c 
	WHERE c.relationship = 'Self'
)



SELECT
	s.studentNumber AS 'Student ID',
	s.studentNumber AS 'StateID',
	s.firstName AS 'First Name',
	s.lastName AS 'Last Name',
	s.middleName AS 'Middle Name',
	format(s.birthdate, 'MM/dd/yyyy') as 'Birth Date',
	sch.number AS 'School Code',
	s.grade AS 'Grade',
/* REMOVED FOR PRIVACY
	'' AS 'SSN',
	CASE
        WHEN ISNULL(s.hispanicEthnicity, 'N') = 'Y' THEN 'H'
		ELSE 'N'
	END AS 'Ethnicity',
	s.raceEthnicityFed AS 'Race', 
*/
	CASE when s.homeprimarylanguage IS NULL THEN 'eng' ELSE s.homeprimarylanguage END AS 'Primary Language',
	s.gender AS 'Gender',
	c.addressLine1 AS 'Street Address Line 1',
	c.city AS 'City',
	c.state AS 'State',
	c.zip AS 'Zip',
	s.homeroomTeacher AS 'Homeroom',
	c1.firstName AS 'Guardian First Name',
	c1.lastName AS 'Guardian Last Name',
	c1.relationship AS 'Guardian Relationship',
	c1.email AS 'Guardian Email',
		CASE 
	    WHEN s.endDate IS NULL OR s.endDate >= GETDATE() THEN 'Active'
		WHEN s.endDate < GETDATE() THEN 'Inactive'
		ELSE 'Inactive'
	END AS 'Status'


FROM v_AdHocStudent s
LEFT OUTER JOIN ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1
JOIN school sch ON sch.schoolid = s.schoolID
JOIN contactself c ON c.personID = s.personID  and c.rowNumber = 1
JOIN calendar cal ON cal.calendarID = s.calendarId

WHERE s.calendarId = cal.calendarid
    AND cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')
    AND s.servicetype = 'P'
    AND (s.stateid IS NOT NULL OR s.stateid <> '')
    AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
