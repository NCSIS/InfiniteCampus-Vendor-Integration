/*
	Title: Classlink Enrollments
	
	Description: 
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/10/2024		Initial creation of this template

*/

select top 3
    CONCAT('s',r.rosterID) AS sourcedId,
	'active' AS status,
	r.modifiedDate AS dateLastModified,
	r.sectionID AS classSourcedId,
	sch.schoolGUID AS schoolSourcedId,
	CONCAT('s',r.personID) AS userSoucedId,
	'student' AS 'role',
	'' AS 'primary',
	r.startDate AS beginDate,
	r.endDate AS endDate
	
FROM roster r
	INNER JOIN section s on s.sectionID = r.sectionID
	INNER JOIN course c on c.courseID = s.courseID
	INNER JOIN calendar cal on c.calendarID = cal.calendarID
	INNER JOIN school sch ON sch.schoolID = cal.schoolID
	
WHERE 
	cal.startDate<=GETDATE() 
	AND cal.endDate>=GETDATE()
	AND (r.endDate IS NULL OR r.enddate > getdate())
	
