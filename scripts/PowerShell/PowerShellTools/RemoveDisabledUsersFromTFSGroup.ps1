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

 $Assem = ( 
    “Microsoft.TeamFoundation.Client, Version=12.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a” , 
    “Microsoft.TeamFoundation.Common, Version=12.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a” 
    ) 

 $Source = @" 
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Server;
using System.Net;


namespace AddDeleteUsersToTeamProject
{
   public static class Program
    {
        public static void RemoveDisabledUsersFromGroup(string UserToDelete, string tfsGroup)
        {

            var tpc = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(new Uri("https://tfsqa.mmm.com/tfs/TrainingCollection"));

            var ims = tpc.GetService<IIdentityManagementService>();

            var tfsGroupIdentity = ims.ReadIdentity(IdentitySearchFactor.AccountName,tfsGroup, MembershipQuery.None, ReadIdentityOptions.IncludeReadFromSource);


            var userIdentity = ims.ReadIdentity(IdentitySearchFactor.AccountName, UserToDelete, MembershipQuery.None, ReadIdentityOptions.IncludeReadFromSource);

            
            ims.RemoveMemberFromApplicationGroup(tfsGroupIdentity.Descriptor, userIdentity.Descriptor);

        }
    }
}

"@ 

#Import Active Directory Moduel for PowerShell
import-module activedirectory 

#Define variables
$identation = 0

# Gets time stamps for all Users in the domain that have NOT logged in since last 30 days
$domain = "usac.mmm.com"  
$DaysInactive = 30  
$time = (Get-Date).Adddays(-($DaysInactive)) 
  
# Get all AD User with lastLogonTimestamp less than our time and set to enable 
#Get-ADUser -Filter {LastLogonTimeStamp -gt $time -and enabled -eq $false} -Properties Enabled, CanonicalName, Displayname, Givenname, Surname, EmployeeNumber, EmailAddress, Department, StreetAddress, Title | select Enabled, CanonicalName, Displayname, GivenName, Surname, EmployeeNumber, EmailAddress, Department, Title

$disabledUsers =Get-ADUser -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $false} -Properties * | select Displayname, Name


foreach($usr in $disabledUsers)
{
   
 # Write-Host  $usr.DisplayName " :: " $usr.Name


}

# TFS part

$TFSQA_Server = "https://tfsqa.mmm.com/tfs/TrainingCollection"
$teamProjectName = "TrainingTeamProject";
$TFS = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($TFSQA_Server)
$GroupFromWhichUserToBeRemoved ="" 
               
$TFS.EnsureAuthenticated()

if (!$TFS.HasAuthenticated)
{
  Write-Host "Failed to authenticate to TFS"
  exit
} 
Write-Host "Connected to Team Foundation Server [" $TFSQA_Server "]"

# Get all groups of TFS and group Members

$idService = $tfs.GetService("Microsoft.TeamFoundation.Framework.Client.IIdentityManagementService")

 Write-Output ""
 Write-Output "Team project collection: " $TFSQA_Server
 Write-Output ""
 Write-Output "Team project: " $teamProjectName
 Write-Output "TFS Group Membership information: "
 $identation++
 Write-Output ""

 function write-idented([string]$text)

    {

        Write-Output $text.PadLeft($text.Length + (6 * $identation)) 

    }


  function list_identities ($queryOption, $tfsIdentity, $readIdentityOptions )

    {
        $identities = $idService.ReadIdentities($tfsIdentity, $queryOption, $readIdentityOptions)
        
       

        $identation++
          

        foreach($id in $identities)

        {
               

            if ($id.IsContainer)

            {
                if ($id.Members.Count -gt 0)

                {
                        write-idented "Group: ", $id.DisplayName
                        
                       

                        list_identities $queryOption $id.Members $readIdentityOptions

                }

                else

                {

                    if ($ShowEmptyGroups)

                    {
                        write-idented "Group: ", $id.DisplayName

                        $identation++;

                        write-idented "-- No users --"

                        $identation--;

                    }

                }

            }

            else

            {

                if ($id.UniqueName)  {

                    write-idented "Member user: ", $id.UniqueName ,  $id.DisplayName

                    # check to see if the member is disabled and lastlogondate > 30 days

                    foreach($usr in $disabledUsers)
                    {
                           $appenUSACToName  = "USAC\" + $usr.Name            
   
                          if( $usr.Displayname -eq $id.DisplayName -and $appenUSACToName -eq $id.UniqueName)
                          {

                                Write-Host $id.DisplayName : "This user account is disabled and lastlogondate < 30, needs to be removed from GROUP" $GroupFromWhichUserToBeRemoved

                                # call method to remove user from TFS group with required parameters.

                                  if (-not ([System.Management.Automation.PSTypeName]'AddDeleteUsersToTeamProject.Program').Type)
                                  {
                                        Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
                                  }
                                 #Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
                                 [AddDeleteUsersToTeamProject.Program]::RemoveDisabledUsersFromGroup($id.UniqueName, $GroupFromWhichUserToBeRemoved)
                          }


                    }


                }

                else {

                    write-idented "Member user: ", $id.DisplayName

                }

            } 

        }

 

        $identation--

    }
        
# Traverse all TFS groups

    foreach($group in $idService.ListApplicationGroups($teamProjectName, [Microsoft.TeamFoundation.Framework.Common.ReadIdentityOptions]::TrueSid))

    {
            $GroupFromWhichUserToBeRemoved = $group.DisplayName
            list_identities  ([Microsoft.TeamFoundation.Framework.Common.MembershipQuery]::Direct) $group.Descriptor ([Microsoft.TeamFoundation.Framework.Common.ReadIdentityOptions]::TrueSid)

    } 

 


