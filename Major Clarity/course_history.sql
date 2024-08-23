/*
	Title: Major Clarity - Course History
	
	Description:
	Major Clarity - Course File	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	08/23/2024		Initial creation of this template

*/

SELECT t.schoolNumber as school_id,
t.courseNumber as course_id,
p.stateID as student_id,
t.score as grade,
t.grade as grade_level,
t.endYear as school_year,
t.actualTerm as term,
t.creditsEarned as credits_earned
FROM v_TranscriptDetail t,
person p
WHERE p.personID=t.personID
