# Copyright (c) 2017 Chocolatey Software, Inc.
# Copyright (c) 2013 - 2017 Lawrence Gripper & original authors/contributors from https://github.com/chocolatey/cChoco
#
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

$ErrorActionPreference='SilentlyContinue'

Configuration win10
{
    param
    (
        #have to keep default values to enable dsc-compilation
        [string]$remoteUserName = (Get-AutomationVariable "mgmtUserName"), 
        [string]$tenantId = (Get-AutomationVariable "tenantId"),
        [string]$azResourceGroup = (Get-AutomationVariable "mgmtResourceGroup"),
        [string]$azLocation = (Get-AutomationVariable "mgmtLocation"),
        [string]$azConfigUrl = (Get-AutomationVariable "mgmtConfigUrl")
    )

    Import-DscResource -ModuleName 'cChoco'
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    #Import-DscResource -ModuleName 'PSDesiredStateConfiguration' DO NOT USE
    
    $remoteUserCred = Get-AutomationPSCredential $remoteUserName
    
    #can't use this because the DSC resource won't compile with it; need to use an external script instead, to set an env variable
    #$tenantId = (invoke-restmethod "http://169.254.169.254/metadata/identity/info?api-version=2018-02-01" -UseBasicParsing -Method GET -Headers @{Metadata = "true" }).TenantId

    Node "devops"
    {
        #######################
        #region WindowsOptionalFeatures
        ####################### 
        WindowsOptionalFeatureSet enableHyperV {
            Name   = @('Microsoft-Hyper-V', 'HypervisorPlatform', 'Microsoft-Hyper-V-Services', 'Microsoft-Hyper-V-Management-Clients', 'VirtualMachinePlatform')
            Ensure = 'Present'
        }
        WindowsOptionalFeatureSet enableNetworkTools {
            Name   = @('ServicesForNFS-ClientOnly', 'ClientForNFS-Infrastructure', 'TelnetClient')
            Ensure = 'Present'
        }
        WindowsOptionalFeature enableContainers {
            Name   = 'Containers'
            Ensure = 'Present'
        }
        WindowsOptionalFeature enableSandbox {
            Name   = 'Containers-DisposableClientVM'
            Ensure = 'Present'
        }
        WindowsOptionalFeature enableWSL {
            Name   = 'Microsoft-Windows-Subsystem-Linux'
            Ensure = 'Present' 
        }
        WindowsOptionalFeatureSet disableUnused {
            Name                 = @('WindowsMediaPlayer', 'WorkFolders-Client', 'Printing-XPSServices-Features', 'FaxServicesClientPackage', 'Internet-Explorer-Optional-amd64', 'MicrosoftWindowsPowerShellV2', 'MicrosoftWindowsPowerShellV2Root')
            Ensure               = 'Absent'
            RemoveFilesOnDisable = $true
        }
        #endregion 
        
        #######################
        #region User+Group Settings
        ####################### 
        User remoteUser {
            Ensure   = 'Present'
            UserName = $remoteUserCred.UserName
            Password = $remoteUserCred # This needs to be a credential object
        }
        Group remoteUserPU {
            GroupName        = 'Power Users'
            Ensure           = 'Present'
            MembersToInclude = @($remoteUserCred.UserName)
        }
        Group remoteUserRA {
            GroupName        = 'Remote Desktop Users'
            Ensure           = 'Present'
            MembersToInclude = @($remoteUserCred.UserName)
        }
        #endregion

        #######################
        #region Environment Settings
        ####################### 
        Environment azResourceGroup {
            Name   = 'AZURE_RESOURCE_GROUP'
            Value  = $azResourceGroup
            Ensure = 'Present'
            Target = @('Process', 'Machine')
        }
        Environment azLocation {
            Name   = 'AZURE_LOCATION'
            Value  = $azLocation
            Ensure = 'Present'
            Target = @('Process', 'Machine')
        }
        Environment azConfigUrl {
            Name   = 'AZURE_CONFIG_URL'
            Value  = $azConfigUrl
            Ensure = 'Present'
            Target = @('Process', 'Machine')
        }
        #endregion

        #######################
        #region  File Settings
        #######################
        
        #endregion

        #######################
        #region Registry Settings
        #######################

        #endregion

        #######################
        #region cChoco Installer
        #######################
        cChocoInstaller installChoco {
            InstallDir = 'c:\choco'
        }
        cChocoFeature allowGlobalConfirmation {
            FeatureName = 'allowGlobalConfirmation'
            Ensure      = 'Present'
        }
        cChocoPackageInstaller installFunctionsCoreTools {
            Ensure      = 'Present'
            Name        = 'azure-functions-core-tools'
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True             #This will automatically try to upgrade if available, only if a version is not explicitly specified.
        }
        cChocoPackageInstaller installdotNetCore {
            Ensure      = 'Present'
            Name        = 'dotnetcore-sdk'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installPostman {
            Ensure      = 'Present'
            Name        = 'postman'
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installNodeJS {
            Ensure      = 'Present'
            Name        = 'nodejs'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installAzureCLI {
            Ensure      = 'Present'
            Name        = 'azure-cli'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installVSCode {
            Ensure      = 'Present'
            Name        = 'vscode'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $True
        }
        cChocoPackageInstallerSet installVSCodeExtensions {
            Ensure    = 'Present'
            Name      = @(
                "ms-vscode.azurecli",
                "msazurermtools.azurerm-vscode-tools",
                "ms-vscode.azure-account"
            )
            DependsOn = '[cChocoPackageInstaller]installVSCode'
        }
        cChocoPackageInstaller installNotepadPlusPlus {
            Ensure      = 'Present'
            Name        = 'notepadplusplus.install'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installAzureStorageExplorer {
            Ensure      = 'Present'
            Name        = 'microsoftazurestorageexplorer'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $True
        }
        cChocoPackageInstallerSet installGitStuff {
            Ensure    = 'Present'
            Name      = @(
                "git-credential-manager-for-windows",
                "github-desktop",
                "git.install"
            )
            DependsOn = '[cChocoInstaller]installChoco'
        }
        #endregion
    }
}
