/*
	Title: PikMyKid Student
	
	Description:  Based on the file format 
        https://drive.google.com/file/d/1nAhD-GKYGQshggNKz3ObTJuZsJbm2MaI/view?usp=sharing

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        08/10/2025 - Original

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
	stu.firstName AS 'Student FirstName',
	stu.lastName AS 'Student LastName',
    sch.number AS 'PMK/School_ID',
	stu.grade AS 'Grade',
	'Ignore' AS 'MostUsedPickupMode',
	transbuspm.number AS 'BusRoute',
	cg1.firstName AS 'Guardian1FirstName',
	cg1.lastName AS 'Guardian1LastName',
	cg1.cellPhone AS 'Guardian1Mobile',
	cg2.firstName AS 'Guardian2FirstName',
	cg2.lastName AS 'Guardian2LastName',
	cg2.cellPhone AS 'Guardian2Mobile',
	stu.homeroomTeacher AS 'Homeroom/Classroom Name',
	stu.stateid AS 'ExternalID/Student Number'
	
FROM
    v_adhocstudent stu
    JOIN Calendar cal ON cal.calendarID = stu.calendarID
    JOIN School sch ON sch.schoolID = cal.schoolID
    LEFT OUTER JOIN ContactCombined cg1 ON cg1.personid = stu.personID AND cg1.rowNumber = '1'
    LEFT OUTER JOIN ContactCombined cg2 ON cg2.personid = stu.personID AND cg2.rowNumber = '2'
    LEFT JOIN TransportationRoute TransPM ON TransPM.personid = stu.personID AND TransPM.routeTypeCode = 'PM'
    LEFT JOIN TransportationBus TransBusPM ON TransPM.busid = TransbusPM.busid

WHERE cal.calendarId=stu.calendarId
   AND sch.schoolID=cal.SchoolID
   AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
   AND (stu.endDate IS NULL or stu.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND (CAST(substring(sch.number,4,3) AS INTEGER) >= 300 or substring(sch.number,4,3) = '000')
   AND stu.stateid IS NOT NULL



