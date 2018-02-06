static void Copy()
        {
            string sourceServerUrl = "https://mmm-parking.visualstudio.com";
            string sourceCollectionName = "DefaultCollection";
            string sourceProjectName = "Element";

            string targetServerUrl = "http://tfs13:8080/tfs"; ;
            string targetCollectionName = "Parking";
            string targetProjectName = "EFMS-Migration-Full";

            try
            {
                NetworkCredential netCred = new NetworkCredential("eandrewtaylor@hotmail.com","P2ssw0rd");
                BasicAuthCredential basicCred = new BasicAuthCredential(netCred);
                TfsClientCredentials tfsCred = new TfsClientCredentials(basicCred);
                tfsCred.AllowInteractive = false;

                // connect to source TPC
                Uri sourceUri = new Uri(sourceServerUrl + "/" + sourceCollectionName);
                Console.WriteLine("Connecting to source TPC: " + sourceUri + "...");
                TfsTeamProjectCollection sourceTpc = new TfsTeamProjectCollection(sourceUri, tfsCred);
                sourceTpc.Authenticate();
                sourceTpc.EnsureAuthenticated();
                sourceTpc.Connect(ConnectOptions.IncludeServices);
                Console.WriteLine("Connected to source TPC.");
                Console.WriteLine();

                // connect to target TPC
                Uri targetUri = new Uri(targetServerUrl + "/" + targetCollectionName);
                Console.WriteLine("Connecting to target TPC " + targetUri + "...");
                TfsTeamProjectCollection targetTpc = new TfsTeamProjectCollection(targetUri);
                targetTpc.Authenticate();
                targetTpc.EnsureAuthenticated();
                targetTpc.Connect(ConnectOptions.IncludeServices);
                Console.WriteLine("Connected to target TPC.");
                Console.WriteLine();
                
                // connect to source test management service for source TPC
                Console.WriteLine("Connecting to Test service for " + sourceCollectionName + ".");
                ITestManagementService sourceSvc = sourceTpc.GetService<ITestManagementService>();
                ITestManagementTeamProject sourceProj = sourceSvc.GetTeamProject(sourceProjectName);

                // connect to source test management service for target TPC
                Console.WriteLine("Connecting to Test service for " + targetCollectionName + ".");
                ITestManagementService targetSvc = targetTpc.GetService<ITestManagementService>();
                ITestManagementTeamProject targetProj = targetSvc.GetTeamProject(targetProjectName);

                // locate test plans for the source project
                ITestPlanHelper sourcePlanHelper = sourceProj.TestPlans;
                ITestSuiteHelper sourceSuiteHelper = sourceProj.TestSuites;

                // set up test plan helpers for the target project
                ITestPlanHelper targetPlanHelper = targetProj.TestPlans;
                ITestSuiteHelper targetSuiteHelper = targetProj.TestSuites;
                
                ITestPlanCollection sourcePlans = sourcePlanHelper.Query("Select * From TestPlan");
                ITestPlanCollection targetPlans = targetPlanHelper.Query("Select * From TestPlan");

                
                foreach( ITestPlan sourcePlan in sourcePlans )
                {
                    Console.WriteLine("Plan: " + sourcePlan.Name);

                    // time to start cloning the test plan
                    ITestPlan targetPlan = targetProj.TestPlans.Create();
                    
                    targetPlan.AreaPath = sourcePlan.AreaPath.Replace(sourceProjectName, targetProjectName);
                    targetPlan.Description = sourcePlan.Description;
                    targetPlan.EndDate = sourcePlan.EndDate;
                    targetPlan.Iteration = sourcePlan.Iteration.Replace(sourceProjectName, targetProjectName);
                    targetPlan.Name = sourcePlan.Name;
                    targetPlan.Owner = targetTpc.AuthorizedIdentity;
                    targetPlan.OwnerTeamFoundationId = targetTpc.InstanceId;
                    targetPlan.StartDate = sourcePlan.StartDate;
                    targetPlan.State = sourcePlan.State;

                    IStaticTestSuite sourceRootSuite = sourcePlan.RootSuite;
                    //targetSuiteHelper.

                    ITestSuiteCollection sourceSuites = sourceRootSuite.SubSuites;
                    foreach (ITestSuiteBase sourceSuite in sourceSuites)
                    {
                        Console.WriteLine("Suite ID: " + sourceSuite.Id.ToString());
                        Console.WriteLine("Suite Title: " + sourceSuite.Title);
                        Console.WriteLine("Suite Description: " + sourceSuite.Description);
                        Console.WriteLine("Suite Type: " + sourceSuite.TestSuiteType.ToString());
                        Console.WriteLine("Suite Parent: " + sourceSuite.Parent.Title);
                        Console.WriteLine("Suite Test Cases: " + sourceSuite.TestCaseCount.ToString());
                        //Console.WriteLine("Suite Title: " + sourceSuite.);
                    }

                    // commit the new test plan
                    targetPlan.Save();
                      

                }

                
                

                
                //ITestSuiteCollection sourceSuites = sourceSuiteHelper.FetchTestSuitesForPlan()

                //foreach (ITestPlan sourcePlan in sourcePlans)
                //{
                //    foreach (var suiteEntry in sourcePlans.RootSuite.Entries)
                //    {
                //        if (!(suiteEntry.TestSuite == null))
                //        {
                //            if (suiteEntry.TestSuite.TestSuiteType == TestSuiteType.DynamicTestSuite)
                //            {
                //                IDynamicTestSuite dts = suiteEntry.TestSuite as IDynamicTestSuite;

                //                if (dts.Query.QueryText.Contains(@"fromValue"))
                //                {
                //                    // ** The following statement is invalid because the QueryText property is read only **
                //                    //dts.Query.QueryText = dts.Query.QueryText.Replace(@fromValue, @toValue);


                //                    ITestSuiteBase tsb = null;

                //                    // ** This doesn't work: tsb is null after assignment
                //                    tsb = suiteEntry as ITestSuiteBase;

                //                    IEnumerable<ITestCase> testcases = testproject.TestCases.Query(dts.Query.QueryText.Replace(@fromValue, @toValue)); // this works :)
                //                    foreach (ITestCase testcase in testcases)
                //                    {
                //                        tsb.TestCases.Add(testcase); // ** this causes an exception
                //                    }


                //                    ITestSuiteHelper tsh = null;
                //                    tsh.CreateEntry(tsb);
                //                    tsh.CreateDynamic();
                //                }
                //            }
                //        }
                //    }

                //    plan.Save();
                //}




                //List<NodeInfo> sourceNodes = new List<NodeInfo>();

                //foreach (NodeInfo sourceNode in sourceCss.ListStructures(sourceInfo.Uri))
                //{
                //    // iterations only
                //    if (sourceNode.StructureType != "ProjectLifecycle")
                //        continue;

                //    XmlElement nodeElement = sourceCss.GetNodesXml(new string[] { sourceNode.Uri }, true);
                //    BuildSourceNodes(sourceCss, sourceNode.Name, nodeElement.ChildNodes[0], sourceNodes);
                //}
                //Console.WriteLine();

                //// make sure there is something to copy
                //if (sourceNodes.Count == 0)
                //{
                //    Console.WriteLine("No iterations to copy. Exiting...");
                //    return;
                //}

                //// connect to target CSS service for target TPC
                //Console.WriteLine("Connecting to CSS service for " + targetCollectionName + ".");
                //ICommonStructureService4 targetCss = targetTpc.GetService<ICommonStructureService4>();
                //ProjectInfo targetInfo = targetCss.GetProjectFromName(targetProjectName);
                //Console.WriteLine("Copying nodes into " + targetProjectName + ".");

                //// copy the nodes from the source to target
                //Console.WriteLine("Copying iterations to " + targetProjectName + "...");
                //foreach (NodeInfo sourceNode in sourceNodes)
                //{
                //    targetCss.CreateNode(sourceNode.Name, sourceNode.ParentUri.Replace(sourceProjectName, targetProjectName), sourceNode.StartDate, sourceNode.FinishDate);
                //}
                //Console.WriteLine();

                // copy complete
                //Console.WriteLine("Successfully copied " + sourceNodes.Count.ToString() + " iterations to target project.");

                // close connections
                sourceTpc.Dispose();
                Console.WriteLine();
                Console.WriteLine("Closed source TPC " + sourceUri.ToString() + ".");

                targetTpc.Dispose();
                Console.WriteLine("Closed target TPC " + targetUri.ToString() + ".");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + ex.ToString());
            }
        }

        //static void BuildSourceNodes(ICommonStructureService4 sourceCss, string parentPath, XmlNode parentNode, List<NodeInfo> sourceNodes)
        //{
        //    if (parentNode.ChildNodes[0] == null)
        //        return;

        //    foreach (XmlNode childNode in parentNode.ChildNodes[0].ChildNodes)
        //    {
        //        string childNodePath = childNode.Attributes["Path"].Value;
        //        NodeInfo childNodeInfo = sourceCss.GetNodeFromPath(childNodePath);

        //        Console.WriteLine("Source Iteration: " + childNodeInfo.Name);
        //        Console.WriteLine("Source Iteration Start Date: " + childNodeInfo.StartDate.ToString());
        //        Console.WriteLine("Source Iteration Finish Date: " + childNodeInfo.FinishDate.ToString());

        //        sourceNodes.Add(childNodeInfo);

        //        BuildSourceNodes(sourceCss, childNodePath, childNode, sourceNodes);

        //    }
        //}

    }