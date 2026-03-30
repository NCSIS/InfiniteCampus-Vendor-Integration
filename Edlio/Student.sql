/*
	Title: Edlio Student -
	
	Description:  Based on the SQL template from FinalSite, Modified to remove duplicates
                Added Bus AM and PM.  If student has multiple buses this will create duplicates.

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	03/30/2026		Initial creation of this template


*/

WITH ContactCombined AS (
    SELECT
        c.personid, c.email, c.homephone, c.workphone, c.cellphone, c.pager, c.communicationLanguage, 
        a.city, a.state, a.zip, a.postOfficeBox, a.number, a.street, a.tag, a.apt, 
        hh.phone, 
        i.homePrimaryLanguage, i.gender, i.lastName, i.firstName, i.middleName, i.birthdate,
        ROW_NUMBER() OVER (PARTITION BY c.personid ORDER BY c.personid) AS rowNumber
    FROM person p 
        INNER JOIN contact c ON p.personid = c.personid
        INNER JOIN [Identity] i ON p.currentIdentityID = i.identityID 
        LEFT OUTER JOIN householdmember hm ON hm.personid = p.personid AND (hm.enddate IS NULL OR hm.enddate >= GETDATE()) AND hm.secondary = '0'
        LEFT OUTER JOIN household hh ON hh.householdid = hm.householdid
        LEFT OUTER JOIN householdlocation hl ON hl.householdid = hh.householdid AND (hl.enddate IS NULL OR hl.enddate >= GETDATE()) AND hl.secondary = '0'
        LEFT OUTER JOIN address a ON hl.addressid = a.addressid
)
SELECT DISTINCT
	stu.stateID AS [Unique ID],
	stu.stateid AS [Student ID],
	'Students' AS [Role],
	cc.firstname AS [First Name],
	cc.lastname AS [Last Name],
	cc.email AS [Email 1],
	TransBusAM.number AS [Bus Route AM],
	TransBusPM.number AS [Bus Route PM],
	COALESCE(cc.phone, cc.homephone, cc.cellphone) AS [Phone 1],
	CASE 
		WHEN NULLIF(cc.homePrimaryLanguage, '') IS NULL THEN 'en'
		WHEN cc.homePrimaryLanguage = 'eng' THEN 'en'
		WHEN cc.homePrimaryLanguage = 'spa' THEN 'es'
		WHEN cc.homePrimaryLanguage = 'vie' THEN 'vi'
        WHEN cc.homePrimaryLanguage = 'tgl' THEN 'tl'
		ELSE cc.homePrimaryLanguage
	END AS [Home Language],
	School.number AS 'Organization ID'

FROM
    student stu
    JOIN Enrollment ON stu.personID = Enrollment.personID
    JOIN Calendar ON Calendar.calendarID = Enrollment.calendarID
    JOIN School ON School.schoolID = Calendar.schoolID
    JOIN SchoolYear ON SchoolYear.endYear = Calendar.endYear
    LEFT OUTER JOIN ContactCombined cc ON cc.personid = stu.personID AND cc.rowNumber = '1'
    LEFT JOIN TransportationRoute TransAM ON TransAM.personid = stu.personID AND TransAM.routeTypeCode = 'AM'
    LEFT JOIN TransportationRoute TransPM ON TransPM.personid = stu.personID AND TransPM.routeTypeCode = 'PM'
    LEFT JOIN TransportationBus TransBusAM ON TransAM.busid = TransbusAM.busid
    LEFT JOIN TransportationBus TransBusPM ON TransPM.busid = TransbusPM.busid

WHERE calendar.calendarId=stu.calendarId
   AND school.schoolID=calendar.SchoolID
   AND calendar.startDate<=GETDATE() AND calendar.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(school.number,4,3) AS INTEGER) >= 300 or substring(school.number,4,3) = '000')
   AND stu.stateid IS NOT NULL


