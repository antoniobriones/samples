Param
(
  [Parameter (Mandatory= $true)]
  [String] $url,
  [Parameter (Mandatory= $true)]
  [String] $featureName,
  [Parameter (Mandatory= $true)]
  [String] $value
)

$appId = Get-AutomationVariable -Name "SPO_AppId"
$appSecret = Get-AutomationVariable -Name "SPO_AppSecret"
$listName= Get-AutomationVariable -Name 'List_Name'

Connect-PnPOnline -AppId $appId -AppSecret $appSecret -Url $url

$ctx = Get-PnPContext

$list = $ctx.Web.Lists.GetByTitle($listName);

$query = New-Object Microsoft.SharePoint.Client.CamlQuery
$query.ViewXml = "<View><Query><Where><And><Eq><FieldRef Name='Title' /><Value Type='Text'>$featureName</Value></Eq><Eq><FieldRef Name='configValue' /><Value Type='Text'>Pending</Value></Eq></And></Where></Query></View>"
$items = $list.GetItems($query)
$ctx.load($items)

$ctx.ExecuteQuery()

if ($items.Count -gt 0) {
    $listItem = $items[0]
    if( $listItem["configValue"] -eq 'Pending') { 

        if($value -eq "Enabled") {               
            $listItem["configValue"] = "Yes"  
        }
        else { 
            $listItem["configValue"] = "No"  
        } 

        $listItem.Update()        
        $ctx.ExecuteQuery()   
    }
}