/*
	Title: GearUP Student File
	
	Description:
	Student demographic data for GEARUP. 
	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	09/16/2024		Initial creation of this template

*/



--Comment for SQL Statement 1
WITH ContactsGrouped AS (
    SELECT
        cg.personID,
        cg.contactPersonID,
        cg.lastName,
        cg.firstName,
        cg.email,
        cg.homePhone,
        cg.cellPhone,
        cg.seq,
        cg.relationship,
        cg.AddressLine1,
        cg.State,
        cg.city,
        cg.zip,
        cg.guardian
    FROM
        v_CensusContactSummary cg
    GROUP BY
        cg.personID,
        cg.contactPersonID,
        cg.lastname,
        cg.firstName,
        cg.email,
        cg.homePhone,
        cg.cellPhone,
        cg.seq,
        cg.relationship,
        cg.AddressLine1,
        cg.state,
        cg.city,
        cg.zip,
        cg.guardian
),
-- Consolidated Contact Ordering
ContactsOrdered AS (
    SELECT
        co.personID,
        co.contactPersonID,
        co.lastName,
        co.firstName,
        co.email,
        co.homePhone,
        co.cellPhone,
        co.seq,
        co.relationship,
        co.AddressLine1,
        co.city,
        co.state,
        co.zip,
        ROW_NUMBER() OVER (
            PARTITION BY co.personID,
            co.relationship
            ORDER BY
                co.seq
        ) AS rowNumber
    FROM
        ContactsGrouped co
    WHERE
        co.seq IS NOT NULL
        AND co.guardian = 1
        AND co.relationship IN ('Mother', 'Father', 'Guardian')
),
ContactSelf AS (
    SELECT
        c.personID,
        c.householdPhone,
        c.seq,
        c.relationship,
        c.email,
        c.addressLine1,
        c.addressLine2,
        c.city,
        c.state,
        c.zip,
        c.cellPhone,
        ROW_NUMBER() OVER (
            PARTITION BY c.personID
            ORDER BY
                c.seq
        ) AS rowNumber
    FROM
        v_CensusContactSummary c
    WHERE
        c.relationship = 'Self'
)
SELECT
    DISTINCT stu.lastname as 'Last Name',
    stu.firstname as 'First Name',
    stu.middlename as 'Middle Name',
    stu.suffix as 'Suffix',
    convert(varchar, stu.birthdate, 101) as 'DOB',
    stu.gender as 'Gender',
    stu.raceEthnicity as 'Ethnicity',
    CASE
        WHEN ISNULL(stu.hispanicEthnicity, 'N') = 'Y' THEN 'H'
        WHEN stu.raceEthnicityFed = 2 THEN 'AI'
        WHEN stu.raceEthnicityFed = 3 THEN 'AS'
        WHEN stu.raceEthnicityFed = 4 THEN 'B'
        WHEN stu.raceEthnicityFed = 5 THEN 'J'
        WHEN stu.raceEthnicityFed = 6 THEN 'W'
        WHEN stu.raceEthnicityFed = 7 THEN 'M'
    END as 'Federal Ethnicity',
    cs.addressLine1 as 'Address Line 1',
    '' as 'Address Line 2',
    cs.city as City,
    cs.state as 'State',
    cs.zip as Zip,
    cs.cellPhone as 'Mobile Phone',
    cs.email as Email,
    stu.grade as 'Grade Level',
    stu.stateID as 'Student Number',
    right(sch.number, 3) as 'School',
    dis.number as 'District',
    right(ns.number, 3) as 'Next School',
    g.diplomaDate as 'HS Grad Date',
    CASE
        WHEN el.programStatus = 'LEP' THEN 'Y'
        ELSE 'N'
    END as 'LEP',
    CASE
        WHEN ses.primaryArea IS NOT NULL
        AND ses.primaryArea <> '' THEN 'Y'
        ELSE 'N'
    END as 'IEP',
    concat(cm.firstname, ' ', cm.lastname) as 'Mother Name',
    cm.cellPhone as 'Mother Cell Phone',
    concat(cf.firstname, ' ', cf.lastname) as 'Father Name',
    cf.cellPhone as 'Father Cell Phone',
    concat(cg.firstname, ' ', cg.lastname) as 'Guardian Name',
    cg.cellPhone as 'Guardian Cell Phone'
FROM
    student stu
    outer apply (
        select
            top 1 programStatus
        from
            dbo.lep
        where
            lep.personID = stu.personID
        order by
            lep.identifiedDate desc
    ) el
    outer apply (
        select
            top 1 CASE
                WHEN ses.primaryDisability = 'AU' THEN 'Aut'
                WHEN ses.primaryDisability = 'DD' THEN 'Dev'
                WHEN ses.primaryDisability = 'ED' THEN 'Emot'
                WHEN ses.primaryDisability = 'HI' THEN 'Hear'
                WHEN ses.primaryDisability IN('IDMO', 'IDMI') THEN 'Int'
                WHEN ses.primaryDisability = 'LD' THEN 'Spec'
                WHEN ses.primaryDisability = 'MU' THEN 'Mult'
                WHEN ses.primaryDisability = 'OH' THEN 'Oth'
                WHEN ses.primaryDisability = 'SI' THEN 'Lang'
                WHEN ses.primaryDisability = 'TB' THEN 'Trau'
                WHEN ses.primaryDisability = 'VI' THEN 'Vis'
                WHEN ses.primaryDisability IN('DF', 'DB') THEN 'Deaf'
                ELSE ''
            END as primaryArea
        from
            dbo.SpecialEdState ses
        where
            ses.personID = stu.personID
            and (
                ses.startDate <= getdate()
                OR ses.startDate IS NULL
            )
            and (
                ses.endDate IS NULL
                OR ses.endDate >= getdate()
            )
            and ses.exitReason IS NULL
        order by
            ses.specialEDStateID asc
    ) ses
    LEFT OUTER JOIN ContactsOrdered cm ON stu.personID = cm.personID
    AND cm.rowNumber = 1
    AND cm.relationship = 'Mother'
    LEFT OUTER JOIN ContactsOrdered cf ON stu.personID = cf.personID
    AND cf.rowNumber = 1
    AND cf.relationship = 'Father'
    LEFT OUTER JOIN ContactsOrdered cg ON stu.personID = cg.personID
    AND cg.rowNumber = 1
    AND cg.relationship = 'Guardian'
    LEFT OUTER JOIN graduation g ON g.personID = stu.personID,
    ContactSelf cs,
    calendar cal,
    school sch,
    district dis,
    enrollment e
    LEFT OUTER JOIN calendar nc ON nc.calendarID = e.nextCalendar
    LEFT OUTER JOIN school ns on ns.schoolID = nc.schoolID
WHERE
    cs.personID = stu.personID
    AND cs.rowNumber = 1
    AND cal.calendarID = stu.calendarID
    AND sch.schoolID = cal.schoolID
    and dis.districtID = sch.districtID
    AND cal.startDate <= getdate()
    AND cal.endDate >= getdate()
    AND e.personID = stu.personID
    AND e.calendarID = cal.calendarID