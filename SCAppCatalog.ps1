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

Write-Output "Starting process to app catalog on site $($url) to set it as $($Status)"

Connect-PnPOnline -Url $admin -AppId $appId -AppSecret $appSecret 

if($Status -eq "Enabled") {    
    Add-PnPSiteCollectionAppCatalog -Site $url 
    Disconnect-PnPOnline
    Write-Output "App catalog set to enabled" 
    .\FeatureOutput.ps1 -url $url -featureName "SCAppCatalog_Status" -value "Enabled"   
}
else {     
    Remove-PnPSiteCollectionAppCatalog -Site $url

    Connect-PnPOnline -Url $url -AppId $appId -AppSecret $appSecret
    $list = Get-PnPList -Identity AppCatalog
    $list.AllowDeletion = $true
    $list.Update()
    $list.Context.ExecuteQuery()    
    Remove-PnPList -Identity AppCatalog -Force
    Disconnect-PnPOnline
    Write-Output "App catalog set to disabled" 
    .\FeatureOutput.ps1 -url $url -featureName "SCAppCatalog_Status" -value "Disabled"
}