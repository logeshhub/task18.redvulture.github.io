using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.TeamFoundation.VersionControl.Client;
using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.Framework.Common;

namespace mmmHIS.ALM.Build.Activities
{
    /// <summary>
    /// Instantiates and calls methods on ProjectFileUpdater and ConfigFileUpdater, which do the actual work of updating references.
    /// </summary>
    internal static class ReferenceUpdateManager
    {
        
        internal static void UpdateReferences(List<string> solutionFiles, string newVersion, Workspace workspace)
        {
            List<ItemSpec> itemSpecs = new List<ItemSpec>();

            ProjectFileUpdater pfu = new ProjectFileUpdater(solutionFiles, newVersion);
            pfu.ExtractCandidateFiles();
            pfu.FindFilesWithFrameworkReferences();

            ConfigFileUpdater cfu = new ConfigFileUpdater(pfu.ProjectFiles, newVersion);
            cfu.ExtractCandidateFiles();
            cfu.FindFilesWithFrameworkReferences();            

            List<ReferenceUpdaterBase> rub = new List<ReferenceUpdaterBase>()
            {
                pfu, cfu
            };

            Parallel.ForEach(rub, ru =>
            {
                ru.UpdateReferences(workspace, itemSpecs);
            });
            
            if (itemSpecs.Count > 0)
            {
                string checkinComment = String.Format("Changed Framework references to {0}", newVersion);
                WorkspaceCheckInParameters wcip = new WorkspaceCheckInParameters(itemSpecs.ToArray(), checkinComment);
                workspace.CheckIn(wcip);
            }
        }
    }
}
