# requires -version 2.0

[CmdletBinding()]

param (

    [parameter(Position=0, Mandatory=$true)]

    [string]

    $CollectionUri, # eg 'http://tfsserver:8080/tfs/DefaultCollection'

 

    [parameter(Position=1, Mandatory=$true)]

    [string]

    $ProjectName, # eg 'MyNewProject'

 

    [parameter(Position=2, Mandatory=$true)]

    [string]

    $ProcessTemplateName # eg 'Microsoft Visual Studio Scrum 2.0' 

)

 

if (-not $Env:TFSPowerToolDir) {

    throw "Environment variable 'TFSPowerToolDir' is not set. You may need to restart the computer after installing the TFS Power Tools."

}

 

$TfptExe = Join-Path -Path $Env:TFSPowerToolDir -ChildPath tfpt.exe

if (-not (Test-Path -Path $TfptExe -PathType Leaf)) {

    throw 'Team Foundation Server Power Tools must be installed.'

}

 

if (Get-Process | Where-Object { $_.Name -eq 'devenv' }) {

    Write-Warning 'For best results, close running instances of Visual Studio before proceeding. Waiting 10 seconds...'

    Start-Sleep -Seconds 10

}

 

$WorkingPath = Join-Path -Path $Env:TEMP -ChildPath ([Guid]::NewGuid())

New-Item -Path $WorkingPath -ItemType Container | Out-Null

 

$XmlDoc = [xml]@"

<?xml version="1.0" encoding="utf-8"?> 

<Project xmlns="ProjectCreationSettingsFileSchema.xsd">

    <TFSName>placeholder</TFSName>

    <LogFolder>placeholder</LogFolder>

    <ProjectName>placeholder</ProjectName> 

    <ProjectReportsEnabled>true</ProjectReportsEnabled>

    <ProjectSiteEnabled>true</ProjectSiteEnabled>

    <ProjectSiteTitle>placeholder</ProjectSiteTitle>

    <SccCreateType>New</SccCreateType> 

    <ProcessTemplateName>placeholder</ProcessTemplateName> 

</Project>

"@

 

$XmlDoc.Project.TFSName = $CollectionUri

$XmlDoc.Project.LogFolder = [string]$WorkingPath

$XmlDoc.Project.ProjectName = $ProjectName

$XmlDoc.Project.ProjectSiteTitle = $ProjectName

$XmlDoc.Project.ProcessTemplateName = $ProcessTemplateName

$XmlDoc.Save("$WorkingPath\settings.xml")

 

& $TfptExe createteamproject /settingsfile:"$WorkingPath\settings.xml" 2>&1 |

    Tee-Object -Variable ExeResult

$TfptExitCode = $LASTEXITCODE

$LogResult = $WorkingPath | Get-ChildItem -Exclude settings.xml | Get-Content

 

Remove-Item -Path $WorkingPath -Force -Recurse

 

if ($ExeResult -is [System.Management.Automation.ErrorRecord]) {

    throw "Failed to create new team project:`n$ExeResult"

}

 

if ($TfptExitCode -or $LogResult -match 'exception') {

    throw "Failed to create new team project:`n$LogResult"

}

 

"Project created."

