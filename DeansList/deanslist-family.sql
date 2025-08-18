/*
    Title: Deanslist Family
    Description: Creates a new row for each guardian

    Author: Jeremiah Jackson - NCDPI
    Revision History:
    08/17/2025  Initial creation of this template
*/

SELECT
    stu.stateid AS [StudentID],
    CONCAT(c.firstname, ' ', c.lastname) AS [Parent Name],

    -- Keep only digits: remove spaces and common punctuation
    REPLACE(
      TRANSLATE(
        COALESCE(c.homePhone, ''),
        ' ()-+./\[]{}:;#*''"',
        REPLICATE(' ', LEN(' ()-+./\[]{}:;#*''"'))
      ),
      ' ', ''
    ) AS [Parent Home Phone],

    REPLACE(
      TRANSLATE(
        COALESCE(c.workPhone, ''),
        ' ()-+./\[]{}:;#*''"',
        REPLICATE(' ', LEN(' ()-+./\[]{}:;#*''"'))
      ),
      ' ', ''
    ) AS [Parent Work Phone],

    REPLACE(
      TRANSLATE(
        COALESCE(c.cellPhone, ''),
        ' ()-+./\[]{}:;#*''"',
        REPLICATE(' ', LEN(' ()-+./\[]{}:;#*''"'))
      ),
      ' ', ''
    ) AS [Parent Cell Phone],

    c.email AS [Parent E-Mail],
    c.relationship AS [Relationship],
	c.seq AS [Parent Priority],
	CASE when c.communicationlanguage IS NULL THEN 'en_US' ELSE c.communicationlanguage END AS [Language]

FROM v_CensusContactSummary AS c
JOIN student AS stu
  ON c.personid = stu.personid
JOIN school AS sch
  ON stu.schoolid = sch.schoolid
JOIN calendar AS cal
  ON cal.calendarid = stu.calendarid
WHERE c.guardian = 1
  AND (stu.endDate IS NULL OR stu.endDate >= GETDATE())
  AND (CAST(SUBSTRING(sch.number, 4, 3) AS int) >= 300 OR SUBSTRING(sch.number, 4, 3) = '000')
  AND stu.stateid IS NOT NULL
  AND cal.calendarId = stu.calendarId
  AND sch.schoolID  = cal.SchoolID
  AND cal.startDate <= GETDATE()
  AND cal.endDate   >= GETDATE();
