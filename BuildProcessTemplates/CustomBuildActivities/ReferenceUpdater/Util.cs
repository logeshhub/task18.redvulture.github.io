using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace mmmHIS.ALM.Build.Activities
{
    /// <summary>
    /// Class containing common utility/functionality to ReferenceUpdater project.
    /// </summary>
    internal static class Util
    {
        /// <summary>
        /// The Regex pattern to be used when comparing assembly names. Includes the leading dog (.).
        /// </summary>
        public const String VersionPattern = @"(\.[vV]\d+\.\d+\.\d+)$";

        /// <summary>
        /// The beginning segments of assemblies that should be updated.
        /// </summary>
        public static readonly String[] AssemblyPrefixes = 
                                                           { 
                                                             "mmmHIS.Core", 
                                                             "mmmHIS.Framework", 
                                                             "SoftMed.Core", 
                                                             "SoftMed.Framework" 
                                                           };

        /// <summary>
        /// The full name of assemblies that should not be updated.
        /// </summary>
        public static readonly String[] ExclusionList = 
                                                        { 
                                                          "mmmHIS.Framework.Invariant", 
                                                          "SoftMed.Framework.WMI.WMIConfiguration",
                                                          "SoftMed.Framework.CoreServices.COM", 
                                                          "SoftMed.Framework.HIPAA.COM", 
                                                          "mmmHIS.Framework.DataBus.Shared" 
                                                        };

        /// <summary>
        /// Create the target assembly name from the current assembly and the new version.
        /// </summary>
        /// <param name="currentAssemblyName">The current name of the assembly.</param>
        /// <param name="version">The new version, expressed as vn.n.n.</param>
        /// <returns>Returns the new assembly name.</returns>
        internal static String ComposeNewAssemblyName(String currentAssemblyName, String version)
        {
            String newAssemblyName = null;
            const String dllExtension = ".dll";

            Boolean endsWithDll = currentAssemblyName.EndsWith(dllExtension, StringComparison.CurrentCultureIgnoreCase);
            if (endsWithDll)
            {
                currentAssemblyName = currentAssemblyName.Substring(0, currentAssemblyName.Length - 4);
            }

            if (!Regex.IsMatch(currentAssemblyName, VersionPattern))
            {
                newAssemblyName = String.Format("{0}.{1}", currentAssemblyName, version);
            }
            else
            {
                newAssemblyName = Regex.Replace(currentAssemblyName, VersionPattern, "." + version);
            }

            if (endsWithDll)
            {
                newAssemblyName += dllExtension;
            }

            return newAssemblyName;
        }

        /// <summary>
        /// Determines whether or not the proposed version of the framework is in a valid format.
        /// </summary>
        /// <param name="proposedVersion">The proposed framework version.</param>
        /// <returns>A tuple with true and the properly formatted version string or false.</returns>
        internal static Tuple<bool, string> ValidateFrameworkVersion(string proposedVersion)
        {
            Match match = Regex.Match(proposedVersion, @"^([Vv])?\d+\.\d+\.\d|$");

            if (match.Success)
            {
                if (!match.Groups[1].Success)
                {
                    proposedVersion = String.Format("v{0}", proposedVersion);
                }

                return new Tuple<bool, string>(true, proposedVersion);
            }

            return new Tuple<bool, string>(false, null);
        }

        /// <summary>
        /// Determines if an assembly name refers to a Smart Framework assembly that should be updated.
        /// </summary>
        /// <param name="assemblyName">The name of the assembly.</param>
        /// <param name="version">The new version, in the form vn.n.n.</param>
        /// <returns>True if the assembly name should be updated.</returns>
        internal static Boolean IsOursNeedsUpdating(String assemblyName, String version)
        {
            assemblyName = assemblyName.Trim();

            if (!String.IsNullOrEmpty(assemblyName))
            {
                var excluded = ExclusionList.FirstOrDefault(e => assemblyName.StartsWith(e, StringComparison.InvariantCultureIgnoreCase));
                if (excluded == null)
                {
                    return AssemblyPrefixes.FirstOrDefault(p => assemblyName.StartsWith(p, StringComparison.InvariantCultureIgnoreCase) && !assemblyName.EndsWith(version, StringComparison.CurrentCultureIgnoreCase)) != null;
                }
            }

            return false;
        }
    }
}
