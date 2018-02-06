//-----------------------------------------------------------------------
// <copyright file="VSDevEnvTests.cs">(c) http://TfsBuildExtensions.codeplex.com/. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
//-----------------------------------------------------------------------
namespace TfsBuildExtensions.Activities.Tests
{
    using System.Activities;
    using System.IO;
    using Microsoft.VisualStudio.TestTools.UnitTesting;
    using TfsBuildExtensions.Activities.VisualStudio;

    /// <summary>
    /// This is a test class for TfsVersionTest and is intended
    /// to contain all TfsVersionTest Unit Tests
    /// </summary>
    [TestClass]
    public class VSDevEnvTests
    {
        /// <summary>
        /// Gets or sets the test context which provides
        /// information about and functionality for the current test run.
        /// </summary>
        public TestContext TestContext { get; set; }
       
        /// <summary>
        /// VSDevEnvBuildSolution
        /// </summary>
        [TestMethod]
        [DeploymentItem("TfsBuildExtensions.Activities.dll")]
        public void VSDevEnvBuildSolution()
        {
            // Initialise Instance
            var target = new VSDevEnv { FilePath = @"D:\Projects\teambuild2010contrib\MAIN\Source\Activities.Tests\VisualStudio\VSDevEnvSample\VSDevEnvSample.sln", Configuration = "Debug|x86", Rebuild = true, OutputFile = @"c:\log.txt" };

            if (File.Exists(@"D:\Projects\teambuild2010contrib\MAIN\Source\Activities.Tests\VisualStudio\VSDevEnvSample\bin\debug\VSDevEnvSample.exe"))
            {
                File.Delete(@"D:\Projects\teambuild2010contrib\MAIN\Source\Activities.Tests\VisualStudio\VSDevEnvSample\bin\debug\VSDevEnvSample.exe");
            }

            // Create a WorkflowInvoker and add the IBuildDetail Extension
            WorkflowInvoker invoker = new WorkflowInvoker(target);
            
            invoker.Invoke();

            // Test the result
            Assert.IsTrue(File.Exists(@"D:\Projects\teambuild2010contrib\MAIN\Source\Activities.Tests\VisualStudio\VSDevEnvSample\bin\debug\VSDevEnvSample.exe"));
        }
    }
}
