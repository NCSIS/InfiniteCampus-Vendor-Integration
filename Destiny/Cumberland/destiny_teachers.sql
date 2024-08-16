/*
	Title: Cumberland Destiny Teachers
	
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/

SELECT DISTINCT
     sm.schoolnumber as 'SchoolID',
     sm.staffstateID as 'SIF_StatePrid',
     sm.gender as 'Gender',
     sm.firstname as 'TEACHERS.First_Name',
     sm.lastname as 'TEACHERS.Last_Name',
     c.email as 'TEACHERS.Email_Addr'
  
FROM staffmember sm 
  INNER JOIN contact c ON sm.personid = c.personid 

WHERE sm.enddate IS NULL AND c.email LIKE '%@ccs.k12.nc.us'
  AND (sm.endDate IS NULL OR sm.enddate > getdate())
