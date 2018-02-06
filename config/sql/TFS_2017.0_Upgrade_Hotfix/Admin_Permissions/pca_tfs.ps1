$url = "https://tfsdev.mmm.com/tfs/testcollection"
$localScopeIdList = Get-Content C:\Temp\LocalScopeIdList.txt
$cmd = "C:\Program Files\Microsoft Team Foundation Server 15.0\Tools\TFSSecurity.exe"

$collection = "/collection:"+ $url
$permissions = "Read", "Write", "Delete", "ManageMembership", "CreateScope"

foreach($scopeId in $localScopeIdList) {
    foreach($permission in $permissions) {
        $token = $scopeId + "\"    
 
        $param =  @("/a+", "Identity", $token, $permission, "adm:", "ALLOW", $collection)
        Write-Host $param

        & $cmd $param
    }
} 
