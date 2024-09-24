/*
	Title: FinalSite Staff
	
	Description:  Final Site Staff



*******************************************
*****  Change email address at the bottom
*******************************************





	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	09/24/2024		Initial creation of this template

*/

WITH ContactSelf AS (
	SELECT DISTINCT
		c.personID, c.lastName, c.firstName, c.email, c.householdPhone, c.seq, c.relationship, c.city, c.zip, c.state, c.addressline1, c.cellphone, c.homephone, c.contactguid,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM 
		v_CensusContactSummary c WITH (NOLOCK)
    WHERE 
                c.relationship = 'Self'
)

SELECT
    sch.number AS 'organizationid',
    sm.staffstateid AS 'teacherid',
    sm.lastname AS 'lastName',
    sm.firstName AS 'firstName',
    COALESCE(c1.householdPhone, c1.homephone, c1.cellPhone) AS 'phoneNumber',
    c1.cellPhone AS 'smsNumber',
    c1.email AS 'emailAddress',
    c1.city AS 'city',
    c1.zip AS 'zip',
    c1.state AS 'state',
    sm.title AS 'title'

FROM staffmember sm
   INNER JOIN school sch ON sch.schoolid = sm.schoolid 
   INNER JOIN person p ON p.personid = sm.personid
   LEFT OUTER JOIN ContactSelf c1 ON c1.contactguid = p.personguid and c1.rownumber = 1


WHERE  (sm.enddate IS NULL or sm.enddate > getdate())
   AND c1.email LIKE '%cravenk12.org'

