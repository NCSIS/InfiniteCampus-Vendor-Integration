WITH ContactSelf AS (
	SELECT 
		c.personID, 
		c.email,
		ROW_NUMBER() OVER (PARTITION BY c.personID ORDER BY c.seq) AS rowNumber
	FROM 
		v_CensusContactSummary c 
	WHERE c.relationship = 'Self'
)



SELECT
           c.email AS 'StudentEmail',
	s.studentNumber AS 'StudentID'
	

FROM v_AdHocStudent s
	JOIN contactself c ON c.personID = s.personID  and c.rowNumber = 1