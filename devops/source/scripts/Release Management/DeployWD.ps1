Param(
    [string] $packageFilename = $(throw "The Web Deploy filename is required, e.g., WebSitePackage.zip"),
    [string] $parameterFilename = $(throw, "The Web Deploy Parameters file is required, e.g., WebSitePackage.SetParameters.xml")
)

#
# trap any errors - and make sure to return a non-zero return code to indicate failure
#
trap { "Error: " + $_; exit 1; }

Add-PSSnapin WDeploySnapin3.0

$parameters = Get-WDParameters $parameterFilename

Restore-WDPackage $packageFilename -Parameters $parameters -Verbose -ErrorVariable WDError

if ( $WDError.Count -ne 0)
{
	Write-Error "An Error occured: " + $WDError
	exit 2
}

