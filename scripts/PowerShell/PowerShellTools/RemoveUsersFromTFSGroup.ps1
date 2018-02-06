#Clear Screen
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
    “Microsoft.TeamFoundation.Common, Version=12.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a” ,
    "System.DirectoryServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=B03F5F7F11D50A3A"
    ) 
$Source = @" 
using System;
using System.DirectoryServices;
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
        public static void RemoveUser(string ProjectCollectionName,string TeamProj)
        {
				// ET:  01/25/16 - Added requirements
				// input arguments for serverName, team project name
				
				 //string serverName = @"https://tfsqa.mmm.com/tfs/TrainingCollection";
				 // string _teamProjectName = "TrainingTeamProject";
			
				string serverName = ProjectCollectionName;
            	string _teamProjectName = TeamProj;

               string[] tfsGroupName = {"[_teamProjectName]\\Build Administrators", "[_teamProjectName]\\Contributors", "[_teamProjectName]\\Project Administrators", "[_teamProjectName]\\Readers" };
              
               
				// ET:  no stored credentials, use current user context of whoever is running the script
				// ET:  will run as scheduled task as TFSSERVICE account, but the script should use the security principal for the current user

               TfsTeamProjectCollection tfs = new TfsTeamProjectCollection(new Uri(serverName));
               tfs.EnsureAuthenticated();

                //*************************************************************************** Code of TFS TEAM  Start ***************************************************************

               // Retrieve the project URI. Needed to enumerate teams.
               var css4 = tfs.GetService<ICommonStructureService4>();
               ProjectInfo projectInfo = css4.GetProjectFromName(_teamProjectName);

               // Retrieve a list of all teams on the project.
               TfsTeamService teamService = tfs.GetService<TfsTeamService>();
               var allTeams = teamService.QueryTeams(projectInfo.Uri);

                // Traverse all the Teams in the given Team Project

               foreach (TeamFoundationTeam team in allTeams)
               {
                   DateTime dtLastLogon;
                   string TeamGroupName = team.Identity.DisplayName;
                   IdentityDescriptor ids = team.Identity.Descriptor;
                   Console.WriteLine("Team name: {0}", team.Name);
                   Console.WriteLine("Team ID: {0}", team.Identity.TeamFoundationId);
                   Console.WriteLine("Description: {0}", team.Description);

                   var members = team.GetMembers(tfs, MembershipQuery.Direct);

					// ET:  make sure to exclude NPSA service accounts ("USF%", "USS%")
					
                   // Traverse all the members of the team
                   foreach (TeamFoundationIdentity teamMember in members)
                   {
                       if (teamMember.IsContainer == true)
                       {

                           if (teamMember.DisplayName == "Everyone")
                           {
                               // remove Everyone Group from Team
                               RemoveUsersFromTeam(teamMember.UniqueName, ids,ProjectCollectionName);

                           }
                           continue;
                       }

                    Console.WriteLine(teamMember.DisplayName);

                       // remove individual team members
                     // RemoveUsersFromTeam(teamMember.UniqueName, ids);

                      // code to get the last logondate of AD user. Start

                                string userNamewithDomain = teamMember.UniqueName;

                                string removeDomainFromUserName = userNamewithDomain.Substring(5);
                                Console.WriteLine( "Remove Domain Name From User Name " + removeDomainFromUserName);

                               DirectoryEntry de = new DirectoryEntry("LDAP://DC=usac,DC=mmm,DC=com");

                               DirectorySearcher ds = new DirectorySearcher(de);

                               ds.Filter = string.Format("(&(objectCategory=user)(objectClass=user)({0}={1}))", "samAccountName",removeDomainFromUserName);

                               ds.PropertiesToLoad.AddRange(new string[] { "samAccountName", "lastLogon" });

                               SearchResult sr = ds.FindOne();
                               
                                long lastLogon = (long)sr.Properties["lastLogon"][0];

                                dtLastLogon = DateTime.FromFileTime(lastLogon);

                                Console.WriteLine("The Lastlogondate of user " + teamMember.UniqueName + " " + dtLastLogon);
                                Console.ReadLine();

                                   // Compare datetime (180 days from today) and lastlogon date of user. Start

                                           int DaysInactive = 180;
                                           DateTime DateTimeThreeMonthsAgo = DateTime.Now.AddDays(-DaysInactive);

                                           if (dtLastLogon < DateTimeThreeMonthsAgo)  // if last logondate is earlier than 6 months
                                           {
                                                Console.WriteLine("Remove user " + teamMember.UniqueName);
                                               // remove only those team members whose lastlogondate is earlier than 6 months
                                               RemoveUsersFromTeam(teamMember.UniqueName, ids,ProjectCollectionName);

                                           }

                                    // Compare datetime (180 days from today) and lastlogon date of user. End
                        
                               
                       // code to get the last logondate of AD user. End

                   }
               }

            //************************************************************************* Code of TFS TEAM End  ***************************************************************************************

               //1.Get the Idenitity Management Service
               IIdentityManagementService ims = tfs.GetService<IIdentityManagementService>();

               foreach (string gr in tfsGroupName)
               {
                   //2.Read the group represnting the root node
                   TeamFoundationIdentity rootIdentity = ims.ReadIdentity(IdentitySearchFactor.AccountName, gr, MembershipQuery.Direct, ReadIdentityOptions.None);

                   //3.Recursively parse the members of the group
                   DisplayGroupTree(ims, rootIdentity, 0,gr,ProjectCollectionName,TeamProj);
               }

              
                    
        }

       private static void DisplayGroupTree(IIdentityManagementService ims, TeamFoundationIdentity node, int level, string group, string serverUrl, string teamProj )
           {
               DisplayNode(node, level);

               if (!node.IsContainer)
                   return;

               TeamFoundationIdentity[] nodeMembers = ims.ReadIdentities(node.Members, MembershipQuery.Direct, ReadIdentityOptions.None);

               int newLevel = level + 1;
               foreach (TeamFoundationIdentity member in nodeMembers)
               {
                   if (member.IsContainer == true)
                   {
                         if(member.DisplayName =="Everyone")
                         {
                           DisplayGroupTree(ims, member, newLevel,group,serverUrl,teamProj);
                           RemoveUsersFromContributorsGroup(member.UniqueName,group,serverUrl);
                         }

                         // iterate team start
                      // string serverName = @"https://tfsqa.mmm.com/tfs/TrainingCollection";
					  // string _teamProjectName = "TrainingTeamProject";
					      string serverName = serverUrl;
                          string _teamProjectName = teamProj;

                       string[] tfsGroupName = { "[_teamProjectName]\\Build Administrators", "[_teamProjectName]\\Contributors", "[_teamProjectName]\\Project Administrators", "[_teamProjectName]\\Readers" };

                       TfsTeamProjectCollection tfs = new TfsTeamProjectCollection(new Uri(serverName));
                       tfs.EnsureAuthenticated();
                       // Retrieve the project URI. Needed to enumerate teams.
                       var css4 = tfs.GetService<ICommonStructureService4>();
                       ProjectInfo projectInfo = css4.GetProjectFromName(_teamProjectName);
                       // Retrieve a list of all teams on the project.
                       TfsTeamService teamService = tfs.GetService<TfsTeamService>();
                       var allTeams = teamService.QueryTeams(projectInfo.Uri);

                       // Traverse all the Teams in the given Team Project

                       foreach (TeamFoundationTeam team in allTeams)
                       {
                             
                               if( member.DisplayName == team.Identity.DisplayName)
                               {
                                   // Remove Team From TFS Internal Group
                                   RemoveUsersFromContributorsGroup(member.UniqueName, group,serverUrl);
                               }

                           
                       }
              //iterate team end

                       continue;
                   }

                   //remove individual members

                   DisplayGroupTree(ims, member, newLevel,group,serverUrl,teamProj);
                   RemoveUsersFromContributorsGroup(member.UniqueName,group,serverUrl);
               }
           }

           private static void DisplayNode(TeamFoundationIdentity node, int level)
           {
               for (int tabCount = 0; tabCount < level; tabCount++) Console.Write("\t");

               Console.WriteLine(node.DisplayName + " " + node.UniqueName);

           }

 // Method definition to remove users from TFS Group

        public static void RemoveUsersFromContributorsGroup(string UserToDelete, string tfsGroup, string ServerURL)
        {

          //  var tpc = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(new Uri("https://tfsqa.mmm.com/tfs/TrainingCollection"));

			var tpc = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(new Uri(ServerURL));

            var ims = tpc.GetService<IIdentityManagementService>();

            var tfsGroupIdentity = ims.ReadIdentity(IdentitySearchFactor.AccountName,tfsGroup, MembershipQuery.None, ReadIdentityOptions.IncludeReadFromSource);

            var userIdentity = ims.ReadIdentity(IdentitySearchFactor.AccountName, UserToDelete, MembershipQuery.None, ReadIdentityOptions.IncludeReadFromSource);
 
            ims.RemoveMemberFromApplicationGroup(tfsGroupIdentity.Descriptor, userIdentity.Descriptor);

        }

  // Method definition to remove users from Team Project Team

        public static void RemoveUsersFromTeam(string UserToDelete, IdentityDescriptor tfsGroup,string TPCUrl)
        {

            //var tpc = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(new Uri("https://tfsqa.mmm.com/tfs/TrainingCollection"));

			 var tpc = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(new Uri(TPCUrl));

            var ims = tpc.GetService<IIdentityManagementService>();

            var tfsGroupIdentity = ims.ReadIdentity(tfsGroup, MembershipQuery.None, ReadIdentityOptions.IncludeReadFromSource);

            var userIdentity = ims.ReadIdentity(IdentitySearchFactor.AccountName, UserToDelete, MembershipQuery.None, ReadIdentityOptions.IncludeReadFromSource);

            ims.RemoveMemberFromApplicationGroup(tfsGroupIdentity.Descriptor, userIdentity.Descriptor);

        }


    }
}

"@ 
if (-not ([System.Management.Automation.PSTypeName]'AddDeleteUsersToTeamProject.Program').Type)
{
   Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
}
function start-script {
param([string] $serverName,
      [string] $TeamProject
      )

 [AddDeleteUsersToTeamProject.Program]::RemoveUser($serverName,$TeamProject)
}
#Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
#[AddDeleteUsersToTeamProject.Program]::RemoveUser()