/*
	
IMPORTANT: Change the email address at the bottom

Title: DeansList - Users
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/17/2025		Initial creation of this template

** This file produces duplicates.  One for each School Assignment.  
If Deanslist needs this changed please contact Jeremiah

*/


SELECT
	sm.staffstateID as [UserID],
	sm.staffstateID as [StaffID],
	sm.title as [Title],
	sm.firstName as [FirstName],
	sm.middleName AS [MiddleName],
	sm.lastname as [LastName],
	c.email AS [Email],
	COALESCE(c.cellphone, c.homephone) AS [PhoneNumber],
	sm.schoolnumber AS [BuildingCode]

  
FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE (sm.endDate IS NULL OR sm.enddate > getdate())
   AND c.email LIKE '%@haywood.k12.nc.us'
