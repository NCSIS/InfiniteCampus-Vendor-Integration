SELECT
    s.studentNumber AS [Student ID],          -- <-- changed from bd.personID
    p.stateID AS [SSID],
    CONVERT(VARCHAR, y.endYear, 23) AS [endYear],
    bd.role AS [Role],
    sch.number AS [IncidentBuilding],
    bd.incidentID AS [IncidentID],
    bd.title AS [IncidentTitle],
    CONVERT(VARCHAR, bd.incidentDate, 23) AS [IncidentDate],
    FORMAT(bd.timestamp, 'hh:mm tt') AS [IncidentTime],
    bi.location AS [Incident Location],
    bd.submittedBy AS [SubmittedBy],
    CASE 
        WHEN bd.status = 'CM' THEN 'Complete'
        WHEN bd.status = 'DF' THEN 'Draft'
        WHEN bd.status = 'IP' THEN 'In-Progress'
        WHEN bd.status = 'SB' THEN 'Submitted'
        ELSE bd.status
    END AS [Status],
    bd.eventID AS [EventID],
    CASE 
        WHEN bd.alignment = -1 THEN 'Discipline'
        WHEN bd.alignment = 1 THEN 'Award'
        ELSE CAST(bd.alignment AS VARCHAR)
    END AS [EventType],
    bd.code AS [EventCode],
    bd.eventName AS [EventName],
    bd.stateEventCode AS [EventStateCode],
    bd.stateEventName AS [EventStateName],
    CASE bt.category
        WHEN '2' THEN 'Serious'
        WHEN '1' THEN 'Minor'
        WHEN '3' THEN 'Extreme'
        ELSE bt.category
    END AS [EventCategory],
    bd.resolutionID AS [ActionID],
    bd.resolutionCode AS [ActionCode],
    bd.resolutionName AS [ActionName],
    bd.stateResCode AS [ActionStateCode],
    bd.stateResName AS [ActionStateName],
    CASE 
      WHEN bd.resolutionCode IN ('003','004','005','135')
        THEN CONVERT(VARCHAR(10), bd.resolutionStartDate, 23)
      ELSE NULL
    END AS [SuspensionStartDate],
    CASE 
      WHEN bd.resolutionCode IN ('003','004','005','135')
        THEN CONVERT(VARCHAR(10), bd.resolutionEndDate, 23)
      ELSE NULL
    END AS [SuspensionEndDate],
    CASE 
      WHEN bd.resolutionCode IN ('006','110','141') THEN 'Y'
      ELSE 'N'
    END AS [Expulsion],
    CASE 
      WHEN bd.lawReferred = 1 THEN 'Y'
      WHEN bd.lawReferred = 0 THEN 'N'
      ELSE ''
    END AS [LawReferred],
    bd.motivationDescription AS [PerceivedMotivations]
FROM
    dbo.v_BehaviorDetail bd
    INNER JOIN dbo.Person p 
        ON bd.personID = p.personID
    INNER JOIN dbo.Student s
        ON bd.personID = s.personID
    INNER JOIN dbo.Calendar cal 
        ON bd.calendarID = cal.calendarID
    INNER JOIN dbo.School sch 
        ON cal.schoolID = sch.schoolID
    INNER JOIN dbo.SchoolYear y 
        ON cal.endYear = y.endYear
    INNER JOIN dbo.BehaviorType bt 
        ON bt.TypeID = bd.eventTypeID
    INNER JOIN dbo.BehaviorIncident bi 
        ON bd.incidentID = bi.incidentID
WHERE
    y.endYear = CASE 
                  WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                  ELSE YEAR(GETDATE())
               END;