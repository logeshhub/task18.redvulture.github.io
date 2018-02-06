﻿using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Xml;

namespace TeamProjectManager.Modules.SourceControl
{
    public static class BranchHierarchyExporter
    {
        #region Constants

        private const string CategoryIdRootBranch = "Root Branch";
        private const string CategoryIdChildBranch = "Child Branch";
        private const string CategoryIdLeafBranch = "Leaf Branch";
        private const string CategoryIdOrphanBranch = "Orphan Branch";
        private const string CategoryIdTeamProject = "Team Project";
        private const string PropertyIdId = "Id";
        private const string PropertyIdLabel = "Label";
        private const string PropertyIdCategory = "Category";
        private const string PropertyIdGroup = "Group";
        private const string PropertyIdDescription = "Description";
        private const string PropertyIdDateCreated = "DateCreated";
        private const string PropertyIdOwner = "Owner";
        private const string PropertyIdBranchDepth = "BranchDepth";
        private const string PropertyIdMaxTreeDepth = "MaxTreeDepth";
        private const string PropertyIdTeamProject = "TeamProject";

        #endregion

        #region Export

        public static void Export(IEnumerable<BranchInfo> rootBranches, string fileName, BranchHierarchyExportFormat format)
        {
            switch (format)
            {
                case BranchHierarchyExportFormat.Dgml:
                    ExportToDgml(rootBranches, fileName);
                    break;
                case BranchHierarchyExportFormat.Xml:
                    ExportToXml(rootBranches, fileName);
                    break;
                default:
                    throw new ArgumentException("The export format is unknown: " + format.ToString());
            }
        }

        #endregion

        #region Export To DGML

        public static void ExportToDgml(IEnumerable<BranchInfo> rootBranches, string fileName)
        {
            using (var writer = new XmlTextWriter(fileName, Encoding.UTF8))
            {
                writer.Formatting = Formatting.Indented;
                writer.WriteStartDocument();
                writer.WriteStartElement("DirectedGraph", "http://schemas.microsoft.com/vs/2009/dgml");

                // Write all nodes.
                writer.WriteStartElement("Nodes");
                var teamProjects = new List<string>();
                foreach (var rootBranch in rootBranches)
                {
                    WriteBranchNode(writer, rootBranch, teamProjects);
                }
                writer.WriteEndElement(); // </Nodes>

                // Write all links between the nodes.
                writer.WriteStartElement("Links");
                foreach (var rootBranch in rootBranches)
                {
                    WriteBranchLink(writer, rootBranch);
                }
                writer.WriteEndElement(); // </Links>

                // Write the (static) categories.
                writer.WriteStartElement("Categories");
                WriteCategory(writer, CategoryIdTeamProject);
                WriteCategory(writer, CategoryIdRootBranch);
                WriteCategory(writer, CategoryIdChildBranch);
                WriteCategory(writer, CategoryIdLeafBranch);
                WriteCategory(writer, CategoryIdOrphanBranch);
                writer.WriteEndElement(); // </Categories>

                // Write the (static) styles for the categories so they show up in the Legend.
                writer.WriteStartElement("Styles");
                WriteStyle(writer, CategoryIdTeamProject, "Team Project", "#FFE8EEF4");
                WriteStyle(writer, CategoryIdRootBranch, "Root Branch", "#FF0071BC");
                WriteStyle(writer, CategoryIdChildBranch, "Child Branch", "#FF00A600");
                WriteStyle(writer, CategoryIdLeafBranch, "Leaf Branch", "#FFE9EC16");
                WriteStyle(writer, CategoryIdOrphanBranch, "Orphan Branch", "#FFFF8A00");
                writer.WriteEndElement(); // </Styles>

                // Write the (static) properties.
                writer.WriteStartElement("Properties");
                WriteProperty(writer, PropertyIdDescription, "Description", typeof(string));
                WriteProperty(writer, PropertyIdDateCreated, "Date Created", typeof(DateTime));
                WriteProperty(writer, PropertyIdOwner, "Owner", typeof(string));
                WriteProperty(writer, PropertyIdTeamProject, "Team Project", typeof(string));
                WriteProperty(writer, PropertyIdBranchDepth, "Branch Depth", typeof(int));
                WriteProperty(writer, PropertyIdMaxTreeDepth, "Maximum Tree Depth", typeof(int));
                writer.WriteEndElement(); // </Properties>

                writer.WriteEndElement(); // </DirectedGraph>
                writer.WriteEndDocument();
            }
        }

        private static void WriteBranchNode(XmlTextWriter writer, BranchInfo branch, IList<string> teamProjects)
        {
            if (!teamProjects.Contains(branch.TeamProjectName))
            {
                writer.WriteStartElement("Node");
                writer.WriteAttributeString(PropertyIdId, branch.TeamProjectName);
                writer.WriteAttributeString(PropertyIdLabel, branch.TeamProjectName);
                writer.WriteAttributeString(PropertyIdCategory, CategoryIdTeamProject);
                writer.WriteAttributeString(PropertyIdGroup, "Collapsed");
                writer.WriteEndElement(); // </Node>
                teamProjects.Add(branch.TeamProjectName);
            }

            writer.WriteStartElement("Node");
            writer.WriteAttributeString(PropertyIdId, branch.Path);
            writer.WriteAttributeString(PropertyIdLabel, branch.Path);
            string category;
            if (branch.Parent == null && !branch.Children.Any())
            {
                category = CategoryIdOrphanBranch;
            }
            else if (branch.Parent == null)
            {
                category = CategoryIdRootBranch;
            }
            else if (!branch.Children.Any())
            {
                category = CategoryIdLeafBranch;
            }
            else
            {
                category = CategoryIdChildBranch;
            }
            writer.WriteAttributeString(PropertyIdCategory, category);
            if (!string.IsNullOrEmpty(branch.Description))
            {
                writer.WriteAttributeString(PropertyIdDescription, branch.Description);
            }
            writer.WriteAttributeString(PropertyIdDateCreated, branch.DateCreated.ToString("o", CultureInfo.InvariantCulture));
            if (!string.IsNullOrEmpty(branch.Owner))
            {
                writer.WriteAttributeString(PropertyIdOwner, branch.Owner);
            }
            if (!string.IsNullOrEmpty(branch.TeamProjectName))
            {
                writer.WriteAttributeString(PropertyIdTeamProject, branch.TeamProjectName);
            }
            writer.WriteAttributeString(PropertyIdBranchDepth, branch.BranchDepth.ToString());
            writer.WriteAttributeString(PropertyIdMaxTreeDepth, branch.MaxTreeDepth.ToString());
            writer.WriteEndElement(); // </Node>

            // Recursively write children.
            foreach (var child in branch.Children)
            {
                WriteBranchNode(writer, child, teamProjects);
            }
        }

        private static void WriteBranchLink(XmlTextWriter writer, BranchInfo branch)
        {
            // Link to the parent if it exists.
            if (branch.Parent != null)
            {
                writer.WriteStartElement("Link");
                writer.WriteAttributeString("Source", branch.Parent.Path);
                writer.WriteAttributeString("Target", branch.Path);
                writer.WriteEndElement(); // </Link>
            }

            // Link to the Team Project as a containment.
            writer.WriteStartElement("Link");
            writer.WriteAttributeString("Source", branch.TeamProjectName);
            writer.WriteAttributeString("Target", branch.Path);
            writer.WriteAttributeString("Category", "Contains");
            writer.WriteEndElement(); // </Link>

            // Recursively write children.
            foreach (var child in branch.Children)
            {
                WriteBranchLink(writer, child);
            }
        }

        private static void WriteCategory(XmlTextWriter writer, string categoryId)
        {
            writer.WriteStartElement("Category");
            writer.WriteAttributeString("Id", categoryId);
            writer.WriteEndElement(); // </Category>
        }

        private static void WriteProperty(XmlTextWriter writer, string id, string label, Type dataType)
        {
            writer.WriteStartElement("Property");
            writer.WriteAttributeString("Id", id);
            writer.WriteAttributeString("Label", label);
            writer.WriteAttributeString("DataType", dataType.FullName);
            writer.WriteEndElement(); // </Property>
        }

        private static void WriteStyle(XmlTextWriter writer, string categoryId, string label, string backgroundColor)
        {
            writer.WriteStartElement("Style");
            writer.WriteAttributeString("TargetType", "Node");
            writer.WriteAttributeString("GroupLabel", label);
            writer.WriteAttributeString("ValueLabel", label);
            writer.WriteStartElement("Condition");
            writer.WriteAttributeString("Expression", string.Format(CultureInfo.InvariantCulture, "HasCategory('{0}')", categoryId));
            writer.WriteEndElement(); // </Condition>
            writer.WriteStartElement("Setter");
            writer.WriteAttributeString("Property", "Background");
            writer.WriteAttributeString("Value", backgroundColor);
            writer.WriteEndElement(); // </Setter>
            writer.WriteEndElement(); // </Style>
        }

        #endregion

        #region Export To XML

        public static void ExportToXml(IEnumerable<BranchInfo> rootBranches, string fileName)
        {
            var dcs = new DataContractSerializer(typeof(BranchInfo[]), "BranchHierarchies", BranchInfo.XmlNamespace);
            using (var writer = XmlWriter.Create(fileName, new XmlWriterSettings { Indent = true }))
            {
                dcs.WriteObject(writer, rootBranches.ToArray());
            }
        }

        #endregion
    }
}