/*
	Title:Panorama - Staff
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


SELECT
	individual.firstName, individual.middleName, individual.lastName, individual.staffStateID, individual.staffNumber, individual.personID,
	pcontact.email,
--	pcontact.secondaryEmail, 
	schoolemployment.active, schoolEmployment.schoolName, sch.number AS 'schoolEmployment.schoolID'
FROM employment
	INNER JOIN individual ON individual.personID = employment.personID
	INNER JOIN contact pcontact ON pcontact.personID = employment.personID
	INNER JOIN v_SchoolEmployment schoolEmployment ON schoolEmployment.personID = employment.personID
	INNER JOIN school sch ON sch.schoolID = schoolemployment.schoolID
WHERE 
	pcontact.email LIKE '%@haywood.k12.nc.us'
	
	
	
