
Clear-Host
$vssPath = "C:\Src\2013SB\Tools\"

$vssFiles = Get-ChildItem $vssPath*.vss* -Recurse
foreach ($file in $vssFiles)
{
    Write-Host "Removing:" $file.FullName
    
    # turn off ready only flag
    Set-ItemProperty $file -name IsReadOnly -value $false
    
    #remove source control metadata file
    Remove-Item $file
}

$vssFiles = Get-ChildItem $vssPath*.vsp* -Recurse
foreach ($file in $vssFiles)
{
    Write-Host "Removing:" $file.FullName

    # turn off ready only flag
    Set-ItemProperty $file -name IsReadOnly -value $false
    
    #remove source control metadata file
    Remove-Item $file
}

$vssFiles = Get-ChildItem $vssPath*.suo* -Recurse
foreach ($file in $vssFiles)
{
    Write-Host "Removing:" $file.FullName
    
    # turn off ready only flag
    Set-ItemProperty $file -name IsReadOnly -value $false
    
    #remove source control metadata file
    Remove-Item $file
}

$vssFiles = Get-ChildItem $vssPath*.user -Recurse
foreach ($file in $vssFiles)
{
    Write-Host "Removing:" $file.FullName
    
    # turn off ready only flag
    Set-ItemProperty $file -name IsReadOnly -value $false
    
    #remove source control metadata file
    Remove-Item $file
}
