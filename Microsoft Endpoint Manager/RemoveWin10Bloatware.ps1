## Removes the bloatware installed by default on Windows 10
## Deploy this script to all devices or a dynamic device group
## GeekByte.com

# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Value added to the RemovedApps.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "RemovedApps.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"
    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to RemovedApps.log file"
    }
}
# Get a list of all apps
Write-LogEntry -Value "Starting appx package removal"
$AppArrayList = Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name
# White list of appx packages to keep installed
$WhiteListedApps = @(
    "Microsoft.CompanyPortal",
    "Microsoft.BingWeather", 
    "Microsoft.DesktopAppInstaller", 
    "Microsoft.HEIFImageExtension"
    "Microsoft.MicrosoftStickyNotes", 
    "Microsoft.MSPaint",
    "Microsoft.ScreenSketch",
    “Microsoft.StorePurchaseApp”,
    “Microsoft.VP9VideoExtensions”,
    “Microsoft.WebMediaExtensions”,
    "Microsoft.WebpImageExtension”,
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsAlarms”,
    "Microsoft.WindowsCalculator”,
    "Microsoft.WindowsCamera”,
    "Microsoft.WindowsMaps”,
    "Microsoft.WindowsSoundRecorder”,
    "Microsoft.WindowsStore",
    "Microsoft.549981C3F5F10",
    "Microsoft.Windows.Cortana"
)
# Loop through the list of appx packages
foreach ($App in $AppArrayList) {
    # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
    if (($App.Name -in $WhiteListedApps)) {
        Write-LogEntry -Value "Skipping excluded application package: $($App.Name)"
    }
    else {
        # Gather package names
        $AppPackageFullName = Get-AppxPackage -Name $App.Name | Select-Object -ExpandProperty PackageFullName
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName
        # Attempt to remove AppxPackage
        try {
            Write-LogEntry -Value "Removing application package: $($AppPackageFullName)"
            Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }
        # Attempt to remove AppxProvisioningPackage
        if ($null -ne $AppProvisioningPackageName ) {
            try {
                Write-LogEntry -Value "Removing application provisioning package: $($AppProvisioningPackageName)"
                Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message
            }
        }
    }
}