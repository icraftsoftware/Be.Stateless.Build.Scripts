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

function Get-DeploymentManifest {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter()]
        [ValidateSet('Debug', 'Release')]
        [string]
        $Configuration = '(Debug|Release)'
    )
    $candidateManifestFiles = @(Get-ChildItem -Path . -Filter Manifest.ps1 -Recurse | Where-Object -FilterScript { $_.FullName -match "\\bin\\$Configuration\\" })
    switch ($candidateManifestFiles.Length) {
        0 {
            throw 'No Manifest.ps1 found.'
        }
        1 {
            Write-Verbose -Message 'One single Manifest.ps1 found.'
            $candidateManifestFiles[0]
        }
        { $_ -eq 2 -and !$PSBoundParameters.ContainsKey('Configuration') } {
            Write-Verbose -Message 'Two Manifest.ps1 found; giving precedence to Release one as Configuration has not been given.'
            $candidateManifestFiles | Where-Object -FilterScript { $_.FullName -match '\\bin\\Release\\' }
        }
        default {
            $candidateManifestFiles | ForEach-Object FullName | Resolve-Path -Relative | Write-Verbose
            throw 'Multiple Manifest.ps1 files found.'
        }
    }
}

