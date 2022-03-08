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

Set-StrictMode -Version Latest

function Load-Certificate {
   [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Private command.')]
   [CmdletBinding()]
   [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateScript( { Test-Path -Path $_ -PathType Leaf } )]
      [string]
      $Path,

      [Parameter(Mandatory = $true)]
      [SecureString]
      $Password
   )
   New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $Path, $Password, 'DefaultKeySet'
}
