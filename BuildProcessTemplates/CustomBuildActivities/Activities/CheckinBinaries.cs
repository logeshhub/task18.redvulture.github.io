//-----------------------------------------------------------------------
// <copyright file="CheckinBinaries.cs" company="3MHIS">
//     3M HIS Copyright.
// </copyright>
//-----------------------------------------------------------------------
namespace TeamFoundation.Build.ActivityPack
{
    using System;
    using System.Activities;
    using System.Globalization;
    using System.IO;
    using Microsoft.TeamFoundation.Build.Client;
    using Microsoft.TeamFoundation.Build.Workflow.Activities;
    using Microsoft.TeamFoundation.VersionControl.Client;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text.RegularExpressions;

    using Microsoft.TeamFoundation.VersionControl.Common;

    /// <summary>
    /// Custom build activity to replace CPlusPlus file and version number with the ALM build number.
    /// </summary>
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class CheckinBinaries : CodeActivity
    {
        /// <summary>
        /// Gets or sets the path to the deliverables folder where the files are to be checked in.
        /// </summary>
        public InArgument<string> DeliverablesFolder { get; set; }

        /// <summary>
        /// Gets or sets the list of assemblies that will be checked into the location of the DeliverablesFolder.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> BinariesFolder { get; set; }

        /// <summary>
        /// Gets or sets the regular expression used to match file(s) that are intended to be checked in.
        /// </summary>        
        public InArgument<string> Regexpr { get; set; }

        /// <summary>
        /// Gets or sets whether the ***NO_CI*** comment passed to the server to prevent CI builds from being kicked off.
        /// </summary>        
        public InArgument<bool> IsNoCiBuild { get; set; }

        /// <summary>
        /// Gets or sets whethere the build performed is a versioned build or not.
        /// </summary>
        [RequiredArgument]
        public InArgument<bool> IsVersionedBuild { get; set; }

        /// <summary>
        /// Gets or sets major build number.
        /// </summary>
        public InArgument<int> MajorVersion { get; set; }

        /// <summary>
        /// Gets or sets minor build number.
        /// </summary>
        public InArgument<int> MinorVersion { get; set; }

        /// <summary>
        /// Gets or sets ternary build number.
        /// </summary>
        public InArgument<int> TernaryVersion { get; set; }

        /// <summary>
        /// Gets or sets Workspace object.
        /// </summary>
        [RequiredArgument]
        public InArgument<Workspace> Workspace { get; set; }

        /// <summary>
        /// Override Execute method for custom build activity.       
        /// </summary>
        /// <param name="context">CodeActivityContext context contains arguments including the InstallShieldProjectFullPath.</param>
        protected override void Execute(CodeActivityContext context)
        {
            Workspace workspace = context.GetValue(this.Workspace);
            string deliverablesFolder = context.GetValue<string>(this.DeliverablesFolder);
            string binariesFolder = context.GetValue(this.BinariesFolder);
            bool isVersionedBuild = context.GetValue<bool>(this.IsVersionedBuild);

            if (!String.IsNullOrEmpty(deliverablesFolder.Trim()))
            {
                if (context.GetValue<bool>(this.IsVersionedBuild))
                {
                    int majorVersion = context.GetValue<int>(this.MajorVersion);
                    int minorVersion = context.GetValue<int>(this.MinorVersion);
                    int ternaryVersion = context.GetValue<int>(this.TernaryVersion);

                    deliverablesFolder = Path.Combine(deliverablesFolder, String.Join(".", majorVersion, minorVersion, ternaryVersion));
                }

                workspace.Map(deliverablesFolder, binariesFolder);

                // if the deliverablesFolder does not exist, PendAdd it so we can add individual files to that folder
                if (!workspace.VersionControlServer.ServerItemExists(deliverablesFolder, ItemType.Folder))
                {
                    workspace.PendAdd(binariesFolder, false);
                    context.TrackBuildMessage(String.Format("Created pending DIRECTORY ADD change for {0} to {1}", binariesFolder, deliverablesFolder), BuildMessageImportance.Low);
                }

                // loop through each file to PendAdd to source control
                foreach (string localFile in Directory.GetFiles(binariesFolder, "*.*", SearchOption.AllDirectories))
                {
                    string fileSubPath = localFile.Remove(0, binariesFolder.Length + 1);
                    string serverFile = Path.Combine(deliverablesFolder, fileSubPath).Replace(@"\", "/");

                    try
                    {
                        // If the RegExpr is an empty string, all files will Match successfully
                        Match match = Regex.Match(
                            fileSubPath, context.GetValue<string>(this.Regexpr), RegexOptions.IgnoreCase);

                        // Move onto next file if the file is not a match
                        if (match.Success != true)
                        {
                            continue;
                        }
                    }
                    catch (Exception ex)
                    {
                        context.TrackBuildMessage(String.Format("Invalid Regular Expression: {0} exception: {1} Aborting Check-In", context.GetValue<string>(this.Regexpr), ex.Message), BuildMessageImportance.Normal);
                        return;
                    }

                    if (workspace.VersionControlServer.ServerItemExists(serverFile, ItemType.File))
                    {
                        byte[] updatedFileContents = File.ReadAllBytes(localFile);

                        workspace.Get(new GetRequest(serverFile, RecursionType.None, VersionSpec.Latest), GetOptions.Overwrite);
                        workspace.PendEdit(serverFile, RecursionType.None);

                        byte[] sourceControlFileContents = File.ReadAllBytes(localFile);
                        if (!updatedFileContents.SequenceEqual(sourceControlFileContents))
                        {
                            File.WriteAllBytes(localFile, updatedFileContents);
                        }

                        context.TrackBuildMessage(String.Format("Created pending FILE EDIT change for {0} to {1}", localFile, serverFile), BuildMessageImportance.Low);
                    }
                    else
                    {
                        workspace.PendAdd(localFile);
                        context.TrackBuildMessage(String.Format("Created pending FILE ADD change for {0} to {1}", localFile, serverFile), BuildMessageImportance.Low);
                    }
                }

                // Check in pending changes if they exist
                PendingChange[] pendingChanges = workspace.GetPendingChanges();
                if (pendingChanges != null)
                {
                    context.TrackBuildMessage(String.Format("Checking in {0} binaries into source control", pendingChanges.Length));

                    // Checks all files in in the workspace that have pending changes
                    // The ***NO_CI*** comment ensures that the CI build is not triggered (and that
                    // you end in an endless loop).                     
                    bool isNoCidBuild = context.GetValue<bool>(this.IsNoCiBuild);
                    string comment = "***NO_CI***";

                    if (!isNoCidBuild)
                    {
                        comment = "";
                    }

                    workspace.CheckIn(pendingChanges, "Build Agent", comment, null, null, new PolicyOverrideInfo("Auto checkin", null), CheckinOptions.SuppressEvent);
                }
            }
        }
    }
}

