#
# UpdateAssemblyInfoAttributes.ps1
#

Set-Location "Some local file system path to the entire local Gorilla workspace"

$versionfiles = get-childitem "assemblyinfo.cs" -recurse

foreach ($versionfile in $versionfiles)
{
    # if the item is a directory, then process it.
    if ($versionfile.Attributes -ne "Directory")
    {  
        # ET:	Change this to determine if the AssemblyInformationVersion attribute exists, and update it.
		#		If there is no attribute in the file, add it.

		(Get-Content $versionFile) |
			Foreach-Object { "Inspect the files here, and either add or replace.  Filter out the files that don't already have AssemblyInformationalVersion attribute.
								Watch out for \\ commented out attributes, just leave that there and add a non-commented out attribute entry.  Just a suggestion..." } | 
				Set-Content $versionfile.FullName -Force
				
		
    }
}

