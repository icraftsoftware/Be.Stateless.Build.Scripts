#region Copyright & License

# Copyright © 2012 - 2020 François Chabot
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
. $PSScriptRoot\module-functions.ps1

$Path = Resolve-Path -Path $Path -Verbose -ErrorAction Stop
$Destination = Resolve-Path -Path $Destination -Verbose -ErrorAction Stop

$moduleManifestSourceFile = Get-ModuleManifest -Path $Path -Verbose
$moduleStagingPath = Join-Path $Destination $moduleManifestSourceFile.BaseName

Write-Host "Module is being staged in '$moduleStagingPath'..."

# stage module's root folder
$target = New-Item -Path $moduleStagingPath -ItemType Directory -Force
Get-ChildItem -Path $Path -File |
    Where-Object { $_.Extension -notmatch '^\.yml$' } |
    Copy-Item -Destination $target -Force -Verbose

# stage module's nested folders
Get-ChildItem -Path $Path -Exclude .* -Directory |
    ForEach-Object -Process {
        $target = New-Item -Path (Join-Path $moduleStagingPath $_.Name) -ItemType Directory -Force
        Get-ChildItem -Path $_ -File | Copy-Item -Destination $target -Force -Verbose
    }

$moduleManifestStagingFile = Get-ModuleManifest -Path $moduleStagingPath -Verbose
Update-ModuleVersion -Path $moduleManifestStagingFile.FullName -Version $ModuleVersion -Verbose

$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $CertificateFilePath, $CertificatePassword, 'DefaultKeySet'
Get-ChildItem -Path $moduleStagingPath -Include *.ps*1 -Recurse |
    Set-AuthenticodeSignature -Certificate $certificate

Write-Host "Module has been staged in '$moduleStagingPath'."
