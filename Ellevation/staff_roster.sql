/*
	Title: Ellevation Staff Roster
	
	
	Author: Clinton City Schools
	
	Revision History:
	07/25/2024		Initial creation of this template

*/



--Comment for SQL Statement 1
SELECT DISTINCT sm.staffstateID,sm.personID,sm.firstname,sm.lastname,sm.schoolnumber,sm.schoolname,sm.enddate,c.email 
FROM staffmember sm 
INNER JOIN contact c ON sm.personid = c.personid 
WHERE sm.enddate IS NULL AND c.email LIKE '%@email.k12.nc.us'
