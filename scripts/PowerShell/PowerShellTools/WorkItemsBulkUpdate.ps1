#
# WorkItemsBulkUpdate.ps1
# Author:	ET
# Date:		05/20/16
# Purpose:	This script will iterate across a specific or all Team Projects for a given TPC and validate all the values currently in the work item.
#           This can correct work item values by uncommenting the save section in the inner foreach loop
#			This is primarily used to validate the results of a Team Project migration to a new template, and whether the migrated values contain valid values for the destination WIT.			
#

Clear-Host

# Referencing Assemblies in PowerShell Script

# TFS 2013
$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5"

Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"

# initialize
#$proj = "fastman_import"
#$outputFile = "C:\Temp\WorkItemValidation_$proj.txt"
#write-host "Project Name:" $proj

$proj = "*"
$outputFile = "C:\Temp\WorkItemValidation_All.QA.txt"
Write-Host "Project Name: All"

# used to set values for bulk corrections
$invalidValue = "Taylor,Everett"
$validValue = "Everett Taylor"
$fieldReferenceName = "System.AssignedTo"

# Connect to TFS
$tfsCollectionUrl = "https://tfsqa.mmm.com/tfs/ProductionCollection"
Write-Host "Connecting to Team Foundation Server [" $tfsCollectionUrl "]"
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

# Use this to target a specific Team Project
<#
$WIQL = @"
SELECT [System.Id], [System.WorkItemType], [System.State], [System.AssignedTo], [System.Title] 
FROM WorkItems 
WHERE [System.TeamProject] = '$proj'
ORDER BY [System.TeamProject], [System.WorkItemType], [System.Id] 
"@
#>

# Use this for all Team Projects in the TPC
$WIQL = @"
SELECT [System.Id], [System.WorkItemType], [System.State], [System.AssignedTo], [System.Title] 
FROM WorkItems 
ORDER BY [System.TeamProject], [System.WorkItemType], [System.Id] 
"@

#  Used in work item query to filter down to single user to fix all instances for that invalid user 
#  AND [System.AssignedTo] = '$invalidValue'

$workItemCollection = $workItemStore.Query($WIQL)
Write-Host "Number of work items found:" $workItemCollection.Count


$invalidItems = 0
foreach ($workItem in $workItemCollection)
{
    Write-Host "Project: " $workItem.Project.Name
    Write-Host "ID:" $workItem.Id
    Write-Host "Type:" $workItem.Type.Name
    

    $workItem.SyncToLatest()
	$invalidFields = $workItem.Validate()
    Write-Host "Invalid fields:" $invalidFields.Count

    if( $invalidFields.Count -gt 0 )
    {
        Write-Host "Invalid work item:" $workItem.Id
        Write-Host "Invalid work title:" $workItem.Title
        foreach( $invalidField in $invalidFields )
        {
            Write-Host "Invalid field name:" $invalidField.ReferenceName
            Write-Host "Invalid field status:" $invalidField.Status
            Write-Host "Invalid field value:" $workItem.Fields[$invalidField.ReferenceName].Value

            $output = "Team Project: " + $workItem.Project.Name + ", ID: " + $workItem.Id+ ", Type: " + $workItem.Type.Name + ", Field: " + $invalidField.ReferenceName + ", Status: " + $invalidField.Status + ", Title: " + $workItem.Title + ", Value: [" + $workItem.Fields[$invalidField.ReferenceName].Value + "]"
            #Write-Host $output
            $output | Out-File -FilePath $outputFile -Append
            
           # Comment this block out for -WhatIf scenarios
           <#
           # if this invalid field is the one to be corrected based on $fieldReferenceName,
           # and has the invalid value (like a specific AssignedTo person), then replace invalid value with valid value and save
            			
           if( $invalidField.ReferenceName -eq $fieldReferenceName -and $workItem.Fields[$invalidField.ReferenceName].Value -eq $invalidValue )
           {
                #  -and $workItem.Fields["System.Id"].Value -eq 36 
               $output = "Correcting: [" + $invalidValue + "] with [" + $validValue + "]"
               Write-Host $output
               $output | Out-File -FilePath $outputFile -Append
               
               $workItem.Open()
               $workItem.Fields["$fieldReferenceName"].Value = $validValue
               $workItem.Save() 
           }#>

        }
        
        Write-Host
	    $invalidItems++
    }
     
#}


}

Write-Host "Found" $invalidItems "invalid work items out of" $workItemCollection.Count "in Team Project" $proj"."

$TFS.Dispose()