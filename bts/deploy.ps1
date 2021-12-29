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
    [Parameter(Mandatory = $false)]
    [ValidateSet('DEV', 'BLD', 'ACC', 'PRE', 'PRD')]
    [string]
    $TargetEnvironment = 'DEV',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration

    # TODO re-expose manifest's param as dynamic params

    # TODO -Skip switches : ?? re-expose Install-BizTalkPackage's param as dynamic params

)
Set-StrictMode -Version Latest
. $PSScriptRoot\manifest-functions.ps1

$arguments = @{ }
if ($PSBoundParameters.ContainsKey('Configuration')) { $arguments.Configuration = $Configuration }
$manifestFile = Get-DeploymentManifest @arguments
$manifest = . $manifestFile.FullName -ErrorAction Stop
Install-BizTalkPackage -TargetEnvironment $TargetEnvironment -Manifest $manifest #-SkipUndeploy
