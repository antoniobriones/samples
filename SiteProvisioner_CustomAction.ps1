Param
(
  [Parameter (Mandatory= $true)]
  [String] $url
)

#Get Variables
$appId = Get-AutomationVariable -Name "SPO_AppId"
$appSecret = Get-AutomationVariable -Name "SPO_AppSecret"
$listName = Get-AutomationVariable -Name "List_Name"
$uri = [System.Uri]$url
$adminURL = "https://$($uri.Host.Split(".")[0])-admin.sharepoint.com"

#Connect to Admin Center
Connect-PnPOnline -AppId $appId -AppSecret $appSecret -Url $adminURL

#Enable Scripting - We enable it here so that we can add the link to the control panel
Set-PnPTenantSite -Url $url -NoScriptSite:$false 

#Adding Link to Control Panel 
Disconnect-PnPOnline
Start-Sleep -Seconds 10
#Connect to the site
Connect-PnPOnline -AppId $appId -AppSecret $appSecret -Url $url
#Add custom action
Add-PnPCustomAction -Title "Site Owner Control Panel" -Url "~site/SitePages/Site-Owners-Control-Panel.aspx" -Name EYSiteOwnerControlPanel -Description "Opens EY Site Owner Control Panel" -Group "SiteActions" -Location "Microsoft.SharePoint.StandardMenu" -Rights "FullMask"
Disconnect-PnPOnline

Connect-PnPOnline -AppId $appId -AppSecret $appSecret -Url $adminURL
#Disabling Scripting - We disable it because the panel will show that it's disabled by default - It's user who needs to enable it
Set-PnPTenantSite -Url $url -NoScriptSite:$true
Disconnect-PnPOnline