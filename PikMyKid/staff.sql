/*
	Title: PikMyKid - All Teachers
	
	
	Author: Jeremiah Jackson NCDPI
	
	IMPORTANT: 
	** Change the email address search at the bottom of this document to your domain
	** This only include all Teachers if you need all staff then commend out the sm.teacher=1
	
	Revision History:
	08/10/2025		Initial creation of this template

*/


SELECT DISTINCT
	sm.staffstateID as 'External Id',
	c.email as 'Staff_Email',
	sm.firstName as 'First_name',
	sm.lastname as 'Last_name',
	'' AS 'Password',
	sm.schoolnumber AS 'Department'  
  
FROM staffmember sm 
	INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE (sm.endDate IS NULL OR sm.enddate > getdate())
	AND sm.teacher = '1'
	AND c.email LIKE '%@haywood.k12.nc.us'
