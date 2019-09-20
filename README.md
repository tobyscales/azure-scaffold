# Deploy A Management and Governance Scaffold for Azure

This creates a DevOps VM and Automation/Management scaffold in Azure, including an Automation Account and several DSC Configs. You can easily add new configurations into the /configurations folder, or simply point this deployment to your own repo.

In addition, you can customize what gets deployed by editing the [config2.json](https://github.com/tescales/azure-scaffold/blob/master/config2.json) file. To ensure you're using the latest version of all selected Modules and Runbooks, use [config.json](https://github.com/tescales/azure-scaffold/blob/master/config.json) instead and run [/scripts/Update-Config.ps1](https://github.com/tescales/azure-scaffold/blob/master/scripts/Update-Config.ps1) to generate the config2.json file prior to deployment. 

This project is notable for its use of my [Azure Bootstrapper](https://github.com/tescales/azure-bootstrapper-arm) to create a sidecar deployment inside a container instance. This is the magic that abstracts all the nested parameter files into a single place.


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftescales%2Fazure-scaffold%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Ftescales%2Fazure-scaffold%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

^^^ these buttons are currently broken due to a sequencing limitation in the Azure Portal. If you '''git clone''' the repo and deploy from a command-line, it will work.




## TODO: 
 * Add bastion host support
 * figure out how to get userObjectId gracefully
 * move VM deployment logic to sidecar (to solve Deploy to Azure button issue)
 * Fix PSGallery deployment type not working for Runbooks
 * Refactor RunNow logic using a .runnow value (collect true/false and deploy jobs for them)
 * Use KV to generate cert for VM authentication:
    https://www.rahulpnath.com/blog/manage-certificates-in-azure-key-vault/
 * Consider adding Function to pull UserObjectID: 
    https://github.com/jussiroine/TenantIDLookup
 * Add Alerts Toolkit:
    https://github.com/Microsoft/manageability-toolkits
    https://www.powershellgallery.com/packages/Enable-AzureDiagnostics/1.1
 * Look at CAF integration:
    https://github.com/microsoft/CloudAdoptionFramework
 * Add AzureAutomation RunAs Account:
    https://docs.microsoft.com/en-us/azure/automation/manage-runas-account
 * Add Update-KVCert script from automation: 
    https://github.com/jefffanjoy/DemoCode/blob/master/Scripts/Azure%20Automation/RenewRunAsCertificate.ps1
 * Investigate DeploymentManager for simplification:
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/deployment-manager-overview#rollout-template

 * Azsecrets?
 https://www.gollahalli.com/blog/azsecrets-a-cli-to-set-azure-key-vault-as-environment-variables/

 * Secure web app? (web+appgw):
 https://blogs.msdn.microsoft.com/mihansen/2018/02/15/web-app-with-vnet-only-access-using-app-gateway-powershell-automation/