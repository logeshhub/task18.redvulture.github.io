Clear-Host

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
# Use localhost for now, may use input argument later
#$tfsCollectionUrl = "http://localhost:8080/tfs/DefaultCollection"

# Name of the Team Project. Used in a LIKE expression, use * for wildcards, (Ensemble*, etc.)
#$teamProjectName = "*";

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

# The first row of the CSV output should be the headers for import into Excel
$outputFile = "C:\Temp\TPC.VersionControl.Info.csv"
$hasHeader = $false
$hasFiles = $false

# File thresholds. Any file over this size will be output.
# > 50 MB (52428800 bytes)
# > 100 MB (104857600 bytes)
$minFileSize = 52428800

foreach($projectName in $teamProjectsList)
{
     $totalSizeMB = 0

     if($projectName.Name -like $teamProjectName)
     {
            Write-host "Team Project Name : " $projectName.Name

            # Get latest version of all the files for the Team Project
            $teamProjectItemsObjects = $versionControlServer.GetItems($projectName.ServerItem, [ Microsoft.TeamFoundation.VersionControl.Client.VersionSpec]::Latest,[Microsoft.TeamFoundation.VersionControl.Client.RecursionType]::Full,[Microsoft.TeamFoundation.VersionControl.Client.DeletedState]::Any,[Microsoft.TeamFoundation.VersionControl.Client.ItemType]::File)
             
            # How many total files in the Team Project?
            $totalFiles = $teamProjectItemsObjects.Items.Count
            Write-host "The total number of files in the Team Project is:" $totalFiles
            
            # Write header to CSV on first row, only once
            if ($hasHeader -eq $false)
            {
                $header = "Project Name,Repo Type,Server Path,Size (MB),Last CheckIn Date"
                $header | Out-File -FilePath $outputFile -Append
                $hasHeader = $true
            }
                    
            foreach ($item in  $teamProjectItemsObjects.Items )
            {
                #$item.ContentLength , $item.CheckinDate,$item.ItemType ,$item.ServerItem,$item.ChangesetId
                                                
                # Export only those files with size larger than the threshold size
                if ($item.ContentLength -gt $minFileSize)
                {
                    # Convert to MB
                    $fileSizeMB = $item.ContentLength / 1024 / 1024

                    # Accumulate total comsumption for the Team Project
                    $totalSizeMB = $totalSizeMB + $fileSizeMB
                    
					# Output to comma separated value file
                    $output = $projectName.Name + ",TFVC," + $item.ServerItem + "," + $fileSizeMB + "," + $item.CheckinDate
                    $output | Out-File -FilePath $outputFile -Append
                    Write-Host $output
                }
            }

            # How much does the Team Project consume?
            Write-Host "Total large file consumption for Team Project [" $projectName.Name "]:" $totalSizeMB "MB"

     }
}
	}

Get-TPC-VersionControl-Info




