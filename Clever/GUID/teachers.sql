/*
	Title: Clever Teacher GUID
	
	Description: Change the email address at the bottom to your schools domain.
                 
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template
	10/10/2024		Fixed enddate filter to include future enddates.

*/

SELECT DISTINCT
     sch.schoolguid as 'School_id',
     person.personGUID AS 'Teacher_id',
     sm.staffstateID as 'Teacher_number',
     sm.staffstateID as 'State_teacher_id',
     sm.lastname as 'Last_name',
     sm.firstName as 'First_name',
     c.email as 'Teacher_email',
     sm.title as 'Title'	

FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
   INNER JOIN school sch ON sm.schoolnumber = sch.number
   INNER JOIN [person] person ON person.personID = sm.personid
WHERE c.email LIKE '%@haywood.k12.nc.us'
   AND (sm.endDate IS NULL OR sm.enddate > getdate())
--   AND sm.teacher = '1'
