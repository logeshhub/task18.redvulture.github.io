###
### Script name: delete IIS logs
### Author: Vishwajeet kumar

set-executionpolicy remotesigned
##set path
$path = "D:\Logs\IIS\"

##dates
$date = Get-Date
    #set value for how old the logfiles have to be for removal
        $daysback = -90
        $deletedates = $date.AddDays($daysback)

##get the files that are to be removed
$Files = get-childitem $path -Recurse | Where-Object { $_.LastWriteTime -lt $deletedates }

#Remove old log files now
$Files | Remove-Item -Force 