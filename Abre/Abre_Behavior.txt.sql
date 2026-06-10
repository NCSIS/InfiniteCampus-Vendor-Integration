SELECT
    s.studentNumber                                   AS [Student ID],
    bd.incidentID                                     AS [Incident ID],
    CONVERT(VARCHAR, bd.incidentDate, 23)             AS [Incident Date],
    bd.submittedBy                                    AS [Referring Staff],
    bd.code                                           AS [Behavio Code],
    bd.eventName                                      AS [Behavior Description],
    bd.resolutionCode                                 AS [Response Code],
    bd.resolutionName                                 AS [Response Description],
    bd.resolutionLengthSchoolDays                     AS [Response Total Days]
FROM dbo.v_BehaviorDetail bd
JOIN dbo.Calendar      cal ON bd.calendarID = cal.calendarID
JOIN dbo.School        sch ON cal.schoolID   = sch.schoolID
JOIN dbo.SchoolYear    y   ON cal.endYear    = y.endYear
JOIN dbo.BehaviorType  bt  ON bt.TypeID      = bd.eventTypeID
JOIN dbo.BehaviorIncident bi ON bi.incidentID = bd.incidentID
JOIN dbo.Student       s   ON s.personID     = bd.personID
                           AND s.calendarID  = bd.calendarID
WHERE y.endYear = CASE 
                    WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                    ELSE YEAR(GETDATE())
                  END
  AND bd.alignment = -1;