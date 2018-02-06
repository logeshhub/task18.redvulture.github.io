#
# Get_TPC_Git_Repo_Consumption
#
# Developed By:  ET
# Created On: 06/05/2017
# Purpose: Locate large files in Git repos.

Clear-Host

# Referencing Assemblies - TE 2015 API
$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.VersionControl.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Git.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Core.WebApi.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.SourceControl.WebApi.dll"


function Find-Files
{

    <#Param([Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
		  [string] $tfsCollectionUrl)#>


	# Connect to TFS, hardcoded for now.  Uncomment the parameter block to switch to argument input.
	$tfsCollectionUrl = "https://tfs.mmm.com/tfs/DefaultCollection"
	Write-Host "Connecting to Team Foundation Server [" $tfsCollectionUrl "]"

	$TFS = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsCollectionUrl)
	$TFS.EnsureAuthenticated()

	if (!$TFS.HasAuthenticated)
	{
	  Write-Host "Failed to authenticate to TFS"
	  Exit
	} 
	Write-Host "Connected to Team Foundation Server [" $tfsCollectionUrl "]"
	Write-Host

	$tpc = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection(New-Object Uri($tfsCollectionUrl))
	$cssService = $tpc.GetService("Microsoft.TeamFoundation.Server.ICommonStructureService3")
	$teamProjects = $cssService.ListProjects() | Sort-Object -Property Name
	$gitService = $tpc.GetService([Microsoft.TeamFoundation.Git.Client.GitRepositoryService])
	
	$startTime = Get-Date
	Write-Host "Started:" $startTime
	
	$queryTime = Get-Date
	Write-Host "Querying source control:" $queryTime
		
	$processingTime = Get-Date
	Write-Host "Started processing:" $processingTime

	Write-Host "Found" $teamProjects.Count "Team Projects."

	cd "D:\_tfs_data\git"

	# write CSV header
	$outputFile = ".\Repo.Info.csv"
	$header = """Team Project"",""Repo Name"",""Repo URL"",Size MB"""
	$header | Out-File -FilePath $outputFile -Append

	$fileCount = 0
	foreach($teamProject in $teamProjects)
	{
		$gitRepos =  $gitService.QueryRepositories($teamProject.Name)
		if ($gitRepos -ne $null)
		{
			
			Write-Host "Team Project:" $teamProject.Name

			foreach($repo in $gitRepos)
			{
				Write-Host "Repo:" $repo.Name
				Write-Host "Url:" $repo.RemoteUrl
								
				#$repoArgs = $repo.RemoteUrl + " """ + $repo.Name + """"
				#$command = "git clone " + $repoArgs
				#Write-Host "Command: " $command
				
				# Clone to local
				git clone $repo.RemoteUrl
				
				# Calculate size of local repo
				$repoSize = (Get-ChildItem $repo.Name -Recurse | Measure-Object -property length -sum)
				$repoMB = "{0:N2}" -f ($repoSize.sum / 1MB)
								
				Write-Host "Repo size (MB): " $repoMB
				
				# Output statistics to file
				# output CSV > repo name, repo URL, file count, repo size
				$output = """" + $teamProject.Name + """,""" + $repo.Name + """,""" + $repo.RemoteUrl + """,""" + $repoMB + """"
				$output | Out-File -FilePath $outputFile -Append
												
				# Drop the local repo, need the space
				Write-Host "Removing local clone..."
				Remove-Item """ + $repo.Name + """ -Recurse -Force
				Write-Host "Local clone removed."
				Write-Host
				
				<#foreach($sourceFile in $item.Items)
				{
					#Write-Host "Item:" $file
					#Write-Host "ServerItem:" $file.ServerItem

			
				}#>
								
			}
			Write-Host
		}
	}

	

	$endTime = Get-Date
	Write-Host "Finished:" $endTime
	Write-Host "Processed" $fileCount "items."
}

Find-Files
