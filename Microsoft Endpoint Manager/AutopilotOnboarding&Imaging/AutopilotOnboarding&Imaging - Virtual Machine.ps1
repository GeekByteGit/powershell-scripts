## Geekbyte.com Intune Autopilot Imaging Automation -Virtual Machine Script


Write-Output "Welcome to GeekByte's Intune Autopilot Imaging Automation" `n;

#Run script from current directory
function global:Write-Host() {}
Push-Location $PSScriptRoot

Write-Host CurrentDirectory $CurDir

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
 
# Run your code that needs to be elevated here
#Write-Host -NoNewLine "Press any key to continue..."
#$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Install NuGet Provider
Write-Output "1. Installing NuGet"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$False | Out-Null

# Install Azure Autopilot modules
Write-Output "2. Installing Azure Autopilot modules"
Install-Script -Name Upload-WindowsAutopilotDeviceInfo -Force -Confirm:$False

# Determine Regular vs Development Laptop
$title = 'Determine Laptop Type'
$question = 'Is this a developer laptop?'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Output "3. Gather & upload device info to GeekByte's Azure tenant"
    Upload-WindowsAutopilotDeviceInfo.ps1 -TenantName "YourTenantHere" -GroupTag "Developer" -Verbose
} else {
    Write-Output "3. Gather & upload device info to GeekByte's Azure tenant"
    Upload-WindowsAutopilotDeviceInfo.ps1 -TenantName "YourTenantHere" -GroupTag "Standard" -Verbose
}

# Wait for upload to complete
Write-Output "Sleeping..."
Start-Sleep -s 10

# Run Windows 10 Setup.exe from above directory
Write-Output "10. Installing a clean version of Windows 10"
Start-Process -Filepath "Setup.exe" -ArgumentList "/auto clean"