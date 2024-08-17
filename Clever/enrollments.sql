/*
	Title: Clever Enrollments
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	08/16/2024		Initial creation of this template

*/

select

    e.sectionID AS 'Section_id',
    e.personID AS 'Student_id',
    sch.identifier AS 'School_id'

from V_OneRosterStudentEnrollment e
INNER JOIN v_OneRosterSchool sch ON sch.SchoolID = e.schoolID
