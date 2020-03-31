#
# basic.ps1
#

Configuration basic
{
    Import-DscResource -Module cChoco  

    Node "installChoco"
    {
        cChocoInstaller InstallChoco
        {
            InstallDir = "c:\choco"
        }
    }
    
    Node "installBoxstarter"
    {
        cChocoInstaller InstallChoco
        {
            InstallDir = "c:\choco"
        }

        cChocoPackageInstaller installBoxstarter
        {
            Name                 = 'boxstarter'
            Ensure               = 'Present'
            DependsOn            = '[cChocoInstaller]installChoco'
        }
    }
} 