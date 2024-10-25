with CurrentStudents as (
    select p.personID
                   , [psuCode]=d.number
                             , [schoolCode]=sch.number
                             , [SchoolName]=sch.name
                             , p.studentNumber
                             , [firstName]=isnull(i.legalFirstName, i.firstName) 
                              , [lastName]=isnull(i.legalLastName, i.lastName) 
                              , [DOB] =CONVERT(char(10), i.birthdate, 126)
                             , [grade]=gl.stateGrade 
                              , [calendarName]=c.name
                             , [calendarNumber]=c.number
              from dbo.Person p 
              INNER JOIN dbo.[Identity] i ON p.currentIdentityID = i.identityID AND p.personID = i.personID
              INNER JOIN dbo.Enrollment e ON e.personID = p.personID and e.ServiceType = 'P' AND (e.noShow IS NULL OR e.noShow = 0) --AND e.active = 1 
              INNER JOIN dbo.Calendar c   ON c.calendarID = e.calendarID and c.districtID = e.districtID  
              INNER JOIN dbo.SchoolYear y ON y.endYear = e.endYear
              INNER JOIN dbo.School sch ON sch.schoolID = c.schoolID and sch.number in ('950308','950316','950320','950324','950336','950338','950334') 
              INNER JOIN dbo.district d ON d.districtID = e.districtID
              INNER JOIN dbo.GradeLevel gl ON gl.calendarID = e.calendarID AND gl.structureID = e.structureID AND gl.name = e.grade
              INNER JOIN (select districtID,personID,enrollmentID,e1.calendarID,e1.startDate,e1.endDate,e1.active,
                                                                          ROW_NUMBER() over (partition by districtID,personID order by e1.startDate desc) latest_rec
                                                          from dbo.enrollment e1 
                                                          INNER JOIN dbo.SchoolYear y ON y.endYear = e1.endYear and y.active = 1
                                                          where e1.startDate <= convert(datetime,'11/01/2024 23:59:59') and e1.serviceType = 'P'  
                                                          ) latest on latest.enrollmentID = e.enrollmentID and latest.districtID = e.districtID and latest.personID = e.personID and latest.latest_rec = 1
)
, EOG as (select tsp.personID
,      [Test] = case when tp.parentID is null then tp.name else concat(ta.name,' ',tp.name) end 
,      [Test Date] = CONVERT(char(10), tsp.[date], 126)-- TO_CHAR(ST.TEST_DATE, 'YYYY-MM-DD')TEST_DATE
,      [Scale Score] = cast(tsp.scaleScore as int) 
,      [Percentile] =  cast(tsp.percentile as int)
,      [Achievement Level] = tsp.performanceLevel
,      [grade] = case when tsp.parentID is null then tsp.testingGrade else tsa.testingGrade end
from dbo.testScore tsp 
inner join dbo.test tp on (tp.testID = tsp.testID)
left outer join dbo.test tc on (tc.parentID = tp.testID) 
left outer join dbo.test ta on ta.testID = tp.parentID 
left outer join dbo.testScore tsa on tsa.scoreID =tsp.parentID
where tp.code in ('EOG_MA6','EOG_RD6', 'EOG_MA7','EOG_RD7', 'EOG_MA8','EOG_RD8', 'EOG_SC8', 'EOC_BI', 'EOC_E2', 'EOC_M1', 'ACT')
  and not (tsp.scaleScore is null and isnull(tsp.performanceLevel,'')='')
)
select cs.schoolCode, cs.studentNumber, cs.lastName, cs.firstName
, cs.DOB 
, [Test]
, [Scale Score]
, [Percentile] 
, [Achievement Level] 
, [Test Date]
, EOG.[grade]
from CurrentStudents cs
inner join EOG on (EOG.personID = cs.personID)
where cs.grade IN ('06', '07', '08', '09', '10', '11', '12')
;
