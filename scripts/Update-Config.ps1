<#PSScriptInfo
.VERSION .1
.AUTHOR Toby Scales
.COMPANYNAME Microsoft Corporation
.ICONURI
.EXTERNALMODULEDEPENDENCIES
    Requires PowerShellCore. 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES

    Initial release.

#>
<#

.SYNOPSIS
    Creates new parameter files for the Azure Scaffold, based on input from a config.json in the root.

.DESCRIPTION
    Requires PSCore. Config.json must exist in the parent directory.

.PARAMETER rootURL
    OPTIONAL - Save time when running the script multiple times! Add the -SkipPrereqs switch today.

#>

param (
    [Parameter(Mandatory = $false)]
    [string]$rootUrl
)

$startPath = $pwd.path
$rootPath = (get-item $PSScriptRoot).Parent.FullName
$dscParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "dsc","azuredeploy.parameters.json")
$automationParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "automation","azuredeploy.parameters.json")

$configFile = (Join-Path $rootPath config.json)
$j = get-content -Raw $configFile | ConvertFrom-Json

$runbookParams = @()
$runnowParams = @()
$dscConfigParams = @()
$dscModuleParams = @()

foreach ($runbook in $j.automationRunBooks) {
    try { $response = invoke-webrequest "https://social.technet.microsoft.com/search/en-US/feed?query=$($runbook.name)&format=RSS&theme=scriptcenter&refinement=200" } catch { $response = $_.Exception.Response } 
    [xml]$xml = $response.Content

    $scriptPage = $xml.rss.channel.item[0].link
    $description = $xml.rss.channel.item[0].description

    try { $response = invoke-webrequest "$scriptPage" } catch { $response = $_.Exception.Response }
    $relativeUrl = ($response.Links | where-object { $_.class -eq "Button" }).href
    $fullUrl = "https://gallery.technet.microsoft.com/$relativeUrl"

    switch ($relativeUrl.split(".")[1]) {
        "ps1" { $type = "PowerShell" }
        "graphrunbook" { $type = "Graph" }
        "py" { $type = "PythonScript" }
    }

    if ($runbook.run -eq "now") {
        $runnowParams += [ordered]@{ 
            'name'        = $runbook.Name
            'description' = $description
            'runBookType' = $type
            'uri'         = $fullUrl
        }
    }
    else {
        $runbookParams += @{ 
            'name'        = $runbook.Name
            'description' = $description
            'runBookType' = $type
            'uri'         = $fullUrl
        }
    }
}

foreach ($config in $j.dscConfigs) {

    if ($rootUrl) {
        $dscConfigParams += [ordered]@{ 
            'name'        = $config.name
            'description' = $config.description
            'uri'         = "$rootUrl/$($config.location)"
        }
    }
    else {
        $dscConfigParams += [ordered]@{ 
            'name'        = $config.name
            'description' = $config.description
            'uri'         = $config.location
        }
    }
}
$j.dscModules | fl 
foreach ($dscModule in $j.dscModules) {

    if ($dscModule.location -eq "PSGallery") { 
        $moduleInfo = find-module $dscModule.name
        try { $response = (invoke-webrequest "https://www.powershellgallery.com/api/v2/package/$($moduleInfo.Name)/$($moduleInfo.Version)" -method Get -MaximumRedirection 0).BaseRequest } catch { $response = $_.Exception.Response } 
        $fullUrl = $response.Headers.Location.AbsoluteUri
        $fullUrl
    }

    $dscModuleParams += [ordered]@{ 
        'name'        = $dscModule.name
        'uri'         = $fullUrl
    }
}

# Optional behavior: save to dedicated azuredeploy.parameters.json files
#  $j = get-content -raw $dscParamsFile | ConvertFrom-Json
#  $j.parameters.modules.value = $dscModuleParams 
#  $j.parameters.configurations.value = $dscConfigParams
#  $j | convertto-json -depth 32 | set-content $dscParamsFile

#  $j = get-content -raw $automationParamsFile | ConvertFrom-Json
#  $j.parameters.runbooks.value = $runbookParams
#  $j.parameters.runnowbooks.value = $runnowParams
#  $j | convertto-json -depth 32 | set-content $automationParamsFile

$j.automationRunBooks = $runbookParams
$j.dscConfigs = $dscConfigParams
$j.dscModules = $dscModuleParams

$j | convertto-json -depth 32 | set-content config2.json