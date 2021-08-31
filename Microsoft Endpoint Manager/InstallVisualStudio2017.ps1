## Change the $argList to include optional components
## GeekByte.com

function Install-VisualStudio()
{
	
		Write-Host 'Visual Studio 2017 not detected, installing' -ForegroundColor Yellow
		$VS2017sku = 'Professional'

		$bootstrapperPath = "$env:TEMP\vs_$VS2017sku.exe"
		Invoke-WebRequest "https://aka.ms/vs/15/release/vs_$VS2017sku.exe" -OutFile $bootstrapperPath

		if (Test-Path $bootstrapperPath)
		{
			$argList = @('--wait', '--passive', '--norestart',
				'--add Component.Dotfuscator',
				'--add Microsoft.Component.VC.Runtime.UCRTSDK',
				'--add Microsoft.Net.Component.3.5.DeveloperTools',
				'--add Microsoft.VisualStudio.Component.Git',
				'--add Microsoft.VisualStudio.Component.PowerShell.Tools',
				'--add Microsoft.VisualStudio.Component.TeamOffice',
				'--add Microsoft.VisualStudio.Component.VC.ATLMFC',
				'--add Microsoft.VisualStudio.Component.VC.140',
				'--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
				'--add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop'
				'--add Microsoft.VisualStudio.Component.Windows81SDK',
				'--add Microsoft.VisualStudio.Component.WinXP',
				'--add Microsoft.VisualStudio.Workload.Azure',
				'--add Microsoft.VisualStudio.Workload.Data',
				'--add Microsoft.VisualStudio.Workload.ManagedDesktop',
				'--add Microsoft.VisualStudio.Workload.NativeDesktop',
				'--add Microsoft.VisualStudio.Workload.NetWeb',
				'--add Microsoft.VisualStudio.Workload.Office',
				'--add Microsoft.VisualStudio.Workload.VisualStudioExtension',
				'--remove Microsoft.VisualStudio.Component.LiveUnitTesting'
				)
			Start-Process -FilePath $bootstrapperPath -ArgumentList $argList -Wait
			Write-Host "VS installation finished" -ForegroundColor Green
		}
}

# Debug
# Install-VisualStudio