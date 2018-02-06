using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Activities;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using Microsoft.TeamFoundation.VersionControl.Client;
using System.EnterpriseServices;

namespace mmmHIS.ALM.Build.Activities
{
    [BuildActivity(HostEnvironmentOption.Agent), System.ComponentModel.ToolboxItem(true)]
    public sealed class COMObjectRegistration : CodeActivity
    {
        public InArgument<string> COMAssembly { get; set; }
        //public InArgument<Workspace> Workspace { get; set; }
        public InArgument<bool> InstallAssembly { get; set; }
        public InOutArgument<string> ApplicationName { get; set; }
        public InOutArgument<string> TLB { get; set; }

        // If your activity returns a value, derive from CodeActivity<TResult>
        // and return the value from the Execute method.
        protected override void Execute(CodeActivityContext context)
        {
            //(Workspace.Get(context)).TryGetLocalItemForServerItem(
            RegistrationHelper registrationHelper = new RegistrationHelper();
            string appName = ApplicationName.Get(context);
            string tlb = TLB.Get(context);

            string comAssemblyPath = COMAssembly.Get(context);

            if (InstallAssembly.Get(context))
            {
                registrationHelper.InstallAssembly(comAssemblyPath, ref appName, ref tlb, InstallationFlags.Default);
                ApplicationName.Set(context, appName);
                TLB.Set(context, tlb);
            }
            else
            {
                registrationHelper.UninstallAssembly(comAssemblyPath, appName);
            }
        }
    }
}
