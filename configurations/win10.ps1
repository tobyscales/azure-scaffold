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
        #have to keep default values to enable dsc-compilation
        [string]$remoteUserName = (Get-AutomationVariable "mgmtUserName"), 
        [string]$tenantId= (Get-AutomationVariable "tenantId"),
        [string]$azResourceGroup= (Get-AutomationVariable "mgmtResourceGroup"),
        [string]$azLocation= (Get-AutomationVariable "mgmtLocation"),
        [string]$azConfigUrl= (Get-AutomationVariable "mgmtConfigUrl")
        # [string]$remoteUserName = "azureadmin",
        # [string]$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47", #MSFT tenantid
        # [string]$azResourceGroup = "dnd-mgmt", #remove for prod
        # [string]$azLocation = "westus2", #remove for prod
        # [string]$azConfigUrl = "https://raw.github.com/user/tescales/az-scaffold/etc" #remove for prod
    )
    Import-DscResource -ModuleName 'cChoco'
    Import-DscResource -ModuleName 'PSDscResources'
    #Import-DscResource -ModuleName 'PSDesiredStateConfiguration' DO NOT USE
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    #Import-DscResource -ModuleName 'xFirefox'
    
    $remoteUserCred = Get-AutomationPSCredential $remoteUserName
    
    #can't use this because the DSC resource won't compile with it; need to use an external script instead, to set an env variable
    #$tenantId = (invoke-restmethod "http://169.254.169.254/metadata/identity/info?api-version=2018-02-01" -UseBasicParsing -Method GET -Headers @{Metadata = "true" }).TenantId

    Node "devops"
    {
        LocalConfigurationManager {
             DebugMode            = 'ForceModuleImport' #change this for prod
             AllowModuleOverwrite = $True
        }
        ## Do I want to force this?
        # WindowsOptionalFeature featureHyperV {
        #     Name      = "Microsoft-Hyper-V-All"
        #     Ensure    = "Enable"
        #     LogLevel  = "All"
        # }
        # PowerShellExecutionPolicy ExecutionPolicy
        # {
        #     ExecutionPolicyScope = 'Process'
        #     ExecutionPolicy      = 'Unrestricted'
        # }
        # MSFT_xFirefoxPreference FirefoxSyncSetting
        # {
        #     PreferenceName  = "identity.sync.tokenserver.uri"
        #     PreferenceValue = "https://sync.scales.cloud/token/1.0/sync/1.5"
        # }

        WindowsOptionalFeature featureContainers {
            Name   = 'Containers'
            Ensure = 'Present'
        }
        WindowsOptionalFeature featureWSL {
            Name   = 'Microsoft-Windows-Subsystem-Linux'
            Ensure = 'Present'
        }
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
        Environment updatePathEnvironmentVariable {
            Name   = 'Path'
            Value  = "$Env:OneDriveCommercial\Tools\CLI"
            Ensure = 'Present'
            Path   = $true
            Target = @('Process', 'Machine')
        }
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
        
        File createDownloads {
            Ensure          = 'Present'
            Type            = "Directory"
            DestinationPath = "D:\Downloads"
        }
        File removeFFShortcut {
            Ensure          = 'Absent'
            Type            = 'File'
            DestinationPath = 'C:\Users\Public\Desktop\Firefox.lnk'
        }
        File removeEdgeBetaShortcut {
            Ensure          = 'Absent'
            Type            = 'File'
            DestinationPath = 'C:\Users\Public\Desktop\Microsoft Edge Beta.lnk'
        }
        File removeVSCShortcut {
            Ensure          = 'Absent'
            Type            = 'File'
            DestinationPath = 'C:\Users\Public\Desktop\Visual Studio Code.lnk'
        }
        File removeZoomShortcut {
            Ensure          = 'Absent'
            Type            = 'File'
            DestinationPath = 'C:\Users\Public\Desktop\Zoom.lnk'
        }
        # File removeGHShortcut {
        #     Ensure          = 'Absent'
        #     Type            = 'File'
        #     DestinationPath = "$Env:OneDriveCommercial\Desktop\Github Desktop.lnk"
        # }
        # File removeEdgeShortcut {
        #     Ensure          = 'Absent'
        #     Type            = 'File'
        #     DestinationPath = "$Env:OneDriveCommercial\Desktop\Microsoft Edge.lnk"
        # }
        File removeUserGHShortcut {
            Ensure          = 'Absent'
            Type            = 'File'
            DestinationPath = "$Env:userprofile\Desktop\Github Desktop.lnk"
        }
        File removeUserEdgeShortcut {
            Ensure          = 'Absent'
            Type            = 'File'
            DestinationPath = "$Env:userprofile\Desktop\Microsoft Edge.lnk"
        }
        #endregion

        #######################
        #region Registry Settings
        #######################

        # Registry odRenameRoot {
        #     Ensure    = '"Present'
        #     Key       = "HKEY_CURRENT_USER\Software\Microsoft\OneDrive\Accounts\Business1"
        #     ValueName = "UserFolder"
        #     ValueData = "C:\ODFB"
        # }
        # Registry odMoveRoot {
        #     Ensure    = '"Present'
        #     Key       = "HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\OneDrive\DefaultRootDir"
        #     ValueName = $tenantId
        #     ValueData = "C:\"
        # }
        Registry odSilentAccountConfig {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
            ValueName = 'SilentAccountConfig'
            ValueType = "Dword"
            ValueData = '1'
            Force     = $true
        }
        Registry odSilentOptIn {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
            ValueName = 'KFMSilentOptIn'
            ValueData = $tenantId
            Force     = $true
        }
        Registry odSilentKFMConfig {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
            ValueName = 'KFMSilentOptInWithNotification'
            ValueData = '1'
            ValueType = "Dword"
            Force     = $true
        }
        Registry moveDownloadsFolder {
            Ensure    = 'Present'
            Key       = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
            ValueName = '{374DE290-123F-4565-9164-39C4925E467B}'
            ValueData = 'D:\Downloads'
            Force     = $true
        }
        Registry moveIEDownloadsFolder {
            Ensure    = 'Present'
            Key       = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main'
            ValueName = 'DefaultDownloadDirectory'
            ValueData = 'D:\Downloads'
            Force     = $true
        }
        #endregion

        #######################
        #region cChoco Installer
        #######################
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
        cChocoPackageInstaller installFunctionsCoreTools {
            Ensure      = 'Present'
            Name        = "azure-functions-core-tools"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installdotNetCore {
            Ensure      = 'Present'
            Name        = "dotnetcore-sdk"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installPostman {
            Ensure      = 'Present'
            Name        = "postman"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstaller installNodeJS {
            Ensure      = 'Present'
            Name        = "nodejs"
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
                "ms-vscode.azurecli",
                "vscode-settingssync",
                "msazurermtools.azurerm-vscode-tools",
                "ms-vscode.azure-account",
                "ms-python.python",
                "ms-vscode.powershell",
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
        cChocoPackageInstallerSet installConferenceTools {
            Ensure    = 'Present'
            Name      = @(
                "zoom",
                "slack",
                "microsoft-teams"
            )
            DependsOn = "[cChocoInstaller]installChoco"
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
        cChocoPackageInstaller installO365 {
            Ensure      = 'Present'
            Name        = "office365business"
            DependsOn   = "[cChocoInstaller]installChoco"
            AutoUpgrade = $True
        }
        cChocoPackageInstallerSet installGitStuff {
            Ensure    = 'Present'
            Name      = @(
                "git-credential-manager-for-windows",
                "github-desktop",
                "git.install"
            )
            DependsOn = "[cChocoInstaller]installChoco"
        }
        cChocoPackageInstaller noFlashAllowed {
            Ensure    = 'Absent'
            Name      = "flashplayerplugin"
            DependsOn = "[cChocoInstaller]installChoco"
        }
        #endregion
    }
}
