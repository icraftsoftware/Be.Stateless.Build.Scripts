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

[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter()]
    [ValidateSet('DEV', 'BLD', 'ACC', 'PRD')]
    [string]
    $TargetEnvironment = 'DEV',

    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration = '(Debug|Release)'
)
Set-StrictMode -Version Latest
. $PSScriptRoot\manifest-functions.ps1

$arguments = @{ }
if ($PSBoundParameters.ContainsKey('Configuration')) { $arguments.Configuration = $Configuration }
$manifestFile = Get-DeploymentManifest @arguments

#Import-Module Resource.Manifest -Force
$manifest = . $manifestFile.FullName -TargetEnvironment $TargetEnvironment -ErrorAction Stop

#Import-Module BizTalk.Deployment -Force
Install-BizTalkPackage -TargetEnvironment $TargetEnvironment -Manifest $manifest -InformationAction Continue -Verbose #-SkipUndeploy
