
Clear-Host
$path = "C:\Src\2013SB\Tools\"

$files = Get-ChildItem $path* -Recurse
foreach ($file in $files)
{
    Write-Host "Removing:" $file.FullName
    
    # turn off ready only flag
    try
	{
		Set-ItemProperty $file -name IsReadOnly -value $false
	}
	catch{}
		    
    #remove local file
    Remove-Item $file
}
