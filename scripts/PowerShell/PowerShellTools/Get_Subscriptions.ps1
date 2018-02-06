#
# Get_Subscriptions.ps1
#
# Developed By:  ET
# Created On: 06/19/2017
# Purpose: Locate and enumerate all subscriptions across an entire TPC
#
#

Clear-Host

# Referencing Assemblies - TE 2017 API
$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
#$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
#$pathToAssemblies = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"

Add-Type -Path "$pathToAssemblies\Microsoft.TeamFoundation.Client.dll"


function Get-Subscriptions
{

    <#Param([Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
		  [string] $tfsCollectionUrl)#>


	# Connect to TFS, hardcoded for now.  Uncomment the parameter block to switch to argument input.
	$tfsCollectionUrl = "https://tfs.mmm.com/tfs/DefaultCollection"
	

	$tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsCollectionUrl)
	$tfs.EnsureAuthenticated()

	if (!$tfs.HasAuthenticated)
	{
	  Write-Host "Failed to authenticate to TFS"
	  Exit
	} 
	Write-Host
	Write-Host "Connected to Team Foundation Server [" $tfsCollectionUrl "]"
	Write-Host

	$eventService = $tfs.GetService(“Microsoft.TeamFoundation.Framework.Client.IEventService”)
    $identityService = $tfs.GetService(“Microsoft.TeamFoundation.Framework.Client.IIdentityManagementService”)
	$subs = $eventService.GetAllEventSubscriptions()

	<#
    foreach ($sub in $eventService.GetAllEventSubscriptions())
    {
        #First resolve the subscriber ID
        $tfsId = $identityService.ReadIdentity([Microsoft.TeamFoundation.Framework.Common.IdentitySearchFactor]::Identifier,
                                               $sub.Subscriber,
                                               [Microsoft.TeamFoundation.Framework.Common.MembershipQuery]::None,
                                               [Microsoft.TeamFoundation.Framework.Common.ReadIdentityOptions]::None )
        if ($tfsId.UniqueName)
        {
            $subscriberId = $tfsId.UniqueName
        }
        else
        {
            $subscriberId = $tfsId.DisplayName
        }
 
		$sub

        #then create custom PSObject
		<#
        $subPSObj = New-Object PSObject -Property @{
                        ID             = $sub.ID
                        Device         = $sub.Device
                        Condition      = $sub.ConditionString
                        EventType      = $sub.EventType
                        Address        = $sub.DeliveryPreference.Address
                        Schedule       = $sub.DeliveryPreference.Schedule
                        DeliveryType   = $sub.DeliveryPreference.Type
                        SubscriberName = $subscriberId
                        Tag            = $sub.Tag
                        }
 
        #Send object to the pipeline. You could store it on an Arraylist, but that just
        #consumes more memory
        $subPSObj
		
	}
	#>
}

Get-Subscriptions






