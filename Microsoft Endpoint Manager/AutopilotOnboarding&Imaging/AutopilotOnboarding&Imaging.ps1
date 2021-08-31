## GeekByte.com Intune Autopilot Imaging Automation Script


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

# Disable BitLocker
Write-Output "4. Disabling BitLocker"
Disable-BitLocker -MountPoint “C:” -ErrorAction SilentlyContinue

If ($error) {
    Write-Warning -Message 'BitLocker is already disabled...';
}

# BIOS Update
Write-Output "5. Checking for Lenovo BIOS update"
Install-Module -Name LSUClient -Force -Confirm:$False | Out-Null
Import-Module LSUClient
$updates = Get-LSUpdate | Where-Object { $_.Category -eq 'BIOS UEFI' }
$updates | Save-LSUpdate
$updates | Install-LSUpdate -SaveBIOSUpdateInfoToRegistry -Verbose

If ($error) {
    Write-Warning -Message 'No BIOS update required...';
}

# Enable Virtualization Technology
Write-Output "6. BIOS: Enabling Virtualization Technology"
(Get-WmiObject -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("Intel(R) Virtualization Technology,Enabled") | Out-Null
(Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("VT-d,Enabled") | Out-Null
(Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("TxT,Enabled") | Out-Null

# Enable TPM Security Chip
Write-Output "7. BIOS: Enabling TPM"
(Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("Security Chip,Active") | Out-Null

# Enable Secure Boot
Write-Output "8. BIOS: Enabling Secure Boot"
(Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("Secure Boot,Enabled") | Out-Null

# Save BIOS changes
Write-Output "9. BIOS: Saving changes..."
(Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings() | Out-Null

# Run Windows 10 Setup.exe from above directory
Write-Output "10. Installing a clean version of Windows 10"
Start-Process -Filepath "Setup.exe" -ArgumentList "/auto clean"