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

Write-Output "Starting process to enable external sharing on site $($url) to set it as $($Status)"

Connect-PnPOnline -Url $admin -AppId $appId -AppSecret $appSecret

Write-Output "Connected to the site..."

if($Status -eq "Enabled") {
    Set-PnPSite -Url $url -Sharing ExternalUserSharingOnly
    Disconnect-PnPOnline    
    .\FeatureOutput.ps1 -url $url -featureName "ExternalSharing_Status" -value "Enabled"
    Write-Output "Sharing capability was set to Enabled"
}
else { 
    Set-PnPSite -Url $url -Sharing Disabled      
    Disconnect-PnPOnline
    .\FeatureOutput.ps1 -url $url -featureName "ExternalSharing_Status" -value "Disabled"
    Write-Output "Sharing capability was set to Disabled"    
}

Write-Output "Finished"