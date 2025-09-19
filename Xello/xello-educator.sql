
/*
	Title: Xello Educators
	
	Description: 
                     
	
	Author: Jeremiah Jackson NCDPI
	
	Revision History:
	09/03/2025		Initial creation of this template

*/

SELECT DISTINCT
     sm.firstName AS [FirstName],
	 sm.lastName AS [LastName],
	 cs.email AS [Email],
	 sm.schoolnumber AS [SchoolCode],
	 CASE
		WHEN sm.supervisor = 1 THEN 1  -- Supervisor takes priority
		WHEN sm.teacher = 1 THEN 2     -- Teacher next
		ELSE 3                         -- Everyone else
	END AS [Permissions],
	sm.staffstateid AS [EducatorSISId],
	sm.title AS [JobTitle]

FROM staffmember sm 

   OUTER APPLY (
    SELECT TOP 1 c.*
    FROM v_CensusContactSummary c
    WHERE c.personID = sm.personID
      AND c.relationship = 'Self'
    ORDER BY c.seq
) cs
WHERE (sm.endDate IS NULL OR sm.endDate > GETDATE());

