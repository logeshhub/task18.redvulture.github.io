// --------------------------------------------------------------------------------------------------------------------
// <copyright file="SQLCompare.cs" company="3MHIS">
//   Copyright 2011 3MHIS
// </copyright>
// <summary>
//   Saves a snapshot of the a database to disk and
//   loads it back in again.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace RedGateWrapper
{
    using System;
    using System.Data.SqlClient;  
    using RedGate.SQLCompare.Engine;
    using mmmHIS.Framework.Diagnostics;
    
    /// <summary>
    /// Saves a snapshot of a database to disk.
    /// </summary>
    internal class SqlCompare
    {
        #region Public Methods

        /// <summary>
        /// GenerateSnapshot of a database.
        /// </summary>
        /// <param name="stagingDatabaseName">
        /// The name of the database to be snapshotted.
        /// </param>
        /// <param name="stagingServerName">
        /// The name of the server hosting the database.
        /// </param>
        /// <param name="snapshotName">
        /// The name of the snapshot file to generate.
        /// </param>
        public void GenerateSnapshot(string stagingDatabaseName, string stagingServerName, string snapshotName)
        {
            // <summary>
            // The path which the snapshot will be saved to
            // </summary>
            string snapshotFile = snapshotName + ".snp";

            using (var stagingDb = new Database())
            {
                // Connect to the WidgetStaging database and read the schema
                var connectionProperties = new ConnectionProperties(stagingServerName, stagingDatabaseName);

                try
                {
                    Log.Information(0, "Registering database " + connectionProperties.DatabaseName);                                       
                    stagingDb.Register(connectionProperties, Options.Default);

                    // Save a snapshot of the database to WidgetStaging.snp
                    Log.Information(0, "Saving snapshot...");
                    Console.WriteLine("Saving snapshot");
                    stagingDb.SaveToDisk(snapshotFile);
                }
                catch (SqlException e)
                {
                    Log.Information(0, e.Message);
                    Log.Information(0, "Database:" + connectionProperties.DatabaseName);
                    Log.Information(0, "Server:" + connectionProperties.ServerName);

                    Console.WriteLine(e.Message);
                    Console.WriteLine(
                        @"
                        Cannot connect to database '{0}' on server '{1}'. The most common causes of this error are:
                        o The sample databases are not installed
                        o ServerName not set to the location of the target database
                        o For sql server authentication, username and password incorrect or not supplied in ConnectionProperties constructor
                        o Remote connections not enabled", 
                        connectionProperties.DatabaseName, 
                        connectionProperties.ServerName);
                    return;
                }
                catch (Exception e)
                {
                    Log.Information(0, e.Message);
                    Console.WriteLine(e.Message);
                }
            }
        }

        #endregion
    }
}