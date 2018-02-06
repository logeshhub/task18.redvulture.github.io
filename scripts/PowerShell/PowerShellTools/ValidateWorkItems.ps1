#
# ValidateWorkItems.ps1
# Author:	ET
# Date:		03/29/16
# Purpose:	This script will iterate across a specific or all Team Projects for a given TPC and validate all the values currently in the work item.
#			This is primarily used to validate the results of a Team Project migration to a new template, and whether the migrated values contain valid values for the destination WIT.			
#
Clear-Host

$outputFile = "C:\Temp\WorkItemValidation.txt"

# Referencing Assemblies in PowerShell Script

# TFS 2013
$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5"

Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"

# Connect to TFS
$tfsCollectionUrl = "https://tfsdev.mmm.com/tfs/DefaultCollection"
$teamProjectName = "fastman_import";
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
    write-host "Project Name:" $proj
}

#Get single Team Project
$teamProject = $workItemStore.Projects[$teamProjectName]

$WIQL = @"
SELECT [System.Id], [System.WorkItemType], [System.State], [System.AssignedTo], [System.Title] 
FROM WorkItems 
WHERE [System.TeamProject] = '$teamProjectName'
ORDER BY [System.TeamProject], [System.WorkItemType], [System.Id] 
"@
 

$workItemCollection = $workItemStore.Query($WIQL)
Write-Host "Number of work items found:" $workItemCollection.Count

# create Ienumerable of type Int
#$idToValidate = new-object System.Collections.Generic.List[int]

$invalidItems = 0
foreach ($workItem in $workItemCollection)
{
    Write-Host "ID:" $workItem.Id
    Write-Host "Type:" $workItem.Type.Name
    

    $workItem.SyncToLatest()
	$invalidFields = $workItem.Validate()
    Write-Host "Invalid fields:" $invalidFields.Count

    if( $invalidFields.Count -gt 0 )
    {

        #Write-Host "Invalid work item:" $workItem.Id
        #Write-Host "Invalid work title:" $workItem.Title
        foreach( $invalidField in $invalidFields )
        {
            Write-Host "Invalid field name:" $invalidField.ReferenceName
            Write-Host "Invalid field status:" $invalidField.Status
            Write-Host "Invalid field value:" $workItem.Fields[$invalidField.ReferenceName].Value

            $output = "Team Project: " + $workItem.Project.Name + ", ID: " + $workItem.Id+ ", Type: " + $workItem.Type.Name + ", Field: " + $invalidField.ReferenceName + ", Status: " + $invalidField.Status + ", Title: " + $workItem.Title + ", Value: " + $workItem.Fields[$invalidField.ReferenceName].Value
            #Write-Host $output
            $output | Out-File -FilePath $outputFile -Append

			# ET: 03/30/16 - Add functionality to EMAIL results to US-ETFS-Admin@mmm.com
			# Added by Vishwajeet to send the output as an attachment.
			#Send-MailMessage -SmtpServer mailserv.mmm.com -To "US-ETFS-Admin@mmm.com" -From "tfs.noreply@mmm.comm" -Subject "WorkItems Validation" -Body "Work Items Validation Output File Attached with this mail." -Attachments $outputFile


        }
        
        #Write-Host
	    $invalidItems++
    }
     
}

# ET: 03/30/16 - Add functionality to EMAIL results to US-ETFS-Admin@mmm.com
# Added by Vishwajeet to send the output as an attachment.
Send-MailMessage -SmtpServer mailserv.mmm.com -To "US-ETFS-Admin@mmm.com" -From "tfs.noreply@mmm.comm" -Subject "WorkItems Validation" -Body "Work Items Validation Output File Attached with this mail." -Attachments $outputFile

$TFS.Dispose()
Write-Host "Found" $invalidItems "invalid work items out of" $workItemCollection.Count "in Team Project" $teamProjectName"."
