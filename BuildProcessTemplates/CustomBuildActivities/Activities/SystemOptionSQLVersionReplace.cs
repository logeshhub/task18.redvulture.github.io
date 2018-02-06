//-----------------------------------------------------------------------
// <copyright file="UpdateSystemOptionSQLVersionReplace.cs" company="3MHIS">
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
    using Microsoft.TeamFoundation.VersionControl.Client;
    using System.Collections.Generic;    

    /// <summary>
    /// Custom build activity to replace CPlusPlus file and version number with the ALM build number.
    /// </summary>
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class SystemOptionSQLVersionReplace : CodeActivity
    {
        /// <summary>
        /// Gets or sets Root folder to find cplusplus *.rc resource files.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> RootPath { get; set; }

        /// <summary>
        /// Gets or sets major build number.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> Major { get; set; }

        /// <summary>
        /// Gets or sets minor build number.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> Minor { get; set; }

        /// <summary>
        /// Gets or sets ternary build number.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> Ternary { get; set; }

        /// <summary>
        /// Gets or sets revision build number.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> Revision { get; set; }

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
            this.ReplaceVersion(context);            
        }

        /// <summary>
        /// Look for all C++ resource *.rc files in root path, including subfolders, and replace the productversion and fileversion numbers.       
        /// </summary>
        /// <param name="context">CodeActivityContext used to get input parameters.</param>
        private void ReplaceVersion(CodeActivityContext context)
        {
            // get the workspace from the context
            Workspace workspace = context.GetValue(this.Workspace);

            // get path to search for SystemOption.sql files.
            var path = context.GetValue(this.RootPath);

            var resourceFiles = new List<string>();

            // find files matching SystemOption.sql files.
            if (Directory.Exists(path))
            {                
                resourceFiles.AddRange(Directory.GetFiles(path, "System_Option.sql", SearchOption.AllDirectories));
            }

            // context build number components.
            string major = context.GetValue(this.Major);
            string minor = context.GetValue(this.Minor);
            string ternary = context.GetValue(this.Ternary);
            string revision = context.GetValue(this.Revision);

            // list of resource files to check-in
            List<ItemSpec> itemSpecs = new List<ItemSpec>();

            // define the check-in comment
            string checkinComment = String.Format("Changed SystemOption.sql file version to {0}.{1}.{2}.{3}", major, minor, ternary, revision);

            // loop through all the System_Option.sql files found in folders and subfolders
            foreach (string filename in resourceFiles)
            {
                // temp file name to build
                string tempPath = Path.GetTempFileName();

                using (StreamReader reader = new StreamReader(filename, System.Text.Encoding.Default))
                {
                    using (StreamWriter writer = new StreamWriter(tempPath, false, reader.CurrentEncoding))
                    {
                        string line;

                        while ((line = reader.ReadLine()) != null)
                        {
                            // ensure the file is writeable. This should be set in build definition but also done here to be sure.
                            FileAttributes fileAttributes = File.GetAttributes(filename);
                            File.SetAttributes(filename, fileAttributes & ~FileAttributes.ReadOnly);

                            // trim the leading spaces/tabs that may exists in resource file.
                            string templine = line.TrimStart();
                            
                            // find lines that being with FILEVERSION, PRODUCTVERSION, VALUE "FileVersion" or VALUE "ProductVersion".
                            if (templine.StartsWith("SET @Version = "))
                            {
                                line = string.Format(CultureInfo.InvariantCulture, " SET @Version = '{0}.{1}.{2}.{3}';", major, minor, ternary, revision);
                            }                           

                            // Write line to temp file.
                            writer.WriteLine(line);
                        }
                    }
                }

                // Copy tempfile overwriting the original resource file.
                File.Copy(tempPath, filename, true);

                // check-out the resource file
                //workspace.PendEdit(filename);

                // Add file to collection
                itemSpecs.Add(new ItemSpec(filename, RecursionType.None));
            }    
        
            // check-in all resource files that were updated
            //WorkspaceCheckInParameters wcip = new WorkspaceCheckInParameters(itemSpecs.ToArray(), checkinComment);
            //workspace.CheckIn(wcip, "DEVTFS", checkinComment, null, );

            // Checks all files in in the workspace that have pending changes
            // The ***NO_CI*** comment ensures that the CI build is not triggered (and that
            // you end in an endless loop)
            //workspace.CheckIn(workspace.GetPendingChanges(), "Build Agent", "***NO_CI***", null, null, new PolicyOverrideInfo("Auto checkin", null), CheckinOptions.SuppressEvent);                       
        }
    }
}

