/*
	Title: Gaggle Watauga
	
	Description:  Based on the file format 
       https://gagglenet.my.salesforce.com/sfc/p/#4W000001VtS4/a/4W000000l9Sg/z8vCmadIXp_7QITGKiTxiWUC_6DMvRaTakP0Nxxi29w

	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
        11/19/2025 - Original


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
    stu.stateid   AS [studentId],
	'950' AS [districtCode],
	'Watauga County Schools' AS [districtName],
    sch.number    AS [schoolCode],
	sch.name	AS [schoolName],
	stu.firstName AS [studentFirstName],
	stu.middleName AS [studentMiddleName],
    stu.lastName  AS [Student LastName],
	stu.grade AS [studentGrade],
	cs.email AS [studentEmailSchool],
	cs.addressLine1 AS [studentAddressLine1],
	cs.city AS [studentAddressCity],
	cs.state AS [studentAddressState],
	cs.zip AS [studentAddressZipCode],
	cg1.firstName AS [Guardian1FirstName],
    cg1.lastName  AS [Guardian1LastName],
	cg1.relationship AS [Guardian1Relationship],
	cg1.email AS [Guardian1Email],
    cg1.cellPhone AS [Guardian1PhoneCell],
	COALESCE(cg1.homephone, cg1.householdPhone) AS [Guardian1Phone1],
	cg2.firstName AS [Guardian2FirstName],
    cg2.lastName  AS [Guardian2LastName],
	cg2.relationship AS [Guardian2Relationship],
	cg2.email AS [Guardian2Email],
    cg2.cellPhone AS [Guardian2PhoneCell],
	COALESCE(cg2.homephone, cg2.householdPhone) AS [Guardian2Phone1]

FROM v_adhocstudent stu
JOIN Calendar cal ON cal.calendarID = stu.calendarID
JOIN School   sch ON sch.schoolID   = cal.schoolID
    OUTER APPLY (
        SELECT TOP 1 * 
        FROM v_CensusContactSummary cs 
        WHERE cs.personID = stu.personID 
        AND cs.relationship = 'Self' 
        ORDER BY cs.contactID DESC
    ) cs
LEFT JOIN ContactsOrdered cg1 ON cg1.personID = stu.personID AND cg1.rn = 1
LEFT JOIN ContactsOrdered cg2 ON cg2.personID = stu.personID AND cg2.rn = 2
WHERE 
    cal.startDate <= GETDATE() AND cal.endDate >= GETDATE()
    AND (stu.endDate IS NULL OR stu.endDate >= GETDATE())
    AND (CAST(SUBSTRING(sch.number,4,3) AS INT) >= 300 OR SUBSTRING(sch.number,4,3) = '000')
    AND stu.stateid IS NOT NULL;
