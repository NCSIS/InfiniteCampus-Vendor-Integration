/*
	Title:Panorama - School File
	
	Description:

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/

Select
  sch.number AS 'School_Id',
  sch.name AS 'School_name'
FROM 
  school sch
WHERE 
  CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000'
  
