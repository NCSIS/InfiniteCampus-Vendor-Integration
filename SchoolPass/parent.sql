/*
	Title: SchoolPass Parent
	
	Description:     

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        08/10/2025 - Original


*/




SELECT DISTINCT
	cg1.personid AS 'ExternalId',
	cg1.firstName AS 'FirstName',
	cg1.lastName AS 'LastName',
	cg1.email AS 'Email', 
	CASE 
	    WHEN stu.endDate IS NULL OR stu.endDate >= GETDATE() THEN 'TRUE'
		ELSE 'FALSE'
	END AS 'ActiveStatus',
	cg1.homephone AS 'HomePhone',
	cg1.cellphone AS 'CellPhone',
	'' AS 'P1_ID',
	'' AS 'LicensePlate',
	'' AS 'LicensePlate2',
	sch.number AS 'PickupAreaName',
	'' AS 'DismissalCalendarName',
	'' AS 'CarpoolName',
	cg1.relationship AS 'Custody'

	
FROM
    v_adhocstudent stu
    JOIN Calendar cal ON cal.calendarID = stu.calendarID
    JOIN School sch ON sch.schoolID = cal.schoolID
CROSS APPLY (
    SELECT TOP 1 cg.*
    FROM v_CensusContactSummary cg
    WHERE cg.personID = stu.personID
      AND cg.guardian = '1'
    ORDER BY cg.contactPersonID DESC
) cg1


WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL
