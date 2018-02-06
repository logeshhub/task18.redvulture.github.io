// --------------------------------------------------------------------------------------------------------------------
// <copyright file="HealthCheck.aspx.cs" company="3M Company">
//   Copyright © 2015-2017 3M Company
// </copyright>
// --------------------------------------------------------------------------------------------------------------------
using System;
using System.Configuration;
using System.Collections.ObjectModel;
using System.Web;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;


namespace ETFS.HealthCheck
{
    public partial class HealthCheck : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // initialize
            bool online = false;
            int teamprojectCount = 0;
            string nodeUri = ConfigurationManager.AppSettings["NodeUri"];

            try
            {
                online = ConfigurationManager.AppSettings["online"] == "true";

                Response.Write("3M Enterprise Team Foundation Server Health Check Diagnostics<br />");
                Response.Write("Diagnostic Runtime:  " + System.DateTime.Now.ToShortDateString() + "&nbsp;" + System.DateTime.Now.ToLongTimeString() + "<br />");
                Response.Write("Server Name:  " + Server.MachineName + "<br />");

                if (online)
                {
                    Uri tfsUri = new Uri(nodeUri);

                    TfsConfigurationServer configurationServer =
                        TfsConfigurationServerFactory.GetConfigurationServer(tfsUri);

                    // Get the catalog of team project collections
                    ReadOnlyCollection<CatalogNode> collectionNodes = configurationServer.CatalogNode.QueryChildren(
                        new[] { CatalogResourceTypes.ProjectCollection },
                        false, CatalogQueryOptions.None);

                    // List the team project collections
                    foreach (CatalogNode collectionNode in collectionNodes)
                    {
                        // Use the InstanceId property to get the team project collection
                        Guid collectionId = new Guid(collectionNode.Resource.Properties["InstanceId"]);
                        TfsTeamProjectCollection teamProjectCollection = configurationServer.GetTeamProjectCollection(collectionId);

                        // Print the name of the team project collection
                        Response.Write("Collection: " + teamProjectCollection.Name + "<br />");

                        // Get a catalog of team projects for the collection
                        ReadOnlyCollection<CatalogNode> projectNodes = collectionNode.QueryChildren(
                            new[] { CatalogResourceTypes.TeamProject },
                            false, CatalogQueryOptions.None);

                        // List the team projects in the collection
                        foreach (CatalogNode projectNode in projectNodes)
                        {
                            teamprojectCount++;
                            Response.Write("Team Project: " + projectNode.Resource.DisplayName + "<br />");
                        }
                    }

                    // Force clean up
                    configurationServer.Dispose();
                }
            }
            catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
            finally
            {
                string status = teamprojectCount > 0 ? "Up" : "Down";
                Response.Write("Status: " + status);
            }
        }
    }
}