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

Configuration win10
{
    param
    (
        [string]$remoteUserName = "azureadmin"
    )
    Import-DscResource -ModuleName 'cChoco'
    Import-DscResource -ModuleName 'PSDscResources'
    #Import-DscResource -ModuleName 'xFirefox'

    $remoteUserCred = Get-AutomationPSCredential $remoteUserName

    Node 'devOps'
    {
        LocalConfigurationManager {
            DebugMode = 'ForceModuleImport'
        }
        ## Do I want to force this?
        <# 
        WindowsOptionalFeature featureHyperV {
            Name      = "Microsoft-Hyper-V-All"
            Ensure    = "Enable"
            LogLevel  = "All"
        }
        WindowsOptionalFeature featureContainers {
            Name      = "Containers"
            Ensure    = "Enable"
            LogLevel  = "All"
        }
        WindowsOptionalFeature featureWSL {
            Name      = "Microsoft-Windows-Subsystem-Linux"
            Ensure    = "Enable"
            LogLevel  = "All"
        }#>
        User 'RemoteUser' {
            Ensure   = 'Present'  # To ensure the user account does not exist, set Ensure to "Absent"
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

        Environment CreatePathEnvironmentVariable {
            Name   = 'AddCLItoPath'
            Value  = '%OneDriveCommercial%\Tools\CLI'
            Ensure = 'Present'
            Path   = $true
        }
        File createDownloads {
            Ensure          = 'Present'
            Type            = "Directory"
            DestinationPath = "D:\Downloads"
        }
        Registry odSilentAccountConfig {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive"
            ValueName = "SilentAccountConfig"
            ValueData = "1"
        }
        Registry odSilentKFMConfig {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive"
            ValueName = "KFMSilentOptInWithNotification"
            ValueData = "1"
        }
        # MSFT_xFirefoxPreference FirefoxSyncSetting
        # {
        #     PreferenceName  = "identity.sync.tokenserver.uri"
        #     PreferenceValue = "https://sync.scales.cloud/token/1.0/sync/1.5"
        # }
        cChocoInstaller installChoco {
            InstallDir = "c:\choco"
        }
        cChocoFeature allowGlobalConfirmation {
            FeatureName = "allowGlobalConfirmation"
            Ensure      = 'Present'
        }
        cChocoPackageInstaller installFirefox {
            Ensure      = 'Present'
            Name        = "firefox"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installNodeJS {
            Ensure      = 'Present'
            Name        = "nodejs"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installZoom {
            Ensure      = 'Present'
            Name        = "zoom"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installAzureCLI {
            Ensure      = 'Present'
            Name        = "azure-cli"
            DependsOn   = "[cChocoInstaller]installChoco"
            #This will automatically try to upgrade if available, only if a version is not explicitly specified.
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installVSCode {
            Ensure      = 'Present'
            Name        = "vscode"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstallerSet installVSCodeExtensions {
            Ensure    = 'Present'
            Name      = @(
                "ms-vscode.azurecli"
                "vscode-settingssync"
                "msazurermtools.azurerm-vscode-tools"
                "ms-vscode.azure-account"
                "ms-python.python"
                "ms-vscode.powershell"
                "peterjausovec.vscode-docker"
            )
            DependsOn = "[cChocoPackageInstaller]installVSCode"
        }
        cChocoPackageInstaller installNotepadPlusPlus {
            Ensure      = 'Present'
            Name        = "notepadplusplus.install"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installSlack {
            Ensure      = 'Present'
            Name        = "slack"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installPSCore {
            Ensure      = 'Present'
            Name        = "powershell-core"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installAzureStorageExplorer {
            Ensure      = 'Present'
            Name        = "microsoftazurestorageexplorer"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installEdgeInsider {
            Ensure      = 'Present'
            Name        = "microsoft-edge-insider"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstallerSet installGitStuff {
            Ensure    = 'Present'
            Name      = @(
                "git-credential-manager-for-windows"
                "github-desktop"
                "git.install"
            )
            DependsOn = "[cChocoInstaller]installChoco"
        }
        cChocoPackageInstaller noFlashAllowed {
            Ensure    = 'Absent'
            Name      = "flashplayerplugin"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    }
}
