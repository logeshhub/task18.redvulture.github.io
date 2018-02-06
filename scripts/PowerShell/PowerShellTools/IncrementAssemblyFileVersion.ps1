param($PathToProjectRoot)

#used to make it easier to spot the comments from the script in the Build Output window
$msgPrefix="   |   "

#useful when testing the script - simply point this to the root of a folder that contains a project
#and the script can be run via PowerShell or ISE without having to constantly build via VS
$defaultProjectRoot="C:\projects\dwise\Samples\PowerShell\Project.Folder"

#the default location for the TFS files.  You may need to update this for your specific installation
set-alias tfs "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\tf.exe"

write-output "$msgPrefix Beginning IncrementAssemblyFileVersion.ps1"

function AssignVersionValue([string]$oldValue, [string]$newValue) {
    if ($newValue -eq $null -or $newValue -eq "") {
        $oldValue
    } else {
        #placeholder for other functionality, like incrementing, dates, etc..
        if ($newValue -eq "increment") {
            $newNum = 1
            try {
                $newNum = [System.Convert]::ToInt64($oldValue) + 1
            } catch {
                #do nothing
            }
            $newNum.ToString()
        } else {
            $newValue
        }
    }
}


function SetAssemblyFileVersion([string]$pathToFile, [string]$majorVer, [string]$minorVer, [string]$buildVer, [string]$revVer) {

    #load the file and process the lines
    $newFile = Get-Content $pathToFile -encoding "UTF8" | foreach-object {
        if ($_.StartsWith("[assembly: AssemblyFileVersion")) {
            $verStart = $_.IndexOf("(")
            $verEnd = $_.IndexOf(")", $verStart)
            $origVersion = $_.SubString($verStart+2, $verEnd-$verStart-3)
            
            $segments=$origVersion.Split(".")
            
            #default values for each segment
            $v1="1"
            $v2="0"
            $v3="0"
            $v4="0"
            
            #assign them based on what was found
            if ($segments.Length -gt 0) { $v1=$segments[0] }
            if ($segments.Length -gt 1) { $v2=$segments[1] } 
            if ($segments.Length -gt 2) { $v3=$segments[2] } 
            if ($segments.Length -gt 3) { $v4=$segments[3] } 
            
            $v1 = AssignVersionValue $v1 $majorVer
            $v2 = AssignVersionValue $v2 $minorVer
            $v3 = AssignVersionValue $v3 $buildVer
            $v4 = AssignVersionValue $v4 $revVer
            
            if ($v1 -eq $null) { throw "Major version CANNOT be blank!" }
            if ($v2 -eq $null) { throw "Minor version CANNOT be blank!" }
            
            $newVersion = "$v1.$v2"
            
            if ($v3 -ne $null) {
                $newVersion = "$newVersion.$v3"
                
                if ($v4 -ne $null) {
                    $newVersion = "$newVersion.$v4"
                }
            }

            write-host "$msgPrefix Setting AssemblyFileVersion to $newVersion"
            $_.Replace($origVersion, $newVersion)
        }  else {
            $_
        } 
    }
    
    $newfile | set-Content $assemblyInfoPath -encoding "UTF8"
}


function CheckOutFile([string]$pathToFile) {
    
    #Make sure the file is writeable from TFS
    $fileInfo =[System.IO.FileInfo]$pathToFile

    # if it is readonly attempt to check it out
    # this is a shortcut because in my environment, ReadOnly means that it is in TFS
    # I could force the checkout all of the time but that adds about 5 seconds to the build
    if ($fileInfo.Attributes -band 1) {
        Write-Output "$msgPrefix Checking out AssemblyInfo.cs"
        $coVal = tfs checkout "$pathToFile"

        if ($coVal -eq $null) {
            throw "Unable to check out the file: $pathToFile"
        }
    }    
}


if ($PathToProjectRoot -eq "" -or $PathToProjectRoot -eq $null) { $PathToProjectRoot=$defaultProjectRoot }
$PathToProjectRoot = $PathToProjectRoot.Trim("\")

#if you use another .net language, you will need to change this to support that.
$assemblyInfoPath = "$PathToProjectRoot\Properties\AssemblyInfo.cs"


CheckOutFile $assemblyInfoPath


# the values here can be whatever your heart desires
$major=$null # $null indicates that whatever value is currently in the file should be used as-is
$minor=$null 
$build=[System.DateTime]::Now.ToString("yyMM")
$rev="increment" # special token to increment whatever value it finds in that field

SetAssemblyFileVersion $assemblyInfoPath $major $minor $build $rev

write-output "$msgPrefix Ending IncrementAssemblyFileVersion.ps1"
