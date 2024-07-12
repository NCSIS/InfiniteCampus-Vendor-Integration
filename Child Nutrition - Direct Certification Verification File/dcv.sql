/*
	Title: Direct Certification Verification File
	
	Description:
	This SQL will generate the file to be used to upload to the Direct Certification Verification System at DPI (https://schoolnutrition.dpi.nc.gov/snp).
	
	Author: Brock Wilson, K12 Solutions
	
	Revision History:
	07/12/2024		Initial creation of this template

*/



--Comment for SQL Statement 1
select 
	 RIGHT(SPACE(4) + d.number,4) 
	+RIGHT(SPACE(12) + ISNULL(stu.stateID,''),12)
	+RIGHT(SPACE(4) + CASE WHEN RIGHT(scl.number,3) LIKE '29%' THEN ISNULL(cal.number,RIGHT(scl.number,3)) ELSE RIGHT(scl.number,3) END,4)
	+LEFT(stu.firstname + SPACE(30),30)
	+LEFT(stu.lastname + SPACE(30),30)
	+LEFT(ISNULL(stu.middlename,'')+SPACE(1),1)
	+FORMAT(stu.birthdate,'MM/dd/yyyy')
	+LEFT(stu.gender+SPACE(1),1)
	+LEFT(ISNULL(a.addressLine1,'')+SPACE(30),30)
	+LEFT(ISNULL(a.apt,'') + SPACE(30),30)
	+LEFT(ISNULL(a.city,'') + SPACE(20),20)
	+LEFT(ISNULL(a.state,'') + SPACE(2),2)
	+LEFT(ISNULL(a.zip,'') + SPACE(5),5)
	+LEFT(ISNULL(sc.lastName,'') + SPACE(30),30)
	+LEFT(ISNULL(sc.firstName,'') + SPACE(30),30)
from (select endYear from dbo.SchoolYear sy where sy.active = 1) sy
join dbo.Calendar cal ON cal.endYear = sy.endYear
join dbo.student stu WITH(NOEXPAND) ON stu.calendarID = cal.calendarID
join dbo.School scl ON scl.schoolID = cal.schoolID
join dbo.District d ON d.districtID = scl.districtID
outer apply (select top 1 *
				from v_Address a
				where a.personID = stu.personID
				and a.districtID = stu.districtID
				and ISNULL(postOfficeBox,0) = 0
				) a
outer apply (select top 1 i.lastname,i.firstname,c.email,c.homephone,c.workphone,c.cellphone
				from dbo.relatedPair rp
				join dbo.individual i ON i.personID = rp.personID2
				left outer join dbo.contact c ON c.personID = rp.personID2
				where rp.personID1 = stu.personID
				and ISNULL(rp.guardian,0) = 1
				order by CASE WHEN ISNULL(rp.name,'ZZ') = 'Mother' THEN 1 WHEN ISNULL(rp.name,'ZZ') = 'Father' THEN 2 ELSE 3 END ASC
				) sc
where 1=1
and (
	(stu.endDate IS NULL OR stu.endDate >= getdate())
	OR
	(stu.endYear = 2024 and stu.endDate >= '5/1/2024')
	)
