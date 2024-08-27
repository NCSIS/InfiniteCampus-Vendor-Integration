/*
    Title: SNAP by ProMed - Contacts File
    
    Description:
    Creates a row for email and phone for each of the 2 contacts associated with each student.
    This has been streamlined for better performance and readability.
    
    Author: Jeremiah Jackson - NCDPI
    
    Revision History:
    08/27/2024        Streamlined the original code for efficiency.
*/

WITH ContactsGrouped AS (
    SELECT
        cg.personID, cg.contactPersonID, cg.lastName, cg.firstName,
        cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship, cg.guardian
    FROM v_CensusContactSummary cg WITH (NOLOCK)
    GROUP BY cg.personID, cg.contactPersonID, cg.lastname, cg.firstName,
        cg.email, cg.homePhone, cg.cellPhone, cg.seq, cg.relationship, cg.guardian
),
ContactsOrdered AS (
    SELECT
        co.personID, co.contactPersonID, co.lastName, co.firstName,
        co.email, co.homePhone, co.cellPhone, co.seq, co.relationship, co.guardian,
        ROW_NUMBER() OVER (PARTITION BY co.personID ORDER BY co.seq) AS rowNumber
    FROM ContactsGrouped co WITH (NOLOCK)
    WHERE co.relationship <> 'Self' AND co.seq IS NOT NULL
    -- Uncomment the line below to only pull guardians.
    AND co.guardian = 1
),
ContactSelf AS (
    SELECT
        c.personID, c.householdPhone, c.seq, c.relationship,
        ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
    FROM v_CensusContactSummary c WITH (NOLOCK)
    WHERE c.relationship = 'Self'
),
StudentContacts AS (
    SELECT
        stu.stateid AS 'Reference ID',
        CONCAT(co.firstName, ' ', co.lastName) AS 'Name',
        co.relationship AS 'Relationship',
        '"HouseholdPhone","E-Mail","CellPhone","HomePhone"' AS 'Type',
        CONCAT('"', cs.householdPhone, '", "', co.email, '", "', co.cellphone, '", "', co.homephone, '"') AS 'Data',
        co.rowNumber
    FROM student stu
    INNER JOIN Calendar cal ON stu.calendarID = cal.calendarID
    INNER JOIN school sch ON sch.schoolid = stu.schoolID
    LEFT OUTER JOIN ContactsOrdered co ON stu.personID = co.personID
    LEFT OUTER JOIN ContactSelf cs ON stu.personID = cs.personID
    WHERE cal.calendarId = stu.calendarId
        AND sch.schoolID = cal.SchoolID
        AND cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
        AND (stu.endDate IS NULL OR stu.endDate >= GETDATE())
        AND (CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300 or SUBSTRING(sch.number, 4, 3) = '000')
        AND (stu.stateid IS NOT NULL or stu.stateid <> '')
        AND co.relationship IS NOT NULL
)

SELECT *
FROM StudentContacts
WHERE rowNumber = 1

UNION ALL

SELECT *
FROM StudentContacts
WHERE rowNumber = 2;
