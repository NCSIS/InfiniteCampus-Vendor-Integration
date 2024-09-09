
/*
	Title: Raptor Staff with email
	
	Description: Change the email address at the bottom to your schools domain.
                     
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/09/2024		Initial creation of this template

*/


SELECT DISTINCT
     sm.firstName as 'First_name',
	 sm.lastname as 'Last_name',
	 sm.middleName as 'Middle Name',
	 sm.staffstateID as 'ID Number',
     sm.title as 'Type',
	 sm.schoolnumber as 'School ID',
	 sm.schoolname AS 'School Name',
	 c.email as 'Staff Email'


FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE (sm.endDate IS NULL OR sm.enddate > getdate())
	AND c.email LIKE '%cravenk12.org'

