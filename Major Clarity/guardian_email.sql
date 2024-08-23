/*
	Title: Major Clarity - Guardian Email
	
	Description:
	Major Clarity - Guardian Email	
	Author: Mark Samberg (mark.samberg@dpi.nc.gov)
	
	Revision History:
	08/23/2024		Initial creation of this template

*/

WITH guardian (person_id, guardian_id, first_name, last_name, email_address, row_number) AS (SELECT vg.personID, guardianID, i.firstName, i.lastName, c.email, ROW_NUMBER() OVER (PARTITION BY vg.personID ORDER BY guardianID)
FROM view_guardian vg,
person p,
[identity] i,
contact c
WHERE vg.guardianID = p.personID
AND i.personID = p.personID
AND c.personID = p.personID)

SELECT 
stu.stateID,
g1.email_address as guardian_email,
g1.first_name as guardian_first_name,
g1.last_name as guardian_last_name,
g2.email_address as guardian_email2,
g2.first_name as guardian_first_name2,
g2.last_name as guardian_last_name2
FROM student stu
LEFT JOIN guardian as g1 ON stu.personID=g1.person_id
LEFT JOIN guardian as g2 ON stu.personID=g2.person_id,
calendar cal,
school sch
WHERE g1.row_number=1 and g2.row_number=2
AND cal.calendarID = stu.calendarID
AND sch.schoolID = cal.schoolID
AND cal.startDate<=GETDATE() AND cal.endDate>=GETDATE() --Get only calendars for the current year
;