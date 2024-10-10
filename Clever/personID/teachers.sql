/*
	Title: Clever Teacher 
	
	Description: Change the email address at the bottom to your schools domain.
                     Staff Members marked as teacher in district assignments
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template
	10/10/2024		Fixed the EndDate filter to include future end dates.

*/

SELECT DISTINCT
     sm.schoolnumber as 'School_id',
     sm.personID AS 'Teacher_id',
     sm.staffstateID as 'Teacher_number',
     sm.staffstateID as 'State_teacher_id',
     sm.lastname as 'Last_name',
     sm.firstName as 'First_name',
     c.email as 'Teacher_email',
     sm.title as 'Title'	

FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE c.email LIKE '%@haywood.k12.nc.us'
   AND (sm.endDate IS NULL OR sm.enddate > getdate())
--   AND sm.teacher = '1'
