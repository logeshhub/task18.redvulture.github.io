using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Microsoft.TeamFoundation.Server;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

using System.DirectoryServices;
using System.DirectoryServices.AccountManagement;


namespace CleanWorkspaces
{
    class Program
    {
        static void Main(string[] args)
        {
            Clean();
            Console.ReadKey();
        }
        
        static void Clean()
        {
            string sourceServerUrl = "http://tfs13sb.archon-tech.com:8080/tfs";
            string sourceCollectionName = "PublicSafety";
            //string sourceProjectName = "ALPR";

            try
            {
                // connect to source TPC
                Uri sourceUri = new Uri(sourceServerUrl + "/" + sourceCollectionName);
                Console.WriteLine("Connecting to source TPC: " + sourceUri + "...");
                TfsTeamProjectCollection sourceTpc = new TfsTeamProjectCollection(sourceUri);
                sourceTpc.Authenticate();
                sourceTpc.EnsureAuthenticated();
                sourceTpc.Connect(ConnectOptions.IncludeServices);
                Console.WriteLine("Connected to source TPC.");
                Console.WriteLine();

                // connect to version control service for source TPC
                Console.WriteLine("Connecting to version control service for " + sourceCollectionName + ".");

                VersionControlServer sourceVCS = sourceTpc.GetService<VersionControlServer>();
                Workspace[] workspaces = sourceVCS.QueryWorkspaces(null, null, null);

                // no workspaces over a year since last accessed
                DateTime cutOffDate = DateTime.Now.Subtract(new TimeSpan(365, 0, 0, 0));

                foreach (Workspace workspace in workspaces)
                {
                    Console.WriteLine("Name: " + workspace.Name);
                    Console.WriteLine("Owner: " + workspace.OwnerDisplayName);
                    Console.WriteLine("Computer: " + workspace.Computer);
                    Console.WriteLine("Last Accessed: " + workspace.LastAccessDate);
                                        
                    // locate the user in AD, make sure still active
                    bool userExists = FindUser( workspace.OwnerName );
                                          
                    // locate the computer in AD, make sure still exists
                    bool archonComputerExists = false;
                    bool usacComputerExists = FindComputer( workspace.Computer, "usac.mmm.com" );
                    
                    if (!usacComputerExists)
                    {
                        archonComputerExists = FindComputer(workspace.Computer, "archon-tech.com");
                    }
                                            
                    // based on criteria, clean up shelvesets
                    if ( !userExists  || (!usacComputerExists && !archonComputerExists) || cutOffDate > workspace.LastAccessDate )
                    {
                        Console.WriteLine("Removing: " + workspace.Name);
                        //sourceVCS.DeleteWorkspace(workspace.Name, workspace.OwnerName);
                        Console.WriteLine("Removed: " + workspace.Name);
                    }

                    Console.WriteLine();
                }
                Console.WriteLine();
                Console.ReadKey();

                Console.WriteLine();
                Console.WriteLine("Clean up complete.");

                // close connections
                sourceTpc.Dispose();
                Console.WriteLine();
                Console.WriteLine("Closed source TPC " + sourceUri.ToString() + ".");

            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + ex.ToString());
            }
            
        }

        static bool FindUser( string userName )
        {
            if (String.IsNullOrEmpty(userName))
                throw new ArgumentNullException("userName");
            
            // if there's an @ in the name, that's from VSO, it needs to go
            if( userName.Contains('@'))
                return false;

            // Create the context for the principal object. 
            PrincipalContext context = new PrincipalContext(ContextType.Domain, userName.Split('\\')[0] );

            // Create an in-memory user object to use as the query example.
            UserPrincipal user = new UserPrincipal( context );

            // Set properties on the user principal object.
            user.Name = userName.Split('\\')[1];

            // Create a PrincipalSearcher object to perform the search.
            PrincipalSearcher searcher = new PrincipalSearcher();

            // Tell the PrincipalSearcher what to search for.
            searcher.QueryFilter = user;

            // Run the query. The query locates users 
            // that match the supplied user principal object. 
            PrincipalSearchResult<Principal> results = searcher.FindAll();
            if (results != null)
            {
                foreach (Principal result in results)
                    return true;
            }

            return false;
        }

        static bool FindComputer( string computerName, string domain )
        {
            if (String.IsNullOrEmpty(computerName))
                throw new ArgumentNullException("computerName");
            if (String.IsNullOrEmpty(domain))
                throw new ArgumentNullException("domain");

            // Create the context for the principal object. 
            PrincipalContext context = new PrincipalContext(ContextType.Domain, domain);

            // Create an in-memory computer object to use as the query example.
            ComputerPrincipal computer = new ComputerPrincipal(context);

            // Set properties on the user principal object.
            computer.Name = computerName;
            
            // Create a PrincipalSearcher object to perform the search.
            PrincipalSearcher searcher = new PrincipalSearcher();

            // Tell the PrincipalSearcher what to search for.
            searcher.QueryFilter = computer;

            // Run the query. The query locates computers 
            // that match the supplied computer principal object. 
            PrincipalSearchResult<Principal> results = searcher.FindAll();
            if (results != null)
            {
                foreach( Principal result in results )
                    return true;
            }
            
            return false;
        }
    }
}
