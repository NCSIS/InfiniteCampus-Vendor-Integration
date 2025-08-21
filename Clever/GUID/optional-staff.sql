
/*
	Title: Clever Staff GUID

  Description: Staff Members not marked as teacher in NCSIS
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template
	08/22/2024		Added StaffStateID

*/

SELECT DISTINCT
     sch.schoolGUID as 'School_id',
     person.personGUID AS 'Staff_id',
     c.email as 'Staff_email',
     sm.firstName as 'First_name',
     sm.lastname as 'Last_name',
     sm.title as 'Title',
     sm.staffstateid as 'Username'


FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
   INNER JOIN school sch ON sch.schoolID = sm.schoolID
   INNER JOIN [person] person ON person.personid = sm.personid

WHERE sm.enddate IS NULL AND c.email LIKE '%@haywood.k12.nc.us'
   AND (sm.endDate IS NULL OR sm.enddate > getdate())
   AND (sm.teacher IS NULL or sm.teacher = '0')
