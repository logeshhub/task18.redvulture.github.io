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


namespace CleanShelvesets
{
    class Program
    {
        static void Main(string[] args)
        {
            Clean( args[0], args[1] );
            Console.ReadKey();
        }


        static void Clean( string serverUrl, string collectionName )
        {
            if (String.IsNullOrEmpty(serverUrl))
                throw new ArgumentNullException("serverUrl");

            if (String.IsNullOrEmpty(collectionName))
                throw new ArgumentNullException("collectionName");

            
            try
            {
                // connect to source TPC
                Uri tpcUri = new Uri(serverUrl + "/" + collectionName);
                Console.WriteLine("Connecting to source TPC: " + tpcUri + "...");
                TfsTeamProjectCollection tpc = new TfsTeamProjectCollection( tpcUri );
                tpc.Authenticate();
                tpc.EnsureAuthenticated();
                tpc.Connect(ConnectOptions.IncludeServices);
                Console.WriteLine("Connected to source TPC.");
                Console.WriteLine();

                // connect to version control service for source TPC
                Console.WriteLine("Connecting to version control service for " + collectionName + ".");

                VersionControlServer vcs = tpc.GetService<VersionControlServer>();
                Shelveset[] shelveSets = vcs.QueryShelvesets(null, null);

                // no workspaces over a year since last accessed
                DateTime cutOffDate = DateTime.Now.Subtract(new TimeSpan(365, 0, 0, 0));

                foreach (Shelveset shelveSet in shelveSets)
                {
                    Console.WriteLine("Name: " + shelveSet.Name);
                    Console.WriteLine("Created: " + shelveSet.CreationDate);
                    Console.WriteLine("Owner: " + shelveSet.OwnerDisplayName);

                    // based on criteria, clean up shelvesets with known system prefixes, etc.
                    if (shelveSet.Name.StartsWith("CodeReview")
                        || shelveSet.Name.StartsWith("_Build")
                        || shelveSet.Name.StartsWith("Gated")
                        || cutOffDate > shelveSet.CreationDate)
                    {
                        Console.WriteLine("Removing: " + shelveSet.Name);
                        //sourceVCS.DeleteShelveset(shelveSet);
                        Console.WriteLine("Removed: " + shelveSet.Name);
                    }

                    Console.WriteLine();
                }
                Console.WriteLine();
                Console.ReadKey();

                Console.WriteLine();
                Console.WriteLine("Clean up complete.");

                // close connections
                tpc.Dispose();
                Console.WriteLine();
                Console.WriteLine("Closed source TPC " + tpcUri.ToString() + ".");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + ex.ToString());
            }
        }
    }
}


