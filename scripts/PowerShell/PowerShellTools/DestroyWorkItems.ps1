Clear-Host

# Referencing Assemblies in PowerShell Script
# TFS 2010
$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\ReferenceAssemblies\v2.0"
$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\ReferenceAssemblies\v4.0"

# TFS 2013
#$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
#$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5"

Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.VersionControl.Client.dll"

# Only 2013 and above
#Add-Type -Path "$pathToAss4\Microsoft.TeamFoundation.ProjectManagement.dll"

# Connect to TFS

$tfsCollectionUrl = "http://localhost:8080/tfs/Connecticut"
$teamProjectName = "Connecticut";
$TFS = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsCollectionUrl)
               
$TFS.EnsureAuthenticated()

if (!$TFS.HasAuthenticated)
{
  Write-Host "Failed to authenticate to TFS"
  exit
} 
Write-Host "Connected to Team Foundation Server [" $tfsCollectionUrl "]"

$server = new-object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection(New-Object Uri($tfsCollectionUrl))

# Create WorkItemStore
$workItemStore = $server.GetService([Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore])
$getProjectName = $workItemStore.Projects.Name

foreach ($proj in $getProjectName)
{
    write-host "Project Name:" $teamProjectName
}

#Get single Team Project
$singleProj = $workItemStore.Projects[$teamProjectName]

$WIQL = @"
SELECT [System.Id], [System.WorkItemType], [System.State], [System.AssignedTo], [System.Title] 
FROM WorkItems 
where [System.TeamProject] = '$teamProjectName' 
ORDER BY [System.WorkItemType], [System.Id] 
"@

#$workitemcollection = $server.GetService([Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemCollection])

$workitemcollection = $workItemStore.Query($WIQL)

# create Ienumerable of type Int
$IdToDestroy = new-object System.Collections.Generic.List[int]

$destroyedItems = 0
foreach ($Witem in $workitemcollection)
{
    Write-Host "WorkItem ID:" $Witem.Id
    
    $IdToDestroy.Add($Witem.Id)
	$destroyedItems++
}

#Destroy all the work items of the team Project.
$workItemStore.DestroyWorkItems($IdToDestroy)

Write-Host "Destroyed" $destroyedItems "work items."

