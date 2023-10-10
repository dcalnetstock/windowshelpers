$BackupDirectory = "C:\restore\Sched_Tasks"
$Customer = "my_customer"

$XmlFiles = Get-ChildItem $BackupDirectory -Filter "*$Customer*.xml"

foreach ($XmlFile in $XmlFiles) {
    $TaskName = $XmlFile.Name -replace '\.xml$'

    Register-ScheduledTask -Xml (Get-Content $XmlFile.FullName | Out-String) -TaskName $TaskName

    Write-Host "Imported task: $TaskName"
}