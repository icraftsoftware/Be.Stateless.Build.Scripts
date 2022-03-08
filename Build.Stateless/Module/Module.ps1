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

function Build-Module {
   [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Approved in PowerShell 6.')]
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateScript( { $_ | Test-Path -Include *.psd1 -PathType Leaf } )]
      [PSObject[]]
      $Path,

      [Parameter(Mandatory = $true)]
      [ValidateNotNull()]
      [System.Security.Cryptography.X509Certificates.X509Certificate2]
      $Certificate,

      [Parameter(Mandatory = $false)]
      [ValidateScript( { Test-Path -Path $_ -PathType Container } )]
      [string]
      $Destination,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [version]
      $ModuleVersion,

      [Parameter(Mandatory = $true)]
      [ValidateSet('Debug', 'Release')]
      [string]
      $Configuration
   )
   $verbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

   $Path |
      Stage-Module -Destination $Destination -Verbose:$verbose |
      Update-ModuleManifest -ModuleVersion $ModuleVersion -Configuration $Configuration -Verbose:$verbose |
      Sign-Module -Certificate $Certificate -Verbose:$verbose
}

function Restore-Module {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateScript( { $_ | Test-Path -Include *.psd1 -PathType Leaf } )]
      [PSObject[]]
      $Path
   )

   $Path | Import-PowerShellDataFile | ForEach-Object RequiredModules | ForEach-Object -Process {
      $arguments = @{}
      if ($_ -is [HashTable]) {
         $arguments.Name = $_.ModuleName
         if ($_.ContainsKey('ModuleVersion')) { $arguments.MinimumVersion = $_.ModuleVersion }
         if ($_.ContainsKey('RequiredVersion')) { $arguments.RequiredVersion = $_.RequiredVersion }
         if ($_.ContainsKey('MaximumVersion')) { $arguments.MaximumVersion = $_.RequiredVersion }
      } else {
         $arguments.Name = $_
      }
      Write-Information -MessageData "Installing PowerShell Module $($arguments.Name)."
      Install-Module @arguments -Scope CurrentUser -AllowClobber -SkipPublisherCheck -Force
   }
}

function Sign-Module {
   [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Private command.')]
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateScript( { $_ | Test-Path -Include *.psd1 -PathType Leaf } )]
      [PSObject[]]
      $Path,

      [ValidateNotNull()]
      [System.Security.Cryptography.X509Certificates.X509Certificate2]
      $Certificate
   )
   $verbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

   Write-Information -MessageData "Signing Module $($Path.FullName)."
   $Path.Directory | Get-ChildItem -Filter *.ps*1 -File -Recurse -PipelineVariable file |
      Set-AuthenticodeSignature -Certificate $Certificate -Verbose:$verbose | Out-Null
}

function Stage-Module {
   [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Private command.')]
   [CmdletBinding()]
   [OutputType([PSObject[]])]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateScript( { $_ | Test-Path -Include *.psd1 -PathType Leaf } )]
      [PSObject[]]
      $Path,

      [Parameter(Mandatory = $true)]
      [ValidateScript( { Test-Path -Path $_ -PathType Container } )]
      [string]
      $Destination
   )

   function Clean-Destination {
      [CmdletBinding()]
      [OutputType([void])]
      param(
         [Parameter(Mandatory = $true)]
         [ValidateNotNullOrEmpty()]
         [PSObject]
         $Path
      )
      $verbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

      if (Test-Path -Path $Path -PathType Container) {
         Write-Information -MessageData "Cleaning module staging destination $Path."
         Remove-Item -Path $Path -Recurse -Force -Confirm:$false -Verbose:$verbose
      }
   }

   function Copy-Module {
      [CmdletBinding()]
      [OutputType([void])]
      param(
         [Parameter(Mandatory = $true)]
         [ValidateScript( { $_ | Test-Path -PathType Container } )]
         [PSObject]
         $Path,

         [Parameter(Mandatory = $true)]
         [ValidateNotNullOrEmpty()]
         [PSObject]
         $Destination
      )
      $verbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

      Write-Information -MessageData "Copying module files to staging destination $Destination."
      Get-ChildItem -Path $Path -Exclude *.Tests.ps1 -File -Recurse | Copy-Item -Verbose:$verbose -Destination {
         $fileDestination = $Destination | Join-Path -ChildPath $_.FullName.Substring($Path.FullName.Length).Trim('\')
         $directory = Split-Path -Path $fileDestination -Parent
         if (-not(Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
            if (-not(Test-Path -LiteralPath $directory -PathType Container)) {
               # https://github.com/PowerShell/PowerShell/issues/5290
               throw "Could not create directory '$directory' because a file at the same location already exists."
            }
         }
         $fileDestination
      }
   }

   $verbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

   $Path | ForEach-Object -Process { $_ } -PipelineVariable manifest | ForEach-Object -Process {
      $moduleDestination = $Destination | Resolve-Path | Join-Path -ChildPath $manifest.BaseName
      Write-Information -MessageData "Staging module $($manifest.BaseName) from $($manifest.DirectoryName) to $moduleDestination."
      Clean-Destination -Path $moduleDestination -Verbose:$verbose
      Copy-Module -Path $manifest.Directory -Destination $moduleDestination -Verbose:$verbose
      Write-Verbose -Message 'Looking for Manifest to pipe.'
      $moduleDestination | Get-ModuleManifest -Verbose:$verbose
   }
}
