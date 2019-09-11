param (
    [Parameter (Mandatory = $false)]
    [object] $WebHookData
)

#Get Variables
$appId = Get-AutomationVariable -Name "SPO_AppId"
$appSecret = Get-AutomationVariable -Name "SPO_AppSecret"
$bodyString = $WebHookData.RequestBody
$body = $bodyString | ConvertFrom-Json
$url = $body.SiteUrl
$admin = $body.AdminUrl
$Status = $body.Status

Write-Output "Starting process to enable script support on site $($url) to set it as $($Status)"

Connect-PnPOnline -Url $admin -AppId $appId -AppSecret $appSecret

if($Status -eq "Enabled") { 
    Set-PnPTenantSite -Url $url -NoScriptSite:$false
    Write-Output "Scripting capability was set to Enabled"
    Disconnect-PnPOnline
    .\FeatureOutput.ps1 -url $url -featureName "ScriptingCapability_Status" -value "Enabled"
}
else { 
    Set-PnPTenantSite -Url $url -NoScriptSite:$true
    Write-Output "Scripting capability was set to disabled"      
    Disconnect-PnPOnline
    .\FeatureOutput.ps1 -url $url -featureName "ScriptingCapability_Status" -value "Disabled"
} 