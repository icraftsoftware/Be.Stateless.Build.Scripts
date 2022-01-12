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
   [Parameter(Mandatory = $false)]
   [int]
   $Major = 0,

   [Parameter(Mandatory = $false)]
   [int]
   $Minor = 0,

   [Parameter(Mandatory = $false)]
   [int]
   $Build = ('{0:yy}{1:000}' -f [datetime]::Today, [datetime]::Today.DayOfYear),

   [Parameter(Mandatory = $false)]
   [int]
   $Revision = (([datetime]::Now - [datetime]::Today).TotalSeconds / 1.4)
)

# construct a Version object to ensure arguments are valid
if ($Major -eq 0) {
   $defaultVersion = ([xml](Get-Content .\src\Directory.Build.props)).Project.PropertyGroup
   if ($defaultVersion.Major -gt 0) {
      $Major = [math]::max(2, $defaultVersion.Major)
      $Minor = [math]::max(0, $defaultVersion.Minor)
   } else {
      $defaultVersion = ([xml](Get-Content $PSScriptRoot\..\Directory.Build.props)).Project.PropertyGroup
      if ($defaultVersion.Major.InnerText -gt 0) {
         $Major = [math]::max(2, $defaultVersion.Major.InnerText)
         $Minor = [math]::max(0, $defaultVersion.Minor.InnerText)
      }
   }
}
$version = New-Object -TypeName System.Version -ArgumentList $Major, $Minor, $Build, $Revision

$requiresMicrosoftBuildEngine = Get-ChildItem -Path .\src -Filter *.btproj -Recurse | Test-Any
if (-not $requiresMicrosoftBuildEngine) {
   $requiresMicrosoftBuildEngine = Get-ChildItem -Path .\src -Filter *.csproj -Recurse |
      ForEach-Object -Process { dotnet list $_.FullName package | Out-String -Stream | Select-Object -Skip 1 } |
      Select-String -SimpleMatch BizTalk.Server.2020.Build | Test-Any
}

# build and package solution
if ($requiresMicrosoftBuildEngine) {
   MSBuild.exe /Target:restore
   MSBuild.exe /property:DelaySign=false`;Configuration=Debug`;Major=$($version.Major)`;Minor=$($Version.Minor)`;Build=$($Version.Build)`;Revision=$($version.Revision)
   MSBuild.exe /property:DelaySign=false`;Configuration=Release`;Major=$($version.Major)`;Minor=$($Version.Minor)`;Build=$($Version.Build)`;Revision=$($version.Revision)`;GeneratePackageOnBuild=true`;NoWarn=1591
} else {
   dotnet restore
   dotnet build -p:DelaySign=false`;Configuration=Debug`;Major=$($version.Major)`;Minor=$($Version.Minor)`;Build=$($Version.Build)`;Revision=$($version.Revision)
   dotnet build -p:DelaySign=false`;Configuration=Release`;Major=$($version.Major)`;Minor=$($Version.Minor)`;Build=$($Version.Build)`;Revision=$($version.Revision)`;GeneratePackageOnBuild=true`;NoWarn=1591
}

# generate build.local.ps1 script file that allows to redo a build and package locally without altering the build version number
$path = Split-Path $script:MyInvocation.MyCommand.Path
@"
& $(Join-Path $path build.ps1) -Major $($version.Major) -Minor $($version.Minor) -Build $($version.Build) -Revision $($version.Revision)
"@ > $(Join-Path $path build.local.ps1)
