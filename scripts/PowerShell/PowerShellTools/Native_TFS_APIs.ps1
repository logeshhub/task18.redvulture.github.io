# Copyright (c) 2013 Adam Tybor
#
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to 
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.

#requires -version 3

function Add-TFSApiAssembly {
  param(
    [ValidateScript( { Test-Path $_ } )]
    $BaseReferenceAssemblyPath = (Join-Path (Get-VsInstallDir) 'ReferenceAssemblies\v2.0'),
    
    [string[]]$Assemblies = @(
      'Microsoft.TeamFoundation.dll'
      'Microsoft.TeamFoundation.Common.dll'
      'Microsoft.TeamFoundation.Client.dll'
      'Microsoft.TeamFoundation.Build.Common.dll'
      'Microsoft.TeamFoundation.Build.Client.dll'
      'Microsoft.TeamFoundation.TestManagement.Client.dll'
      'Microsoft.TeamFoundation.VersionControl.Client.dll'
      'Microsoft.TeamFoundation.VersionControl.Common.dll')
  )

  $Assemblies |% { Join-Path $BaseReferenceAssemblyPath $_ } |% { Add-Type -Path $_ -Verbose }

}

function Get-VsInstallDir {
  [CmdletBinding()]
  [OutputType([System.IO.DirectoryInfo])]
  param(
    [ValidateSet('2012','2010','2008','2005','2003')]
    [Parameter(Position=1)]
    [string]$Version
  )

  $versionToMatch = switch ($Version) {
    2012 { 11 }
    2010 { 10 }
    2008 { 9 }
    2005 { 8 }
    2003 { 7 }
    else { 0 }
  }

  if (Test-Path HKLM:\SOFTWARE\Wow6432Node) {
    $node = Get-Item HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio
  } else {
    $node = Get-Item HKLM:\SOFTWARE\Microsoft\VisualStudio
  }

  $vsVersionItem = Get-ChildItem -Path "Registry::$($node.Name)" |? Name -Match \d+\.\d+ |
    %{ Add-Member -InputObject $_ -NotePropertyMembers @{ 
      MajorVersion = [int] ((Split-Path $_.Name -Leaf).Split('.', 2))[0]
      MinorVersion = [int] ((Split-Path $_.Name -Leaf).Split('.', 2))[1]
    } -PassThru |% { 
      $_ } } |
    Sort-Object MajorVersion -Descending |
    ? { ($_.GetValue('InstallDir', $null) -ne $null) -and ($versionToMatch -le 0 -or ($versionToMatch -gt 0 -and $versionToMatch -eq $_.MajorVersion)) }
    Select-Object -First 1

  if ($vsVersionItem)
  {
    Get-ItemProperty "Registry::$($vsVersionItem.Name)" | Select-Object -ExpandProperty InstallDir | Get-Item
  } else {
    $msg = "Could not locate a Visual Studio InstallDir"
    if ($versionToMatch -gt 0) {
      $msg += " matching version '$Version'"
    }
    throw (new-object System.IO.DirectoryNotFoundException("$msg"))
  }
}

function Clear-TfsObjects {
  param([switch]$Remove)

  Get-Variable -Exclude Runspace |
    ? Value -Is [System.IDisposable] |
    ? { $_.Value.GetType().Namespace.StartsWith('Microsoft.TeamFoundation') } |
    % { 
      $_.Value.Dispose()
      if ($Remove) { 
        Remove-Variable $_.Name -Scope 1
      }
    }
}

function Add-TypesToObject {
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject,
    [string[]]$Assemblies,
    [string]$TypeContainerPropertyName="Types"
  )

  process {
    foreach($obj in $InputObject) {
      $typeContainer = new-object psobject

      foreach($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
        foreach($asmName in $Assemblies) {
          if ($asmName.EndsWith('.dll')) { $asmName = $asmName.Substring(0, $asmName.Length -4) }
          if ($asmName -eq $asm.GetName().Name) {
            $asm.GetTypes() |
              ? { $_.IsPublic -and !$_.IsSubclassOf( [Exception] ) -and $_.Name -notmatch "event" } |
              % { Add-Member NoteProperty $_.Name $_ -InputObject $typeContainer }
          }
        }
      }
      Add-Member -InputObject $obj -NotePropertyName $TypeContainerPropertyName $typeContainer
      $obj
    }
  }
}

function Get-Tfs {
  [CmdletBinding()]
  [OutputType([Microsoft.TeamFoundation.Client.TfsTeamProjectCollection])]
  param(
    [Parameter(Mandatory)]
    [System.Uri]$Uri,
    
    [ValidateSet("BS", "VCS", "WIT", "CSS", "GSS", "TM")]
    [string[]]$Services,
    [switch]$NonCached
  )

  $propertiesToAdd = @(
    @('VCS', 'Microsoft.TeamFoundation.VersionControl.Client', 'Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer'),
    @('WIT', 'Microsoft.TeamFoundation.WorkItemTracking.Client', 'Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore'),
    @('CSS', 'Microsoft.TeamFoundation', 'Microsoft.TeamFoundation.Server.ICommonStructureService'),
    @('BS', 'Microsoft.TeamFoundation.Build.Client', 'Microsoft.TeamFoundation.Build.Client.IBuildServer'),
    @('TM', 'Microsoft.TeamFoundation.TestManagement.Client', 'Microsoft.TeamFoundation.TestManagement.Client.ITestManagementService')
  )
  
  Add-TFSApiAssembly -Assemblies 'Microsoft.TeamFoundation.Client.dll'

  if ($NonCached) {
    $tfs = new-object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection($Uri)
  } else {
    $tfs = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($Uri)
  }
   
  $propertiesToAdd |
    ? { $Services -contains $_[0] } |
    % {
      # Ensure the Assembl is loaded
      Add-TFSApiAssembly -Assemblies "$($_[1]).dll"

      # Create a ScriptBlock that will return a call to GetService
      $scriptBlock = '[{0}] $this.GetService([{0}]) | Add-TypesToObject -Assemblies {1}' -f $_[2], "$($_[1]).dll"

      # Add the custom property to the object, use -Force to overwrite any existing properties
      Add-Member ScriptProperty -Name $_[0] -Value $ExecutionContext.InvokeCommand.NewScriptBlock($scriptBlock) -InputObject $tfs -Force
      $typeName = 'PoshTfs.Accessor.{0}' -f $_[2]

      # Add a custom type name to identify the extended services provided
      if ($tfs.PSObject.TypeNames -notcontains $typeName) {
        $tfs.PSObject.TypeNames.Insert(0, $typeName)
      }
    }
  $tfs
}

function Get-TfsBuildService {
  [OutputTpe([Microsoft.TeamFoundation.Build.Client.IBuildServer])]
  param(
    [Parameter(Mandatory)]
    [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection]$Tfs
  )
  if ($Tfs.PSObject.Properties.Match('BS')) {
    $Tfs.BS
  } else {
    $Tfs.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
  }
}

function Get-TfsBuildDefinition {
  [OutputType([Microsoft.TeamFoundation.Build.Client.IBuildDefinition])]
  param(
    [ValidateScript( { $_.PSObject.TypeNames -contains 'PoshTfs.Accessor.Microsoft.TeamFoundation.Build.Client.IBuildServer' } )]
    [Parameter(Mandatory)]
    [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection]$Tfs,

    [Parameter(Mandatory, ParameterSetName='By TeamProject')]
    [string]$TeamProject,

    [Parameter(Mandatory, ParameterSetName='By Uri')]
    [Uri]$Uri
  )

  switch ($PSCmdlet.ParameterSetName) {
    'By TeamProject' {
      $Tfs.BS.QueryBuildDefinitions($TeamProject)
      break;
    }
    'By Uri' {
      break;
    }
  }
}


