/*
	Title: Clever Enrollments
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/

select
    sch.identifier AS 'School_id',
    e.sectionID AS 'Section_id',
    e.personID AS 'Student_id'


from V_OneRosterStudentEnrollment e
INNER JOIN v_OneRosterSchool sch ON sch.SchoolID = e.schoolID
WHERE (e.endDate IS NULL or e.endDate>=GETDATE()) 
