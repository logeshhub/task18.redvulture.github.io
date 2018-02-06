using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

using Microsoft.TeamFoundation.Server;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;

namespace ChangesetLinkage
{
    class Program
    {

        static void Main(string[] args)
        {
            Find();
            Console.ReadKey();
        }

        static void Find()
        {
            string sourceServerUrl = "https://mmm-parking.visualstudio.com";
            string sourceCollectionName = "DefaultCollection";
            string sourceProjectName = "Element";


            try
            {
                NetworkCredential netCred = new NetworkCredential("eandrewtaylor@hotmail.com", "P2ssw0rd");
                BasicAuthCredential basicCred = new BasicAuthCredential(netCred);
                TfsClientCredentials tfsCred = new TfsClientCredentials(basicCred);
                tfsCred.AllowInteractive = false;

                // connect to source TPC
                Uri sourceUri = new Uri(sourceServerUrl + "/" + sourceCollectionName);
                Console.WriteLine("Connecting to source TPC: " + sourceUri + "...");
                TfsTeamProjectCollection sourceTpc = new TfsTeamProjectCollection(sourceUri, tfsCred);
                sourceTpc.Authenticate();
                sourceTpc.EnsureAuthenticated();
                sourceTpc.Connect(ConnectOptions.IncludeServices);
                Console.WriteLine("Connected to source TPC.");
                Console.WriteLine();

                // 04/05/14 ET:  Abandoned tool since Parking was comfortable with using two different migration passes, which will effectively break their changeset > work item linkage.

                // connect to source VC service for TPC
                Console.WriteLine("Connecting to VC service for " + sourceCollectionName + ".");
                //sourceCss = sourceTpc.GetService<ICommonStructureService4>();
                //ProjectInfo sourceProj = sourceCss.GetProjectFromName(sourceProjectName);

                

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

        static void BuildNodes(ProjectInfo sourceProj, ProjectInfo targetProj, ICommonStructureService4 sourceCss, ICommonStructureService4 targetCss,
            string parentPath, XmlNode parentNode, List<NodeInfo> sourceNodes, string targetParentUri)
        {
            if (parentNode.ChildNodes[0] == null)
                return;

            foreach (XmlNode childNode in parentNode.ChildNodes[0].ChildNodes)
            {
                string childNodePath = childNode.Attributes["Path"].Value;
                NodeInfo childNodeInfo = sourceCss.GetNodeFromPath(childNodePath);

                Console.WriteLine("Source Area: " + childNodeInfo.Name);
                Console.WriteLine("Source Path: " + childNodeInfo.Path);
                Console.WriteLine("Source Area Uri: " + childNodeInfo.Uri);
                Console.WriteLine("Source Area Parent Uri: " + childNodeInfo.ParentUri);
                Console.WriteLine();

                string targetPath = childNodeInfo.Path.Replace(sourceProj.Name, targetProj.Name);

                // Create on the fly. The current Uri will be generated for the next call since we don't know the actual Uri of this node until it gets added
                string targetUri = targetCss.CreateNode(childNodeInfo.Name, targetParentUri);

                Console.WriteLine("Target Area: " + childNodeInfo.Name);
                Console.WriteLine("Target Path: " + targetPath);
                Console.WriteLine("Target Area Uri: " + targetUri);
                Console.WriteLine("Target Area Parent Uri: " + targetParentUri);
                Console.WriteLine();
                Console.ReadKey();

                // call recursive
                BuildNodes(sourceProj, targetProj, sourceCss, targetCss, childNodePath, childNode, sourceNodes, targetUri);

            }
        }
    }
}
