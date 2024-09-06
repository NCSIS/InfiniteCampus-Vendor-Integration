
/*
	Title: Info Handler for EzEdMed -EC Data

	Description: 
                     
	
	Author: Trey Staton - Polk County Schools 
  tstaton   (at)  polkschools.org
	
	Revision History:
	09/06/2024		Initial creation of this template

*/

SELECT DISTINCT
    stu.studentNumber as 'Student ID',
    stu.lastName as 'Last Name',
    stu.firstName as 'First Name',
    stu.middleName as 'Middle Name',
    stu.gender as 'sex',
    FORMAT(stu.birthdate,'MM/dd/yyyy') as 'Birthdate',
    sch.number as 'SchoolID',
    stu.grade as 'GradeLevel',
    '1' as 'EC Status',
    'Yes' as 'Active'
FROM v_AdHocStudent stu
    LEFT OUTER JOIN specialEdState sped ON sped.personID = stu.personID
    INNER JOIN school sch ON sch.schoolid = stu.schoolID
WHERE stu.activeToday = 1 AND sped.servicesStartDate <> ''
