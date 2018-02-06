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


namespace MigrateAreas
{
    class Program
    {

        static void Main(string[] args)
        {
            Copy();
            Console.ReadKey();
        }

        static void Copy()
        {
            string sourceServerUrl = "http://tfs13sb.archon-tech.com:8080/tfs";
            string sourceCollectionName = "PublicSafety";
            string sourceProjectName = "ALPR";

            string targetServerUrl = "https://tfsdev.mmm.com/tfs";
            string targetCollectionName = "DefaultCollection";
            string targetProjectName = "ALPR_Migration_Iterations";

            try
            {
                /*
                NetworkCredential netCred = new NetworkCredential("eandrewtaylor@hotmail.com", "P2ssw0rd");
                BasicAuthCredential basicCred = new BasicAuthCredential(netCred);
                TfsClientCredentials tfsCred = new TfsClientCredentials(basicCred);
                tfsCred.AllowInteractive = false;
                */

                // connect to source TPC
                Uri sourceUri = new Uri(sourceServerUrl + "/" + sourceCollectionName);
                Console.WriteLine("Connecting to source TPC: " + sourceUri + "...");
                TfsTeamProjectCollection sourceTpc = new TfsTeamProjectCollection(sourceUri);
                sourceTpc.Authenticate();
                sourceTpc.EnsureAuthenticated();
                sourceTpc.Connect(ConnectOptions.IncludeServices);
                Console.WriteLine("Connected to source TPC.");
                Console.WriteLine();

                // connect to target TPC
                Uri targetUri = new Uri(targetServerUrl + "/" + targetCollectionName);
                Console.WriteLine("Connecting to target TPC " + targetUri + "...");
                TfsTeamProjectCollection targetTpc = new TfsTeamProjectCollection(targetUri);
                targetTpc.Authenticate();
                targetTpc.EnsureAuthenticated();
                targetTpc.Connect(ConnectOptions.None);
                Console.WriteLine("Connected to target TPC.");
                Console.WriteLine();

                // connect to source CSS service for source TPC
                Console.WriteLine("Connecting to CSS service for " + sourceCollectionName + ".");
                ICommonStructureService4 sourceCss = sourceTpc.GetService<ICommonStructureService4>();
                ProjectInfo sourceProj = sourceCss.GetProjectFromName(sourceProjectName);

                // connect to target CSS service for target TPC
                Console.WriteLine("Connecting to CSS service for " + targetCollectionName + ".");
                ICommonStructureService4 targetCss = targetTpc.GetService<ICommonStructureService4>();
                ProjectInfo targetProj = targetCss.GetProjectFromName(targetProjectName);

                List<NodeInfo> sourceNodes = new List<NodeInfo>();
                List<NodeInfo> targetNodes = new List<NodeInfo>();

                // !!!!!!!!!!!!!!!! NOTE: GO CHECK THE TARGET PROJECT AND MAKE SURE NO AREAS ALREADY EXIST.  NOT ENOUGH TIME TO WRITE CODE FOR DETECTION !!!!!!!!!!!!!!!!!!!!!!!!

                // get the top level Uri for the Area node on the target
                NodeInfo targetRootNode = null;
                foreach (NodeInfo targetNode in targetCss.ListStructures(targetProj.Uri))
                {
                    // looking for the root Area
                    if (targetNode.StructureType == "ProjectModelHierarchy")
                    {
                        targetRootNode = targetNode;
                        Console.WriteLine("Root Area node:" + targetRootNode.Name);
                        Console.WriteLine("Root Area node path:" + targetRootNode.Path);
                        Console.WriteLine("Root Area node Uri:" + targetRootNode.Uri);
                        break;
                    }
                }
                Console.WriteLine();
                Console.ReadKey();

                // build target nodes from source XML structure
                Console.WriteLine("Begin building Area nodes.");
                foreach (NodeInfo sourceNode in sourceCss.ListStructures(sourceProj.Uri))
                {
                    // Areas only
                    if (sourceNode.StructureType != "ProjectModelHierarchy")
                        continue;

                    XmlElement nodeElement = sourceCss.GetNodesXml(new string[] { sourceNode.Uri }, true);
                    BuildNodes(sourceProj, targetProj, sourceCss, targetCss, sourceNode.Path, nodeElement.ChildNodes[0], sourceNodes, targetRootNode.Uri);
                                
                }
                Console.WriteLine();
                Console.WriteLine("Migration complete.");

                // close connections
                sourceTpc.Dispose();
                Console.WriteLine();
                Console.WriteLine("Closed source TPC " + sourceUri.ToString() + ".");

                targetTpc.Dispose();
                Console.WriteLine("Closed target TPC " + targetUri.ToString() + ".");
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
