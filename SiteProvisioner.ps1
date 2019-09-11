Param
(
  [Parameter (Mandatory= $true)]
  [String] $url
)

#Get Variables
$appId = Get-AutomationVariable -Name "SPO_AppId"
$appSecret = Get-AutomationVariable -Name "SPO_AppSecret"
$adminURL = Get-AutomationVariable -Name 'SPO_AdminUrl'
$storageConnectionString = Get-AutomationVariable -Name "StorageAccount_ConnectionString"
$fileShareName = Get-AutomationVariable -Name "StorageAccount_name"
$provisioningTemplateFileName = Get-AutomationVariable -Name "StorageAccount_filename"
$listName = Get-AutomationVariable -Name "List_Name"
$contentTypeName= 'SiteProvisionContentType' 
$siteOwnersControlPanelPageId = 0

Write-Output "Starting Site Provisioner for $($url)"

Connect-PnPOnline -AppId $appId -AppSecret $appSecret -Url $url
$web = Get-PnPWeb

try {
    #Get PnP template from Storage Account
    $tempFile = New-TemporaryFile
    $storageContext = New-AzureStorageContext -ConnectionString $storageConnectionString
    Get-AzureStorageFileContent -Context $storageContext -ShareName $fileShareName -Path "/$provisioningTemplateFileName" -Destination $tempFile -Force
    $tempFileContents = Get-Content $tempFile -Raw -ErrorAction:SilentlyContinue
    $inMemoryProvisioningTemplatePath = $tempFile.FullName

    #Apply PnP Template
    Apply-PnPProvisioningTemplate -Path $inMemoryProvisioningTemplatePath

    #Break role inheritance in site owners control panel
    $list = $web.Lists.GetByTitle($listName)
    $pages = $web.Lists.GetByTitle("Site Pages")
    $query = New-Object Microsoft.SharePoint.Client.CamlQuery
    $query.ViewXml = "<View><Query><Where><Eq><FieldRef Name='Title' /><Value Type='Text'>Site Owners Control Panel</Value></Eq></Where></Query></View>"
    $items = $pages.GetItems($query)

    $web.Context.load($items)
    $web.Context.Load($list)
    $web.Context.Load($web.AssociatedOwnerGroup)
    $web.Context.ExecuteQuery()

    if ($items.Count -gt 0) {
        $listItem = $items[0]
        $listItem.BreakRoleInheritance($false, $true)
        $siteOwnersControlPanelPageId = $items[0].Id
    }

    #Get Site Owners Group Id
    $siteOwnersGroupId = $web.AssociatedOwnerGroup.Id

    #Hide Config list
    $list.Hidden = $true
    $list.Update()
    $web.Context.ExecuteQuery()

    #Set permissions in site owners control panel page to owners
    if ($siteOwnersControlPanelPageId -ne 0) {
        Set-PnPListItemPermission -List "Site Pages" -Identity $siteOwnersControlPanelPageId -AddRole "Full Control" -Group $siteOwnersGroupId -ClearExisting
    }

    Disconnect-PnPOnline
    .\FeatureOutput.ps1 -url $url -featureName "ExternalSharing_Status" -value "Disabled"
    .\SiteProvisioner_CustomAction.ps1 -url $url
}
catch {
    $PSItem.InvocationInfo | Format-List *
    $PSItem.ScriptStackTrace    
    $PSItem.Exception | Format-List *
}
