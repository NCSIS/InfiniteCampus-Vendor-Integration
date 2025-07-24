/*
	Title: Classlink Admins and Aides
	
	Description: This is a suplemental file for classlink to add admins and aides to the Roster Server.

 *** IMPORTANT:  Change the LIKE email address to your schools domain at the bottom
                 
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/27/2024		Initial creation of this template
        07/24.2025		added missing 'd' to sourcedids and orgsourcedids

*/

SELECT DISTINCT
     ident.identityGUID AS 'sourcedId',
     'true' AS 'enabledUser',
     sch.schoolguid as 'orgSourcedIds',
	CASE
		WHEN sm.supervisor = '1' THEN 'administrator'
		ELSE 'aide'
	END AS 'role',
	left(c.email, charindex('@', c.email) - 1) AS 'username',
	sm.firstName as 'givenName',
	sm.lastName as 'familyName',
--	sm.middleName as 'middleName',
	sm.staffstateID AS 'identifier',
	c.email AS 'email'
--	COALESCE(c.homePhone, c.cellPhone) AS 'phone'


FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
   INNER JOIN school sch ON sm.schoolnumber = sch.number
   INNER JOIN "identity" ident ON ident.personID = sm.personid
WHERE sm.enddate IS NULL AND c.email LIKE '%@haywood.k12.nc.us'
   AND (sm.endDate IS NULL OR sm.enddate > getdate())
   AND sm.teacher <> '1'
