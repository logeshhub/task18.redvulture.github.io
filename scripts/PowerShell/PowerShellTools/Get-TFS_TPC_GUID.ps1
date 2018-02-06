# ET - 06/01/2016 - Modified script to pull correct TFS instance ID

Clear-host

# TFS 2013
$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5"

Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.VersionControl.Client.dll"

# Development Instance
#TFS Server Collection
[string] $tfsUrlDEV = "https://tfsdev.mmm.com/tfs"
[string] $tfsCollectionUrlDEV = "https://tfsdev.mmm.com/tfs/DefaultCollection"

# get the TFS instance
$tfsDEV = [Microsoft.TeamFoundation.Client.TfsConfigurationServerFactory]::GetConfigurationServer($tfsUrlDEV)
$tfsDEV.EnsureAuthenticated()

if (!$tfsDEV.HasAuthenticated)
{
  Write-Host "Failed to authenticate to development instance."
  exit
} 
Write-Host "Authenticated to development instance."
Write-Host "Connected to development Team Foundation Server [" $tfsUrlDEV "]"
Write-Host

#Get Team Project Collection
$teamProjectCollectionDEV = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsCollectionUrlDEV)
Write-Host "Connected to development Team Project Collection [" $tfsCollectionUrlDEV "]"

# Write to console window
Write-Host "Development Instance:"
Write-Host "TFS GUID = "  $tfsDEV.InstanceId
Write-Host "TPC GUID = "  $teamProjectCollectionDEV.InstanceId
Write-Host

$tfsDEV.Dispose()
$teamProjectCollectionDEV.Dispose()

# QA Instance ********************************************
#TFS Server Collection
[string] $tfsUrlQA = "https://tfsqa.mmm.com/tfs"
[string] $tfsCollectionUrlQA = "https://tfsqa.mmm.com/tfs/DefaultCollection"

# get the TFS instance
$tfsQA = [Microsoft.TeamFoundation.Client.TfsConfigurationServerFactory]::GetConfigurationServer($tfsUrlQA)
$tfsQA.EnsureAuthenticated()

if (!$tfsQA.HasAuthenticated)
{
  Write-Host "Failed to authenticate to QA instance."
  exit
} 
Write-Host "Authenticated to QA instance."
Write-Host "Connected to QA Team Foundation Server [" $tfsUrlQA "]"
Write-Host

#Get Team Project Collection
$teamProjectCollectionQA = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsCollectionUrlQA)
Write-Host "Connected to QA Team Project Collection [" $tfsCollectionUrlQA "]"
Write-Host

# Write to console window
Write-Host "QA Instance:"
Write-Host "TFS GUID = "  $tfsQA.InstanceId
Write-Host "TPC GUID = "  $teamProjectCollectionQA.InstanceId
Write-Host

$tfsQA.Dispose()
$teamProjectCollectionQA.Dispose()

# Production Instance *****************************
[string] $tfsUrlPROD = "https://tfs.mmm.com/tfs"
[string] $tfsCollectionUrlPROD = "https://tfs.mmm.com/tfs/DefaultCollection"

# get the TFS instance
$tfsPROD = [Microsoft.TeamFoundation.Client.TfsConfigurationServerFactory]::GetConfigurationServer($tfsUrlPROD)
$tfsPROD.EnsureAuthenticated()

if (!$tfsPROD.HasAuthenticated)
{
   Write-Host "Failed to authenticate to production instance."
  exit
} 
Write-Host "Authenticated to production instance."
Write-Host "Connected to production Team Foundation Server [" $tfsCollectionUrlPROD "]"

#Get Team Project Collection
$teamProjectCollectionPROD = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsCollectionUrlPROD)
Write-Host "Connected to production Team Project Collection [" $tfsUrlPROD "]"
Write-Host

# Write to console window
Write-Host "Production Instance:"
Write-Host "TFS GUID = "  $tfsPROD.InstanceId
Write-Host "TPC GUID = "  $teamProjectCollectionPROD.InstanceId
Write-Host

$tfsPROD.Dispose()
$teamProjectCollectionPROD.Dispose()

