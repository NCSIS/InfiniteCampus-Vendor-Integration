/*
	Title: FinalSite Parent
	
	Description:  Finalsite Parent File  
                This creates a new row for each guardian

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	09/24/2024		Initial creation of this template

*/


SELECT
	c.contactpersonid AS 'Account ID',
	sch.number AS 'Organization ID',
	c.lastName AS 'Last Name',
	c.firstName AS 'First Name',
	CASE
		WHEN ferpa.directoryquestion = 'NO' THEN 'YES'
		ELSE 'NO'
	END AS 'Hidden from Directory',
	stu.stateid AS 'Student ID',
	c.relationship AS 'Title',
	COALESCE(c.householdPhone, c.homePhone, c.cellPhone) AS 'Primary Phone',
	c.cellphone AS 'Cell Phone',
	c.homephone AS 'Home Phone',
	c.email AS 'Email 1',
	c.secondaryEmail AS 'Email 2',
	c.addressLine1 AS 'Street Address',
	c.city AS 'City',
	c.state AS 'State',
	c.zip AS 'Zip',
	c.cellphone AS 'Text Number 1',
	c.communicationlanguage AS 'Language'
	
FROM v_CensusContactSummary c
	INNER JOIN student stu ON c.personid = stu.personid
	INNER JOIN school sch ON stu.schoolid = sch.schoolid
  LEFT OUTER JOIN ferpa ON ferpa.personid = stu.personid
WHERE c.guardian = '1'
  AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date      
