
Import-Module ActiveDirectory


Function IsUSACLogin($name)
{
    if ( $name.Length -gt 2 )
    {
        if ( $name.Substring($name.Length - 2, 2) -eq "ZZ")
        {
             return $true
        }
        else
        {
            if ($name.SubString(0, 2) -eq "US")
            {
                return $true
            }
        }
    }
    
    return $false
}

Function IsOldContractorRecord($resourceID, $email, $dataset)
{
    # iterate back through the dataset, look for a match on email
    foreach ($row in $dataset.Tables[0].Rows)
    {
        $currentID = $row["ResourceID"].ToString()
        $currentEmail = $row["MMMLotusNotesEmailAddress"].ToString()

        if( $currentEmail -eq $email -and $currentID -ne $resourceID )
        {    
            return $true
        }
    }
    
    return $false
}



Clear-Host

$server = "timerptsql.archon-tech.com"
$database = "TimeReporting"

#non archon-tech records should be filtered out by the SQL query
$query = "SELECT * FROM [TimeReporting].[dbo].[Resource] 
            WHERE ([MMMUserPIN] IS NOT NULL AND [MMMUserPIN] NOT IN('x','unavailable','notavailable'))
                AND ([Username] IS NOT NULL AND [Username] NOT IN('x','unavailable','notavailable'))
                AND	[Username] != [MMMUserPIN]"
                #AND ([Username] LIKE ('etaylor%') OR [MMMUserPIN] LIKE ('etaylor%'))"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$server;Database=$database;Integrated Security=True"

$command = New-Object System.Data.SqlClient.SqlCommand
$command.CommandText = $query
$command.Connection = $connection

$adapter = New-Object System.Data.SqlClient.SqlDataAdapter
$adapter.SelectCommand = $command

$dataset = New-Object System.Data.DataSet
$adapter.Fill( $dataset )

$connection.Close()

# set up output dataset, this will be output to XML later
$records = 0
$exportDataset = New-Object System.Data.DataSet
$exportDataset.DataSetName = "UserMappings"
$exportDataset.Tables.Add("User")
$exportTable = $exportDataset.Tables["User"]

$archonColumn = New-Object System.Data.DataColumn "Archon", ([string])
$exportTable.Columns.Add($archonColumn)

$usacColumn = New-Object System.Data.DataColumn "USAC", ([string])
$exportTable.Columns.Add($usacColumn)


foreach ($row in $dataset.Tables[0].Rows)
{
    Write-Host

    $userName = $row["UserName"].ToString().Trim()
    $userPIN = $row["MMMUserPIN"].ToString().Trim()

    #Write-Host "Raw User: " $userName
    #Write-Host "Raw PIN: " $userPIN
    
    $usac = ""
    $archon = ""

    # start with verification of the first column, UserName
    $isUSACPIN = IsUSACLogin $userName
    if ( $isUSACPIN -eq $true )
    {
        # there is a valid USAC
        $usac = $userName

        # make sure this actually has an archon-tech login in the MMMUserPIN field 
        $isUSACPIN = IsUSACLogin $userPIN
        if ( $isUSACPIN -eq $false )
        {
            # this is a valid pair, fall through to next section to check for duplicates, or a contractor record
            $archon = $userPIN
        }
        else
        {
            # there must be a USAC pin in both fields, skip it
            Write-Host "Skipped:"$userName","$userPIN
            continue
        }
    }
    else
    {
        # there must be an archon-tech login in the UserName field
        $archon = $userName
        
        # check that a valid USAC PIN is in MMMUserPIN
        $isUSACPIN = IsUSACLogin $userPIN
        if ( $isUSACPIN -eq $true )
        {
            # this is a valid pair, fall through to next section to check for duplicates, or a contractor record
            $usac = $userPIN
        }
        else
        {
            # there must be a USAC pin in both fields, skip it
            Write-Host "USAC in both fields, skipped:"$userName","$userPIN
            continue
        }
    }

    # we have a valid pair, now look for duplicates from an old contractor record
    # translate by adding the original current archon name, and locate the corresponding FTE record
    
    Write-Host "Pair is valid:" $archon","$usac
    Write-Host "Looking for contractor duplicates..."
    
    if ($archon -like '*contractor')
    {
        Write-Host $archon "is a contractor record."
        Write-Host "Searching for the FTE record for translation..."

        $contractorID = $row["ResourceID"].ToString()
        $contractorEmail = $row["MMMLotusNotesEmailAddress"].ToString()
        $hasMatchingFTE = $false

        # iterate back through the dataset, look for a match on email
        foreach ($searchRow in $dataset.Tables[0].Rows)
        {
            $currentID = $searchRow["ResourceID"].ToString()
            $currentEmail = $searchRow["MMMLotusNotesEmailAddress"].ToString()

            #Write-Host "Examining "$currentEmail

            if( $currentEmail -eq $contractorEmail -and $currentID -ne $contractorID )
            {
                $hasMatchingFTE = $true    
                continue
            }
        }

        if( $hasMatchingFTE -eq $true )
        {
            # this record is an old contract record that has a matching FTE record, skip this one
            Write-Host "A newer FTE record exists for $archon, skipping."
            continue
        }
        else
        {
            Write-Host "No newer FTE record exists for $archon, included."
        }

    }
       
    #LDAP validation to determine which records are still valid
    #if not valid, use last, first for the entry
    $user = $null
    try
    {
        $user = Get-ADUser $usac
        Write-Host "User [$usac] is a valid AD account."
        Write-Host $user  
    }
    catch
    {
        Write-Host "User [$usac] is not a valid AD account, skipping."
        continue
    }
     
    Write-Host "Ready to add:" $archon","$usac
    $exportRow = $exportTable.NewRow()
    $exportRow["Archon"] = $archon
    $exportRow["USAC"] = $usac
    $exportTable.Rows.Add($exportRow)

    $records++
    

}

#LDAP validation to determine which records are still valid
#if not valid, use last, first for the entry


#process any records
if( $records -gt 0 -and $exportTable.Rows.Count -gt 0 )
{
    #build XML Document
    #nodes will <DisplayNameMapping Left="ARCHON-TECH\user1" Right="USAC\user1" MappingRule="SimpleReplacement" />
    
    [System.Xml.XmlDocument]$doc = New-Object System.Xml.XmlDocument
    [System.Xml.XmlElement] $root = $doc.CreateElement("UserMappings")
    $doc.AppendChild($root)

    foreach( $row in $exportTable.Rows )
    {
        [System.XML.XMLElement]$userMapping = $root.appendChild($doc.CreateElement("DisplayNameMapping"))
        $userMapping.SetAttribute("Left","ARCHON-TECH\" + $row["Archon"].ToString())
        $userMapping.SetAttribute("Right","USAC\" + $row["USAC"].ToString())
        $userMapping.SetAttribute("MappingRule","SimpleReplacement")
        
        Write-Host $userMapping.OuterXml
    }
         
    $doc.Save("C:\Temp\User_VC_DisplayNameMapping.xml")
    
    Write-Host "Exported" $records "valid records."
}

Write-Host "Export complete."
Write-Host "Processed" $records "valid records."



