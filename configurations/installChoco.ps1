#
# installChoco.ps1
#

Configuration InstallChoco
{
    Import-DscResource -Module cChoco  

    Node "chocoVM"
    {
        cChocoInstaller InstallChoco
        {
            InstallDir = "c:\choco"
        }

        cChocoPackageInstaller installSkypeWithChocoParams
        {
            Name                 = 'skype'
            Ensure               = 'Present'
            DependsOn            = '[cChocoInstaller]installChoco'
        }
    }
} 