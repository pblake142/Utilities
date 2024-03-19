$Site = "SiteName"
$List = "ListName"
$Url = "https://contoso.sharepoint.com/sites/$Site"
$OutputPath = "VersionHistory.csv"

Connect-PnPOnline -Url $Url -Interactive

# Get the items from the list
$Items = Get-PnPListItem -List $List

# Initialize array to hold objects
$OutputObjects = @()

foreach ($item in $Items) {
    $id = $item.Id

    # Retrieve version history
    $versions = Get-PnPListItemVersion -List $List -Identity $id

    # Sort the versions by version number in descending order and select the four most recent
    $recentVersions = $versions | Sort-Object -Property Version -Descending | Select-Object -First 4

    # Prepare a hashtable to hold the values for CSV output
    $csvObject = @{
        ID = $id
        N = $null
        'N-1' = $null
        'N-2' = $null
        'N-3' = $null
    }

    # Iterate through the versions and assign the target value to the respective column
    for ($i = 0; $i -lt $recentVersions.Count; $i++) {
        $title = $recentVersions[$i].Values["Title"]
        switch ($i) {
            0 { $csvObject.N = $title }
            1 { $csvObject.'N-1' = $title }
            2 { $csvObject.'N-2' = $title }
            3 { $csvObject.'N-3' = $title }
        }
    }

    # Add the hashtable to the array
    $OutputObjects += New-Object PSObject -Property $csvObject
}

# Export the array to a CSV file
$OutputObjects | Select-Object ID, N, 'N-1', 'N-2', 'N-3' | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Output "Version history exported to $OutputPath"