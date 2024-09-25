/*
	Title: Final Site Student -
	
	Description:  Based on the SQL template from FinalSite, Modified to remove duplicates
                Added Bus AM and PM.  If student has multiple buses this will create duplicates.

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	09/24/2024		Initial creation of this template
	09/25/2024		Changes BusID to BusNumber

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
    School.schoolID,
    School.number AS organizationid,
    stu.personID,
    stu.stateid AS studentid,
    cc.lastName,
    cc.firstName,
    cc.middlename AS middleName,
	CASE
		WHEN ferpa.directoryquestion = 'NO' THEN 'YES'
		ELSE ''
	END AS 'Hidden from Directory',
    FORMAT(cc.birthdate, 'MM/dd/yyyy') AS birthDate,
    cc.gender AS gender,
    Enrollment.grade AS gradeLevel,
    CASE 
        WHEN NULLIF(cc.communicationLanguage, '') IS NULL THEN 'en_US'
        ELSE cc.communicationLanguage
    END AS preferredLanguage1ID,
    CASE cc.postOfficeBox WHEN '1' THEN 'P.O. Box ' + cc.number + ' ' + ISNULL(cc.street,'') + ' ' + ISNULL(cc.tag,'') + ' ' + ISNULL('apt '+cc.apt,'') 
      ELSE cc.number + ' ' + ISNULL(cc.street,'') + ' ' + ISNULL(cc.tag,'') + ' ' + ISNULL('apt '+cc.apt,'') 
      END AS address1,
    cc.city,
    cc.state,
    cc.zip,
    cc.email AS emailAddress,
    cc.phone AS phoneNumber,
    cc.homephone AS phoneNumber2,
    cc.workphone AS workphoneNumber,
    cc.cellphone AS mobilephoneNumber,
    cc.cellphone AS smsNumber,
    cc.pager,
    Enrollment.language,
    cc.homePrimaryLanguage,
    TransBusAM.number AS 'AMBusNumber',
    TransBusPM.number AS 'PMBusNumber'
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
    LEFT JOIN ferpa ON ferpa.personid = stu.personid

WHERE calendar.calendarId=stu.calendarId
   AND school.schoolID=calendar.SchoolID
   AND calendar.startDate<=GETDATE() AND calendar.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(school.number,4,3) AS INTEGER) >= 300 or substring(school.number,4,3) = '000')
   AND stu.stateid IS NOT NULL



/*WHERE 
    stu.studentNumber IS NOT NULL
    AND ISNULL(Enrollment.noshow,0) = 0
    AND Enrollment.enddate IS NULL
    AND Calendar.exclude = 0
    AND SchoolYear.active = 1
*/
