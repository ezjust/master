$folder = "C:\ProgramData\AppRecovery\Logs1"
$folder_check = Test-Path $folder
 

function operation {
 
    $config =  Get-ChildItem –force -Path "C:\Program Files\AppRecovery\Core\CoreService\" -Filter *.config | Where-Object {$_.Name -match "Core.Service*"}
    $logs = Get-ChildItem –force -Path "C:\ProgramData\AppRecovery\Logs" -Filter "Apprecovery*" -File | Where-Object {$_.Name -notmatch "[0-9]"} | Sort LastWriteTime -Descending
    $Date = Get-Date -UFormat "%Y.%m.%d %H-%M"
    $logs_folder = New-Item -ItemType Directory -Path "C:\Temp\Core_Logs_$Date"

        foreach ($file in $logs) {
        Copy-Item $file.FullName -Destination $logs_folder -Verbose -Force
        }

    Get-ChildItem 'C:\Temp' | Where-Object {$_.CreationTime -le (Get-Date).AddDays(-7) } | Foreach-Object { Remove-Item $_.FullName -Recurse -Verbose -Force}
    Copy-Item $config.FullName -Destination $logs_folder -Verbose -Force
    $zip = "\\10.10.61.20\LinuxQA_share\Logs\Core_Logs_$Date.zip"
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($logs_folder, $zip)
        if ( $LastExitCode -eq 0 ) {
        Write-Host "$date : core logs archive has been gathered into $zip"
        Read-Host
        Exit 0
        }
        }
if ($folder_check -eq $true) {
operation
}
else {
     Write-Host "Path to apprecovery logs doesn't exist at C:\ProgramData\AppRecovery\Logs write it mannually (For Example: E:\ProgramData\AppRecovery\Logs_Folder) or skip by pressing Enter: "
     $logs_folder=Read-Host
     $folder_check = Test-Path -IsValid $logs_folder
     if ($folder_check -eq $true) {
     operation
     }
     else {
     Write-Host -foregroundcolor "DarkYellow" "Skipped...folder doesn't exist"
     Exit 1
     }
}
