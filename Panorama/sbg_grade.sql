SELECT s.personID,
s.stateID,
s.studentNumber,
s.firstName,
s.lastName,
g.sectionID,
g.sectionNumber,
g.courseName,
g.termID,
g.termName,
g.taskID,
g.standardID,
g.scoreID,
g.score,
g.[percent],
g.progressScore,
g.task,
c.schoolID
FROM student s,
v_GradingScores g,
calendar c
WHERE g.personID=s.personID
AND c.calendarID=g.calendarID
AND c.startDate<=GETDATE() AND c.endDate>=GETDATE() --Get only calendars for the current year
   AND (s.endDate IS NULL or s.endDate>=GETDATE()) --Get students with no end-date or future-dated end date
   AND s.stateid IS NOT NULL
   AND s.stateid <> ''
