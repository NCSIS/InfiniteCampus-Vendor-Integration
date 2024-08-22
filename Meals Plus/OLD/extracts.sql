/*
	Title: School Nutrition POS Linker
	
	Description:
	Point-of-Sale Linker file for school nutrition point-of-sale system
	
	Author: Rutherford County Schools
	
	Revision History:
	07/12/2024		Initial creation of this template

*/



--Rutherford County Schools, NC, Infinite Campus MealsPlus query, JMT 7/2024
--Followed and recreated previous NC Meals Plus Linker Header from State Report / PowerSchool
--Unused fields as shown in the Meals Plus Import are just the header recreated with no data
--JMT 7/31/2024 Removed NOLOCK per Infinite Campus KB https://kb.infinitecampus.com/help/nolock-faq
--Also added AND sch.name <> 'NCDPI' to filter out NCDPI users from export, cuts down on errors in Meals Plus import log. 

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
		v_CensusContactSummary c
	WHERE 
		c.guardian = 1
)

SELECT 
	s.studentNumber AS 'NCWISE_ID', 
	'' AS 'SSN',
	s.lastName AS 'Last Name',
	s.firstName AS 'First Name', 
	FORMAT(s.birthdate,'MM/dd/yyyy') AS 'Birth Date',
	'' AS 'Entry Date',
	CASE 
		WHEN s.activeToday = 0 THEN 'I'
		WHEN s.activeToday = 1 THEN 'A'
		ELSE ''
	END AS 'Current Status',
	'' AS 'Exit Date',
	 /* Uncomment if we need a leading 0 to make 2 digits, example 09 instead of 9
	CASE
		WHEN ISNUMERIC(s.grade) = 1 THEN RIGHT('00' + CAST(s.grade AS VARCHAR(2)), 2)
		ELSE s.grade  
	END AS 'Grade',  
	*/
	s.grade AS 'Grade',
	sch.name AS 'School Name',
	SUBSTRING(sch.number, 4, LEN(sch.number) - 3) AS 'School Number',
	s.homeroomTeacher AS 'Homeroom',
	c1.addressLine1 AS 'Mailing Address',
	'' AS 'Mailing Apt',
	'' AS 'Mailing PO Box',
	c1.city AS 'Mailing City',
	c1.state AS 'Mailing State',
	c1.zip AS 'Mailing ZipCode',
	'' AS 'Address',
	'' AS 'APT',
	'' AS 'City',
	'' AS 'State',
	'' AS 'Zip',
	c1.lastName AS 'Mother Last',
	c1.firstName AS 'Mother First',
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c1.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c1.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Mother Day Phone',
	c1.email AS 'Mother Email',
	c2.lastName AS 'Father Last',
	c2.firstName AS 'Father First',
	COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(c2.homePhone, '(', ''), ')', ''), '-', ''), ''), REPLACE(REPLACE(REPLACE(c2.cellPhone, '(', ''), ')', ''), '-', '')) AS 'Father Day Phone',
	c2.email AS 'Father Email',
	'' AS 'Guardian Last',
	'' AS 'Guardian First',
	'' AS 'Guardian Day Phone',
	'' AS 'Guardian Email',
	REPLACE(REPLACE(REPLACE(REPLACE(hh.phone, ' ', ''), '(', ''), ')', ''), '-', '') AS 'Student Phone',
	c.email AS 'Student Email'

FROM 
	v_AdHocStudent s
LEFT OUTER JOIN 
	ContactsOrdered c1 ON s.personID = c1.personID AND c1.rowNumber = 1
LEFT OUTER JOIN 
	ContactsOrdered c2 ON s.personID = c2.personID AND c2.rowNumber = 2
JOIN 
	school sch ON sch.schoolid = s.schoolID
JOIN 
	contact c ON c.personID = s.personID
JOIN
	householdMember hm ON hm.personID = s.personID
JOIN
	Household hh ON hh.householdID = hm.householdID
WHERE 
	s.activeYear = 1
-- Added the below to prevent null student ids from showing up in the export. Meals Plus import can fail import with missing student numbers. (RCS/JMT 7/25/2024)
	AND s.studentNumber IS NOT NULL
	AND s.studentNumber <> ''
        AND sch.name <> 'NCDPI'

-- Change the below to 1 for active students, have set to 0 to pull non-active for summer. Leave below commented out to allow all activeYear to export, use below if needed to filter out inactives during the school year. 
-- AND s.activeToday = 0
