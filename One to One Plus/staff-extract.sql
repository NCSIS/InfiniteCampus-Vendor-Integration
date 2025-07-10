/*
	Title: One to One Plus Staff
	Author: Jeremiah Jackson NCDPI
	Revision History:
	07/10/2025		Enhanced logic to prefer active jobs but fallback to latest inactive

** Reminder to change the email address in the bottom of this file to match your email domain.

*/

WITH RankedStaff AS (
    SELECT DISTINCT
         sm.staffstateID AS 'Staff ID',
         sm.firstname AS 'First Name',
         sm.lastname AS 'Last Name',
         c.email AS 'Email Address',
         sm.schoolnumber AS 'Site',
         sm.startdate,
         CASE
              WHEN (sm.enddate IS NULL OR sm.endDate > GETDATE()) THEN 'Active'
              ELSE 'Inactive'
         END AS 'Status',
         ROW_NUMBER() OVER (
              PARTITION BY sm.staffstateID
              ORDER BY 
                   -- Prefer active records first
                   CASE WHEN sm.enddate IS NULL OR sm.endDate > GETDATE() THEN 1 ELSE 2 END,
                   -- Then prefer latest startdate
                   sm.startdate DESC
         ) AS rn
    FROM staffmember sm 
    INNER JOIN contact c ON sm.personid = c.personid 
    WHERE c.email LIKE '%@haywood.k12.nc.us'
)

SELECT
     [Staff ID],
     [First Name],
     [Last Name],
     [Email Address],
     [Site],
     [Status]
FROM RankedStaff
WHERE rn = 1;
