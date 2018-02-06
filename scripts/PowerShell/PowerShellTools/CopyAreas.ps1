Clear-Host

# ET: 07/20/15: Ported to PowerShell from C# console application
# source and target, will add as arguments eventually

# Add necessary API references
[string] $binpath = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0"
Add-Type -Path $binpath\Microsoft.TeamFoundation.Common.dll
Add-Type -Path $binpath\Microsoft.TeamFoundation.Client.dll
Add-Type -Path $binpath\Microsoft.TeamFoundation.WorkItemTracking.Client.dll

[string] $sourceServerUrl = "http://tfs13sb.archon-tech.com:8080/tfs"
[string] $sourceCollectionName = "PublicSafety"
[string] $sourceProjectName = "ALPR"

[string] $targetServerUrl = "https://tfsdev.mmm.com/tfs"
[string] $targetCollectionName = "DefaultCollection"
[string] $targetProjectName = "ALPR_Migration"

try
{
   
    # connect to source TPC
	[Microsoft.TeamFoundation.Client.TfsClientCredentials] $creds = New-Object Microsoft.TeamFoundation.Client.TfsClientCredentials
    
    [Uri] $sourceUri = New-Object Uri $sourceServerUrl"/"$sourceCollectionName
    Write-Host "Connecting to source TPC:"$sourceUri.ToString()"..."
    [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $sourceTpc = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection $sourceUri, $creds
    $sourceTpc.Authenticate()
    $sourceTpc.EnsureAuthenticated()
           
    Write-Host "Connected to source TPC."
    Write-Host

    # connect to target TPC
    [Uri] $targetUri = New-Object Uri $targetServerUrl"/"$targetCollectionName
    Write-Host "Connecting to target TPC:"$targetUri"..."
    [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $targetTpc = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection $targetUri, $creds
    $targetTpc.Authenticate()
    $targetTpc.EnsureAuthenticated()
    
    Write-Host "Connected to target TPC."
    Write-Host

    # connect to source CSS service for source TPC
    Write-Host "Connecting to CSS service for"$sourceCollectionName"."
    [Microsoft.TeamFoundation.Server.ICommonStructureService4] $sourceCss = $sourceTpc.GetService("Microsoft.TeamFoundation.Server.ICommonStructureService4")
    [Microsoft.TeamFoundation.Server.ProjectInfo] $sourceProj = $sourceCss.GetProjectFromName( $sourceProjectName )
    
    # connect to target CSS service for target TPC
    Write-Host "Connecting to CSS service for"$targetCollectionName"."
    [Microsoft.TeamFoundation.Server.ICommonStructureService4] $targetCss = $targetTpc.GetService("Microsoft.TeamFoundation.Server.ICommonStructureService4")
    [Microsoft.TeamFoundation.Server.ProjectInfo] $targetProj = $targetCss.GetProjectFromName( $targetProjectName )

    $sourceNodes = New-Object "System.Collections.Generic.List[Microsoft.TeamFoundation.Server.NodeInfo]"
    $targetNodes = New-Object "System.Collections.Generic.List[Microsoft.TeamFoundation.Server.NodeInfo]"

    # !!!!!!!!!!!!!!!! NOTE: GO CHECK THE TARGET PROJECT AND MAKE SURE NO AREAS ALREADY EXIST.  NOT ENOUGH TIME TO WRITE CODE FOR DETECTION !!!!!!!!!!!!!!!!!!!!!!!!

    # get the top level Uri for the Area node on the target
    [Microsoft.TeamFoundation.Server.NodeInfo] $targetRootNode = $null
    foreach( $targetNode in $targetCss.ListStructures($targetProj.Uri) )
    {
        # looking for the root Area
        if( $targetNode.StructureType -eq "ProjectModelHierarchy" )
        {
            $targetRootNode = $targetNode
            Write-Host "Root Area node:"$targetRootNode.Name
            Write-Host "Root Area node path:"$targetRootNode.Path
            Write-Host "Root Area node Uri:"$targetRootNode.Uri
            
            break
        }
    }
    Write-Host
    Write-Host "Ready to begin building Area nodes."
	Write-Host

    
    # build target nodes from source XML structure
    Write-Host "Begin building Area nodes."
    
    [Microsoft.TeamFoundation.Server.NodeInfo] $sourceRootNode = $null
    foreach( $sourceNode in $sourceCss.ListStructures( $sourceProj.Uri ) )
    {
        # Areas only
        if( $sourceNode.StructureType -ne "ProjectModelHierarchy" )
        {
            continue
        }

        [System.Xml.XmlElement] $nodeElement = $sourceCss.GetNodesXml( @($sourceNode.Uri), $true)
        Write-Host "NodeElement:"$nodeElement.OuterXml

        BuildNodes( $sourceProj, $targetProj, $sourceCss, $targetCss, $sourceNode.Path, $nodeElement.ChildNodes[0], $sourceNodes, $targetRootNode.Uri )
                                
    }
    Write-Host
	Write-Host "Migration complete."

    # close connections
    $sourceTpc.Dispose()
    Write-Host
    Write-Host "Closed source TPC:"$sourceUri.ToString()"."

    $targetTpc.Dispose()
    Write-Host "Closed target TPC:"$targetUri.ToString()"."
	
}
catch
{
	write-host "Caught an exception:" -ForegroundColor Red
    write-host "Exception Type:"$_.Exception.GetType().FullName -ForegroundColor Red
    write-host "Exception Message:"$_.Exception.Message -ForegroundColor Red
}


Function BuildNodes(
            [Microsoft.TeamFoundation.Server.ProjectInfo] $sourceProj,
            [Microsoft.TeamFoundation.Server.ProjectInfo] $targetProj,
            [Microsoft.TeamFoundation.Server.ICommonStructureService4] $sourceCss,
            [Microsoft.TeamFoundation.Server.ICommonStructureService4] $targetCss,
            [string] $parentPath,
            [System.Xml.XmlNode] $parentNode,
            [System.Collections.Generic.List[Microsoft.TeamFoundation.Server.NodeInfo]] $sourceNodes,
            [string] $targetParentUri ){

          
        if( $parentNode.ChildNodes[0] -eq $null )
        {
            return
        }

        foreach( $childNode in $parentNode.ChildNodes[0].ChildNodes )
        {
            [string] $childNodePath = $childNode["Path"]
            
            $childNodeInfo = $sourceCss.GetNodeFromPath( $childNodePath )

            Write-Host "Source Area:" $childNodeInfo.Name
            Write-Host "Source Path:" $childNodeInfo.Path
            Write-Host "Source Area Uri:" $childNodeInfo.Uri
            Write-Host "Source Area Parent Uri:" $childNodeInfo.ParentUri
            Write-Host 

            $targetPath = $childNodeInfo.Path.Replace($sourceProj.Name, $targetProj.Name)
            
            # Create on the fly. The current Uri will be generated for the next call since we don't know the actual Uri of this node until it gets added
            $targetUri = $targetCss.CreateNode($childNodeInfo.Name, $targetParentUri)

            Write-Host "Target Area:" $childNodeInfo.Name
            Write-Host "Target Path:" $targetPath
            Write-Host "Target Area Uri:" $targetUri
            Write-Host "Target Area Parent Uri:" + $targetParentUri
            Write-Host 
            
            # call recursive
            BuildNodes $sourceProj, $targetProj, $sourceCss, $targetCss, $childNodePath, $childNode, $sourceNodes, $targetUri
        }
    }

        
