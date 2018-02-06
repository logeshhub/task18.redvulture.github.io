// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Program.cs" company="3MHIS">
//   Copyright 2011 3MHIS
// </copyright>
// <summary>
//   The RedGateWrapper program. Uses the Redgate SQL Compare SDK 8 to generate a database snapshot.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace RedGateWrapper
{
    using System;
    using mmmHIS.Framework.Diagnostics;

    /// <summary>
    /// The program.
    /// </summary>
    internal class Program
    {
        #region Methods

        /// <summary>
        /// The main method of RedgateWrapper.exe.
        /// </summary>
        /// <param name="args">
        /// The args are the arguments passed to the Main method.
        /// </param>
        private static void Main(string[] args)
        {
            // Command line parsing
            var commandLine = new Arguments(args);

            // Log object
            Log.FileLogLevel = LogLevels.All;

            Log.Information(0, "database: " + commandLine["database"]);
            Log.Information(0, "server: " + commandLine["server"]);
            Log.Information(0, "snapshot: " + commandLine["snapshot"]);

            // Look for specific arguments values             
            if ((commandLine["database"] != null) && (commandLine["server"] != null) && (commandLine["snapshot"] != null))
            {
                var sqlCompare = new SqlCompare();
                sqlCompare.GenerateSnapshot(
                    commandLine["database"].ToString(),
                    commandLine["server"].ToString(),
                    commandLine["snapshot"].ToString());
            }
            else
            {
                Log.Information(0, "Usage: RedGateWrapper.exe /database:yourname /server:yourserver /snapshot:yourfilename");
                Console.WriteLine(
                    "Usage: RedGateWrapper.exe /database:yourname /server:yourserver /snapshot:yourfilename");
            }
        }    
        #endregion
    }
}