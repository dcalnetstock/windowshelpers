# Define the URL for the Google Chrome installer
# Author: Daniel Callister

$chromeInstallerUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"

# Define the path where you want to save the installer
$installerPath = "C:\ChromeInstaller.exe"

# Download the Google Chrome installer
Invoke-WebRequest -Uri $chromeInstallerUrl -OutFile $installerPath

# Install Google Chrome silently
Start-Process -FilePath $installerPath -ArgumentList "/silent /install" -Wait

# Clean up the installer file (optional)
Remove-Item -Path $installerPath
