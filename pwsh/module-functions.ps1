#region Copyright & License

# Copyright © 2012 - 2021 François Chabot
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
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container } )]
        [string]
        $Path
    )
    $moduleManifestFile = Get-ChildItem -Path $Path -Filter *.psd1 -Exclude *.Messages.psd1 -File -Recurse -Depth 1
    if ($moduleManifestFile -isnot [System.IO.FileInfo]) { throw "Unique module manifest file could not be found in '$Path'." }
    Write-Verbose "Found module manifest file '$($moduleManifestFile.FullName)'."
    $moduleManifestFile
}

function Update-ModuleVersion {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf } )]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [version]
        $Version
    )
    $manifest = Import-PowerShellDataFile -Path $Path
    $versionPattern = [regex]::Escape($manifest.ModuleVersion)
    $pattern = "(ModuleVersion\s*=\s*['`"])$versionPattern(['`"])"
    (Get-Content -Path $Path -Encoding UTF8 -Raw) -creplace $pattern, "`${1}$Version`${2}" | Set-Content -Path $Path -Encoding UTF8
    Write-Verbose "Version of Module Manifest '$Path' has been set to '$Version'."
}
