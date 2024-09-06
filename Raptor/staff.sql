
/*
	Title: Raptor Staff
	
	Description: 
                     
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/06/2024		Initial creation of this template

*/

SELECT DISTINCT
     sm.firstName as 'First_name',
	 sm.lastname as 'Last_name',
	 sm.middleName as 'Middle Name',
	 sm.staffstateID as 'ID Number',
     sm.title as 'Type',
	 sm.schoolnumber as 'School ID',
	 sm.schoolname AS 'School Name'


FROM staffmember sm 
WHERE (sm.endDate IS NULL OR sm.enddate > getdate())

