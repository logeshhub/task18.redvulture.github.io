param (
      [string]$tfsServer = "https://tfsqa.mmm.com/tfs",
        [string]$tfsLocation = "$/etfs/scripts/PowerShell",
        [string]$localFolder ="c:\LocalFolderPath"
    
    )
   $clientDll = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll"
   $versionControlClientDll = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Client.dll"
   $versionControlCommonDll = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Common.dll"
    
   #Load the Assemblies
  [Reflection.Assembly]::LoadFrom($clientDll)
   [Reflection.Assembly]::LoadFrom($versionControlClientDll)
  [Reflection.Assembly]::LoadFrom($versionControlCommonDll)
   
  #Set up connection to TFS Server and get version control
   $tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsServer)
   $versionControlType = [Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]
  $versionControlServer = $tfs.GetService($versionControlType)
    
   #Create a "workspace" and map a local folder to a TFS location
   $workspace = $versionControlServer.CreateWorkspace("PowerShellWorkspace",$versionControlServer.AuthenticatedUser)
   echo "Created Workspace "  $workspace.Name
  $workingfolder = New-Object Microsoft.TeamFoundation.VersionControl.Client.WorkingFolder($tfsLocation,$localFolder)
   $workspace.CreateMapping($workingFolder)
 

# perform get-latest on the new workspace

echo "Getting Latest Code"
$workspace.Get()
echo "GET DONE... Script Done Ready for Use"

# delete the new workspace.

 $workspace.Delete()