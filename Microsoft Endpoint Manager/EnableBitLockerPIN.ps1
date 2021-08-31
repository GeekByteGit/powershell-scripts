## Enables the BitLocker PIN with a default 123456
## GeekByte.com

$AllProtectors = (Get-BitlockerVolume -MountPoint $env:SystemDrive).KeyProtector 
$RecoveryProtector = ($AllProtectors | where-object { $_.KeyProtectorType -eq "TPMPin"})

if(!($RecoveryProtector)){
    Get-BitLockerVolume -MountPoint "C:" | Add-BitLockerKeyProtector -Pin (ConvertTo-SecureString "123456" -AsPlainText -Force) -TpmAndPinProtector
}