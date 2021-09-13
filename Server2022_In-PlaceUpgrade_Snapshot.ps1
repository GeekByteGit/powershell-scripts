##  Microsoft Server 2022 In-Place Upgrade + Snapshot Automation
##
##  For detailed usage instructions visit:
##  https://www.geekbyte.com/post/part-1-microsoft-server-2022-azure-vm-in-place-upgrade-automation
##
##  Before running the script modify line:
##  203 - Add your storage account name, file share name, file share path, and shared access signature token.
##
##  This script pefroms the following functions:
##  Elevates as Administrator
##  Switches to TLS 1.2
##  Installs Az Modules and prerequisites
##  Asks for user inputs:
##      Subscription
##      Resource Group
##      Location
##      (Computer name is auto-extracted)
##  Takes a snapshot of the Operating System (OS) drive and saves it to the same resource group the server resides
##  Creates a new folder C:\Server2022-InPlaceUpgrade
##  Installs AzCopy
##  Downloads Server 2022 locally to the folder created above
##  Mounts the Server 2022 ISO and begins an in-place upgrade to Server 2022 Datacenter with Desktop Experience

param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

Write-Host 'Please wait while the script loads with full admin privileges! A Microsoft login window will appear momentarily.' -ForegroundColor Green


## Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

## Install Az Modules and prerequisites
Install-PackageProvider -Name "NuGet" 
Install-Module -Name Az -AllowClobber 
Import-Module Az
Connect-AzAccount

## User inputs
Get-AzSubscription | Out-Null
$subscriptionInput = Read-Host  -Prompt "Enter the Subscription name"
Write-Host "The entered Subscription is" $subscriptionInput -ForegroundColor Green
Select-AzSubscription -Subscription "$subscriptionInput"

$resourceGroupNameInput = Read-Host -Prompt "Enter the Resource Group name" 
Write-Host "The entered Resource Group name is" $resourceGroupNameInput -ForegroundColor Green
$resourceGroupName = "$resourceGroupNameInput"
$locationInput = Read-Host -Prompt "Enter the Location e.g., West US 2"
Write-Host "The entered Location is" $locationInput -ForegroundColor Green
$location = "$locationInput"
#$vmNameInput = Read-Host -Prompt "Enter the VM name"
$vmNameInput = $env:COMPUTERNAME
Write-Host "The entered VM name is" $vmNameInput -ForegroundColor Green
$vmName = "$vmNameInput"

$vm = Get-AzVM -Name $vmName `
               -ResourceGroupName $resourceGroupName

## Snapshot configuration
Write-Host "Taking a snapshot of the OS drive and saving to the RG" -ForegroundColor Green
$snapshotConfig =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
                                        -Location $location `
                                        -CreateOption copy `
                                        -SkuName Standard_LRS

## Take Snapshot and save to same RG
$timestamp = Get-Date -Format yyMMddThhmmss
$snapshotName = ($vmName+$timestamp)
                                         
New-AzSnapshot -Snapshot $snapshotConfig `
               -SnapshotName $snapshotName `
               -ResourceGroupName $resourceGroupName

## Create new folder to store Server 2022 ISO
New-Item -Path "c:\" -Name "Server2022-InPlaceUpgrade" -ItemType "directory" -Force

## AzCopy Installation
Write-Host "Installing  AzCopy locally" -ForegroundColor Green
$scriptName = "AzCopy_Download_and_Silent_Installation"
$adminToolsFolderName = "_Admin_Tools"
$adminToolsFolder = "C:\" + $adminToolsFolderName +"\"
$itemType = "Directory"
$azCopyFolderName = "AzCopy"
$azCopyFolder = $adminToolsFolder + $azCopyFolderName 
$azCopyUrl = (curl https://aka.ms/downloadazcopy-v10-windows -MaximumRedirection 0 -ErrorAction silentlycontinue).headers.location
$azCopyZip = "azcopy.zip"
$azCopyZipLocation = $adminToolsFolder + $azCopyZip

$writeEmptyLine = "`n"
$writeSeperator = " - "
$writeSpace = " "
$global:currentTime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currentTime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"

##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if running as Administrator, otherwise close the PowerShell window

$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdministrator = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($IsAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperator + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 5
    exit
}
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Start script execution

Write-Host ($writeEmptyLine + "#" + $writeSpace + $scriptName + $writeSpace + "Script started" + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Create C:\_Admin_Tools folder if not exists

If(!(test-path $adminToolsFolder))
{
New-Item -Path "C:\" -Name $adminToolsFolderName -ItemType $itemType -Force | Out-Null
}

Write-Host ($writeEmptyLine + "#" + $writeSpace + $adminToolsFolderName + $writeSpace + "folder available" + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Delete AzCopy folder if already exists in _Admin_Tools folder

If(test-path $azCopyFolder)
{
Remove-Item $azCopyFolder -Recurse | Out-Null
}

Write-Host ($writeEmptyLine + "#" + $writeSpace + $azCopyFolderName + $writeSpace + "folder not available" + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Write Download started

Write-Host ($writeEmptyLine + "#" + $writeSpace + $azCopyFolderName + $writeSpace + "download started" + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Download, extract and cleanup the latest AzCopy zip file
 
Invoke-WebRequest $azCopyUrl -OutFile $azCopyZipLocation
Expand-Archive -LiteralPath $azCopyZipLocation -DestinationPath $adminToolsFolder -Force
Remove-Item $azCopyZipLocation

Write-Host ($writeEmptyLine + "#" + $writeSpace + "azcopy.exe available" + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Rename AzCopy folder

$azCopyOriginalFolderName = Get-ChildItem -Path $adminToolsFolder -Name azcopy*
$azCopyFolderToRename = $adminToolsFolder + $azCopyOriginalFolderName
$azCopyFolderToRenameTo = $adminToolsFolder + $azCopyFolderName

Rename-Item $azCopyFolderToRename $azCopyFolderToRenameTo

Write-Host ($writeEmptyLine + "#" + $writeSpace + "azcopy folder renamed to" + $writeSpace + $azCopyFolderName + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Add the AzCopy folder to the Path System Environment Variables

[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$azCopyFolderToRenameTo", "Machine")

Write-Host ($writeEmptyLine + "#" + $writeSpace + "The directory location of the AzCopy executable is added to the system path" + $writeSpace `
+ $writeSeperator + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine 
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "#" + $writeSpace + "Script completed" + $writeSeperator + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Download Server 2022 to C:\Server2022-InPlaceUpgrade
Write-Host "Downloading Server 2022 from Azure" -ForegroundColor Green
C:\_Admin_Tools\AzCopy\AzCopy.exe copy "https://<storage-account-name>.file.core.windows.net/<file-share-name>/<file-path><SAS-token>" "C:\Server2022-InPlaceUpgrade\Server2022.iso" --preserve-smb-permissions=true --preserve-smb-info=true

Start-Sleep -s 5

## Mount Server 2022 ISO
Write-Host "It may say transfer failed, ignore that statement... Installing Server 2022 In-Place Upgrade" -ForegroundColor Green
$vol = Mount-DiskImage C:\Server2022-InPlaceUpgrade\Server2022.iso  -PassThru |
	Get-DiskImage | 
	Get-Volume
$installer = "{0}:\setup.exe" -f $vol.DriveLetter
Start-Process $installer -ArgumentList "/auto upgrade /imageindex 4"
