/*
	Title: Clever School
	
	Description: Change the email address at the bottom to your schools domain
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/

select
   sch.number as 'School_id',
   sch.name as 'School_name',
   sch.number as 'School_number',
   sch.principalName as 'Principal',
   sch.principalEmail as 'Principal_email'

FROM school sch
WHERE CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000' -- Charter schools remove this line
