#
# Update the user list from TFS user activity
#
# mob - 4/3/2015
# small change
Add-PSSnapin Microsoft.Sharepoint.Powershell
Import-Module ActiveDirectory

function ValidateUsers([string]$server, [string]$listname)
{
    $pi = 0;
    $cur = 0;
    Write-Progress -Id 1 -ParentId 0 -Activity "Validating Users accounts in the People SharePoint list" -PercentComplete (1) -Status "Opening Connection to the People SharePoint List";
    try
    {
        $w = Get-SPWeb -Identity $server;
        $list = $w.Lists[$listname];    
        $listTitle = $list.Title;
        $pi = $list.Items.Count;

        Write-Host ([String]::Format("Validating Users accounts in the $listTitle SharePoint list for {0} users.",$pi)) -ForegroundColor Green;    

        foreach($entry in $list.Items)
        {
            try
            {
                Write-Progress -Id 1 -ParentId 0 -Activity "Validating Users accounts in the People SharePoint list" -PercentComplete ($cur/$pi*100) -Status "Validating user ($cur/$pi)";
                
                if($entry["Active"] -eq $true)
                {
                   $userinfo = $entry["Title"] -split "\\";
                    $userAD = Get-ADUser $userinfo[1] -server $userinfo[0] -Properties *;
                
                    if( $userAD.Enabled -eq $false)
                    {
                        $entry["Active"] = $false;
                        $entry.Update();
                        Write-Host ([String]::Format(" User {0} set to Inactive",$entry["Title"])) -ForegroundColor Red;
                    }
                    else
                    {
                        $entry["Department Number"] = [system.int32]::Parse($userAD.departmentNumber);
                        $entry["Department"] = $userAD.Department;
                        $entry["Division"] = $userAD.Division;
                        $entry.Update();
                    }
                }
                else
                {
                    Write-Host([String]::Format("  Skipping inactive user for validation: {0}", $entry["Title"])) -ForegroundColor Yellow;
                }

            }
            catch [System.Exception]
            {
                 Write-Host ([String]::Format(" Error with user item. User {0} has been marked Inactive. Error: {1}. ",$entry["Title"],$_)) -ForegroundColor Red -BackgroundColor White;
                 $entry["Active"] = $false;
                 $entry.Update();
                 continue;
            }
            $cur++;
        }
     }
     catch [System.Exception]
     {
        Write-Host ([String]::Format(" Error with validating user item. User {0} has been skipped. Error: {1}. ",$entry["Title"],$_)) -ForegroundColor Red -BackgroundColor White;
        continue;    
     }
     finally
     {
        $w.Dispose();
        Write-Host ([String]::Format("Complete: Validated {0} users.",$pi)) -ForegroundColor Green;    
        Write-Progress -Id 1 -ParentId 0 -Activity "Validating Users accounts in the People SharePoint list" -PercentComplete (100) -Status "Complete: Validated $cur Users.";
     }

}


function UpdateTFSUsers([string]$server, [string]$listName)
{    
    # Connect to the database
    $conn = New-Object System.Data.SqlClient.SqlConnection("Data Source=prodsql220\sql220; Initial Catalog=Tfs_Configuration; Integrated Security=SSPI")
    Write-Progress -Id 1 -ParentId 0 -Activity "Importing Data From SQL into SharePoint" -PercentComplete (1) -Status "Opening Connection to the SQL Server";
    $conn.Open();
    try
    {            
        # Execute the query
        Write-Progress -Id 1 -ParentId 0 -Activity "Importing Data From SQL into SharePoint" -PercentComplete (2) -Status "Querying SQL Server";    
        $query = "Select IdentityName AS ID,StartTime AS Last_Access_Time,Command as Reason, IPAddress as IP, ExecutionTime as Time from tbl_Command where CommandId in (Select Max(CommandId) from tbl_Command where Application not like 'Team Foundation JobAgent' and IdentityName not like '%$' and IdentityName not like 'USAC\Usf%' and IdentityName not like 'USAC\USP%' and IdentityName <> '' Group By IdentityName ) order by Last_Access_Time desc";
		$dap = new-object System.Data.SqlClient.SqlDataAdapter($query,$conn);
        $dt = new-object System.Data.DataTable;
        $pi = $dap.Fill($dt);                
        $w = Get-SPWeb -Identity $server;
        $list = $w.Lists[$listName];    
        $listTitle = $list.Title;
        $pci = 1;
        $itemsAdded = 0;
        $itemsUpdated = 0;
        
        Write-Progress -Id 1 -ParentId 0 -Activity "Importing Data From TFS into SharePoint" -PercentComplete (25/($pi+45)*100) -Status "Importing ($pi) items into SharePoint.";        
        foreach($r in $dt.Rows)
        {
            Write-Progress -Id 1 -ParentId 0 -Activity "Importing Data From SQL into SharePoint" -PercentComplete (($pci+25)/($pi+45)*100) -Status "Importing ($pi) items into SharePoint.";
            Write-Progress -Id 2 -ParentId 1 -Activity "Adding new items to $listTitle" -PercentComplete ($pci/$pi*100) -Status "Importing item $pci into SharePoint.";
            $pci++;
            $i = 0;
            $itemStatus = "";
            try
            {
                # check if this user already exists
                $entry = $list.Items | where {$_['Title'] -eq $r["ID"]};
                if ($entry -eq $null)
                {
                    # new
                    $i = $list.Items.Add();
                    $itemsAdded++;
                    $itemStatus = "Added";
 
                    # Set the field values
                    $i["Title"] = $r["ID"];
                    $i["Name"] = $w.EnsureUser($r["ID"]);
                }
                else
                {
                    # update
                    $itemStatus = "Updated";
                    $i = $entry;
                    $itemsUpdated++;
                }

                #Save changes to the item
        	    $i["Last Access Time"] = $r["Last_Access_Time"];
                $i["Active"] = $true;
                $i.Update();

                Write-Host ([String]::Format("$itemStatus : '{0}', with Last seen: {1}",$r["ID"],$r["Last_Access_Time"])) -ForegroundColor Green;
            }
            catch [System.Exception]{
                Write-Host ([String]::Format(" Error with user item. User {0} has been skipped. Error: {1}. ",$r["ID"],$_)) -ForegroundColor Red -BackgroundColor White;
                continue;    
            }    
        }        
        Write-Progress -Id 1 -ParentId 0 -Activity "Importing Users From ETFS into SharePoint" -PercentComplete (80) -Status "Closing SQL Connection.";        
        Write-Host ([String]::Format("Finished updating the user list: {0} updated,  {1} new users added. ",$itemsUpdated, $itemsAdded)) -ForegroundColor Blue -BackgroundColor White;
        Write-Progress -Id 1 -ParentId 0 -Activity "Importing Users From ETFS into SharePoint" -PercentComplete (90) -Status "Finished: Updated ($itemsUpdated) Users and added ($itemsAdded) new Users into SharePoint.";
        $w.Dispose();
    }
    catch [System.Exception]{
        Write-Host ([String]::Format("Error: {0} ",$_)) -ForegroundColor Red -BackgroundColor White;    
        Write-Progress -Id 1 -ParentId 0 -Activity "Importing Data From SQL into SharePoint" -PercentComplete (100) -Status "An error occured.";        
    }
    finally{
        $conn.Close();    
    }            
}

$server = "http://tfs.mmm.com";
$list = "People";

ValidateUsers $server $list;
UpdateTFSUsers $server $list;