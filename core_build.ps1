$username = "user"
$password = "password"
$downloadFolder = "z:\"
$release7 = "https://tc.appassure.com/httpAuth/app/rest/builds/branch:%3Cdefault%3E,status:SUCCESS,buildType:AppAssure_Windows_Release700_FullBuild/artifacts/children/installers"
$develop = "https://tc.appassure.com/httpAuth/app/rest/builds/branch:%3Cdefault%3E,status:SUCCESS,buildType:AppAssure_Windows_Develop20_FullBuild/artifacts/children/installers"
 
 
   
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$wc = New-Object system.net.webclient
$wc.UseDefaultCredentials = $true
$wc.Credentials = New-Object System.Net.NetworkCredential($username, $password)
[xml]$xml = $wc.DownloadString($release7)
   
foreach ( $link in $xml.files.file.content.href) {
    if ($link -like '*Core-X*' -or $link -like '*Agent-X*' -or $link -like '*CentralConsole-*' -or $link -like '*LocalMountUtility-X*') {
        $myMatch = ".*installers\/(.*-([\d.]+).exe)"
        $link -match $myMatch | out-null
        $installer = $($Matches[1])
        $dlink = "https://tc.appassure.com" + $link
        $output = Join-Path $downloadfolder -ChildPath $installer
        if ((Test-Path $output -PathType Leaf)) {
            Write-Host "$installer already exist in $downloadFolder. Skipping..."
               
        }
        else {
            Write-host "Downloading $installer to $downloadFolder..."
            $credCache = new-object System.Net.CredentialCache
            $creds = new-object System.Net.NetworkCredential($username, $password)
            $credCache.Add($dlink, "Basic", $creds)
            $wc.Credentials = $credCache
            $wc.DownloadFile($dlink, $output)
               
            Write-Host "Download of $installer completed"
        }
       
    }
}
         
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$wc = New-Object system.net.webclient
$wc.UseDefaultCredentials = $true
$wc.Credentials = New-Object System.Net.NetworkCredential($username, $password)
[xml]$xml = $wc.DownloadString($develop)
   
foreach ( $link in $xml.files.file.content.href) {
    if ($link -like '*Core-X*' -or $link -like '*Agent-X*' -or $link -like '*CentralConsole-*' -or $link -like '*LocalMountUtility-X*') {
        $myMatch = ".*installers\/(.*-([\d.]+).exe)"
        $link -match $myMatch | out-null
        $installer = $($Matches[1])
        $dlink = "https://tc.appassure.com" + $link
        $output = Join-Path $downloadfolder -ChildPath $installer
        if ((Test-Path $output -PathType Leaf)) {
            Write-Host "$installer already exist in $downloadFolder. Skipping..."
               
        }
        else {
            Write-host "Downloading $installer to $downloadFolder..."
            $credCache = new-object System.Net.CredentialCache
            $creds = new-object System.Net.NetworkCredential($username, $password)
            $credCache.Add($dlink, "Basic", $creds)
            $wc.Credentials = $credCache
            $wc.DownloadFile($dlink, $output)
               
            Write-Host "Download of $installer completed"
        }
       
    }
}
