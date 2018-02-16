#ATTENTION!!!MAKE SURE THAT aria2c is downloaded and configured on your system (for 16flows downloading. Manual is here https://www.youtube.com/watch?v=LS-VmSmtaWg)
#
#Preset of variables. Note: $password and QA.lic (Core license file) file should exists in current directory. Also if LOGS folder is not default please change $folder path
$downloadFolder = split-path -parent $MyInvocation.MyCommand.Definition
$username = "dev-softheme"
$password = Get-Content "$downloadFolder\devuser_tc.txt"
$folder = "C:\ProgramData\AppRecovery\Logs"
$down_log = "$downloadFolder\downloading.log"

#SMTP settings
$User = "ezjusy"
$Pass = "ezJUST3009"

$From = "ezjusy@gmail.com"
$To = "3spirit3@ukr.net"
$emailSmtpServer = "smtp.gmail.com"
$emailSmtpServerPort = "587"

#Getting branch version develop or release
$folder_check = Test-Path $folder
$log = "$folder\AppRecoveryInstallation.log"

if ($folder_check -eq $true) {
$log_check = Test-Path $log
$build_num = (Select-String $log -pattern "Build number: " | Out-String ) 
    if ($log_check -eq $true) {
        ForEach-Object -Process {
        $result = $build_num.Split("Build number: ")[-1]
        }
        $branch = $result.Remove(5)
    }
    else { Write-Host -foregroundcolor yellow "file AppRecoveryInstallation.log doesn't exist at C:\ProgramData\AppRecovery\Logs please enter branch number manually:"
    $branch=Read-Host
    }
}

#Branch version should be filled if Core is not installed

else { Write-Host -foregroundcolor yellow "Core is not installed, please enter branch version for installation. For example 6.2.0 or 7.1.0"
$branch=Read-Host
}
#Dates in different formats
$date_time=Get-Date
$date=Get-Date -UFormat "%m/%d/%Y"
$date_=Get-Date -UFormat "%Y-%m-%d"

#Installation of latest downloaded build for last 105 minutes
function install_core {
$last_build=Get-ChildItem $downloadFolder\* -Include *.exe | Where{$_.LastWriteTime -gt (Get-Date).AddMinutes(-105)} | Select-Object -first 1 | Select -exp Name
$com = "$downloadFolder\$last_build"
$com_args = @(
"/silent",
"licensekey=$downloadFolder\QA.lic",
"reboot=asneeded"
)
$install = Start-Process -FilePath "$com" -ArgumentList $com_args -Wait -PassThru
}
return $install.ExistCode
#Delete builds those are older than 3 days in folder
$extension="*.exe"
$days="2"
$lastwrite = (get-date).AddDays(-$days)
Get-ChildItem -Path $downloadFolder -Include $extension -Recurse | Where {$_.LastWriteTime -lt $lastwrite} | Remove-Item


#Set Permissions for log file, to allow send it via mail, BE SURE that all needed files such are Process.log and last_installation.log and other "new added" files EXIST in the installation folder

function change_perm {
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ("Users","FullControl","Allow")

foreach ($file in $(Get-ChildItem $downloadFolder -Exclude *devuser_tc.txt -Recurse )) {
  
  $acl=get-acl $file.FullName
 
  #Add this access rule to the ACL
  $acl.SetAccessRule($Ar)
  
  #Write the changes to the object
  set-acl $File.Fullname $acl
  }
}

# Set $artlink depends on $branch

if ($branch -eq "6.2.0") {
$artilink = "https://tc.appassure.com/httpAuth/app/rest/builds/branch:%3Cdefault%3E,status:SUCCESS,buildType:AppAssure_Windows_Release700_FullBuild/artifacts/children/installers"
}
elseif ($branch -eq "7.1.0") {
$artilink = "https://tc.appassure.com/httpAuth/app/rest/builds/branch:%3Cdefault%3E,status:SUCCESS,buildType:AppAssure_Windows_Develop20_FullBuild/artifacts/children/installers"
}
else {
Write-Error "$date : branch has been set in wrong way, there is no such $branch available on the teamcity" >> $down_log
}


# Validating artifacts link on the team city

$HTTP_Request = [System.Net.WebRequest]::Create($artilink)
$HTTP_Request.Credentials = new-object System.Net.NetworkCredential($username, $password)

# We then get a response from the site.
$HTTP_Response = $HTTP_Request.GetResponse()
$HTTP_Status = [int]$HTTP_Response.StatusCode
$HTTP_Request.ServicePoint.CloseConnectionGroup("")

# Checking for branch and then download Core installation file if it is not exists in current folder
 
if ($HTTP_Status -eq "200") {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $wc = New-Object system.net.webclient
    $wc.UseDefaultCredentials = $true
    $wc.Credentials = New-Object System.Net.NetworkCredential($username, $password)
    [xml]$xml = $wc.DownloadString($artilink)
   
    foreach ($link in $xml.files.file.content.href) {
        if ($link -like '*Core-X*') {
            $myMatch = ".*installers\/(.*-([\d.]+).exe)"
            $link -match $myMatch | out-null
            $installer = $($Matches[1])
            $dlink = "https://tc.appassure.com" + $link
            $output = Join-Path $downloadfolder -ChildPath $installer
            if ((Test-Path $output -PathType Leaf)) {
                Write-Output "$date_time : $installer already exist in $downloadFolder. Skipping..." >> $down_log
                Write-Host -foregroundcolor cyan "Please check current directory downloading.log for details"
            }
            else {
                Write-host "Downloading $installer to $downloadFolder..."
                aria2c -x 16 -d $downloadFolder --http-user=$username --http-passwd=$password $dlink
                #very slow downloading
                #$credCache = new-object System.Net.CredentialCache
                #$creds = new-object System.Net.NetworkCredential($username, $password)
                #$credCache.Add($dlink, "Basic", $creds)
                #$wc.Credentials = $credCache 
                #$wc.DownloadFile($dlink, $output)
               
                Write-Host -foregroundcolor Green "Download of $installer completed"
            }
       
        }
    }

# Call previously set functions 
install_core
change_perm

}

else {Write-Error "$date : There are no artifacts in the last build, wait for new one or install manually" >> $down_log;}

#Collecting powershell output installation log from bat file execution
$power_logs = "$downloadFolder\Process.log"
Get-Content "$downloadFolder\powershell_execution.log" | Out-File $power_logs


#Sending e-mails and save logs of installation proccess

if ( $install.ExitCode -eq 0 ) {
Write-Output "$date_time : new Core build $installer is successfully installed" >> $down_log

$cores_ser = Get-Service -Name "*Core*" | %{$_.Status}
$mongos_ser = Get-Service -Name "*Mongo*" | %{$_.Status}
$statuses = "Mongo service status = $mongos_ser `r`nCore service status = $cores_ser"

#Message to mail

$emailMessage = New-Object System.Net.Mail.MailMessage( $From , $To )
#$emailMessage.cc.add($emailcc)
$emailMessage.Subject = "CORE UPGRADED" 
#$emailMessage.IsBodyHtml = $true #true or false depends
$emailMessage.Body = "new Core build $installer is successfully installed `r`n$statuses"
$att1 = new-object Net.Mail.Attachment($power_logs)
$emailMessage.Attachments.add($att1)
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $False
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $User , $Pass );
$SMTPClient.EnableSsl = $true;
$SMTPClient.Send( $emailMessage )

Exit 0
}
else { Write-Output "$date_time : INSTALLATION FAILED check AppRecoveryInstallation.log and Process.log for details" >> $down_log

#Collecting powershell output installation log
$last_log = "$downloadFolder\last_installation.log"
Get-Content $log | Select-String -pattern "$date", "$date_" | Set-Content $last_log


#Message to mail if core was not upgraded
$emailMessage = New-Object System.Net.Mail.MailMessage( $From , $To )
#$emailMessage.cc.add($emailcc)
$emailMessage.Subject = "CORE FAILED TO UPGRADE" 
$emailMessage.Body = "OOps...Something went wrong.Look at attached log file, maybe it could help to investigate the issue"
$emailMessage.Attachments.add($power_logs)
$emailMessage.Attachments.add($last_log)
$emailMessage.Attachments.add($down_log)
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $False
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $User , $Pass );
$SMTPClient.EnableSsl = $true;
$SMTPClient.Send( $emailMessage ) 


Exit 2
}

@' 
Directory should consist of this list of files:
1. upgrade_core script
2. password file to teamcity
3. downloading.log
4. QA.lic
5. Core-X64-build for installation
6. Process.log
7. last_installation.log

BE aware if develop and release builds would change numbers, also numbers should be changed into the script under:
if ($branch -eq "7.0.0")
if ($branch -eq "7.1.0")
'@  
