#region Copyright & License

# Copyright © 2012 - 2022 François Chabot
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

[CmdletBinding()]
[OutputType([void])]
param(
   [Parameter(Mandatory = $true)]
   [ValidateScript( { Test-Path -Path $_ -PathType Container } )]
   [string]
   $Path,

   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]
   $Destination,

   [Parameter(Mandatory = $true)]
   [version]
   $ModuleVersion,

   [Parameter(Mandatory = $true)]
   [ValidateScript( { Test-Path -Path $_ -PathType Leaf } )]
   [string]
   $CertificatePath,

   [Parameter(Mandatory = $true)]
   [SecureString]
   $CertificatePassword,

   [Parameter(Mandatory = $true)]
   [ValidateSet('Debug', 'Release')]
   [string]
   $Configuration
)
Set-StrictMode -Version Latest
if (-not(Test-Path -Path $Destination -PathType Container)) { New-Item -Path $Destination -ItemType Directory -Force }
Import-Module -Name $PSScriptRoot\..\Build.Stateless\Build.Stateless.psd1 -DisableNameChecking -Force
$certificate = Load-Certificate -Path $CertificatePath -Password $CertificatePassword
Get-ModuleManifest -Path $Path -Verbose | Build-Module -Certificate $certificate -Destination $Destination -ModuleVersion $ModuleVersion -Configuration $Configuration -InformationAction Continue
