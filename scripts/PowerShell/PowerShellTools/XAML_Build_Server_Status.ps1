#
# XAML_Build_Server_Status.ps1
#
# Developed By:  ET
# Created On: 02/08/2017
# Purpose: Locate and enumerate all XAML build controllers and agents across an entire TPC
# Pull current build information for any running builds.  Initially used to pinpoint extremely heavy builds.
#
#

Clear-Host

# Referencing Assemblies - TE 2015 API
$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Build.Client.dll"
Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Build.Common.dll"


function Get-TPC-Build-Info
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
	$buildServer = $server.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
	$buildControllers = $buildServer.QueryBuildControllers()


	# Iterate through the build controllers, check all the agents to determine which ones are currently active
	foreach($buildController in $buildControllers)
	{
		Write-Host "*********************************************************"
		Write-Host "Controller:" $buildController.Name
		Write-Host "Status:" $buildController.Status
		Write-Host "*********************************************************"
		Write-Host
	
		foreach($buildAgent in $buildController.Agents)
		{
			Write-Host "Agent:" $buildAgent.Name
			Write-Host "Status:" $buildAgent.Status
			Write-Host "Active:" $buildAgent.IsReserved
				
			# if the Agent is reserved, what build is currently running?
			if(($buildAgent.IsReserved -eq "True") -and ($buildAgent.ReservedForBuild -ne $null))
			{
				$buildDetail = $buildServer.GetBuild($buildAgent.ReservedForBuild)
				Write-Host "Team Project:" $buildDetail.BuildDefinition.TeamProject
				Write-Host "Definition:" $buildDetail.BuildDefinition.Name
				Write-Host "Build:" $buildAgent.ReservedForBuild
				Write-Host "Started:" $buildDetail.StartTime
				Write-Host "Source:" $buildAgent.URL
			}
			Write-Host
		}
	}

	$server.Dispose()	
}

Get-TPC-Build-Info





