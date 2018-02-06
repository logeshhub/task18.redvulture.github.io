﻿using System.Collections.Generic;
using TeamProjectManager.Common;

namespace TeamProjectManager.Modules.WorkItemConfiguration
{
    public class WorkItemTypeInfo
    {
        public TeamProjectInfo TeamProject { get; private set; }
        public string Name { get; private set; }
        public string Description { get; private set; }
        public int WorkItemCount { get; private set; }
        public ICollection<string> WorkItemCategories { get; private set; }
        public string WorkItemCategoriesList { get; private set; }
        public WorkItemTypeDefinition WorkItemTypeDefinition { get; private set; }

        public WorkItemTypeInfo(TeamProjectInfo teamProject, string name, string description, int workItemCount, ICollection<string> workItemCategories, WorkItemTypeDefinition workItemTypeDefinition)
        {
            this.TeamProject = teamProject;
            this.Name = name;
            this.Description = description;
            this.WorkItemCount = workItemCount;
            this.WorkItemCategories = workItemCategories;
            this.WorkItemCategoriesList = this.WorkItemCategories == null ? null : string.Join(", ", this.WorkItemCategories);
            this.WorkItemTypeDefinition = workItemTypeDefinition;
        }
    }
}