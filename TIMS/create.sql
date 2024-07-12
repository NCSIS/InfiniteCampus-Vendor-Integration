/*
	Title: TIMS Temporary Tables and Stored Procedures
	
	Description:
	This will be created in by DPI for the TIMS extracts.
	
	Author: Brock Wilson K12 Solutions
	
	Revision History:
	07/12/2024		Initial creation

*/



IF OBJECT_ID('tempdb..#TIMS') IS NOT NULL DROP TABLE #TIMS

create table #TIMS(
	personID int,
	enrollmentID int,
	calendarID int,
	activeStatus varchar(1),
	studentID varchar(25),
	lastName varchar(100),
	middleName varchar(100),
	firstName varchar(100),
	grade varchar(10),
	nextGrade varchar(10),
	birthdate smalldatetime,
	race varchar(25),
	gender varchar(1),
	hrInfo varchar(100),  --is it important BEFORE school starts?  If yes, need to adjust term info below
	homePrimaryLanguage varchar(10),
	addy1 varchar(100),
	addy2 varchar(100),
	addy3 varchar(100),
	addy4 varchar(100),
	addy5 varchar(100),
	addy6 varchar(100),
	mailingAddress varchar(250),
	homephone varchar(250),
	g1name varchar(100),
	g1cell varchar(25),
	g1relationship varchar(100),
	g2name varchar(100),
	g2cell varchar(25),
	g2relationship varchar(100),
	e1name varchar(100),
	e1cell varchar(25),
	e1relationship varchar(100),
	e2name varchar(100),
	e2cell varchar(25),
	e2relationship varchar(100),
	enrSchool varchar(10),
	nextSchool varchar(10),
	resSchool varchar(10),  --enrollment.residentSchool?
	regDate smalldatetime,
	enrDate smalldatetime,
	amAltAddy varchar(250),
	pmAltAddy varchar(250),
	accommodations varchar(250),
	lift varchar(1),
	monitor varchar(1)
	)

CREATE INDEX #TIMS ON #TIMS(personID)

insert #TIMS(personID,enrollmentID,calendarID,activeStatus,studentID,lastName,middleName,firstName,grade,race,gender,homePrimaryLanguage,enrSchool,enrDate,resSchool,birthdate)
select 
	 stu.personID
	,e.enrollmentID
	,stu.calendarID
	,CASE WHEN stu.endDate IS NULL OR stu.endDate > getdate() THEN 'C' ELSE 'D' END
	,stu.stateID
	,stu.lastName
	,stu.middleName
	,stu.firstName
	,gl.stateGrade
	,stu.raceEthnicityFed --need to discuss this to make sure we get what they want.  Comma delimited list? Single federal value/
	,stu.gender
	,stu.homePrimaryLanguage
	,LEFT(d.number,3) + RIGHT(scl.number,3)
	,stu.startDate
	,ISNULL(e.residentDistrict,'') + ISNULL(e.residentSchool,'')
	,stu.birthdate
from (select endYear 
	from dbo.schoolYear 
	where active = 1) sy
join dbo.student stu WITH(NOEXPAND) ON stu.endYear = sy.endYear
join dbo.enrollment e ON e.enrollmentID = stu.enrollmentID
join dbo.GradeLevel gl ON gl.calendarID = stu.calendarID and gl.structureID = stu.structureID and gl.name = stu.grade
join dbo.School scl ON scl.schoolID = stu.schoolID
join dbo.District d ON d.districtID = stu.districtID
where 1=1
and stu.startDate <= getdate()
and stu.serviceType = 'P'
and stu.startDate = (select top 1 startDate
					from dbo.student stu2 WITH(NOEXPAND)
					where stu2.endYear = stu.endYear
					and stu2.personID = stu.personID
					and stu2.serviceType = 'P'
					order by stu2.startDate desc
					)

update t set
	 addy1 = a.number 
	,addy2 = CASE WHEN a.prefix IS NULL THEN '' ELSE a.prefix + ' ' END 
		+ a.street 
		+ CASE WHEN a.tag IS NULL THEN '' ELSE ' ' + a.tag END
		+ CASE WHEN a.dir IS NULL THEN '' ELSE ' ' + a.dir END
	,addy3 = a.apt 
	,addy4 = a.city 
	,addy5 = a.state
	,addy6 = a.zip
	,homephone = a.phone 
from #TIMS t
CROSS apply (select top 1 *
				from v_Address a
				where 1=1
				and a.personID = t.personID
				and ISNULL(a.secondary,0) = 0
				and a.startDate <= getdate()
				and (a.endDate IS NULL OR a.endDate >= getdate())
				and ISNULL(a.postOfficeBox,0) = 0
				order by CASE WHEN a.relatedBy = 'household' THEN 1 ELSE 2 END asc, a.householdID asc
				) a

update t set 
	 mailingAddress = ma.addressLine1 + ' ' + ma.addressLine2
from #TIMS t
cross apply (select top 1 *
				from v_MailingAddress a
				where 1=1
				and a.personID = t.personID
				and ISNULL(a.secondary,0) = 0
				and a.startDate <= getdate()
				and (a.endDate IS NULL OR a.endDate >= getdate())
				order by CASE WHEN a.relatedBy = 'household' THEN 1 ELSE 2 END asc, a.householdID asc
				) ma


update t set 
	 nextGrade = gl2.stateGrade
	,nextSchool = scl.number
from #TIMS t
join dbo.Enrollment e ON e.enrollmentID = t.enrollmentID
join dbo.GradeLevel gl2 ON gl2.calendarID = e.nextCalendar 
				and gl2.structureID = e.nextStructureID 
				and gl2.name = e.nextGrade
join dbo.Calendar cal ON cal.calendarID = e.nextCalendar
join dbo.School scl ON scl.schoolID = cal.schoolID


update t set
	 hrInfo = hr.hrInfo
from #TIMS t
cross apply (select top 1 ti.lastname + ' - ' + ISNULL(rm.name,'No room assigned') as hrInfo
				from (select trialID
						from dbo.Trial trl
						where trl.active = 1
						and trl.calendarID = t.calendarID
						) trl
				join dbo.Roster ros ON ros.personID = t.personID and ros.trialID = trl.trialID
				join dbo.Section sec ON sec.sectionID = ros.sectionID and sec.trialID = trl.trialID
				join dbo.Course crs ON crs.courseID = sec.courseID
				join dbo.SectionStaffHistory ssh ON ssh.sectionID = sec.sectionID and ssh.trialID = trl.trialID and ssh.staffType = 'P'
				join dbo.individual ti ON ti.personID = ssh.personID
				left outer join dbo.Room rm ON rm.roomID = sec.roomID
				where 1=1
				and (ISNULL(crs.homeroom,0) = 1
					OR
					ISNULL(sec.homeroomSection,0) = 1
					)
				and exists(
						select 1 
						from dbo.sectionPlacement sp
						join dbo.term trm ON trm.termID = sp.termID
						where sp.trialID = trl.trialID
						and sp.sectionID = sec.sectionID
						and trm.startDate <= getdate()
						and trm.endDate >= getdate()
						)
				) hr
where 1=1


update t set 
	 g1name = r.g1name,
	 g1relationship = r.g1relationship,
	 g1cell = r.g1cell,
	 g2name = r.g2name,
	 g2relationship = r.g2relationship,
	 g2cell = r.g2cell
from #TIMS t
join (
select
	 t.personID,
	 g1name = MAX(CASE WHEN rp.rn = 1 THEN rp.gName END),
	 g1relationship = MAX(CASE WHEN rp.rn = 1 THEN rp.gRelation END),
	 g1cell = MAX(CASE WHEN rp.rn = 1 THEN rp.cellPhone END),
	 g2name = MAX(CASE WHEN rp.rn = 2 THEN rp.gName END),
	 g2relationship = MAX(CASE WHEN rp.rn = 2 THEN rp.gRelation END),
	 g2cell = MAX(CASE WHEN rp.rn = 2 THEN rp.cellPhone END)
from #TIMS t
join (select rp.personID1,i.lastname + ', ' + i.firstname as gName,rp.name as gRelation,c.cellPhone,ROW_NUMBER() OVER(PARTITION BY rp.personID1 ORDER BY CASE WHEN rp.seq IS NULL THEN 99 ELSE rp.seq END asc, rp.personID1 asc) rn
		from dbo.RelatedPair rp 
		join dbo.individual i ON i.personID = rp.personID2
		left outer join dbo.contact c ON c.personID = rp.personID2
		where ISNULL(rp.guardian,0) = 1
		and (rp.startDate IS NULL OR rp.startDate <= getdate())
		and (rp.endDate IS NULL OR rp.endDate >= getdate())
		) rp ON rp.personID1 = t.personID 
group by t.personID
) r ON r.personID = t.personID

update t set 
	 e1name = r.g1name,
	 e1relationship = r.g1relationship,
	 e1cell = r.g1cell,
	 e2name = r.g2name,
	 e2relationship = r.g2relationship,
	 e2cell = r.g2cell
from #TIMS t
join (
select
	 t.personID,
	 g1name = MAX(CASE WHEN rp.rn = 1 THEN rp.gName END),
	 g1relationship = MAX(CASE WHEN rp.rn = 1 THEN rp.gRelation END),
	 g1cell = MAX(CASE WHEN rp.rn = 1 THEN rp.cellPhone END),
	 g2name = MAX(CASE WHEN rp.rn = 2 THEN rp.gName END),
	 g2relationship = MAX(CASE WHEN rp.rn = 2 THEN rp.gRelation END),
	 g2cell = MAX(CASE WHEN rp.rn = 2 THEN rp.cellPhone END)
from #TIMS t
join (select rp.personID1,i.lastname + ', ' + i.firstname as gName,rp.name as gRelation,c.cellPhone,ROW_NUMBER() OVER(PARTITION BY rp.personID1 ORDER BY CASE WHEN rp.seq IS NULL THEN 99 ELSE rp.seq END asc, rp.personID1 asc) rn
		from dbo.RelatedPair rp 
		join dbo.individual i ON i.personID = rp.personID2
		left outer join dbo.contact c ON c.personID = rp.personID2
		where ISNULL(rp.guardian,0) = 0
		and (rp.startDate IS NULL OR rp.startDate <= getdate())
		and (rp.endDate IS NULL OR rp.endDate >= getdate())
		) rp ON rp.personID1 = t.personID 
group by t.personID
) r ON r.personID = t.personID

update t set
	 regDate = e.startDate
from #TIMS t
cross apply (select top 1 startDate
			from dbo.enrollment e
			where e.personID = t.personID
			and ISNULL(e.noShow,0) = 0
			order by e.startDate asc) e


update t set 
	amAltAddy = pickupLocation,
	pmAltAddy = dropoffLocation
from #TIMS t
join dbo.TransportationRoute tr ON tr.personID = t.personID
where tr.transportationRouteID = (select top 1 tr2.transportationRouteID
									from dbo.TransportationRoute tr2
									where tr2.personID = tr.personID
									and tr2.startDate <= getdate()
									and (tr2.endDate IS NULL OR tr2.endDate >= getdate())
									order by tr2.startDate desc
									)

select 
	 activeStatus as 'Active Status'
	,studentID as 'Student ID'
	,lastName as 'Student Last Name'
	,middleName as 'Student Middle Name'
	,firstName as 'Student First Name'
	,grade as 'Grade'
	,nextGrade as 'Next Grade'
	,REPLACE(CONVERT(char(10),birthdate,101),'/','') as 'Birth Date'
	,race as 'Race' --what do they want??
	,gender as 'Gender' --legal or identified?
	,hrInfo as 'Homeroom'
	,homePrimaryLanguage as 'Home Primary Language'
	,addy1 as 'Primary Address Line 1: Number'
	,addy2 as 'Primary Address Line 2: Street'
	,addy3 as 'Primary Address Line 3: Apt or Lot'
	,addy4 as 'Primary Address Line 4: City'
	,addy5 as 'Primary Address Line 5: State'
	,addy6 as 'Primary Address Line 6: Zip Code'
	,mailingAddress as 'Mailing Address'
	,homephone as 'Household Phone'
	,g1name as 'Guardian 1 Name'
	,g1cell as 'Guardian 1 Cell'
	,g1relationship as 'Relationship of Guardian 1'
	,g2name as 'Guardian 2 Name'
	,g2cell as 'Guardian 2 Cell'
	,g2relationship as 'Relationship of Guardian 2'
	,e1name as 'Emergency Contact 1 Name'
	,e1cell as 'Emergency Contact 1 Cell Phone'
	,e1relationship as 'Relationship of Emergency Contact 1'
	,e2name as 'Emergency Contact 2 Name'
	,e2cell as 'Emergency Contact 2 Cell Phone'
	,e2relationship as 'Relationship of Emergency Contact 2'
	,enrSchool as 'School of Enrollment'
	,nextSchool as 'Next School of Enrollment'
	,resSchool as 'School of Residence'
	,REPLACE(CONVERT(char(10),regDate,101),'/','') as 'Registered Date'
	,REPLACE(CONVERT(char(10),enrDate,101),'/','') as 'Admitted Date'
	,amAltAddy as 'AM Alternate Address'
	,pmAltAddy as 'PM Alternate Address'
	,'' as 'Accommodations' --need to revisit
	,'' as 'Lift' --need to revisit
	,'' as 'Monitor' --need to revisit
from #TIMS