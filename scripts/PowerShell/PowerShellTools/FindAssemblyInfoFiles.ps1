
Set-Location "D:\Builds\942\src"

$versionfiles = get-childitem "assemblyinfo.cs" -recurse
$outputFile = "C:\Temp\AssemblyFiles.txt"
Clear-Content $outputFile

foreach ($versionfile in $versionfiles)
{
    # if the item is a directory, then process it.
    if ($versionfile.Attributes -ne "Directory")
    {  
        #output name, filter to those without AssemblyInformationFileVersion
		$versionfile.FullName >> $outputFile
		
		#(Get-Content $versionfile.FullName ) |
		#	Foreach-Object { $_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyFileVersion(""$file_version"")" } | 
		#	Set-Content $versionfile.FullName -Force

		#(Get-Content $versionfile.FullName ) | 
		#	Foreach-Object { $_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyVersion(""$product_version"")" } |
		#	Set-Content $versionfile.FullName -Force
		
    }
}
