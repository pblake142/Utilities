Install-Module -Name AzureAD
Install-Module -Name MicrosoftTeams
Install-Module -Name Microsoft.Online.SharePoint.PowerShell

$credential = Get-Credential
Connect-AzureAD -Credential $credential

$orgName="0GN0W"

Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -Credential $Credential

Get-SPOTenant | Out-File -FilePath .\SPOTenant.txt
