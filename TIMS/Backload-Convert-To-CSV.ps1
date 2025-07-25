# This is a powershell script that converts the output from TIMS into the correct format to load into Infinite Campus
# This is not Universal.  You will need to modify the $ variables below to the correct file locations.
# You MUST have Excel loaded on the computer that you run this script on.
#
# In order to automate to run as non-interactive.  there are some serious changes that have to happen to allow this
# https://kb.dataself.com/ds/configure-windows-to-run-excel-in-non-interactive-
# You also may need to change some permissions. 

#
# Author:   Jeremiah Jackson NCDPI

################
# Variables - Change These
###############
$timsloadfile = "C:\sftp\tims\timstocampusbackload.xls"
$xlsxPath = "C:\sftp\tims\convertedtimstocampusbackload.xlsx"
$timsCSV = "C:\users\psusersync\tims2ic.csv"


## you shouldn't need to change anything below here.
##
##
##
##

# Delete the old output files
##############
if (Test-Path -path $xlsxPath ){Remove-Item -Path $xlsxPath -Force}
if (Test-Path -path $timsCSV ){Remove-Item -Path $timsCSV -Force}


#Convert XLS to XLSX
######################
$excel = New-Object -ComObject Excel.Application
$workbook = $excel.Workbooks.Open($timsloadfile)
$workbook.SaveAs($xlsxPath, 51)  # 51 = xlOpenXMLWorkbook (xlsx)
$workbook.Close($false)
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)  


#Import the DATA to reformat
########################
$timsdata = Import-Excel -Path $xlsxPath
  

ForEach ($ID in $timsdata)
{
$cleanID = [decimal]$ID.stu_districtid
    switch ($ID.stutrip_ztriptype_id) {
        1 { $mappedValue = 'To' }
        2 { $mappedValue = 'From' }
        3 { $mappedValue = 'To' }
        4 { $mappedValue = 'From' }
        default { $mappedValue = $ID.stutrip_ztriptype_id }
    }

if ($ID.rte_id) {

	$newcsv = New-Object psobject
			$newcsv | Add-Member -MemberType NoteProperty -name StudentStateID -Value $cleanID
			$newcsv | Add-Member -MemberType NoteProperty -name RouteName -Value $ID."run_desc"
			$newcsv | Add-Member -MemberType NoteProperty -name RouteTypeCode -Value $mappedValue
			$newcsv | Add-Member -MemberType NoteProperty -name BusNumber -Value $ID.rte_id
			$newcsv | Add-Member -MemberType NoteProperty -name StopDescription -Value $ID."stop_desc"
			$newcsv | Add-Member -MemberType NoteProperty -name StopTime -Value $ID."runsrv_timeatsrv"
			$newcsv | Add-Member -MemberType NoteProperty -name SchoolDist -Value $ID."stu_schdist_geo"
			$newcsv | export-csv $timsCSV -notypeinformation -append
			}
}
