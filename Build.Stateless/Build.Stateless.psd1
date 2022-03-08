#region Copyright & License

# Copyright © 2021 - 2022 François Chabot
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

@{
   RootModule            = 'Build.Stateless.psm1'
   ModuleVersion         = '1.0.0.0'
   GUID                  = '82ada072-c3e8-4a9a-952b-bfb29536c6a7'
   Author                = 'François Chabot'
   CompanyName           = 'be.stateless'
   Copyright             = '(c) 2021 - 2022 be.stateless. All rights reserved.'
   Description           = 'Commands supporting DevOps build pipelines for be.stateless.'
   ProcessorArchitecture = 'None'
   PowerShellVersion     = '5.0'
   NestedModules         = @()
   RequiredAssemblies    = @()
   RequiredModules       = @()
   AliasesToExport       = @()
   CmdletsToExport       = @()
   FunctionsToExport     = @(
      # Certificate
      'Load-Certificate',
      # Module
      'Build-Module',
      'Restore-Module',
      # ModuleManifest
      'Get-ModuleManifest'
   )
   VariablesToExport     = @()
   PrivateData           = @{
      PSData = @{
         Tags                       = @('be.stateless.be', 'icraftsoftware', 'DevOps', 'Build', 'Pipelines')
         LicenseUri                 = 'https://github.com/icraftsoftware/Be.Stateless.Build.Scripts/blob/master/LICENSE'
         ProjectUri                 = 'https://github.com/icraftsoftware/Be.Stateless.Build.Scripts'
         ExternalModuleDependencies = @()
      }
   }
}
