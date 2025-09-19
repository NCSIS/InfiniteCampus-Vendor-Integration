/*
    Title: Xello School
    Author: Jeremiah Jackson - NCDPI
    Revision History:
    09/03/2025  Initial creation of this template
*/

SELECT DISTINCT
    sch.number AS [SchoolCode],
    sch.name   AS [Name],
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM gradelevel gl
            WHERE gl.calendarid = cal.calendarid
              AND gl.excludeenrollment = 0
              AND TRY_CONVERT(int, gl.stategrade) >= 9
        ) THEN 1  -- HS
        WHEN EXISTS (
            SELECT 1
            FROM gradelevel gl
            WHERE gl.calendarid = cal.calendarid
              AND gl.excludeenrollment = 0
              AND TRY_CONVERT(int, gl.stategrade) BETWEEN 0 AND 8
        ) THEN 2  -- ESMS
        ELSE 3     -- Other (no included numeric grades)
    END AS [SchoolType]
FROM school sch
INNER JOIN calendar cal
    ON cal.schoolid = sch.schoolid
WHERE
    (
      TRY_CONVERT(int, SUBSTRING(sch.number, 4, 3)) >= 300
      OR SUBSTRING(sch.number, 4, 3) = '000'
    )
  AND cal.startdate <= GETDATE()
  AND cal.enddate   >= GETDATE();

