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
    [Parameter(Mandatory = $false)]
    [int]
    $Major = 2,

    [Parameter(Mandatory = $false)]
    [int]
    $Minor = 0,

    [Parameter(Mandatory = $false)]
    [int]
    $PackagePatch = 0,

    [Parameter(Mandatory = $false)]
    [int]
    $Build = ('{0:yy}{1:000}' -f [datetime]::Today, [datetime]::Today.DayOfYear),

    [Parameter(Mandatory = $false)]
    [int]
    $Revision = (([datetime]::Now - [datetime]::Today).TotalSeconds / 1.4)
)

Clear-Host

# construct a Version object to ensure arguments are valid
$version = New-Object -TypeName System.Version -ArgumentList $Major, $Minor, $Build, $Revision

# build and package solution
if (Get-ChildItem -Path *.sln | Where-Object Name -match 'Be\.Stateless\.BizTalk\.(Dummies|Orchestrations|Pipelines|Schemas|Transforms)\.sln') {
    MSBuild.exe /Target:restore
    MSBuild.exe /property:DelaySign=false`;Configuration=Debug`;Major=$($version.Major)`;Minor=$($version.Minor)`;PackagePatch=$($PackagePatch)`;Build=$($version.Build)`;Revision=$($version.Revision)
    MSBuild.exe /property:DelaySign=false`;Configuration=Release`;Major=$($version.Major)`;Minor=$($version.Minor)`;PackagePatch=$($PackagePatch)`;Build=$($version.Build)`;Revision=$($version.Revision)`;GeneratePackageOnBuild=true`;NoWarn=1591
}
else {
    dotnet build -p:DelaySign=false`;Configuration=Debug`;Major=$($version.Major)`;Minor=$($version.Minor)`;PackagePatch=$($PackagePatch)`;Build=$($version.Build)`;Revision=$($version.Revision)
    dotnet build -p:DelaySign=false`;Configuration=Release`;Major=$($version.Major)`;Minor=$($version.Minor)`;PackagePatch=$($PackagePatch)`;Build=$($version.Build)`;Revision=$($version.Revision)`;GeneratePackageOnBuild=true`;NoWarn=1591
}

# generate build.local.ps1 script file that allows to redo a build and package locally wihtout altering the build version number
$path = Split-Path $script:MyInvocation.MyCommand.Path
@"
& $(Join-Path $path build.ps1) -Major $($version.Major) -Minor $($version.Minor) -Build $($version.Build) -Revision $($version.Revision)
"@ > $(Join-Path $path build.local.ps1)
