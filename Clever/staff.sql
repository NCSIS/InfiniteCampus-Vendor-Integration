/*
	Title: Clever Staff

  Description: Staff Members not marked as teacher in NCSIS
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/

SELECT DISTINCT
     sm.schoolnumber as 'School_id',
     sm.personID AS 'Staff_id',
     c.email as 'Staff_email',
     sm.firstName as 'First_name',
     sm.lastname as 'Last_name'


FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE sm.enddate IS NULL AND c.email LIKE '%@haywood.k12.nc.us'
   AND (sm.endDate IS NULL OR sm.enddate > getdate())
   AND (sm.teacher IS NULL or sm.teacher = '0')
