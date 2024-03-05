param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("ARE", "BRA", "KOR", "IND", "AUS", "EUR", "APC", "CHE", "GBR", "NAM", "DEU")]
    [string]$SourceGeo = "NAM",

    [Parameter(Mandatory=$false)]
    [ValidateSet("ARE", "BRA", "KOR", "IND", "AUS", "EUR", "APC", "CHE", "GBR", "NAM", "DEU")]
    [string]$DestinationGeo = "BRA",

    [Parameter(Mandatory=$false)]
    [string]$SiteGroupName
)

# Set URL for Connect-SPOService to use within the script
if ($SourceGeo -eq "NAM") {
    $ServiceUrl = "https://contoso-admin.sharepoint.com"
    $SiteUrl = "https://contoso.sharepoint.com/sites/$SiteGroupName"
} else {
    $ServiceUrl = "https://contoso$SourceGeo-admin.sharepoint.com"
    $SiteUrl = "https://contoso$SourceGeo.sharepoint.com/sites/$SiteGroupName"
}

Write-Host "Service URL: $ServiceUrl"
Write-Host "Site URL: $SiteUrl"

# Authenticate with browser to satisfy 2fa
try {
    Connect-SPOService -Url $ServiceUrl
    Write-Host "Successfully authenticated to $ServiceUrl"
}
catch {
    Write-Host "Failed to authenticate to $ServiceUrl"
    return
}

# Return CompatibilityStatus
$CompatibilityStatus = Get-SPOGeoMoveCrossCompatibilityStatus | Where-Object {
    $_.SourceDataLocation -eq $SourceGeo -and $_.DestinationDataLocation -eq $DestinationGeo
}

if ($CompatibilityStatus.CompatibilityStatus -eq "Compatible") {
    Write-Host "Migration is compatible from $SourceGeo to $DestinationGeo"
} else {
    Write-Host "WARNING: CompatibilityStatus between $SourceGeo and $DestinationGeo is: $($CompatibilityStatus.CompatibilityStatus)"
    Write-Host "Type 'y' to proceed. Any other key will terminate script:"
    $userInput = Read-Host
    if ($userInput -match '^y$') {
        Write-Host "Proceeding with migration from $SourceGeo to $DestinationGeo"
    } else {
        Write-Host "Terminating script"
        return
    }
}

# Pull site details to identify if it is group enabled
$site = Get-SPOSite -Identity $SiteUrl -Detailed
$SiteTemplate = $site.Template
Write-Host "Site Template: $SiteTemplate"

# Initiate the move appropriately based on template
if ($SiteTemplate -like "GROUP"){
    Set-SPOUnifiedGroup -PreferredDataLocation $DestinationGeo -GroupAlias $SiteGroupName
    Get-SPounifiedGroup -GroupAlias $SiteGroupName

    Start-SPOUnifiedGroupMove -GroupAlias $SiteGroupName -DestinationDataLocation $DestinationGeo
} else {
    Start-SPOSiteContentMove -SourceSiteUrl $SiteUrl
}

# Check the move status based on template
# Not satisfied with the return, but it is a start

do{
    if($SiteTemplate -like "GROUP"){
        $activeMove = Get-SPOUnifiedGroupMoveStatus
        $MoveStatus = $activeMove.MoveState
    } else {
        $activeMove = Get-SPOUSiteContentMoveState
        $MoveStatus = $activeMove.MoveState
    }

    Write-Host $MoveStatus
    $userChoice = Read-Host "Press 'y' to check again. Pressing any other key will terminate the script"
} while ($userChoice -match '^y$')