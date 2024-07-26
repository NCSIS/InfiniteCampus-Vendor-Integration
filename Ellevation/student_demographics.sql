/*
	Title: Ellevation Student Demographics
	
	
	Author: Clinton City Schools
	
	Revision History:
	07/25/2024		Initial creation of this template

*/

select distinct
i.firstname,
isnull(i.middlename,'') middlename,
i.lastname,
'Yes' as activeStatus,
sc.number [LEA School Code],
sc.name [School Name],
p.studentNumber [District Local ID],
p.stateid [State Testing ID],
e.grade [Grade Level],
i.gender,
convert(varchar,i.birthdate,101) [Date of Birth],
i.birthCountry [Birth Country],
i.homePrimaryLanguage [Native Language],
i.homePrimaryLanguage [Home Language],
case when i.hispanicEthnicity='Y' then 'Hispanic'
when i.hispanicEthnicity='N' then 'Not Hispanic'
end [Ethnicity],
i.raceEthnicity,
lep.programStatus as [LEP Program Status],
lep.firstYearMonitoring, 
lep.secondYearMonitoring, 
lep.thirdYearMonitoring, 
lep.fourthYearMonitoring, 
convert(varchar,lep.parentDeclinedDate,101) [Parent Declined Date], 
lep.longTermEL, 
lep.atRiskEL,
convert(varchar,lep.identifiedDate,101) [Date Entered LEP],
convert(varchar,lep.exitDate,101) [Date Exited LEP],
prog.name [Program Name],
convert(varchar,i.dateEnteredUS,101) [Date Entered US],
convert(varchar,i.dateEnteredUSSchool,101) [Date Enrolled in the US],
convert(varchar,e.startdate,101) [Date Enrolled in the District],
e.specialEdStatus,
e.specialEdSetting,
e.disability1,
E.section504,
gdn.firstName [Guardian First Name], 
gdn.lastName [Guardian Last Name], 
ccs.addressLine1,
ccs.addressLine2, 
ccs.city, 
ccs.state, 
ccs.zip 
from person p
left join RelatedPair rp ON rp.personID1 = p.personID and rp.guardian=1 and rp.seq=1
left join [Identity] gdn ON gdn.personID = rp.personID2
left join v_CensusContactSummary ccs ON ccs.personID = p.personID and ccs.guardian = 'true'
inner join enrollment e on e.personid=p.personid
inner join schoolyear sy on e.endyear = sy.endyear
left join [identity] i on i.identityid=p.currentidentityid
left join calendar ca on ca.calendarid=e.calendarid
left join school sc on sc.schoolid=ca.schoolid
left join lep on lep.personid=e.personid
left join ProgramParticipation propar ON propar.personID = lep.personID and propar.endDate is null
left join Program prog ON prog.programID = propar.programID 
where sy.active=1 
