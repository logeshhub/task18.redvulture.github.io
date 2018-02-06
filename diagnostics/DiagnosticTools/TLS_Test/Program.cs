/*
 
 * Author:  Everett Taylor
 * Created: 06/27/2017
 * Purpose: Tests for TLS connection failures with TFS.
 *          Indended to run as a scheduled task to capture intermittent TLS handshake failures.
 * Notes:   Uses the TFS 2013 APIs and deprecated connection style since some of the servers are only running TFS 2013 (e.g. remote build servers).
 *          NuGet package version for 2013/2015 APIs - https://www.nuget.org/packages/Microsoft.TeamFoundationServer.ExtendedClient/14.102.0

 */

using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Common;


namespace TLS_Test
{
    class Program
    {
        static void Main(string[] args)
        {
            
            int cycleCount = Convert.ToInt32(ConfigurationManager.AppSettings["cycleCount"]);
            int cycleSleepDuration = Convert.ToInt32(ConfigurationManager.AppSettings["cycleSleepDuration"]);
            
            Uri tpcUri = new Uri(ConfigurationManager.AppSettings["serverUri"]);
            string logPath = ConfigurationManager.AppSettings["logPath"];
            string result = null;

            Console.WriteLine("Logging started: " + DateTime.Now.ToString() + ".");
            Console.WriteLine("Logging path: " + DateTime.Now.ToString() + ".");
            
            
            // moved settings to .config
            //Uri tpcUri = new Uri("https://tfsqa.mmm.com/tfs/DefaultCollection");
            //string logPath = @"C:\Temp\TFS\Security\TLS.Test.txt";

            // Need source and destination IP addresses
            string sourceIP = Dns.GetHostAddresses(Dns.GetHostName())[0].ToString();
            string destinationIP = Dns.GetHostAddresses(tpcUri.DnsSafeHost)[0].ToString();

            Console.WriteLine("Source IP: " + sourceIP + ".");
            Console.WriteLine("Destination IP: " + destinationIP + ".");

            for (int i = 1; i <= cycleCount; i++)
            {
                try
                {
                    Console.WriteLine("Connection attempt: " + i.ToString());
                    Console.WriteLine("Connecting to: " + tpcUri.Host + ".");

                    TfsClientCredentials credentials = new TfsClientCredentials();
                    
                    // Basic connection to TFS WorkItemStore
                    TfsTeamProjectCollection tpc = new TfsTeamProjectCollection(tpcUri, credentials);

                    // TLS 1.0 handshake will fail here
                    tpc.EnsureAuthenticated();
                    if (!tpc.HasAuthenticated)
                    {
                        throw new Exception("Could not authenticate.");
                    }

                    // Log success
                    Console.WriteLine("Connection successful.");
                    result = "\"Success\",\"" + DateTime.Now.ToUniversalTime().ToString() + "\",\"" + sourceIP + "\",\"" + destinationIP + "\",\"\"";

                    tpc.Dispose();

                }
                catch (Exception ex)
                {
                    Console.WriteLine("Connection failed: " + ex.Message);
                    result = "\"Failure\",\"" + DateTime.Now.ToUniversalTime().ToString() + "\",\"" + sourceIP + "\",\"" + destinationIP + "\",\"" + ex.Message.Replace(System.Environment.NewLine, " ") + "\"";
                }
                finally
                {
                    // Write result to log
                    StreamWriter sw = File.AppendText(logPath);
                    sw.WriteLine(result);
                    sw.Close();
                }

                System.Threading.Thread.Sleep(cycleSleepDuration);
            }

            Console.WriteLine("Logging ended at " + DateTime.Now.ToString() + ".");

        }
    }
}
