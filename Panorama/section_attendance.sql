SELECT s.personID,
s.stateID,
s.studentNumber,
s.firstName,
s.lastName,
a.calendarID,
a.structureID,
a.termID,
a.termName,
a.periodID,
a.periodName,
a.periodSeq,
a.sectionID,
a.sectionNumber,
a.date,
a.status,
a.excuse,
a.behaviorExcuse,
a.code,
a.stateCode,
a.description,
a.courseNumber,
c.calendarID,
c.schoolID,
c.[name]
FROM student s,
v_AttendanceDetail a,
calendar c
WHERE a.personID=s.personID
AND c.calendarID=a.calendarID
AND c.startDate<=GETDATE() AND c.endDate>=GETDATE() --Get only calendars for the current year
   AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND s.stateid IS NOT NULL
   AND s.stateid <> ''
