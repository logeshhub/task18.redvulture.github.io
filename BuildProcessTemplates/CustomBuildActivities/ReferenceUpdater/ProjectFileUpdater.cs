using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace mmmHIS.ALM.Build.Activities
{
    /// <summary>
    /// Updates the version suffix of Smart Framework assemblies referenced in csproj files. Implements <see cref="ReferenceUpdaterBase"></see>.
    /// </summary>
    public class ProjectFileUpdater : ReferenceUpdaterBase
    {      
        private Regex projectRegex = new Regex(@"Project.+?EndProject", RegexOptions.Singleline | RegexOptions.Compiled);

        /// <summary>
        /// Initializes a new instance of the ProjectFileUpdaterClass.
        /// </summary>
        /// <param name="solutionFiles">The solution files specified by the build definition.</param>
        /// <param name="newVersion">The new Smart Framework version specified in the build definition.</param>
        public ProjectFileUpdater(List<String> solutionFiles, string newVersion)
            : base(solutionFiles, newVersion, ".csproj")
        {
        }

        /// <summary>
        /// Extracts a list of csproje files included in each project.
        /// </summary>
        public override void ExtractCandidateFiles()
        {
            CandidateFiles.Clear();
            foreach (String solutionFile in SourceFiles)
            {
                String baseDir = Path.GetDirectoryName(solutionFile) + "\\";
                Uri baseUri = new Uri(baseDir);

                String solutionFileContents = File.ReadAllText(solutionFile);
                MatchCollection matches = projectRegex.Matches(solutionFileContents);
                foreach (Match match in matches)
                {
                    String[] parts = match.Value.Replace("\r\n", " ").Split(',');

                    if (parts != null && parts.Length > 1 && parts[1].Contains(FileExtension))
                    {
                        Uri csprojUri = new Uri(baseUri, parts[1].Replace("\"", ""));
                        if (!CandidateFiles.Contains(csprojUri.LocalPath))
                        {
                            CandidateFiles.Add(csprojUri.LocalPath);
                        }
                    }
                }
            }
        }
 
        /// <summary>
        /// Determines which of the candidate files contain framework references.
        /// </summary>
        public override void FindFilesWithFrameworkReferences()
        {
            foreach (string projectFileName in CandidateFiles)
            {
                try
                {
                    XElement projectElement = XElement.Load(projectFileName);
                    IEnumerable<XElement> itemGroupElements = projectElement.Elements().Where(x => x.Name.LocalName == "ItemGroup");
                    IEnumerable<XElement> referenceElements = itemGroupElements.SelectMany(i => i.Elements().Where(r => (r.Name.LocalName == "Reference") && IsOursAndNeedsUpdating(r)));
                    if (referenceElements.Count() > 0)
                    {
                        if (!FilesWithFrameworkReferences.Contains(projectFileName))
                        {
                            FilesWithFrameworkReferences.Add(projectFileName);
                        }
                    }
                }

                catch (Exception)
                {
                    throw;
                }
            }
        }

        /// <summary>
        /// Updates references in <see cref="ReferenceUpdaterBase.FilesWithFrameworkReference"/>.
        /// </summary>
        /// <param name="workspace">The Workspace being used by the Team Foundation Server.</param>
        /// <param name="itemSpecs">A list of ItemSpec, provided by <see cref="ReferenceUpdateManager"/>.</param>
        public override void UpdateReferences(Workspace workspace, List<ItemSpec> itemSpecs)
        {            
            // filesWithFrameworkReferences will only contain csproj files that have framework references that need updating!
            Parallel.ForEach(FilesWithFrameworkReferences, projectFile =>
            {
                int filesCheckedOut = workspace.PendEdit(projectFile);
                UpdateFile(projectFile);
                lock (itemSpecs)
                {
                    itemSpecs.Add(new ItemSpec(projectFile, RecursionType.None));
                }
            });
        }

        /// <summary>
        /// Gets the csproj files referenced by the solutions specified in the build definition.
        /// </summary>
        public List<string> ProjectFiles
        {
            get
            {
                return CandidateFiles;
            }
        }
 
        /// <summary>
        /// Updates a csproj file by changing references to <see cref="ReferenceUpdaterBase.NewVersion"/> and then saving the file.
        /// </summary>
        /// <param name="projectFile">The project file to update.</param>
        protected override void UpdateFile(string projectFile)
        {
            try
            {
                XElement projectElement = XElement.Load(projectFile);

                IEnumerable<XElement> itemGroupElements = projectElement.Elements().Where(x => x.Name.LocalName == "ItemGroup");
                IEnumerable<XElement> referenceElements = itemGroupElements.SelectMany(i => i.Elements().Where(r => (r.Name.LocalName == "Reference") && IsOursAndNeedsUpdating(r)));
                Boolean changed = false;

                foreach (XElement referenceElement in referenceElements)
                {
                    UpdateVersion(referenceElement, NewVersion, ref changed);
                }

                if (changed)
                {
                    try
                    {
                        projectElement.Save(projectFile);
                    }
                    catch
                    {
                        throw;
                    }
                }
            }
            catch
            {
                throw;
            }

        }

        /// <summary>
        /// Verfies whether an Include attribute contains a reference to a SmartFramework assembly.
        /// Extracts the assembly name from the Include element, and delegates the assembly validation
        /// to <see cref="Util.IsOursAndNeeds updating"/>.
        /// </summary>
        /// <param name="x">The element that contains the Include attribute.</param>
        /// <returns>Returns true if the element references a Smart Framework assembly reference that needs updating.</returns>
        private Boolean IsOursAndNeedsUpdating(XElement x)
        {
            Boolean isOurs = false;
            XAttribute includeAttribute = x.Attribute("Include");
            if (includeAttribute != null)
            {
                String[] parts = includeAttribute.Value.Split(',');
                isOurs = Util.IsOursNeedsUpdating(parts[0], NewVersion);
            }

            return isOurs;
        }

        /*
         * 
         *     <Reference Include="SoftMed.Framework.Common.v3.5.6, Version=3.5.1.2, Culture=neutral, processorArchitecture=MSIL">
         *       <SpecificVersion>False</SpecificVersion>
         *     </Reference>
         * 
         * 
         *     <Reference Include="mmmHIS.Core.CentralMenu.v3.5.6">
         *       <HintPath>..\..\..\..\Depot\Softmed\SmartFramework_MS_Framework_v3.6\Deliverables\SmartFramework\Release\mmmHIS.Core.CentralMenu.v3.5.6.dll</HintPath>
         *     </Reference>
         * 
         */

        /// <summary>
        /// Updates the framework reference in a &lt;Reference Include= ...&gt; XML element in the csproj file.
        /// </summary>
        /// <param name="referenceElement">The &lt;Reference Include= ...&gt; element.</param>
        /// <param name="version">The new version number.</param>
        /// <remarks>Prerequisite:  the new files must be present on the local computer in the same location of the hint path.</remarks>
        /// <param name="changed">Set to true during processing if an element is changed.</param>
        private void UpdateVersion(XElement referenceElement, String newVersion, ref Boolean changed)
        {
            XAttribute includeAttribute = referenceElement.Attribute("Include");

            /*
             * The element looks like this:
             * <Reference Include="SoftMed.Framework.UI.Components.v3.5.6, Version=3.5.1.2, Culture=neutral, processorArchitecture=MSIL">
             * 
             * or this:
             * <Reference Include="mmmHIS.Core.CentralMenu.v3.5.6">
             * 
             */

            String[] includeParts = includeAttribute.Value.Split(',');
            String currentAssemblyName = includeParts[0];

            String newAssemblyName = Util.ComposeNewAssemblyName(currentAssemblyName, newVersion);
            includeAttribute.Value = newAssemblyName;

            if (!newAssemblyName.Equals(currentAssemblyName, StringComparison.CurrentCultureIgnoreCase))
            {
                try
                {
                    XElement hintPathElement = referenceElement.Descendants().Where(e => e.Name.LocalName == "HintPath").FirstOrDefault();
                    if (hintPathElement != null && hintPathElement.Value.Contains(currentAssemblyName))
                    {
                        hintPathElement.Value = Util.ComposeNewAssemblyName(hintPathElement.Value, newVersion);
                    }

                    changed = true;
                }

                catch (Exception)
                {
                    throw;
                }
            }
        }
    }
}
