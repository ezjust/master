#ATTENTION!!!MAKE SURE THAT aria2c is downloaded and configured on your system (for 16flows downloading. Manual is here https://www.youtube.com/watch?v=LS-VmSmtaWg)
#
#Preset of variables. Note: credentials.txt and QA.lic (Core license file) file should exist in current directory. Also if LOGS folder is not default please change $folder path
$downloadFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$local_user = "share"
$username = "dev-softheme"
$tc_string = Get-Content "$downloadFolder\credentials.txt" | Select-string -pattern "tc_password" -encoding ASCII | Select -First 1
$password = $tc_string -replace ".*="
$test_connection = Get-Content "$downloadFolder\credentials.txt" | Select-string -pattern "test_connection" -encoding ASCII | Select -First 1
$local_pass = $test_connection -replace ".*="
$folder = "C:\ProgramData\AppRecovery\Logs"
$inst_log = "$downloadFolder\last_installation.log"
$dies = Add-Content -Path $inst_log -Value "`n---------------------------------" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Set Security protocol

#SMTP settings
$mail_user = "linuxqateam@gmail.com"
$From = "linuxqateam@gmail.com"
$To = "3spirit3@ukr.net"
$emailSmtpServer = "smtp.gmail.com"
$emailSmtpServerPort = "587"


#LOg to file all executions of powershell

Start-Transcript -Path $inst_log

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
        if ($result) {
        $branch = $result.Remove(5)
        }
     }
        else { Write-Host -foregroundcolor yellow "file AppRecoveryInstallation.log doesn't exist at C:\ProgramData\AppRecovery\Logs please enter branch number manually:"
        $branch=Read-Host
        }
}

#Branch version should be filled if Core is not installed

else { Write-Host -foregroundcolor yellow "Core is not installed, please enter branch version for installation. For example 6.2.1 or 7.1.0"
$branch=Read-Host
}

# Set $artlink depends on $branch

$ip = Get-NetIPAddress | Where { $_.AddressFamily -like "IPv4" -and $_.InterfaceAlias -match "Ethernet" } | Select -ExpandProperty IPAddress

if ($branch -eq "6.2.1") {
$artilink = "https://tc.appassure.com/httpAuth/app/rest/builds/branch:%3Cdefault%3E,status:SUCCESS,buildType:AppAssure_Windows_Release621_FullBuild/artifacts/children/installers"
$br_name="release"
$weekdays="Wednesday"
}
elseif ($branch -eq "7.1.0") {
$artilink = "https://tc.appassure.com/httpAuth/app/rest/builds/branch:%3Cdefault%3E,status:SUCCESS,buildType:AppAssure_Windows_Develop20_FullBuild/artifacts/children/installers"
$br_name="develop"
$weekdays="Tuesday","Thursday"
}
else {
$dies
Add-Content -Path $inst_log -Value "`n***[INFO]*** $date : branch has been set in wrong way, there is no such $branch available on the teamcity" -Force
}

#Create Scheduled task in Windows manager of tasks if it is not exist

$check_task = Get-ScheduledTask -TaskName *Core_Upgrade*

if ($check_task -eq $null) {    
$Time = New-ScheduledTaskTrigger -Weekly -At 22:00 -DaysOfWeek $weekdays 
$PS = New-ScheduledTaskAction -Execute "$downloadFolder\upgrade_core.ps1"
Register-ScheduledTask -TaskName "Core_Upgrade_$br_name" -RunLevel Highest -Trigger $Time -User $local_user -Password "$local_pass" �Action $PS -Description "$br_name Core instalation or upgrade task of $branch branch"
}

#Dates in different formats
$date_time=Get-Date
$date=Get-Date -UFormat "%m/%d/%Y"
$date_=Get-Date -UFormat "%Y-%m-%d"

# Validating artifacts link on the team city

$HTTP_Request = [System.Net.WebRequest]::Create($artilink)
$HTTP_Request.Credentials = new-object System.Net.NetworkCredential($username, $password)

# We then get a response from the site.
$HTTP_Response = $HTTP_Request.GetResponse()
$HTTP_Status = [int]$HTTP_Response.StatusCode
$HTTP_Request.ServicePoint.CloseConnectionGroup("")

# Checking for branch and then download Core installation file if it is not exists in current folder

if ($HTTP_Status = "200") {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $wc = New-Object system.net.webclient
    $wc.UseDefaultCredentials = $true
    $wc.Credentials = New-Object System.Net.NetworkCredential($username, $password)
    [xml]$xml = $wc.DownloadString("$artilink")
    $wc.Dispose()
       
    foreach ($link in $xml.files.file.content.href) {
        if ($link -like '*Core-X*') {
            $myMatch = ".*installers\/(.*-([\d.]+).exe)"
            $link -match $myMatch | out-null
            $installer = $($Matches[1])
            $dlink = "https://tc.appassure.com" + $link
            $output = Join-Path $downloadfolder -ChildPath $installer
            if ((Test-Path $output -PathType Leaf)) {
                $dies
                Add-Content -Path $inst_log -Value "`n***[INFO]*** $date_time : $installer already exist in $downloadFolder. Skipping..." -Force
                Write-Host -foregroundcolor cyan "Please check current directory last_installation.log for details"
            }
        
            else {
                Write-host "Downloading $installer to $downloadFolder..."
                aria2c --check-certificate="false" -x 16 -d $downloadFolder --http-user=$username --http-passwd=$password $dlink
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
}


else { $dies; Add-Content -Path $inst_log -Value "`n***[ERROR]*** $date : There are no artifacts in the last build, wait for new one or install manually" -Force}


#Collecting powershell output installation log of bat file execution
#Get-Content "$downloadFolder\ps_exec.log" | Out-File -Append $inst_log

#Installation of latest downloaded build for last day

    $last_build=Get-ChildItem $downloadFolder\* -Include *.exe | Where{$_.LastWriteTime -gt (Get-Date).AddDays(-1)} | Select-Object -first 1 | Select -exp Name
    $com = "$downloadFolder\$last_build"
    $com_args = @(
    "/silent",
    "licensekey=$downloadFolder\QA.lic",
    "reboot=never"
    "privacypolicy=accept"
    )
    Write-Host -foregroundcolor yellow "$last_build exists in the $downloadFolder and it's started to install"
    $install = Start-Process -FilePath "$com" -ArgumentList $com_args -Wait
    $lastcom=$? 
    $install.ExitCode   
#Delete builds those are older than 3 days in folder
$extension="*.exe"
$days="2"
$lastwrite = (get-date).AddDays(-$days)
Get-ChildItem -Path $downloadFolder -Include $extension -Recurse | Where {$_.LastWriteTime -lt $lastwrite} | Remove-Item

#Set Permissions for log file, to allow send it via mail, BE SURE that all needed files such last_installation.log and other "new added" files EXIST in the installation folder


    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule ("Users","FullControl","Allow")

    foreach ($file in $(Get-ChildItem $downloadFolder -Exclude *devuser_tc.txt -Recurse )) {
  
    $acl=get-acl $file.FullName
 
    #Add this access rule to the ACL
    $acl.SetAccessRule($Ar)
  
    #Write the changes to the object
    set-acl $file.Fullname $acl
    }

#Sending notifications and save logs of installation proccess

while (($Core_Status -ne 200 -and $lastcom1 -ne $True) -and ( $count -lt 20 ))
{    
# Get a response from the Core
$count=$count+1
$Core_Request = [System.Net.WebRequest]::Create("https://localhost:8006/apprecovery/admin/")
$Core_Request.Credentials = new-object System.Net.NetworkCredential("$local_user", "$local_pass")
$Core_Response = $Core_Request.GetResponse()
$lastcom1 = $?
$Core_Status = [int]$Core_Response.StatusCode
}

Write-Host $lastcom $Core_Status $lastcom1

if ($lastcom -eq $True -and $Core_Status -eq 200 -and $lastcom1 -eq $True) {
$dies
Add-Content -Path $inst_log -Value "`n***[INFO]*** $date_time : new Core build $installer is successfully installed" -Force
#$cores_ser = Get-Service -Name "*Core*" | %{$_.Status}
Remove-Item -Path "$inst_log.old" -Force -ErrorAction Continue
Move-Item $inst_log -Destination "$inst_log.old" -Force -ErrorAction Continue

#Message to mail
<#
$emailMessage = New-Object System.Net.Mail.MailMessage( $From , $To )
$emailMessage.cc.add($emailcc)
$emailMessage.Subject = "CORE UPGRADED" 
$emailMessage.IsBodyHtml = $true #true or false depends#
$emailMessage.Body = "Server info = $core_ver`r`nnew Core build $installer is successfully installed`r`n$statuses"
$att1 = new-object Net.Mail.Attachment($power_logs)
$emailMessage.Attachments.add($att1)
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $False
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $User , $Pass );
$SMTPClient.EnableSsl = $true;
$SMTPClient.Send( $emailMessage )
#>

#Message to slack

$sl_string = Get-Content "$downloadFolder\credentials.txt" | Select-string -pattern "sl_token" -encoding ASCII | Select -First 1
$token = $sl_string -replace ".*="
$emoji=":ghost:"
$text="Server info = $ip, $br_name`r`nnew Core build $installer is successfully installed`r`n'https://localhost:8006/apprecovery/admin/' successfully validated!"
$postSlackMessage = @{token="$token";channel="qa-linux-team";text="$text";username="linux_qa-bot"; icon_emoji="$emoji"}

# Very important setting for Invoke-Webrequest, makes invoke-webrequest in the same powershell space after eralier created webclients
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null

Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body $postSlackMessage

Exit 0
}

else { 

$dies
Add-Content -Path $inst_log -Value "`n***[ERROR]*** $date_time : INSTALLATION FAILED check last_installation.log for details" -Force
$dies
Get-Content $log | Select-String -pattern "$date", "$date_" | Out-File -Append $inst_log
Remove-Item -Path "$inst_log.old"
Move-Item -Force $inst_log -Destination "$inst_log.old"

#Message to mail if core was not upgraded
$emailMessage = New-Object System.Net.Mail.MailMessage( $From , $To )
#$emailMessage.cc.add($emailcc)
$emailMessage.Subject = "CORE FAILED TO UPGRADE" 
$emailMessage.Body = "Server info = $ip, $br_name`r`nOOps...Something went wrong.Look at attached log file, maybe it could help to investigate the issue"
$emailMessage.Attachments.add("$inst_log.old")
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $False
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $mail_user , $local_pass );
$SMTPClient.EnableSsl = $true;
$SMTPClient.Send( $emailMessage ) 


Exit 2
}

Stop-Transcript

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
if ($branch -eq "6.2.1")
if ($branch -eq "7.1.0")
'@  
