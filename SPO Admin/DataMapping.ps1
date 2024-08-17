# Generate Logs

$scriptName = $MyInvocation.MyCommand.Name -replace '\.ps1$', ''
Start-Transcript -Path ".\logs\${scriptName}_$(Get-Date -Format dd-mm-yyyy).log" -Append

$SiteUrl = "https://contoso.sharepoint.com/sites/TheSite"
$ListName = "Documents"

$connection = Get-PnPConnection
if ($null -eq $connection) {
    Write-Host "No connection established. Connecting to $SiteUrl."
} else {
    Write-Host "Connected to SharePoint Site: $($connection.Url)"
}

<# Functions #>
# Function to convert a PSCustomObject to a hashtable
function ConvertTo-Hashtable {
    param ($Object)
    $Hashtable = @{}
    foreach ($Property in $Object.PSObject.Properties) {
        $Hashtable[$Property.Name] = $Property.Value
    }
    return $Hashtable
}

function Find-UserProfile {
    param ([string]$userName)
    try {
        Write-Host "UserID: $userName"
        $user = Get-PnPUser -Identity $userName -ErrorAction
        Write-Host "User found: Name = $($user.Title), Email = $($user.Email), LoginName = $($user.LoginName)"
        return -not [string]::IsNullOrEmpty($user.Email)
    } catch {
        Write-Host "User not found: $userName"
        return $false
    }
}

function Get-TaxonomyLabel {
    param ([Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValue]$TaxonomyValue)
    if ($null -eq $TaxonomyValue) {
        return $null
    }
    return $TaxonomyValue.Label
}
Stop-Transcript