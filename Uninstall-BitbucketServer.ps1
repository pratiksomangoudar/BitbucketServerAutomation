# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding()]
param(
    [string]
    $BitbucketInstallationPath = (Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian\Bitbucket'),

    [string]
    $BitbucketApplicationDataPath = (Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian\ApplicationData\Bitbucket')
)

Set-StrictMode -Version 'Latest'
#Requires -RunAsAdministrator

& {
    $VerbosePreference = 'SilentlyContinue'

    $importCarbonModulePath = (Join-Path -Path $PSScriptRoot -ChildPath '.\PSModules\Carbon\2.6.0\Import-Carbon.ps1')
    if (-not (Test-Path -Path $importCarbonModulePath -PathType Leaf))
    {
        Save-Module -Name 'Carbon' -Path (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules') -RequiredVersion '2.6.0' -Force
    }

    & $importCarbonModulePath
}

Get-Service -Name '*Bitbucket*' |
    Stop-Service -PassThru -Force |
    ForEach-Object { Uninstall-Service -Name $_.Name }

Remove-EnvironmentVariable -Name 'BITBUCKET_HOME' -ForComputer -ForUser -ForProcess
Remove-EnvironmentVariable -Name 'BITBUCKET_INSTALLATION' -ForComputer -ForUser -ForProcess

Uninstall-User -Username 'atlbitbucket'

foreach ($path in @('HKLM:\SOFTWARE\Atlassian\Bitbucket', $BitbucketInstallationPath, $BitbucketApplicationDataPath))
{
    if ( (Test-Path -Path $path) )
    {
        Remove-Item -Path $path -Recurse -Force
    }
}
