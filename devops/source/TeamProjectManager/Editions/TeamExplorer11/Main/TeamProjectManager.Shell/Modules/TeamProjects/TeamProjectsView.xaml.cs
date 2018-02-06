﻿using System.ComponentModel.Composition;
using System.Linq;
using System.Windows.Controls;
using TeamProjectManager.Common;
using TeamProjectManager.Common.Infrastructure;

namespace TeamProjectManager.Shell.Modules.TeamProjects
{
    [Export]
    public partial class TeamProjectsView : UserControl
    {
        public RelayCommand SelectAllCommand { get; private set; }
        public RelayCommand SelectNoneCommand { get; private set; }

        public TeamProjectsView()
        {
            InitializeComponent();
            this.SelectAllCommand = new RelayCommand(SelectAll, CanSelectAll);
            this.SelectNoneCommand = new RelayCommand(SelectNone, CanSelectNone);
        }

        [Import]
        public TeamProjectsViewModel ViewModel
        {
            get
            {
                return (TeamProjectsViewModel)this.DataContext;
            }
            set
            {
                this.DataContext = value;
            }
        }

        private void teamProjectsListBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            this.ViewModel.SelectedTeamProjects = this.teamProjectsListBox.SelectedItems.Cast<TeamProjectInfo>().ToList();
        }

        private bool CanSelectAll(object argument)
        {
            return (this.teamProjectsListBox.SelectedItems.Count != this.teamProjectsListBox.Items.Count);
        }

        private void SelectAll(object argument)
        {
            this.teamProjectsListBox.SelectAll();
        }

        private bool CanSelectNone(object argument)
        {
            return (this.teamProjectsListBox.SelectedItems.Count > 0);
        }

        private void SelectNone(object argument)
        {
            this.teamProjectsListBox.SelectedItem = null;
        }
    }
}