/*
	Title: SchoolCash by KEV - Teachers
	
	
	Author: Jeremiah Jackson NCDPI
	
	IMPORTANT: 
  -Change the email address search at the bottom of this document to your domain. 
  -If you want more than just classroom teachers comment out the sm.teacher=1 with a -- at the beginning of the line
  
	
	Revision History:
	08/20/2024		Initial creation of this template

*/


SELECT DISTINCT
     sm.schoolname AS 'Staff_School_Name',
     sm.schoolnumber AS 'Staff_School_Number',
     sm.firstName as 'First_name',
	'' AS 'Staff_Middle_Name',
     sm.lastname as 'Last_name',
     sm.staffstateID as 'Teacher_number',
	 '' AS 'Staff_Address',
	 '' AS 'Staff_City',
	 '' AS 'Staff_State',
	 '' AS 'Staff_Zip_Code',
	 '' AS 'Staff_Phone',
	 '' AS 'Reserved-1',
	 '' AS 'Staff_Classroom/Homeroom',
     'staff' AS 'Staff_Grade',
	 '' AS 'Staff_Parent/Guardian1_First_Name',
	 '' AS 'Staff_Parent/Guardian1_Last_Name',
	 '' AS 'Staff_Parent/Guardian2_First_Name',
	 '' AS 'Staff_Parent/Guardian2_Last_Name',
	 '' AS 'Staff_DOB',  -- I am not including this.  I see no reason to share staff birthdate with a vendor
	 '' AS 'Reserved-2',
     c.email as 'Staff_Email',
	 '' AS 'Reserved-3',
	 '' AS 'Reserved-4'

  
FROM staffmember sm 
   INNER JOIN contact c ON sm.personid = c.personid AND c.email IS NOT NULL
WHERE (sm.endDate IS NULL OR sm.enddate > getdate())
   AND sm.teacher = '1'
   AND c.email LIKE '%@haywood.k12.nc.us'
