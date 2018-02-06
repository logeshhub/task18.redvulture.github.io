﻿using System.ComponentModel.Composition;
using System.Windows.Shell;
using Microsoft.Practices.Prism.Events;
using TeamProjectManager.Common.Infrastructure;
using TeamProjectManager.Common.ObjectModel;
using TeamProjectManager.Shell.Infrastructure;

namespace TeamProjectManager.Shell
{
    [Export(typeof(ShellViewModel))]
    [Export(typeof(IStatusService))]
    public class ShellViewModel : ViewModelBase, IStatusService
    {
        #region Properties

        public TaskbarItemInfo TaskbarItemInfo { get; private set; }

        #endregion

        #region Observable Properties

        public string WindowTitle
        {
            get { return this.GetValue(WindowTitleProperty); }
            set { this.SetValue(WindowTitleProperty, value); }
        }

        public static ObservableProperty<string> WindowTitleProperty = new ObservableProperty<string, ShellViewModel>(o => o.WindowTitle);

        public object HelpContent
        {
            get { return this.GetValue(HelpContentProperty); }
            set { this.SetValue(HelpContentProperty, value); }
        }

        public static ObservableProperty<object> HelpContentProperty = new ObservableProperty<object, ShellViewModel>(o => o.HelpContent);

        #endregion

        #region Constructors

        [ImportingConstructor]
        public ShellViewModel(IEventAggregator eventAggregator, ILogger logger)
            : base(eventAggregator, logger, "Shell")
        {
            this.WindowTitle = InternalConstants.DefaultWindowTitle;
            this.TaskbarItemInfo = new TaskbarItemInfo();
            HelpProvider.HelpContentUpdateRequested += (sender, e) => { this.HelpContent = e.HelpContent; };
        }

        #endregion

        #region IStatusService Members

        public void SetMainWindowTitleStatus(string status)
        {
            if (string.IsNullOrWhiteSpace(status))
            {
                this.WindowTitle = InternalConstants.DefaultWindowTitle;
            }
            else
            {
                this.WindowTitle = string.Concat(InternalConstants.DefaultWindowTitle, " - ", status);
            }
        }

        public void ClearMainWindowTitleStatus()
        {
            SetMainWindowTitleStatus(null);
        }

        public void SetMainWindowProgress(TaskbarItemProgressState state, double progressValue)
        {
            this.TaskbarItemInfo.ProgressState = state;
            this.TaskbarItemInfo.ProgressValue = progressValue;
        }

        public void SetMainWindowProgress(TaskbarItemProgressState state)
        {
            this.TaskbarItemInfo.ProgressState = state;
        }

        #endregion
    }
}