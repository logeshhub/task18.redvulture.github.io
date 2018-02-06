using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace mmmHIS.ALM.Build.Activities
{

    // The BuildActivityAttribute tells TFS that this activity is safe to load into the build controller.
    [BuildActivity(HostEnvironmentOption.Agent), System.ComponentModel.ToolboxItem(true)]
    public sealed class UpdateReferences : CodeActivity
    {
        public InArgument<List<string>> SolutionFiles { get; set; }
        public InArgument<string> BuildNumber { get; set; }
        public InArgument<Workspace> Workspace { get; set; }
        public InArgument<string> SmartFrameworkVersion { get; set; }

        // If your activity returns a value, derive from CodeActivity<TResult>
        // and return the value from the Execute method.
        protected override void Execute(CodeActivityContext context)
        {
            string buildNumber = BuildNumber.Get(context);          
            string smartFrameworkVersion = context.GetValue<string>(SmartFrameworkVersion);
            
            if (String.IsNullOrWhiteSpace(smartFrameworkVersion))
            {
                throw new ArgumentNullException("SmartFrameworkVersion", "In UpdateReferences.Execute, SmartFrameworkVersion is null or whitespace.");
            }

            Tuple<bool, string> versionValidation = Util.ValidateFrameworkVersion(smartFrameworkVersion);

            if (versionValidation.Item1)
            {
                List<string> solutionFiles = SolutionFiles.Get(context);
                Workspace workspace = Workspace.Get(context);
                ReferenceUpdateManager.UpdateReferences(solutionFiles, versionValidation.Item2, workspace);
            }
            else
            {
                string message = String.Format("{0} is not a valid Smart Framework version.", smartFrameworkVersion);
                throw new ArgumentException(message);
            }
        }
    }
}
