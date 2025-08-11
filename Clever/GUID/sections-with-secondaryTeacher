/*
    Title: Clever Sections

    Description: 

    Author: Jeremiah Jackson NCDPI

    Revision History:
    08/16/2024     Initial creation of this template
    08/11/2025     Added secondary teachers
*/

SELECT
    sch.schoolGUID    AS [School_id],
    s.sectionID       AS [Section_id],
    per.personGUID    AS [Teacher_id],
    t2.personGUID AS [Teacher_2_id],  -- Will be NULL if no second teacher
    s.number          AS [Section_number],
    c.name            AS [Course_name],
    p.name            AS [Period],
    sp.termName       AS [Term_name],
    sp.termStartDate  AS [Term_start],
    sp.termEndDate    AS [Term_end]

FROM v_OneRosterSectionPlacement sp
INNER JOIN section s            ON sp.sectionID = s.sectionID
INNER JOIN course c             ON c.courseID = s.courseID
INNER JOIN v_OneRosterCourse orc ON c.courseID = orc.courseID
INNER JOIN period p             ON p.periodID = sp.periodID
INNER JOIN calendar cal         ON cal.calendarID = c.calendarID
INNER JOIN School sch           ON sch.schoolID = orc.schoolID
INNER JOIN person per           ON s.teacherpersonid = per.personid
OUTER APPLY (
    SELECT TOP (1)
        per2.personGUID
    FROM dbo.SectionStaffHistory AS ssh
    INNER JOIN person AS per2 ON per2.personid = ssh.personid
    WHERE
        ssh.sectionid = s.sectionid
        AND ssh.staffType = 'T'
        AND (ssh.endDate IS NULL OR ssh.endDate >= GETDATE())
    ORDER BY ssh.createdDate DESC
) AS t2

WHERE
    cal.startDate <= GETDATE()
    AND cal.endDate >= GETDATE();  -- Only current-year calendars
