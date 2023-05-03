#Pull from config file
Foreach ($i in $(Get-Content script.config)){
    Set-Variable -Name $i.split("=")[0] -Value $i.split("=",2)[1]
}

Install-Module -Name AzureAD
Install-Module -Name MicrosoftTeams
Install-Module -Name Microsoft.Online.SharePoint.PowerShell

$credential = Get-Credential
Connect-AzureAD -Credential $credential
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -Credential $Credential

Get-SPOTenant | Out-File -FilePath .\SPOTenant.txt
