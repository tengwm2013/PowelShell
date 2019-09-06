# Update Outlet database
# SQL script save in "C:\ValueMax\PowellShell\SQLScript\AdminConsoleUserID.sql"

set-executionpolicy remotesigned
set-executionpolicy -executionpolicy unrestricted
Clear-Host 
Import-Module MySqlCmdlets 
Add-Type -Path 'C:\Program Files (x86)\Wiechecki.it\PowerShell\Modules\MySqlCmdlets\MySql.Data.dll'

[DateTime] $currentDate = [DateTime]::Now 
[string] $userName = "s" 
[string] $mySQLServer = "172.30.16.200"
#[string] $mySQLServer = "172.30.38.56"
[string] $databaseName = "VampireServer"
[string] $branchcode = ""
[string] $IP = ""

[string] $ctDatabaseRegEx = "database=[_a-zA-Z]+"
[string] $ctUserIDRegEx = "userid=[_a-zA-Z]+"
[string] $ctUserPWdRegEx = "password=[_a-zA-Z]+"              


#All Outlet
$mySQLQuery = "SELECT branchcode, ConnectionString, REPLACE(LEFT(connectionstring, INSTR(ConnectionString, ';PORT')-1), 'server=', '') 
as IP FROM Branch WHERE ConnectionSTring <> '' AND companytype ='PAWNSHOP' AND Country ='SINGAPORE' 
AND (Branchcode NOT IN ('SH','FY','HC','CK','BK','ZA','LI','TL','HV','BN','TE') AND Branchcode >'AM')"
#$mySQLQuery = "SELECT branchcode, ConnectionString, REPLACE(LEFT(connectionstring, INSTR(ConnectionString, ';PORT')-1), 'server=', '') 
#as IP FROM Branch WHERE ConnectionSTring <> '' AND companytype ='PAWNSHOP' AND Branchcode IN ('WA')"

# Malaysia
$mySQLQuery = "SELECT branchcode, ConnectionString, REPLACE(LEFT(connectionstring, INSTR(ConnectionString, ';PORT')-1), 'server=', '') 
as IP FROM Branch WHERE ConnectionSTring <> '' AND companytype ='PAWNSHOP' AND Country ='MALAYSIA' AND Branchcode NOT IN ('BT','MA','UT','KL') and Branchcode >'UT'"


Try
{
    
  $ConnectionString ="server=" + $mySQLServer + ";port=3307;uid=s;pwd=s;database="+$databaseName

  [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  $Connection.ConnectionString = $ConnectionString
  $Connection.Open()
  $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($mySQLQuery, $Connection)
  $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
  $DataSet = New-Object System.Data.DataSet
  $RecordCount = $dataAdapter.Fill($DataSet, "data")    

  #READ Script 
  #$mySQLQuery=get-content "C:\ValueMax\PowellShell\SQLScript\VPS-Sript.sql"
  $mySQLQuery=get-content "C:\ValueMax\PowerShell\SQLScript\InsertOutletBranch.sql"
  $mySQLQuery=get-content "C:\ValueMax\PowerShell\SQLScript\ChangeBranchDefault.sql"

  
  foreach ($Row in $DataSet.Tables[0].Rows)
  { 
   $IndConnStr = $Row["ConnectionString"]
   
   $IndIP = $Row["IP"]
   $Branchcode = $Row["branchcode"]

   [regex]$DBrx="database=[_a-zA-Z]+"
   [regex]$IDrx="userid=[_a-zA-Z]+"
   [regex]$Pwdrx="password=[_a-zA-Z]+"

   $IndConnStr1=$IndConnStr.Replace(" ", "")

   $IndDB= $DBrx.Match($IndConnStr1).Value.Replace("database=","")   
   $IndID = $IDrx.Match($IndConnStr1).Value.Replace("userid=","")
   $IndPwd = $Pwdrx.Match($IndConnStr1).Value.Replace("password=","")
   
   $Vpspassword = ConvertTo-SecureString $IndPwd -AsPlainText -Force
   $VpsCred = New-Object System.Management.Automation.PSCredential ($IndID, $Vpspassword)
     
   
   Write-Host "Start: $($IndDB) - $($IndIP) -  $Branchcode"

   $IndConnection = New-Object MySql.Data.MySqlClient.MySqlConnection
   $IndConnection.ConnectionString = $IndConnStr
   $IndConnection.Open()   
   
   Write-Host "END : $($IndDB) - $($IndIP) -  $Branchcode"
  
   $IndCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($mySQLQuery, $IndConnection)
   $iRowsAffected=$IndCommand.ExecuteNonQuery()
   
   $IndConnection.Close()

   Write-Host "Inserted into : $($IndDB) - $($IndIP) "

  }
}
Catch 
{
  Write-Host "ERROR : Unable to run query : $mySQLQuery `n$Error[0]"
 }
Finally {
  $Connection.Close()
  }


