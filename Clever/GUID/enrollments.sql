/*
	Title: Clever Enrollments
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/

select
    sch.schoolGUID AS 'School_id',
    e.sectionID AS 'Section_id',
    stu.personGUID AS 'Student_id'


from V_OneRosterStudentEnrollment e
INNER JOIN v_OneRosterSchool sch ON sch.SchoolID = e.schoolID
INNER JOIN student stu ON stu.personID = e.personid
