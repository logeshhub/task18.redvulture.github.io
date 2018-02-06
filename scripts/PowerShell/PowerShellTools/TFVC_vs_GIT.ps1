Clear-Host
#Load TFS PowerShell Snap-in
if((Get-PSSnapIn -Name Microsoft.TeamFoundation.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin Microsoft.TeamFoundation.PowerShell
}


# Referencing Assemblies in PowerShell Script
$pathToAss2 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
$pathToAss4 = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.VersionControl.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Git.Client.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.Git.Common.dll"
Add-Type -Path "$pathToAss2\Microsoft.TeamFoundation.SourceControl.WebApi.dll"

Add-Type -Path "$pathToAss4\Microsoft.TeamFoundation.ProjectManagement.dll"


Function CheckGITProject{ 
	param([string]$teamProjectName)
	[string]$tfsCollectionUrl="https://nathcorpdev.visualstudio.com/DefaultCollection"
	
	[string]$tfsTeamProjectName=$teamProjectName
	$tpc=[Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsCollectionUrl)
	$gitRepository = $tpc.GetService([type]"Microsoft.TeamFoundation.Git.Client.GitRepositoryService")
	$gitProjectRepoService = $gitRepository.QueryRepositories($tfsTeamProjectName)
	if($gitProjectRepoService -ne $null)
	{
	#$defaultGitRepo = $gitProjectRepoService | where {$_.Name -eq $tfsTeamProjectName}
		$defaultGitRepo=$gitProjectRepoService[0]
		if($defaultGitRepo -ne $null)
		{
			Write-Output $defaultGitRepo.Name
            Write-Output "$teamProjectName is GIT team Project"
            
		}
        
	}
    else
    {
            Write-Output "$teamProjectName is Not GIT team Project"
    }
}
Function CheckTFVCProject
{
	param([string]$teamProjectName)
	[string]$tfsCollectionUrl="https://nathcorpdev.visualstudio.com/DefaultCollection"
	$tpc=[Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsCollectionUrl)
	$versionControl=$tpc.GetService([type]"Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer")
	$teamProjects=$versionControl.GetAllTeamProjects($False)
	$teamProject=$teamProjects | where {$_.Name -eq $teamProjectName}
	if($teamProject -ne $null)
	{
		#Write-Output "success"
        Write-Output "$teamProjectName is a TFVC project."
	}
	else
	{
		Write-Output "$teamProjectName is not a TFVC project."
	}
}
CheckGITProject "NCSYNC"
CheckTFVCProject "ncsync"