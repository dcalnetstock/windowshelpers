# Define an array of software installation URLs
$softwareUrls = @(
    "https://dl.google.com/chrome/install/latest/chrome_installer.exe",
    "https://repo.saltproject.io/windows/Salt-Minion-3004.1-1-Py3-AMD64-Setup.exe",
    # Add more URLs as needed
)

# Define the installation directory where the software will be saved and installed
$installDirectory = "C:\Users\Administrator\Downloads"

# Iterate through the URLs and install the software
foreach ($url in $softwareUrls) {
    # Extract the file name from the URL
    $fileName = [System.IO.Path]::GetFileName($url)
    
    # Define the local path where the installer will be saved
    $installerPath = Join-Path -Path $installDirectory -ChildPath $fileName

    # Download the installer from the URL
    Invoke-WebRequest -Uri $url -OutFile $installerPath

    # Check the file extension to determine the installation method (e.g., .exe or .msi)
    $fileExtension = [System.IO.Path]::GetExtension($fileName)

    # Install the software based on the file extension
    if ($fileExtension -eq ".exe") {
        # For .exe files, run them silently
        Start-Process -FilePath $installerPath -ArgumentList "/silent /install" -Wait
    }
    elseif ($fileExtension -eq ".msi") {
        # For .msi files, use msiexec to install them silently
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn" -Wait
    }

    # Clean up the installer file
    Remove-Item -Path $installerPath
}

