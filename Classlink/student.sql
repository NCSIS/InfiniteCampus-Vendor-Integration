/*
	Title: Classlink Student
	
	Description: 
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/10/2024		Initial creation of this template

*/

SELECT
	CONCAT('s',stu.personid) AS 'sourcedId',
	'1' AS 'enabledUser',
	sch.schoolGUID as 'ordSourcedIds',
	'student' as 'role',
	cs.email as 'username',
	CONCAT('{"type":"stateID","identifier":"',stu.stateID,'"}') as 'userIds',
	stu.firstName AS 'givenName',
	stu.lastName AS 'familyName',
	stu.middleName AS 'middleName',
	stu.stateID AS 'identifier',
	cs.email AS 'email',
	stu.grade AS 'grades'
	
FROM student stu
	INNER JOIN school sch ON stu.schoolID = sch.schoolID
	INNER JOIN calendar cal ON cal.calendarID = stu.calendarId
    CROSS APPLY (
        SELECT TOP 1 * 
        FROM v_CensusContactSummary cs 
        WHERE cs.personID = stu.personID 
        AND cs.relationship = 'Self' 
        ORDER BY cs.contactID DESC
    ) cs

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
	
