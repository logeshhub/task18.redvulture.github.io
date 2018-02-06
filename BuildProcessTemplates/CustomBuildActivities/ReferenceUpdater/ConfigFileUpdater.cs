using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.XPath;
using System.Xml.Linq;
using Microsoft.TeamFoundation.VersionControl.Client;
using System.Threading.Tasks;

namespace mmmHIS.ALM.Build.Activities
{
    /// <summary>
    /// Updates the version suffix of Smart Framework assemblies referenced in configuration files. Implements <see cref="ReferenceUpdaterBase"></see>.
    /// </summary>
    public class ConfigFileUpdater : ReferenceUpdaterBase
    {
        /// <summary>
        /// A delegate for "LookIn ..." methods. One delegate will be created for each "LookIn" method.
        /// </summary>
        /// <param name="fileName"></param>
        /// <param name="configFile"></param>
        /// <param name="continueToNextFile"></param>
        private delegate void LookIn(string fileName, XDocument configFile, out bool continueToNextFile);

        /// <summary>
        /// A multi-cast delegate to handle "Update..." methods.
        /// </summary>
        /// <param name="fileName"></param>
        /// <param name="configFile"></param>
        private delegate void Update(XDocument configFile, string newVersion);

        // use a list instead of a delegate because we want to be able to break out, which we can't do with a delegate
        private List<LookIn> lookinProcs;
        private Update updateProcs;

        /// <summary>
        /// Initializes a new instance of the ConfigFileUpdater class.
        /// </summary>
        /// <param name="projectFiles">The project files discovered by ProjectFileUpdater.</param>
        /// <param name="newVersion">The Smart Framework version specified in the definition.</param>
        public ConfigFileUpdater(List<string> projectFiles, String newVersion)
            : base(projectFiles, newVersion, "config")
        {
            lookinProcs = new List<LookIn>
            {
                LookInConfigSection,
                LookInModulesSection,
                LookInRemotingSection,
                LookInExceptionHandlingSection,
                LookInControlsSection
            };

            updateProcs += UpdateConfigSection;
            updateProcs += UpdateRemotingSection;
            updateProcs += UpdateModulesSection;
            updateProcs += UpdateExceptionHandlingSection;
            updateProcs += UpdateControlsSection;
        }

        /// <summary>
        /// Extracts a list of configuration files included in each project.
        /// </summary>
        public override void ExtractCandidateFiles()
        {
            foreach (String csprojFile in SourceFiles)
            {
                XElement projectFile = XElement.Load(csprojFile);
                String baseDir = Path.GetDirectoryName(csprojFile) + "\\";
                Uri baseUri = new Uri(baseDir);
                IEnumerable<XElement> itemGroupElements = projectFile.Elements().Where(x => x.Name.LocalName == "ItemGroup");
                IEnumerable<XElement> noneOrContentElements = itemGroupElements.SelectMany(i => i.Elements().Where(r => (r.Name.LocalName.Equals("None") || r.Name.LocalName.Equals("Content"))));
                foreach (XElement noneOrContentElement in noneOrContentElements)
                {
                    XAttribute includeAttribute = noneOrContentElement.Attribute("Include");
                    if (includeAttribute != null && includeAttribute.Value.EndsWith(FileExtension, StringComparison.CurrentCultureIgnoreCase))
                    {
                        Uri configUri = new Uri(baseUri, includeAttribute.Value);
                        if (!File.Exists(configUri.LocalPath))
                        {
                            String message = String.Format("Config file {0} referenced in {1} could not be found.", configUri.LocalPath, csprojFile);
                            throw new FileNotFoundException(message);
                        }
                        else if (!CandidateFiles.Contains(configUri.LocalPath))
                        {
                            CandidateFiles.Add(configUri.LocalPath);
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
            foreach (String filename in CandidateFiles)
            {
                XDocument configFile = null;
                try
                {
                    configFile = XDocument.Load(filename);
                }
                catch
                {
                    throw;
                }
                
                // In any of the "LookIn..." methods, as soon as at least one Smart Framework reference is found,
                // move on the the next file 

                Boolean continueToNextFile = false;
                foreach (LookIn lookinProc in lookinProcs)
                {
                    lookinProc(filename, configFile, out continueToNextFile);
                    if (continueToNextFile)
                    {
                        break;
                    }
                } 
            }
        }

        /// <summary>
        /// Updates Framework references in the configuration files in <see cref="ReferenceUpdaterBase.FilesWithFrameworkReferences"/>.
        /// </summary>
        /// <param name="workspace">The Workspace being used by the Team Foundation Server.</param>
        /// <param name="itemSpecs">A list of ItemSpec, provided by <see cref="ReferenceUpdateManager"/>.</param>
        public override void UpdateReferences(Workspace workspace, List<ItemSpec> itemSpecs)
        {
            // Unlike ProjectFileUpdater, FindFilesWithFrameworkReferences does not also check that all elements with Framework references have the 
            // current version. It could be presumed that if one is correct, all are, but in fact the check of all elements only occurs during UpdateFile.
            Parallel.ForEach (FilesWithFrameworkReferences, configFile =>
            {
                workspace.PendEdit(configFile);
                UpdateFile(configFile);
                lock (itemSpecs)
                {
                    itemSpecs.Add(new ItemSpec(configFile, RecursionType.None));
                }
             });
         }

        #region Private "LookIn..." methods to determine if any elements of a specific type contain Framework references that must be changed

        private void LookInConfigSection(String filename, XDocument configFile, out Boolean continueToNextFile)
        {
            continueToNextFile = false;
            IEnumerable<XElement> configSectionsElement = configFile.Descendants().Where(d => d.Name.LocalName == "configSections");
            foreach (XElement sectionElement in configSectionsElement.Descendants().Where(x => x.Name.LocalName == "section"))
            {
                XAttribute typeAttribute = sectionElement.Attributes()
                    .Where(x => x.Name.LocalName == "type")
                    .FirstOrDefault();

                if (IsFrameworkAttribute(typeAttribute))
                {
                    AddFileWithFrameworkReferences(filename);
                    continueToNextFile = true;
                    break;
                }

                if (continueToNextFile)
                {
                    break;
                }
            }
        }

        private void LookInModulesSection(String filename, XDocument configFile, out Boolean continueToNextFile)
        {
            // Find files with references in the Modules Section
            continueToNextFile = false;
            IEnumerable<XElement> modulesSectionElement = configFile.Descendants().Where(d => d.Name.LocalName == "ModulesSection");
            foreach (XElement classElement in modulesSectionElement.Descendants().Elements().Where(x => x.Name.LocalName == "Class"))
            {
                XAttribute typeNameAttribute = classElement.Attributes()
                    .Where(x => x.Name.LocalName == "typeName")
                    .FirstOrDefault();

                if (IsFrameworkAttribute(typeNameAttribute))
                {
                    AddFileWithFrameworkReferences(filename);
                    continueToNextFile = true;
                    break;
                }

                if (continueToNextFile)
                {
                    break;
                }
            }
        }

        private void LookInRemotingSection(String filename, XDocument configFile, out Boolean continueToNextFile)
        {
            continueToNextFile = false;

            /* Find files with references in the Remoting section, e.g.
             * 
             * <system.runtime.remoting>
             *   <application>
             *     <channels>
             *       <channel ref="http">
             *         <clientProviders>
             *           <provider type="SoftMed.Framework.Common.PrincipalTransportClientSinkProvider, SoftMed.Framework.Common" />
             *           <provider type="SoftMed.Framework.Common.AuthenticationClientSinkProvider, SoftMed.Framework.Common" />
             *           <provider type="SoftMed.Framework.Common.CompressionClientSinkProvider, SoftMed.Framework.Common" />
             *         </clientProviders>
             *       </channel>
             *     </channels>
             *   </application>
             * </system.runtime.remoting>
             * 
             */

            XElement remotingElement = configFile.Descendants().Where(d => d.Name.LocalName == "system.runtime.remoting").FirstOrDefault();
            XElement applicationElement = null;
            if (remotingElement != null)
            {
                applicationElement = remotingElement.Descendants().Where(d => d.Name.LocalName == "application").FirstOrDefault();
                if (applicationElement != null)
                {
                    XElement clientProviderElement = remotingElement.Descendants().Where(d => d.Name.LocalName == "clientProviders").FirstOrDefault();
                    if (clientProviderElement != null)
                    {
                        foreach (XElement providerElement in clientProviderElement.Elements().Where(d => d.Name.LocalName == "provider"))
                        {
                            XAttribute typeAttribute = providerElement.Attributes()
                                .Where(x => x.Name.LocalName == "type")
                                .FirstOrDefault();

                            if (IsFrameworkAttribute(typeAttribute))
                            {
                                AddFileWithFrameworkReferences(filename);
                                continueToNextFile = true;
                                break;
                            }

                            if (continueToNextFile)
                            {
                                break;
                            }
                        }
                    }
                }
            }

            /* and also services
             * 
             *  <system.runtime.remoting>
             *    <application>
             *      <service>
             *        <wellknown mode="SingleCall" objectUri="AutoGeneratedDocumentBusinessService.rem" type="MMM.HIS.DCD.AutoGeneratedDocumentManagement.AutoGeneratedDocumentBusinessService, MMM.HIS.DCD.Service" />
             *        <wellknown mode="SingleCall" objectUri="CentralVoiceTransferManager.rem" type="MMM.HIS.DCD.VoiceScript.MaintenanceService.CentralVoiceTransferManagement,MMM.HIS.DCD.Service"/>
             *        <wellknown mode="SingleCall" objectUri="ChartScriptNetExporter.rem" type="mmmHIS.DCD.JobExport.Service.ChartScriptNetExportBusinessService, mmmHIS.DCD.JobExport.Service" />
             *        <wellknown mode="SingleCall" objectUri="ChartScriptNetUserBusinessService.rem" type="MMM.HIS.DCD.ChartScriptNetUserManagement.ChartScriptNetUserBusinessService, MMM.HIS.DCD.Service" />
             *        <wellknown mode="SingleCall" objectUri="CodeTableManager.rem" type="MMM.HIS.DCD.CodeTableManagement.CodeTableBusinessService, MMM.HIS.DCD.Service" />
             *      </service>
             *    </application>
             *  </system.runtime.remoting>
            */

            if (!continueToNextFile && (remotingElement != null) && (applicationElement != null))
            {
                XElement serviceElement = remotingElement.Descendants().Where(d => d.Name.LocalName == "service").FirstOrDefault();
                if (serviceElement != null)
                {
                    foreach (XElement providerElement in serviceElement.Elements().Where(d => d.Name.LocalName == "wellknown"))
                    {
                        XAttribute typeAttribute = providerElement.Attributes()
                            .Where(x => x.Name.LocalName == "type")
                            .FirstOrDefault();

                        if (IsFrameworkAttribute(typeAttribute))
                        {
                            AddFileWithFrameworkReferences(filename);
                            continueToNextFile = true;
                            break;
                        }

                        if (continueToNextFile)
                        {
                            break;
                        }
                    }
                }
            }
        }

        private void LookInExceptionHandlingSection(String filename, XDocument configFile, out Boolean continueToNextFile)
        {
            continueToNextFile = false;

            /* FindFilesWith references in the ExceptionHandling section, e.g.
             * 
             * <exceptionHandling>
             *   <exceptionPolicies>
             *     <add name="FrameworkBusinessLayerExceptionPolicy">
             *       <exceptionTypes>
             *         <add name="Exception" type="System.Exception, mscorlib" postHandlingAction="ThrowNewException">
             *           <exceptionHandlers>
             *             <add name="Custom Handler" type="SoftMed.Framework.Common.ExceptionHandlers.FrameworkBusinessExceptionHandler, SoftMed.Framework.Common" />
             *           </exceptionHandlers>
             *         </add>
             *       </exceptionTypes>
             *     </add>
             *   </exceptionPolicies>
             * </exceptionHandling>
             * 
             */

            IEnumerable<XElement> exceptionHandlerElements = configFile.Descendants().Where(x => x.Name.LocalName == "exceptionHandlers");

            foreach (XElement exceptionHandlerElement in exceptionHandlerElements)
            {
                IEnumerable<XElement> addElements = exceptionHandlerElement.Descendants().Where(x => x.Name.LocalName == "add");
                foreach (XElement addElement in addElements)
                {
                    XAttribute typeAttribute = addElement.Attributes().FirstOrDefault(a => a.Name.LocalName.Equals("type"));
                    if (IsFrameworkAttribute(typeAttribute))
                    {
                        AddFileWithFrameworkReferences(filename);
                        continueToNextFile = true;
                        break;
                    }
                }
            }
        }

        private void LookInControlsSection(String filename, XDocument configFile, out Boolean continueToNextFile)
        {
            continueToNextFile = false;

            /* FindFilesWith references in the Controls section, e.g.
             * 
             * <UserEditorNodes>
             *     <Controls>
             *       <add NodeName="General" Control="SoftMed.Framework.UI.COR_SystemAdmin.COR_UserDetailsGeneral,SoftMed.Framework.UI.Components.v3.5.2" MultiEdit="False" />
             *       <add NodeName="Modules" Control="SoftMed.Framework.UI.COR_SystemAdmin.COR_UserModule,SoftMed.Framework.UI.Components.v3.5.2" MultiEdit="False" />
             *       <add NodeName="Groups" Control="SoftMed.Framework.UI.SystemAdmin.COR_UserGroupMappingControl,SoftMed.Framework.UI.Components.v3.5.2" MultiEdit="False" />
             *     </Controls>
             *   </UserEditorNodes>
             *   <GroupEditorNodes>
             *     <Controls>
             *       <add NodeName="General" Control="SoftMed.Framework.UI.Forms.Admin.GroupDetailsGeneral,SoftMed.Framework.UI.Components.v3.5.2" MultiEdit="False" />
             *       <add NodeName="Users" Control="SoftMed.Framework.UI.Forms.Admin.GroupDetailsUsers,SoftMed.Framework.UI.Components.v3.5.2" MultiEdit="False" />
             *     </Controls>
             *   </GroupEditorNodes>
             *   
             */

            IEnumerable<XElement> addElements =
                from element in configFile.Elements().First().XPathSelectElements("//*//Controls//add")
                select element;

            foreach (XElement addElement in addElements)
            {
                XAttribute typeAttribute = addElement.Attributes().FirstOrDefault(a => a.Name.LocalName.Equals("Control"));
                if (IsFrameworkAttribute(typeAttribute))
                {
                    AddFileWithFrameworkReferences(filename);
                    continueToNextFile = true;
                    break;
                }
            }
        }

        #endregion

        #region Private "Update..." methods to change Framework references in elements of a specific type

        /// <summary>
        /// Updates a configuration file by changing references to <see cref="ReferenceUpdaterBase.NewVersion"/> and then saving the file.
        /// </summary>
        /// <param name="configFile">The configuration file to update.</param>
        protected override void UpdateFile(string configFile)
        {
            try
            {
                XDocument configElement = XDocument.Load(configFile);
                updateProcs(configElement, NewVersion);
                try
                {
                    configElement.Save(configFile);
                }
                catch
                {
                    throw;
                }
                
            }
            catch
            {
                throw;
            }
        }

        /// <summary>
        /// Update the typename entries nested within the &lt;ModulesSection&gt;.
        /// </summary>
        /// <param name="configFile">The configuration file that contains the &lt;ModulesSection&gt;.</param>
        /// <param name="version">The new version.</param>
        /// <param name="changed">True if any value was changed during the update. Will not change an argument of true to false.</param>
        /// <remarks>Typically found in the Modules.custom.config file.</remarks>
        private void UpdateModulesSection(XDocument configFile, String version)
        {
            IEnumerable<XElement> modulesSectionElement = configFile.Descendants().Where(d => d.Name.LocalName == "ModulesSection");
            foreach (XElement classElement in modulesSectionElement.Descendants().Elements().Where(x => x.Name.LocalName == "Class"))
            {
                XAttribute typeNameAttribute = classElement.Attributes()
                    .Where(x => x.Name.LocalName == "typeName")
                    .FirstOrDefault();
                UpdateVersionInTypeAttribute(typeNameAttribute, version);
            }
        }

        /// <summary>
        /// Updates entries that are children of the &lt;configSections&gt; element.
        /// </summary>
        /// <param name="configFile">The configuration file.</param>
        /// <param name="version">The new version.</param>
        /// <param name="changed">True if any value was changed during the update.</param>
        /// <remarks>Typically found in the application configuration file.</remarks>
        private void UpdateConfigSection(XDocument configFile, String version)
        {
            IEnumerable<XElement> configSectionsElement = configFile.Descendants().Where(d => d.Name.LocalName == "configSections");
            IEnumerable<XElement> sectionElements = configSectionsElement.Descendants().Where(x => x.Name.LocalName == "section");
            foreach (XElement sectionElement in sectionElements)
            {
                XAttribute typeAttribute = sectionElement.Attributes()
                    .Where(x => x.Name.LocalName == "type")
                    .FirstOrDefault();

                UpdateVersionInTypeAttribute(typeAttribute, version);
            }
        }

        /// <summary>
        /// Updates &lt;provider&gt; entries nested within the &lt;system.runtime.remoting&gt; section.
        /// </summary>
        /// <param name="configFile">The configuration file that contains the &lt;ModulesSection&gt;.</param>
        /// <param name="version">The new version.</param>
        /// <remarks>Typically found in the application config file. </remarks>
        private void UpdateRemotingSection(XDocument configFile, String version)
        {
            XElement remotingElement = configFile.Descendants().Where(d => d.Name.LocalName == "system.runtime.remoting").FirstOrDefault();
            if (remotingElement != null)
            {
                XElement clientProviderElement = remotingElement.Descendants().Where(d => d.Name.LocalName == "clientProviders").FirstOrDefault();
                if (clientProviderElement != null)
                {
                    foreach (XElement providerElement in clientProviderElement.Elements().Where(d => d.Name.LocalName == "provider"))
                    {
                        XAttribute typeAttribute = providerElement.Attributes()
                            .Where(x => x.Name.LocalName == "type")
                            .FirstOrDefault();
                        UpdateVersionInTypeAttribute(typeAttribute, version);
                    }
                }

                XElement serviceElement = remotingElement.Descendants().Where(d => d.Name.LocalName == "service").FirstOrDefault();
                if (serviceElement != null)
                {
                    foreach (XElement providerElement in serviceElement.Elements().Where(d => d.Name.LocalName == "wellknown"))
                    {
                        XAttribute typeAttribute = providerElement.Attributes()
                            .Where(x => x.Name.LocalName == "type")
                            .FirstOrDefault();
                        UpdateVersionInTypeAttribute(typeAttribute, version);
                    }
                }
            }
        }

        /// <summary>
        /// Updates the type defined under &lt;SectionTypes&gt; within the &lt;exceptionHandling&gt; section.
        /// </summary>
        /// <param name="configFile">The configuration file that contains the &lt;ModulesSection&gt;.</param>
        /// <param name="version">The new version.</param>
        /// <remarks>Typically found in the application config file.</remarks>
        private void UpdateExceptionHandlingSection(XDocument configFile, string version)
        {
            IEnumerable<XElement> exceptionHandlerElements = configFile.Descendants().Where(x => x.Name.LocalName == "exceptionHandlers");

            foreach (XElement exceptionHandlerElement in exceptionHandlerElements)
            {
                IEnumerable<XElement> addElements = exceptionHandlerElement.Descendants().Where(x => x.Name.LocalName == "add");

                foreach (XElement addElement in addElements)
                {
                    XAttribute typeAttribute = addElement.Attributes().FirstOrDefault(a => a.Name.LocalName.Equals("type"));
                    if (IsFrameworkAttribute(typeAttribute))
                    {
                        UpdateVersionInTypeAttribute(typeAttribute, version);
                    }
                }
            }
        }

        /// <summary>
        /// Updates &lt;Controls&gt; elements.
        /// </summary>
        /// <param name="configFile">The configuration file as an <see cref="XDocument"/>.</param>
        /// <param name="version">The new version.</param>
        private void UpdateControlsSection(XDocument configFile, string version)
        {
            IEnumerable<XElement> addElements =
                from element in configFile.Elements().First().XPathSelectElements("//*//Controls//add")
                select element;

            foreach (XElement addElement in addElements)
            {
                XAttribute typeAttribute = addElement.Attributes().FirstOrDefault(a => a.Name.LocalName.Equals("Control"));
                UpdateVersionInTypeAttribute(typeAttribute, version);
            }
        }

        #endregion

        /// <summary>
        /// Sets the Assembly Name portion of a type attribute (Type, Assembly) to the new version.
        /// </summary>
        /// <param name="typeAttribute">The XAttribute containing the type definition.</param>
        /// <param name="version">The version to update.</param>
        private void UpdateVersionInTypeAttribute(XAttribute typeAttribute, String version)
        {
            String[] parts = typeAttribute.Value.Split(','); // type, assembly
            if (parts.Length == 2 && Util.IsOursNeedsUpdating(parts[1], version))
            {
                parts[1] = Util.ComposeNewAssemblyName(parts[1], version);
                typeAttribute.Value = String.Join(",", parts);
            }
        }

        private bool IsFrameworkAttribute(XAttribute typeAttribute)
        {
            if (typeAttribute != null)
            {
                String[] parts = typeAttribute.Value.Split(','); // type, assem
                if (parts.Length == 2 && Util.IsOursNeedsUpdating(parts[1], NewVersion))
                {
                    return true;
                }
            }

            return false;
        }

        private void AddFileWithFrameworkReferences(String fileName)
        {
            if (!FilesWithFrameworkReferences.Contains(fileName))
            {
                FilesWithFrameworkReferences.Add(fileName);
            }
        }
    }
}
