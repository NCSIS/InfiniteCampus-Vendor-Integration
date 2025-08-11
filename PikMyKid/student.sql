/*
	Title: PikMyKid Student
	
	Description:  Based on the file format 
        https://drive.google.com/file/d/1nAhD-GKYGQshggNKz3ObTJuZsJbm2MaI/view?usp=sharing

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        08/10/2025 - Original
		08/10/2025 r2 - Fixed Duplicates and moved guardian2 into the correct spots

*/
WITH ContactsOrdered AS (
    SELECT
        cg.personID,
        cg.contactPersonID,
        cg.guardian,
        cg.firstName,
        cg.lastName,
        cg.cellPhone,
        cg.homePhone,
        cg.householdPhone,
        cg.email,
        cg.relationship,
        cg.relatedby,
        ROW_NUMBER() OVER (
            PARTITION BY cg.personID
            ORDER BY 
                /* prioritize actual guardians, then your preferred sort */
                CASE WHEN cg.guardian = '1' THEN 0 ELSE 1 END,
                cg.relatedby,            -- or cg.relationship
                cg.contactPersonID DESC  -- deterministic tie-break
        ) AS rn
    FROM v_CensusContactSummary cg WITH (NOLOCK)
    INNER JOIN student stu ON cg.personID = stu.personID
    WHERE
        (stu.endDate IS NULL OR stu.endDate >= GETDATE())
        AND cg.guardian = '1'
)
SELECT
    stu.firstName AS [Student FirstName],
    stu.lastName  AS [Student LastName],
    sch.number    AS [PMK/School_ID],
    stu.grade     AS [Grade],
    'Ignore'      AS [MostUsedPickupMode],
    transbuspm.number AS [BusRoute],
    cg1.firstName AS [Guardian1FirstName],
    cg1.lastName  AS [Guardian1LastName],
    cg1.cellPhone AS [Guardian1Mobile],
    cg2.firstName AS [Guardian2FirstName],
    cg2.lastName  AS [Guardian2LastName],
    cg2.cellPhone AS [Guardian2Mobile],
    stu.homeroomTeacher AS [Homeroom/Classroom Name],
    stu.stateid   AS [ExternalID/Student Number]
FROM v_adhocstudent stu
JOIN Calendar cal ON cal.calendarID = stu.calendarID
JOIN School   sch ON sch.schoolID   = cal.schoolID
LEFT JOIN ContactsOrdered cg1 ON cg1.personID = stu.personID AND cg1.rn = 1
LEFT JOIN ContactsOrdered cg2 ON cg2.personID = stu.personID AND cg2.rn = 2
LEFT JOIN TransportationRoute TransPM   ON TransPM.personID = stu.personID AND TransPM.routeTypeCode = 'PM'
LEFT JOIN TransportationBus  TransBusPM ON TransPM.busID    = TransBusPM.busID
WHERE 
    cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (stu.endDate IS NULL OR stu.endDate >= GETDATE())
    AND (CAST(SUBSTRING(sch.number,4,3) AS INT) >= 300 OR SUBSTRING(sch.number,4,3) = '000')
    AND stu.stateid IS NOT NULL;
