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
   $Repository,

   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]
   $NuGetApiKey
)
Set-StrictMode -Version Latest
Import-Module -Name $PSScriptRoot\..\Build.Stateless\Build.Stateless.psd1 -DisableNameChecking -Force
if ($Repository -ne 'PSGallery') {
   $arguments = @{
      Name               = $Repository
      SourceLocation     = "https://pkgs.dev.azure.com/icraftsoftware/be.stateless/_packaging/$Repository/nuget/v2"
      PublishLocation    = "https://pkgs.dev.azure.com/icraftsoftware/be.stateless/_packaging/$Repository/nuget/v2"
      InstallationPolicy = 'Trusted'
      Credential         = New-Object -TypeName PSCredential -ArgumentList 'DevOps', (ConvertTo-SecureString $NuGetApiKey -AsPlainText -Force)
   }
   if (Get-PSRepository | Where-Object Name -EQ $arguments.Name) {
      Set-PSRepository @arguments
   } else {
      Register-PSRepository @arguments
   }
}
Get-ModuleManifest -Path $Path -Verbose | ForEach-Object -Process {
   Write-Host "Publishing PowerShell Module '$($_.BaseName)' to Feed '$Repository'."
   Publish-Module -Path $_.DirectoryName -Repository $Repository -NuGetApiKey $NuGetApiKey
}
