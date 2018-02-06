//-----------------------------------------------------------------------
// <copyright file="VSDevEnv.cs">(c) http://TfsBuildExtensions.codeplex.com/. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
//-----------------------------------------------------------------------
namespace TfsBuildExtensions.Activities.VisualStudio
{
    using System.Activities;
    using System.Diagnostics;
    using System.Globalization;
    using System.IO;
    using Microsoft.Build.Utilities;
    using Microsoft.TeamFoundation.Build.Client;

    /// <summary>
    /// VSDevEnv
    /// </summary>
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class VSDevEnv : BaseCodeActivity
    {
        private string devenvpath = "devenv.exe";

        /// <summary>
        /// The Path to the solution or Project to build
        /// </summary>
        [RequiredArgument]
        public InArgument<string> FilePath { get; set; }

        /// <summary>
        /// The Configuration to Build.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> Configuration { get; set; }

        /// <summary>
        /// The path to DevEnv.exe. Default is DevEnv.exe, so the path should be in your Path Environment Variable.
        /// </summary>
        public string DevEnvPath
        {
            get { return this.devenvpath; }
            set { this.devenvpath = value; }
        }

        /// <summary>
        /// Specifies whether Clean and then build the solution or project with the specified configuration. Default is false
        /// </summary>
        public bool Rebuild { get; set; }

        /// <summary>
        /// Specifies the File to log all output to.
        /// </summary>
        [RequiredArgument]
        public InArgument<string> OutputFile { get; set; }

        /// <summary>
        /// Executes the logic for this workflow activity
        /// </summary>
        protected override void InternalExecute()
        {
            using (Process proc = new Process())
            {
                proc.StartInfo.FileName = this.DevEnvPath;
                proc.StartInfo.UseShellExecute = false;
                proc.StartInfo.RedirectStandardOutput = true;
                proc.StartInfo.RedirectStandardError = true;
                proc.StartInfo.Arguments = this.GenerateCommandLineCommands();
                this.LogBuildMessage("Running " + proc.StartInfo.FileName + " " + proc.StartInfo.Arguments);
                proc.Start();

                string outputStream = proc.StandardOutput.ReadToEnd();
                if (outputStream.Length > 0)
                {
                    this.LogBuildMessage(outputStream);
                }

                string errorStream = proc.StandardError.ReadToEnd();
                if (errorStream.Length > 0)
                {
                    this.LogBuildError(errorStream);
                }

                proc.WaitForExit();
                if (proc.ExitCode != 0)
                {
                    this.LogBuildError(proc.ExitCode.ToString(CultureInfo.CurrentCulture));
                    return;
                }
            }
        }

        private string GenerateCommandLineCommands()
        {
            FileInfo outputfile = new FileInfo(this.OutputFile.Get(this.ActivityContext));
            if (outputfile.Exists)
            {
                outputfile.Delete();
            }

            CommandLineBuilder builder = new CommandLineBuilder();
            builder.AppendSwitch(this.Rebuild ? "/Rebuild" : "/Build");
            builder.AppendSwitch("\"" + this.Configuration.Get(this.ActivityContext) + "\"");
            builder.AppendSwitch("/out \"" + outputfile.FullName + "\"");
            builder.AppendSwitch("\"" + this.FilePath.Get(this.ActivityContext) + "\"");
            return builder.ToString();
        }
    }
}