#
# Get_Connected_Services.ps1
#
# Developed By:  ET
# Created On: 05/22/2017
# Purpose: Locate and enumerate all connected services across an entire TPC
#
#

Clear-Host

# Referencing Assemblies - TE 2015 API
$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.VersionControl.Client.dll"


function Get-TPC-Connected-Services
{

    <#Param([Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
		  [string] $tfsCollectionUrl)#>


	# Connect to TFS, hardcoded for now.  Uncomment the parameter block to switch to argument input.
	$tfsCollectionUrl = "https://tfs.mmm.com/tfs/DefaultCollection"
	

	$TFS = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsCollectionUrl)
	$TFS.EnsureAuthenticated()

	if (!$TFS.HasAuthenticated)
	{
	  Write-Host "Failed to authenticate to TFS"
	  Exit
	} 
	Write-Host
	Write-Host "Connected to Team Foundation Server [" $tfsCollectionUrl "]"
	Write-Host

	$server = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection(New-Object Uri($tfsCollectionUrl))
	
	# Get all the group memberships, and look for Endpoint Administrator groups
	$versionControlServer = $server.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer])
	$projects = $versionControlServer.GetAllTeamProjects($true)
	
	$IDService = $server.GetService([Microsoft.TeamFoundation.Framework.Client.IIdentityManagementService])

	foreach($project in $projects)
	{
		Write-Host "Project:" $project.Name
		
		# Find the Release Administrators groups
		$groups = $IDService.ListApplicationGroups($project.ArtifactUri, [Microsoft.TeamFoundation.Framework.Common.ReadIdentityOptions]::ExtendedProperties)

		foreach($group in $groups)
		{
			#Write-Host "Group:" $group.DisplayName
			if($group.DisplayName -like "*Endpoint Administrators*")
			{
				Write-Host "Found Endpoint Administrators for Team Project:" $project.Name
				foreach($member in $group.Members)
				{
					Write-Host "Found member:" $member.DisplayName
					Write-Host
				}
			}
		}	
	
		Write-Host "*********************************************************"
		Write-Host
	}
	
	
}

Get-TPC-Connected-Services





