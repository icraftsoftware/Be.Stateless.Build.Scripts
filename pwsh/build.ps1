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
   [ValidateScript( { Test-Path -Path $_ -PathType Container } )]
   [string]
   $Destination,

   [Parameter(Mandatory = $true)]
   [version]
   $ModuleVersion,

   [Parameter(Mandatory = $true)]
   [ValidateScript( { Test-Path -Path $_ -PathType Leaf } )]
   [string]
   $CertificateFilePath,

   [Parameter(Mandatory = $true)]
   [SecureString]
   $CertificatePassword
)
Set-StrictMode -Version Latest

$moduleDestination = Join-Path -Path $Destination (Split-Path -Path $Path -Leaf)
Write-Host "PowerShell Module is being staged to '$moduleDestination'..."

Get-ChildItem -Path $Path -Exclude *.Tests.ps1 -File -Recurse | Copy-Item -Verbose -Destination {
   $fileDestination = Join-Path -Path $moduleDestination -ChildPath $_.FullName.Substring($Path.length)
   $folder = Split-Path -Path $fileDestination -Parent
   if (-not (Test-Path -Path $folder -PathType Container)) { New-Item -Path $folder -ItemType Directory -Verbose | Out-Null }
   $fileDestination
}

Get-ChildItem -Path $Destination -Filter *.psd1 -File -Recurse | ForEach-Object -Process {
   $manifest = $_ | Import-PowerShellDataFile
   $versionPattern = [regex]::Escape($manifest.ModuleVersion)
   $pattern = "^(\s*ModuleVersion\s*=\s*['`"])$versionPattern(['`"]\s*)$"
   Write-Host "Setting Module Manifest '$_' Version Property to '$ModuleVersion'."
   ($_ | Get-Content -Encoding UTF8) -replace $pattern, "`${1}$ModuleVersion`${2}" | Set-Content -Path $_.FullName -Encoding UTF8
}

$certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $CertificateFilePath, $CertificatePassword, 'DefaultKeySet'
Get-ChildItem -Path $Destination -Filter *.ps*1 -Recurse | Set-AuthenticodeSignature -Certificate $certificate

Write-Host "PowerShell Module has been staged to '$Destination'."
