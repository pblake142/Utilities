<#

Script to create columns on the ContentTypeHub (for ingestion into a global content type)
based on an xml definition. I've included a sample xml definition in another comment
below. 

#>

# Logs
$scriptName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
Start-Transcript -Path ".\logs\${scriptName}_$(Get-Date -Format dd-mm-yyyy).log" -Append

$Url = "https://contoso.sharepoint.com/sites/ContentTypeHub"
$xmlPath = ".\ColumnDefinitions.xml"

# Establish Connection
Write-Output "Connecting to $Url"
Connect-PnPOnline -Url $Url -Interactive

# Load XML
Write-Output "Loading XML from $xmlPath"
[xml]$xmlContent = Get-Content -Path $xmlPath

<# Example XML:

<Columns>
    <Column>
        <Field Type=Choice Name=TestChoiceColumn DisplayName=TestChoiceColumn Group=TestGroup>
            <CHOICES>
                <CHOICE>Choice1</CHOICE>
                <CHOICE>Choice2</CHOICE>
                <CHOICE>Choice3</CHOICE>
            </CHOICES>
    </Column>
    <Column>
        <Field Type=Text Name=TestTextColumn DisplayName=TestTextColumn Group=TestGroup>
    </Column>
</Columns>

For detailed columns types, see:
https://learn.microsoft.com/en-us/dotnet/api/microsoft.sharepoint.client.fieldtype?view=sharepoint-csom
#>

# Get Columns (this was originally written as part of a single script)
$columns = $xmlContent.Columns.Column

Write-Output "Creating Columns"
foreach ($column in $columns) {
    $name = $column.Field.Name
    $type = $column.Field.Type
    $internalName = $column.Field.Name
    $group = $column.Field.Group
    $creationTime = Get-Date

    if ($null -eq $name) {
        Write-Output "Nothing was loaded"
    } elseif ($type -eq "Choice") {
        $choices = $column.Field.CHOICES.CHOICE | ForEach-Object { $_ }
        Add-PnPField -DisplayName $name -InternalName $internalName -Type $type -Group $group -Choices $choices
    } else {
        Add-PnPField -DisplayName $name -InternalName $internalName -Type $type -Group $group
    }

    $columnId = (Get-PnPField -Identity $name).Id
    Write-Output "Column '$name' of '$type' with internal name of '$internalName' created at $creationTime with ID $columnId in group '$group'"
    if($choices) {
        Write-Output "Choices for '$name': $choices"
    }
}

Stop-Transcript
