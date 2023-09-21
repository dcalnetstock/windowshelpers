# Author: Daniel Callister
# Date  : 21 Sept 2023

# Important Variables:
$vaultAddress = $Env:VAULT_AGENT_ADDR
$vaultToken = $Env:VAULT_TOKEN
$kvPath = "netsuite/"
$todaysDate = Get-Date -Format "yyyy-MM-dd"
$backupDirectory = "C:\NETSTOCK\-Backups\vault\$todaysDate"
$backupZipDir = "C:\NETSTOCK\-Backups\archives"
$backupZipTarget = "${backupZipDir}/${todaysDate}.zip" 
$gpgKeyTarget = "sysadmin+devops-test@netstock.co"

# Compress-Directory -SourceDirectory "C:\Path\To\SourceDirectory" -OutputZipFile "C:\Path\To\Output.zip"
function Compress-Directory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputZipFile
    )

    # Check if the source directory exists
    if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
        Write-Host "Source directory $SourceDirectory not found."
        return
    }

    # Compress the directory into a ZIP file
    try {
        Compress-Archive -Path $SourceDirectory -DestinationPath $OutputZipFile -Force
        Write-Host "Directory $SourceDirectory compressed to $OutputZipFile"
    } catch {
        Write-Host "Failed to compress the directory. Error: $($_.Exception.Message)"
    }
}

# Usage example:
# Encrypt-ZipFileWithGpg4win -InputZipFile "C:\Path\To\Input.zip" -OutputEncryptedFile "C:\Path\To\EncryptedOutput.gpg" -RecipientKeyID "recipient@example.com"
function Encrypt-ZipFileWithGpg4win {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputZipFile,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputEncryptedFile,
        
        [Parameter(Mandatory = $true)]
        [string]$RecipientKeyID
    )

    # Check if the input ZIP file exists
    if (-not (Test-Path -Path $InputZipFile -PathType Leaf)) {
        Write-Host "Input ZIP file $InputZipFile not found."
        return
    }

    # Ensure that the output directory exists
    $outputDirectory = (Get-Item -Path $OutputEncryptedFile).Directory.FullName
    if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
        New-Item -Path $outputDirectory -ItemType Directory | Out-Null
    }

    # Encrypt the ZIP file using Gpg4win and save it to the output file
    $command = "gpg --encrypt --recipient $RecipientKeyID --output '$OutputEncryptedFile' '$InputZipFile'"
    Invoke-Expression -Command $command

    Write-Host "ZIP file $InputZipFile encrypted and saved to $OutputEncryptedFile"
}

# Usage example:
# Remove-OldFiles -DirectoryPath "C:\Path\To\Directory"
function Remove-OldFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath
    )

    # Calculate the date 5 days ago
    $cutoffDate = (Get-Date).AddDays(-5)

    # Get a list of files in the directory
    $files = Get-ChildItem -Path $DirectoryPath -File

    # Loop through the files and remove files older than 5 days
    foreach ($file in $files) {
        if ($file.LastWriteTime -lt $cutoffDate) {
            Remove-Item -Path $file.FullName -Force
            Write-Host "Removed file $($file.FullName) (Last modified: $($file.LastWriteTime))"
        }
    }

    Write-Host "Old files removed from $DirectoryPath."
}

# Remove-SecureDirectory -DirectoryPath "C:\Path\To\Directory"
function Remove-SecureDirectory {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$DirectoryPath
    )

    # Check if the directory exists
    if (Test-Path -Path $DirectoryPath -PathType Container) {
        # Securely delete the contents of files within the directory
        Get-ChildItem -Path $DirectoryPath -File | ForEach-Object {
            $file = $_.FullName
            Clear-Content -Path $file
            Write-Host "File $file has been securely deleted."
        }

        # Remove the directory
        Remove-Item -Path $DirectoryPath -Recurse -Force
        Write-Host "Directory $DirectoryPath has been securely deleted."
    } else {
        Write-Host "Directory $DirectoryPath not found."
    }
}


# Set the VAULT_ADDR environment variable to the Vault address
[Environment]::SetEnvironmentVariable("VAULT_ADDR", $vaultAddress, [EnvironmentVariableTarget]::Process)

# Create the backup directory if it doesn't exist
if (-not (Test-Path -Path $backupDirectory -PathType Container)) {
    New-Item -Path $backupDirectory -ItemType Directory
}

# Get a list of all secrets stored under the specified KV path
$secrets = vault kv list -format=json $kvPath | ConvertFrom-Json

# Loop through the list of secrets and back up each one
$charTrim = "/"
foreach ($secret in $secrets) {
	$customer = $secret.Trim($charTrim)
	$outputFile = "${customer}.json"
	$secretPath = "${kvPath}${secret}"
    $backupFilePath = Join-Path -Path $backupDirectory -ChildPath "${outputFile}"
    
    # Retrieve the secret data and save it to a JSON file
	$CustomerRawData = vault read -format=json "${secretPath}/oauth"
	$CustomerDataObject = $CustomerRawData | ConvertFrom-Json
	$dataField = $CustomerDataObject.data
	$dataField | ConvertTo-Json -Depth 3 | Set-Content -Path $backupFilePath
}

# zip a dir
# encrypt the zip
# remove any old files from dir
Compress-Directory -SourceDirectory $backupDirectory -OutputZipFile $backupZipTarget
Encrypt-ZipFileWithGpg4win -InputZipFile $backupZipTarget -OutputEncryptedFile "C:\NETSTOCK\-Backups\archives\${todaysDate}.zip.gpg" -RecipientKeyID $gpgKeyTarget
Remove-OldFiles -DirectoryPath $backupZipDir

# Remove TempFiles
Remove-SecureDirectory -DirectoryPath $backupDirectory
Clear-Content -Path $backupZipTarget
Remove-Item -Path $backupZipTarget -Force