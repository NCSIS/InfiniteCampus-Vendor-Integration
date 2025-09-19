/*
	Title: Xello Family
	
	Description: 
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	09/03/2025		Initial creation of this template

*/


SELECT DISTINCT
	c.firstName AS [FirstName],
	c.lastName AS [LastName],
	c.email AS [Email],
	stu.stateid AS [StudentId],
	c.contactpersonid AS [SourceParentId],
	COALESCE(c.householdPhone, c.homePhone, c.cellPhone) AS [Phone]

	
FROM v_CensusContactSummary c
	INNER JOIN student stu ON c.personid = stu.personid
	INNER JOIN school sch ON stu.schoolid = sch.schoolid
	INNER JOIN calendar cal ON cal.calendarid = stu.calendarid
WHERE c.guardian = '1'
        AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
        AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
        AND stu.stateid IS NOT NULL
        AND cal.calendarId=stu.calendarId
        AND sch.schoolID=cal.SchoolID
        AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
