$ListName = "TestList"
$ColumnMappings = @{
    "Column1Unmanaged" = "Column1Managed";
    "Column2Unmanaged" = "Column2Managed";
    "Column3Unmanaged" = "Column3Managed"}

$Items = Get-PnPListItem -List $ListName

foreach ($item in $Items) {
    foreach ($column in $ColumnMappings.GetEnumerator()){
        $sourceValue = $item[$column.Key]
        Set-PnPListItem -List $ListName -Identity $item.Id -Values @{"$($column.Value)" = $sourceValue}
    }
}