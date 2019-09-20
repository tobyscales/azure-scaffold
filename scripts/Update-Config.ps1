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
function get-TechNetItem {
    param(
        [string]$itemName
    )
    [hashtable]$return = @{}

    try { $response = invoke-webrequest "https://social.technet.microsoft.com/search/en-US/feed?query=$itemName&format=RSS&theme=scriptcenter&refinement=200" } catch { $response = $_.Exception.Response } 
    [xml]$xml = $response.Content

    $scriptPage = $xml.rss.channel.item[0].link
    $return.description = $xml.rss.channel.item[0].description

    try { $response = invoke-webrequest "$scriptPage" } catch { $response = $_.Exception.Response }
    $relativeUrl = ($response.Links | where-object { $_.class -eq "Button" }).href
    $return.fullUrl = "https://gallery.technet.microsoft.com/$relativeUrl"

    switch ($relativeUrl.split(".")[1]) {
        "ps1" { $return.type = "PowerShell" }
        "graphrunbook" { $return.type = "Graph" }
        "py" { $return.type = "PythonScript" }
    }

    return $return
}
function get-PSGalleryItem {
    param(
        [string]$itemName, [string]$itemType
    )
    [hashtable]$return = @{}

    switch ($itemType) {
        "module" { $info = find-module $itemName }
        "script" { $info = find-script $itemName; $return.type="Script" }
    }
    
    try { $response = (invoke-webrequest "https://www.powershellgallery.com/api/v2/package/$($info.name)/$($info.version)" -method Get -MaximumRedirection 0).BaseRequest } catch { $response = $_.Exception.Response } 
    $return.fullUrl = $response.Headers.Location.AbsoluteUri
    $return.description = $info.description

    # return AbsoluteUri for scripts... probably a better place to get this info from
    if ($itemType -eq "script") { $return.fullUrl = $info.ProjectUri.AbsoluteUri }
    
    return $return
}

$startPath = $pwd.path
$rootPath = (get-item $PSScriptRoot).Parent.FullName
$dscParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "dsc", "azuredeploy.parameters.json")
$automationParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "automation", "azuredeploy.parameters.json")

$configFile = (Join-Path $rootPath config.json)
$j = get-content -Raw $configFile | ConvertFrom-Json

$runbookParams = @()
$runnowParams = @()
$dscConfigParams = @()
$dscModuleParams = @()

foreach ($runbook in $j.automationRunbooks) {

    if ( $runbook.location -eq "TechNet" ) { $item = get-TechNetItem -itemName $runbook.name } 
    elseif ( $runbook.location -eq "PSGallery" ) { $item = get-PSGalleryItem -itemName $runbook.name -itemType "script" }

    if ($runbook.run -eq "now") {
        $runnowParams += [ordered]@{ 
            'name'        = $runbook.name
            'description' = $item.description
            'runbookType' = $item.type
            'uri'         = $item.fullUrl
        }
    }
    else {
        $runbookParams += @{ 
            'name'        = $runbook.name
            'description' = $item.description
            'runbookType' = $item.type
            'uri'         = $item.fullUrl
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

foreach ($dscModule in $j.dscModules) {

    if ($dscModule.location -eq "PSGallery") { 
        $item = Get-PSGalleryItem -itemName $dscModule.name -itemType "module"
    }

    $dscModuleParams += [ordered]@{ 
        'name' = $dscModule.name
        'uri'  = $item.fullUrl
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

$j | add-member -MemberType NoteProperty -Name "automationRunbooks" -Value $runbookParams -force
$j | add-member -MemberType NoteProperty -Name "automationRunnowbooks" -Value $runnowParams -Force
$j | add-member -MemberType NoteProperty -Name "dscConfigs" -Value $dscConfigParams -Force
$j | add-member -MemberType NoteProperty -Name "dscModules" -Value $dscModuleParams -Force

$j | convertto-json -depth 32 | set-content config2.json