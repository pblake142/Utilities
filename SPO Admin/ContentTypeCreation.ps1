<# 
Script to create content types within the Content Type Hub
based on an XML defintion. This script presumes you have
already created all the columns you will be adding.
#>

# Logs
$scriptName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
Start-Transcript -Path ".\logs\${scriptName}_$(Get-Date -Format dd-mm-yyyy).log" -Append

$Url = "https://contoso.sharepoint.com/sites/ContentTypeHub"
$xmlPath = ".\ContentTypeDefinitions.xml"

# Establish Connection
Write-Output "Connecting to $Url"
Connect-PnPOnline -Url $Url -Interactive

# Load XML
Write-Output "Loading XML from $xmlPath"
[xml]$xmlContent = Get-Content -Path $xmlPath

<# Example XML:

<ContentTypes>
    <ContentType 
        <Name>TestListContentType</Name>
        <Group>TestGroup</Group>
        <Description>TestDescription</Description>
        <ParentCategory>"List Item Content Types"</ParentCategory>
        <Parent>0x01</Parent>
        <Fields>
            <FieldRef Name=TestChoiceColumn />
            <FieldRef Name=TestTextColumn />
        </Fields>
    </ContentType>
    <ContentType 
        <Name>TestDocumentContentType</Name>
        <Group>TestGroup</Group>
        <Description>TestDescription</Description>
        <ParentCategory>"Document Content Types"</ParentCategory>
        <Parent>0x0101</Parent>
        <Fields>
            <FieldRef Name=TestChoiceColumn />
            <FieldRef Name=TestTextColumn />
        </Fields>
    </ContentType>
</ContentTypes>
#>

Write-Output "Starting on Content Types"
foreach($ct in $xmlContent.ContentTypes.ContentType) {
    $ctname = $ct.Name
    $ctParent = Get-PnPContentType -Identity $ct.Parent
    $createdCt = Add-PnPContentType -Name $ctName -Description $ct.Description -Group $ct.Group -ParentContentType $ctParent
    Write-Output "Content Type $ctName created"

    # Add Fields
    $ctFields = $ct.Fields.Field | ForEach-Object { $_ }
    foreach($field in $ctFields) {
        Add-PnPFieldToContentType -ContentType $ctName -Field $field.Name
    }

    try {
        Publish-PnPContentType -ContentType $createdCt
        Write-Output "Content Type $ctName published"
    } catch {
        Write-Output "Oops: $_"
    }
}

Stop-Transcript