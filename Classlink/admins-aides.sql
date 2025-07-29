/*
	Title: Classlink Admins and Aides
	
	Description: This is a suplemental file for classlink to add admins and aides to the Roster Server.

 *** IMPORTANT:  Change the LIKE email address to your schools domain at the bottom
                 
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/27/2024		Initial creation of this template
        07/24/2025		added missing 'd' to sourcedids and orgsourcedids
        07/29/2025		Removed Dupes - Grouped by SourceDID and added all orgs as a comma delimited field for every org..
        07/29/2025		SELECT DISTINCT

*/
WITH grouped_orgs AS (
    SELECT 
        ident.identityGUID AS sourcedId,
        STRING_AGG(CAST(sch.schoolguid AS NVARCHAR(36)), ',') AS orgSourcedIds
    FROM staffmember sm
    INNER JOIN school sch ON sm.schoolnumber = sch.number
    INNER JOIN "identity" ident ON ident.personID = sm.personid
    INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
    WHERE sm.enddate IS NULL 
        AND c.email LIKE '%@haywood.k12.nc.us'
        AND (sm.endDate IS NULL OR sm.enddate > GETDATE())
        AND sm.teacher <> '1'
    GROUP BY ident.identityGUID
)


SELECT DISTINCT
    go.sourcedId,
    'true' AS enabledUser,
    go.orgSourcedIds,
    CASE
        WHEN sm.supervisor = '1' THEN 'administrator'
        ELSE 'aide'
    END AS role,
    LEFT(c.email, CHARINDEX('@', c.email) - 1) AS username,
    sm.firstName AS givenName,
    sm.lastName AS familyName,
    sm.staffstateID AS identifier,
    c.email AS email
FROM grouped_orgs go
INNER JOIN staffmember sm ON sm.personid = (
    SELECT TOP 1 ident.personID 
    FROM "identity" ident 
    WHERE ident.identityGUID = go.sourcedId
)
INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE sm.enddate IS NULL 
    AND c.email LIKE '%@haywood.k12.nc.us'
    AND (sm.endDate IS NULL OR sm.enddate > GETDATE())
    AND sm.teacher <> '1'
