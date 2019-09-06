# VPS Deployment Push file to outlet

set-executionpolicy remotesigned
set-executionpolicy -executionpolicy unrestricted
Clear-Host 
Import-Module MySqlCmdlets 
Add-Type -Path 'C:\Program Files (x86)\Wiechecki.it\PowerShell\Modules\MySqlCmdlets\MySql.Data.dll'


#$password = ConvertTo-SecureString “s” -AsPlainText -Force
#$Cred = New-Object System.Management.Automation.PSCredential (“s”, $password)


function BackupnCopy($SourceFile, $DestFile, $text)
{
    #Backup existing CDD.Rpt

    Write-Host $text + ":" + $SourceFile + "~" + $DestFile
    Copy-Item $SourceFile -Destination $DestFile 
}


[DateTime] $currentDate = [DateTime]::Now 
[string] $userName = "s" 
[string] $mySQLServer = "172.30.16.200"
[string] $databaseName = "VampireServer"
[regex] $IPRegEx ="\b\d{1,3}\.\d{1,3}\.\d{1,3}\b"       
[regex] $IPRegExLast ="\d{1,3}\z"       
             

#All Outlet To Get 
$mySQLQuery = "SELECT branchcode, ConnectionString, REPLACE(LEFT(connectionstring, INSTR(ConnectionString, ';PORT')-1), 'server=', '') 
as IP FROM Branch WHERE ConnectionSTring <> '' AND companytype ='PAWNSHOP' AND Country ='SINGAPORE' 
AND (Branchcode NOT IN ('SH','FY','HC','CK','BK','ZA','LI','TL','HV','BN','TE','BS') AND Branchcode='WS' )"

#Problematic Outlet BA

# Malaysia
#$mySQLQuery = "SELECT branchcode, ConnectionString, REPLACE(LEFT(connectionstring, INSTR(ConnectionString, ';PORT')-1), 'server=', '') 
#as IP FROM Branch WHERE ConnectionSTring <> '' AND companytype ='PAWNSHOP' AND Country ='MALAYSIA' AND Branchcode NOT IN ('BT','MA','UT','KL') and Branchcode >'UT'"




Try
{
  # Mp Deplyment server drive
  #If (!(Test-Path T:))
  #  {  
  #      New-PSDrive -Name T -PSProvider FileSystem -Root '\\172.30.16.98\Volumne_1' -Persist    
  #  }
  
  $getDate = GET-DATE -UFORMAT "%Y%m%d"

  #DEployment file  Change this for new deployment
  $deploypath ="\\172.30.16.98\Volume_1\_Sabrina\_temp\RollOut - VAMPIRENET\" 
  $deployfile ="CDD.RPT"
  $backupfile ="CDD" + $getDate + ".RPT"

  #GEt IP Address from Branch
  $ConnectionString ="server=" + $mySQLServer + ";port=3307;uid=s;pwd=s;database="+$databaseName
  [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  $Connection.ConnectionString = $ConnectionString
  $Connection.Open()
  $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($mySQLQuery, $Connection)
  $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
  $DataSet = New-Object System.Data.DataSet
  $RecordCount = $dataAdapter.Fill($DataSet, "data")    
  

  foreach ($Row in $DataSet.Tables[0].Rows)
  { 
       $IndConnStr = $Row["ConnectionString"]   
       $IndIP = $Row["IP"]
       $Branchcode = $Row["branchcode"]

       #$outLetPC = "\\" + $IndIP + "\c$\Administrative\" 
       #$outLetPC= "\\" + $IndIP + "\Administrative\" 
        
       Write-Host "  "
       Write-Host "Process: $($Branchcode) - $($IndDB) - $($IndIP)"
       
       #Take care sub pc       
       
       $IndIP_1st= $IPRegEx.Match($IndIP).Value   
       $IndIP_Last= $IPRegExLast.Match($IndIP).Value
       $intIP = [int]$IndIP_Last


       #http://regexstorm.net/tester
              
       #For ($i=$intIP; 1; $i++)
       #foreach ($i in $intIP..$intIP+1)
       #$arrIP = 10,11,12,13,14,15,30,40,41       
       $arrIP = 11       
       #foreach ($i in 10..11)
       Foreach ($i in $arrIP)
       {
           
           $loopIndIP=$IndIP_1st +"." + [String]$i

           $outLetPC1 = "\\" + $loopIndIP + "\c$\Administrative\Application\" 
           $outLetPC2 = "\\" + $loopIndIP + "\Administrative\Application\" 
           $DestPath =""

           $TestPath = $outLetPC1 

           
           $Cred = Get-Credential
           
           [Bool]$valid =Test-Path $TestPath -Credential $Cred

           if (!($valid))
           {
                $TestPath = $outLetPC2 
                $valid =Test-Path $TestPath 
                if($valid) 
                {
                    $outLetPC = $outLetPC2
                }
           }            
           else
           {
                $outLetPC = $outLetPC1
           }
           
           if (!($valid))
           {
                  Write-Host "ERROR : Fail to Map OutLet : $($Branchcode) -  $($loopIndIP) "  
                  continue
           }           
           $valid = $false

           Write-Host "Process PC with IP Address: $($loopIndIP)"

           # Map OutLet Main PC      
           # New-PSDrive -Name U -PSProvider FileSystem -Root $outLetPC -Persist               
           $outletpath1 =$outLetPC + "VAMPIRESNET\VampiresNET\Template\Crystal\"
           $outletpath2 = $outLetPC + "VAMPIRESNET\Template\Crystal\"
           $TestPath = $outletpath1 +"*"
           $valid =Test-Path $TestPath -PathType leaf
               
           IF ($valid)
           {
                $DestPath = $outletpath1                       
                Write-Host $DestPath
           }       
           ELSE
           {
                $TestPath = $outletpath2 +"*"
                $valid =Test-Path $TestPath -PathType leaf
                if ($valid)
                {
                    $DestPath = $outletpath2            
                }            
           }

           IF (!$valid)
           {
                Write-Host "ERROR : Fail to Copy file"  
           }
           else
           {
               $SourceFilePath = $DestPath + $deployfile
               $DestFilePath = $DestPath + $backupfile

               #Backup existing CDD.Rpt
               #Write-Host "BAckup:" + $SourceFilePath + "~" + $DestFilePath
               #Copy-Item $SourceFilePath -Destination $DestFilePath
               BackupnCopy $SourceFilePath $DestFilePath "Backup"


               #Copy CDD from Deployment Server to Outlet
               $SourceFilePath = $deploypath + $deployfile
               $DestFilePath = $DestPath 

               #Write-Host "COPY: " + + $SourceFilePath + "~" + $DestFilePath
               #Copy-Item $SourceFilePath -Destination $DestFilePath
               BackupnCopy $SourceFilePath $DestFilePath "Copy"
   
               Write-Host "SUCESS : ($loopIndIP) -  $Branchcode " $DestPath + $deployfile    
               write-Host "---------------------------------------------------------------" 

           }

       }  
   }
}   
Catch 
{
  
  Write-Host "ERROR : `n$Error[0]"  
 }
 
Finally {
  $Connection.Close()
  #Remove-PSDrive T
  }