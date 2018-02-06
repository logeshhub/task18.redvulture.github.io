#
# Death_Star.ps1
#
# Developed By:  ET
# Created On: 03/10/17
# Purpose: Locate large files in version control based on a pattern, and DESTROY them.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!! BE INCREDIBLY CAREFUL WITH THIS SCRIPT !!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#

Clear-Host

# Referencing Assemblies - TE 2015 API
$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.VersionControl.Client.dll"

# Need path to tf.exe
#Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE"

function Destroy-Files
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

	$server = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection(New-Object Uri($tfsCollectionUrl))
	$versionControlServer = $server.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer])

	# <<<<<<<<<< Entire Team Project >>>>>>>>>>>
	#$itemSpec = $NewItemSpec = New-Object Microsoft.TeamFoundation.VersionControl.Client.ItemSpec("$/GrouperApplications", [Microsoft.TeamFoundation.VersionControl.Client.RecursionType]::Full)
	
	# <<<<<<<<<< Specific parent branch >>>>>>>>>>>
	#$itemSpec = New-Object Microsoft.TeamFoundation.VersionControl.Client.ItemSpec("$/GrouperApplications/PricerTables_Media/Releases", [Microsoft.TeamFoundation.VersionControl.Client.RecursionType]::Full)
	
	# <<<<<<<<<< Single branch for testing >>>>>>>>>>>
	#$itemSpec = New-Object Microsoft.TeamFoundation.VersionControl.Client.ItemSpec("$/GrouperApplications/PricerTables_Media/Releases/PricerTables_Media_TOPT-2016.2.0_Candidate2", [Microsoft.TeamFoundation.VersionControl.Client.RecursionType]::Full)
	$itemSpec = New-Object Microsoft.TeamFoundation.VersionControl.Client.ItemSpec("$/Public/Test", [Microsoft.TeamFoundation.VersionControl.Client.RecursionType]::Full)
	
	$versionSpec = [Microsoft.TeamFoundation.VersionControl.Client.VersionSpec]::Latest
	$deletedState = [Microsoft.TeamFoundation.VersionControl.Client.DeletedState]::Any
	
	# <<<<<<<<<< For individual files >>>>>>>>>>>>>>>>
	$itemType = [Microsoft.TeamFoundation.VersionControl.Client.ItemType]::File
	$searchPattern = "*/Pricer_Automation_Project/*/Output/Error_Logs/*"

	# <<<<<<<<<< For folders >>>>>>>>>>>>>>>>
	#$itemType = [Microsoft.TeamFoundation.VersionControl.Client.ItemType]::Folder
	#$searchPattern = "*/folder name"

	$startTime = Get-Date
	Write-Host "Started:" $startTime
	Write-Host "Searching for items using expression "$searchPattern"..."

	$title = "Confirm Deletion"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Destroy the file"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skip the file"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

	$queryTime = Get-Date
	Write-Host "Querying source control:" $queryTime

	$fileCount = 0
	$sourceItems = $versionControlServer.GetItems($itemSpec, $versionSpec, $deletedState, $itemType, $false)

	$processingTime = Get-Date
	Write-Host "Started processing:" $processingTime

	foreach($item in $sourceItems)
	{
		foreach($sourceFile in $item.Items)
		{
			#Write-Host "Item:" $file
			#Write-Host "ServerItem:" $file.ServerItem

			if($sourceFile.ServerItem -like $searchPattern)
			{
				# <<<<<<<<<<< Commence primary ignition >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
				# <<<<<<<<<<< Use the /preview flag on tf destroy for testing >>>>>>>>>>>>>>>
				# <<<<<<<<<<< tf destroy commented out here for safety >>>>>>>>>>>>>>>>>>>>>>

				#& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" destroy $sourceFile.ServerItem /preview /noprompt /s:""$tfsCollectionUrl""
				$fileCount++

				# <<<<<<<<<<<<<< For individual file prompts >>>>>>>>>>>>>>>>>
				<#
				$message = "Are you sure that you want to destroy: " + $sourceFile.ServerItem
				$result = $host.ui.PromptForChoice($title, $message, $Options, 0)
				if( $result -eq 0)
				{
					& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" destroy $sourceFile.ServerItem /noprompt /s:""$tfsCollectionUrl""
					$fileCount++
				}
				else
				{
					Write-Host "Skipped" $sourceFile.ServerItem
				}
				#>						
			}
		}
	}

	$endTime = Get-Date
	Write-Host "Finished:" $endTime
	Write-Host "Processed" $fileCount "items."
}

Destroy-Files
