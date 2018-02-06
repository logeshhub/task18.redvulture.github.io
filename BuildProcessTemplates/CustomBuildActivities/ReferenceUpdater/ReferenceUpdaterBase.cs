using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace mmmHIS.ALM.Build.Activities
{
    /// <summary>
    /// Abstract base class representing the methods required of a reference updater derivative and including protected members.
    /// </summary>
    public abstract class ReferenceUpdaterBase
    {
        /// <summary>
        /// The source files, either .sln file that contain .csproj references, or .csproj files that contain .config references.
        /// This list must be provided by the constructor of the implementing class.
        /// </summary>
        protected List<string> SourceFiles;
        protected List<string> FilesWithFrameworkReferences = new List<string>();
        protected List<string> CandidateFiles = new List<string>();
        protected string NewVersion;
        protected String FileExtension;

        /// <summary>
        /// Initializes protected fields of the ReferenceUpdaterBase class and
        /// </summary>
        /// <param name="sourceFiles">The solution (.sln) files for a ProjectFileUpdater, or the project (.csproj) files for
        /// a ConfigFileUpdater.</param>
        /// <param name="newVersion">The new Framework version</param>
        /// <param name="fileExtension">The file extension of the SourceFiles (.sln or .csproj).</param>
        protected ReferenceUpdaterBase(List<String> sourceFiles, string newVersion, string fileExtension)
        {
            this.SourceFiles = sourceFiles;
            this.NewVersion = newVersion;
            this.FileExtension = fileExtension;
        }

        /// <summary>
        /// Creates a list of files that may contain Framework references. The candidate files for a .sln are the .csproj files. 
        /// The candidate files for a .csproj file are the .config files.
        /// </summary>
        public abstract void ExtractCandidateFiles();

        /// <summary>
        /// Searches the CandidateFiles to discover if any elements contain Smart Framework references that need updating.
        /// </summary>
        public abstract void FindFilesWithFrameworkReferences();

        /// <summary>
        /// Updates Smart Framework references to <see cref="NewVersion"/>.
        /// </summary>
        /// <param name="workspace">The <see cref="Microsoft.TeamFoundation.VersionControl.Client.Workspace"/> that is being
        /// used on the build machine.</param>
        /// <param name="itemSpecs">A list of <see cref="Microsoft.TeamFoundation.VersionControl.Client.ItemSpec"/> representing
        /// the files that were checked out and changed and need to be checked back in.</param>
        public abstract void UpdateReferences(Workspace workspace, List<ItemSpec> itemSpecs);
        protected abstract void UpdateFile(string fileName);
    }
}
