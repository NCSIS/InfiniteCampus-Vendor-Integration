/*
	Title: One to One Plus Staff
	Author: Jeremiah Jackson NCDPI
	Revision History:
	07/10/2025		Enhanced logic to prefer active teacher jobs, fallback to non-teacher if none

Prioritize by: Active status THEN Teacher status (sm.teacher = 1) THEN Most recent startdate

*********
********* Reminder to change the email domain below to match your domain
*********
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
                   -- 1. Active first
                   CASE WHEN sm.enddate IS NULL OR sm.endDate > GETDATE() THEN 1 ELSE 2 END,
                   -- 2. Teacher jobs first
                   CASE WHEN sm.teacher = 1 THEN 1 ELSE 2 END,
                   -- 3. Then latest start date
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
