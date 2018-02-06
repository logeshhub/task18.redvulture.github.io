#Clear host
clear-host

# Referencing Assemblies in PowerShell Script
$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.VersionControl.Client.dll"
Add-Type -Path "$pathToAss4\Microsoft.TeamFoundation.ProjectManagement.dll"

# Register PowerShell commands

#Add-PSSnapin Microsoft.TeamFoundation.PowerShell

# Create function with parameters

function Get-TPC-VersionControl-Info

{

    Param([Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
		[string] $tfsCollectionUrl,
		  [Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
          [string] $teamProjectName)

# Connect to TFS

#$tfsCollectionUrl = "https://tfsqa.mmm.com/tfs/DefaultCollection"
#$teamProjectName = "Ensemble";
$TFS = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsCollectionUrl)
               
$TFS.EnsureAuthenticated()

if (!$TFS.HasAuthenticated)
{
  Write-Host "Failed to authenticate to TFS"
  exit
} 
Write-Host "Connected to Team Foundation Server [" $tfsCollectionUrl "]"

$server = new-object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection(New-Object Uri($tfsCollectionUrl))

$versionControlServer = $server.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer])

$teamProjectsList = $versionControlServer.GetAllTeamProjects($true)

foreach($projectName in $teamProjectsList)
{
     if($projectName.Name -like  $teamProjectName)
     {
             Write-host "Team Project Name : " $projectName.Name

             #$tim = $versionControlServer.GetItems($projectName.ServerItem)

             $teamProjectItemsObjects = $versionControlServer.GetItems($projectName.ServerItem, [ Microsoft.TeamFoundation.VersionControl.Client.VersionSpec]::Latest,[Microsoft.TeamFoundation.VersionControl.Client.RecursionType]::Full,[Microsoft.TeamFoundation.VersionControl.Client.DeletedState]::Any,[Microsoft.TeamFoundation.VersionControl.Client.ItemType]::File)
             
             #$teamProjectItemsObjects.Items | Out-File -FilePath "C:\Scripts\TPC_VersionInfo.csv"
             
             $totalFiles = $teamProjectItemsObjects.Items.Count

             Write-host "The total number of files in the Team Project is : " $totalFiles
             
            foreach ($item in  $teamProjectItemsObjects.Items )
            {
                #$item.ContentLength , $item.CheckinDate,$item.ItemType ,$item.ServerItem,$item.ChangesetId            

                # Export the value of $item to CSV file

                    #$item | Out-File -FilePath C:\Scripts\TPCVersionInfo.csv -Append
                
                # Export all properties of those files with size > 50 MB (52428800 bytes)
               
                if($item.ContentLength -gt 52428800)
                {
                    $item | Out-File -FilePath C:\Scripts\TPCVersionInfo.csv -Append
                }
            }

            # Create custom CSV file with only required fields
                    #region
                              #this bit creates the CSV if it does not already exist

                                $headers = "Team Project","File Full Path", "File Size(MB)","Check In Date","Item Type","ChangeSet ID"
                                $psObject = New-Object psobject
                                foreach($header in $headers)
                                {
                                 Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
                                }
                                $psObject | Export-Csv C:\Scripts\CustomeCSV_TPC_Info.csv -NoTypeInformation   

                                 foreach ($customeitem in  $teamProjectItemsObjects.Items )
                                    {
                                        
                
                                        # Export only required properties of those files with size > 50 MB (52428800 bytes)
               
                                        if($customeitem.ContentLength -gt 52428800)
                                        {
                                            $HTeamProject= $projectName.Name
                                            $HFilePath = $customeitem.ServerItem
                                            $HFileSizeInBytes = $customeitem.ContentLength
											$fileSizeInMB = $HFileSizeInBytes / 1024 / 1024
                                            $HCheckInDate = $customeitem.CheckinDate
                                            $HItemType = $customeitem.ItemType
                                            $HChangeSetID = $customeitem.ChangesetId
                                            
                                            $hash = @{
                                                         "Team Project" =  $HTeamProject
                                                         "File Full Path" = $HFilePath
                                                         "File Size(MB)"= $fileSizeInMB
                                                         "Check In Date" = $HCheckInDate
                                                         "Item Type" = $HItemType
                                                         "ChangeSet ID" = $HChangeSetID
                                                     
                                                      }

                                            $newRow = New-Object PsObject -Property $hash
                                            Export-Csv C:\Scripts\CustomeCSV_TPC_Info.csv -inputobject $newrow -append -Force
                                            
                                            
                                        }
                                    }

                    #endregion

     }
     

}
	}



