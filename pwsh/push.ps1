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
    [ValidateScript( { Test-Path -Path $_ -PathType Container })]
    [string]
    $Path,

    [Parameter(Mandatory = $true)]
    [string]
    $NuGetApiKey
)
Set-StrictMode -Version Latest
. $PSScriptRoot\module-functions.ps1

$Path = Resolve-Path $Path -Verbose -ErrorAction Stop
$manifest = Get-ModuleManifest -Path $Path -Verbose
$modulePath = Split-Path $manifest.FullName
Publish-Module -Path $modulePath -NuGetApiKey $NuGetApiKey
