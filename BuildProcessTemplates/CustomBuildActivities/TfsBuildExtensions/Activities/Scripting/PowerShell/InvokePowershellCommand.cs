//-----------------------------------------------------------------------
// <copyright file="InvokePowerShellCommand.cs">(c) http://TfsBuildExtensions.codeplex.com/. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
//-----------------------------------------------------------------------
namespace TfsBuildExtensions.Activities.Scripting
{
    using System;
    using System.Activities;
    using System.ComponentModel;
    using System.Globalization;
    using System.IO;
    using System.Linq;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;
    using Microsoft.TeamFoundation.Build.Client;
    using Microsoft.TeamFoundation.Build.Workflow.Activities;
    using Microsoft.TeamFoundation.VersionControl.Client;
    using Microsoft.TeamFoundation.VersionControl.Common;

    /// <summary>
    /// A command to invoke powershell scripts on a build agent
    /// </summary>
    [BuildActivity(HostEnvironmentOption.Agent)]
    public sealed class InvokePowerShellCommand : CodeActivity<PSObject[]>
    {
        /// <summary>
        /// Gets or sets the powershell command script to execute.
        /// </summary>
        /// <value>The command script in string form</value>
        [RequiredArgument]
        [Browsable(true)]
        public InArgument<string> Script { get; set; }

        /// <summary>
        /// Gets or sets any arguments to be provided to the script
        /// <value>An arguments list for the command as a string</value>
        /// </summary>
        [Browsable(true)]
        public InArgument<string> Arguments { get; set; }

        /// <summary>
        /// Gets or sets the build workspace. This is used to obtain
        /// a powershell script from a source control path
        /// </summary>
        /// <value>The workspace used by the current build</value>
        [Browsable(true)]
        [DefaultValue(null)]
        public InArgument<Workspace> BuildWorkspace { get; set; }

        /// <summary>
        /// Resolves the provided script parameter to either a server stored 
        /// PS file or an inline script for direct execution.
        /// </summary>
        /// <param name="context">The activity context</param>
        /// <returns>An executable powershell script</returns>
        internal string ResolveScript(CodeActivityContext context)
        {
            var script = this.Script.Get(context);

            if (string.IsNullOrWhiteSpace(script))
            {
                throw new ArgumentNullException("context", "Script");
            }

            if (VersionControlPath.IsServerItem(script))
            {
                var workspace = this.BuildWorkspace.Get(context);

                if (workspace == null)
                {
                    throw new ArgumentNullException("context", "BuildWorkspace");
                }

                var workspaceFilePath = workspace.GetLocalItemForServerItem(script);
                if (!File.Exists(workspaceFilePath))
                {
                    throw new FileNotFoundException("Script", string.Format(CultureInfo.CurrentCulture, "Workspace local path {0} for source path {1} was not found", script, workspaceFilePath));
                }

                var arguments = this.Arguments.Get(context);
                script = "& '" + workspaceFilePath + "' " + arguments;
            }

            return script;
        }

        /// <summary>
        /// When implemented in a derived class, performs the execution of the activity.
        /// </summary>
        /// <param name="context">The execution environment under which the activity executes.</param>
        /// <returns>PSObject array</returns>
        protected override PSObject[] Execute(CodeActivityContext context)
        {
            if (context == null)
            {
                throw new ArgumentNullException("context");
            }

            var script = this.ResolveScript(context);

            context.TrackBuildMessage(string.Format(CultureInfo.CurrentCulture, "Script resolved to {0}", script), BuildMessageImportance.Low);

            using (var runspace = RunspaceFactory.CreateRunspace(new WorkflowPsHost(context)))
            {
                runspace.Open();

                using (var pipeline = runspace.CreatePipeline(script))
                {
                    var output = pipeline.Invoke();
                    return output.ToArray();
                }
            }
        }
    }
}