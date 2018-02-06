
Write-Host "Ready to transfer files..."
$source_dir = Read-Host("Source directory")
$dest_dir = Read-Host("Destination directory")
$file = Read-Host("File name")

robocopy $source_dir $dest_dir $file /Z /R:100 /W:30



