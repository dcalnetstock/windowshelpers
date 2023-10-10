$BackupDirectory = "C:\restore\Sched_Tasks"

# Get a list of XML files in the specified directory.
$XmlFiles = Get-ChildItem $BackupDirectory -Filter "*.xml"

foreach ($XmlFile in $XmlFiles) {
    # Extract the task name from the XML file name (remove the .xml extension).
    $TaskName = $XmlFile.BaseName

    # Register the scheduled task using the XML content from the file.
    Register-ScheduledTask -Xml (Get-Content $XmlFile.FullName | Out-String) -TaskName $TaskName

    Write-Host "Imported task: $TaskName"
}