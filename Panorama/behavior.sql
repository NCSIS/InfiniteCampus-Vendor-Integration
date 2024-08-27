/*
	Title:Panorama - Behavior
	
	Description: 
	
	Author: Jeremiah Jackson - NCDPI
	
	Revision History:
	08/20/2024		Initial creation of this template

*/

SELECT
	student.personID, student.stateID, student.studentNumber, student.firstName, student.lastName,
--	behaviorDetail.context, behaviorDetail,contextDescription, behaviorDetail.damages, 
	behaviorDetail.details,behaviorDetail.incidentDate, behaviorDetail.incidentID, behaviorDetail.location, behaviorDetail.locationDescription, 
--	behaviorDetail.status, 
	behaviorDetail.submittedByPersonID, behaviorDetail.submittedBy, 
--	behaviorDetail.submittedByDate, behaviorDetail."timestamp", behaviorDetail.title
	behaviorDetail.behaviorComments, behaviorDetail.code, behaviorDetail.eventID, behaviorDetail.eventName, 
--	behaviorDetail.fightRelated
	behaviorDetail.incidentDescription, 
--	behaviorDetail.stateEventCode, behaviorDetail.stateEventName, 
	behaviorDetail.role, behaviorDetail.roleID, behaviorDetail.resolutionID, behaviorDetail.resolutionCode, behaviorDetail.resolutionName,
	behaviorDetail.staffName, behaviorDetail.staffPersonID, 
	cal.calendarID, sch.number AS 'cal.schoolID', cal.name
	
FROM
	v_BehaviorDetail behaviorDetail
	INNER JOIN v_AdhocStudent student ON student.personID = behaviorDetail.personID
	INNER JOIN calendar cal ON cal.calendarID = student.calendarID
	INNER JOIN school sch ON sch.schoolID = student.schoolID
WHERE
    cal.startDate <= GETDATE()
    AND cal.endDate >= GETDATE() -- Get only calendars for the current year
    AND behaviorDetail.incidentDate >= DATEADD(YEAR, -1, DATEFROMPARTS(cal.endyear, 7, 1))
    AND behaviorDetail.incidentDate < DATEFROMPARTS(cal.endyear, 7, 1)
    AND (
        CAST(SUBSTRING(sch.number, 4, 3) AS INTEGER) >= 300
        OR SUBSTRING(sch.number, 4, 3) = '000'
    );
