#region Copyright & License

# Copyright © 2021 - 2022 François Chabot
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#endregion

Set-StrictMode -Version Latest

function Get-ModuleManifest {
   [CmdletBinding()]
   [OutputType([PSObject[]])]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateScript( { Test-Path -Path $_ -PathType Container } )]
      [string]
      $Path
   )
   Get-ChildItem -Path $Path -Filter *.psd1 -Recurse -File | Where-Object -FilterScript {
      # recursively exclude files underneath a \*.Tests\ folder
      $_.DirectoryName -notmatch '\\\w\S+\.Tests\\'
   } | Where-Object -FilterScript {
      # as per PowerShell conventions, the manifest and its containing folder are eponymous
      $_.BaseName -eq $_.Directory.BaseName
   } | Where-Object -FilterScript {
      Test-Path -Path (Join-Path -Path $_.Directory -ChildPath ($_ | Import-PowerShellDataFile).RootModule)
   } | ForEach-Object -Process {
      Write-Verbose -Message "Found PowerShell Module Manifest $($_.FullName)"
      $_
   }
}

function Update-ModuleManifest {
   [CmdletBinding()]
   [OutputType([PSObject[]])]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateScript( { $_ | Test-Path -Include *.psd1 -PathType Leaf } )]
      [PSObject[]]
      $Path,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [version]
      $ModuleVersion,

      [Parameter(Mandatory = $true)]
      [ValidateSet('Debug', 'Release')]
      [string]
      $Configuration
   )
   $Path.Directory | Get-ChildItem -Filter *.psd1 -Exclude *.Messages.psd1 -File -Recurse | ForEach-Object -Process {
      Write-Information -MessageData "Updating Manifest $($_.FullName)'s Module Version $ModuleVersion."
      $manifest = $_ | Import-PowerShellDataFile
      if ($Configuration -eq 'Release') {
         $moduleVersionReplacementArguments = "^(\s*ModuleVersion\s*=\s*['`"])$([regex]::Escape($manifest.ModuleVersion))(['`"]\s*)$", "`${1}$ModuleVersion`${2}"
         $prereleaseSuffixReplacementArguments = "^(\s*Prerelease\s*=\s*['`"])($([regex]::Escape($manifest.PrivateData.PSData.Prerelease)))(['`"]\s*)$", '${1}${3}'
      } else {
         $version = [Version]$ModuleVersion
         $moduleVersionReplacementArguments = "^(\s*ModuleVersion\s*=\s*['`"])$([regex]::Escape($manifest.ModuleVersion))(['`"]\s*)$", "`${1}$($version.Major).$($version.Minor).$($version.Build)`${2}"
         $prereleaseSuffixReplacementArguments = "^(\s*Prerelease\s*=\s*['`"])($([regex]::Escape($manifest.PrivateData.PSData.Prerelease)))(['`"]\s*)$", "`${1}preview$($version.Revision)`${3}"
      }
      ($_ | Get-Content -Encoding UTF8) -replace $moduleVersionReplacementArguments -replace $prereleaseSuffixReplacementArguments | Set-Content -Path $_.FullName -Encoding UTF8
      Write-Verbose -Message 'Looking for Manifest to pipe.'
      $Path.Directory | Get-ModuleManifest -Verbose:$verbose
   }
}
