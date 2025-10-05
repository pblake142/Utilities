function Get-DefaultFieldBlacklist {
  @(
    # identity / routing
    'ID','GUID','UniqueId','ParentUniqueId','ScopeId','ContentVersion',
    'ContentTypeId','FileRef','FileDirRef','FileLeafRef','File_x0020_Type','FSObjType','ProgId','SyncClientId',
    'OriginatorId','InstanceID',
    # authorship / timestamps
    'Author','Editor','Created','Modified','Created_x0020_Date','Last_x0020_Modified',
    # versioning / moderation / workflow
    'owshiddenversion','WorkflowVersion','WorkflowInstanceID',
    '_UIVersion','_UIVersionString','_ModerationStatus','_ModerationComments',
    # attachments / counts
    'Attachments','ItemChildCount','FolderChildCount',
    # compliance / security / malware
    'ComplianceAssetId','_ComplianceFlags','_ComplianceTag','_ComplianceTagWrittenTime','_ComplianceTagUserId',
    'AccessPolicy','_VirusStatus','_VirusVendorID','_VirusInfo','_RansomwareAnomalyMetaInfo',
    # copy tracking
    '_HasCopyDestinations','_CopySource',
    # formatting helpers
    '_ColorHex','_ColorTag','_Emoji',
    # telemetry / storage metrics
    'SMTotalSize','SMTotalFileStreamSize','SMTotalFileCount','SMLastModifiedDate',
    # app model
    'AppAuthor','AppEditor',
    # comments
    '_CommentFlags','_CommentCount',
    # misc internal/meta
    'MetaInfo','SortBehavior','Order','Restricted','NoExecute','_Level','_IsCurrentVersion'
  )
}

function Test-CommandExists {
  param([Parameter(Mandatory)][string]$Name)
  $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Convert-UserValueToEmails {
  <#
    Input: FieldUserValue | FieldUserValue[] | string | string[]
    Output: string (email) or string[] (emails)
    Strategy:
      - If the object exposes .Email, use it.
      - Else try Get-PnPUser -Identity LookupId (or LookupValue) to resolve Email.
      - Else, if the string already contains "@", treat as email.
  #>
  param([Parameter(Mandatory)]$Value)

  function _one($v) {
    if ($null -eq $v) { return $null }

    # FieldUserValue (common path)
    if ($v -is [Microsoft.SharePoint.Client.FieldUserValue]) {
      $emailProp = $v.PSObject.Properties['Email']
      if ($emailProp -and $emailProp.Value) { return $emailProp.Value }

      # Try resolve via Id first
      $u = $null
      if ($v.LookupId) {
        $u = Get-PnPUser -Identity $v.LookupId -ErrorAction SilentlyContinue
      }
      if (-not $u -and $v.LookupValue) {
        $u = Get-PnPUser -Identity $v.LookupValue -ErrorAction SilentlyContinue
      }
      if ($u -and $u.Email) { return $u.Email }

      # Last resort: if LookupValue smells like an email, pass it on
      if ($v.LookupValue -and ($v.LookupValue -match '@')) { return $v.LookupValue }
      return $null
    }

    # Raw string (sometimes SharePoint returns claims or email)
    if ($v -is [string]) {
      if ($v -match '@') { return $v }  # assume email
      # Could be a claims login; attempt a resolve
      $u = Get-PnPUser -Identity $v -ErrorAction SilentlyContinue
      if ($u -and $u.Email) { return $u.Email }
      return $null
    }

    return $null
  }

  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $out = @()
    foreach ($x in $Value) {
      $e = _one $x
      if ($e) { $out += $e }
    }
    return $out | Select-Object -Unique
  } else {
    return _one $Value
  }
}

function Resolve-LookupValue {
  param([Parameter(Mandatory)] $Value)
  if ($null -eq $Value) { return $null }

  if ($Value -is [Microsoft.SharePoint.Client.FieldLookupValue]) { return $Value }
  if ($Value -is [int]) { 
    return (New-Object Microsoft.SharePoint.Client.FieldLookupValue -Property @{ LookupId = $Value }) 
  }
  if ($Value -is [string] -and ($Value -as [int])) {
    return (New-Object Microsoft.SharePoint.Client.FieldLookupValue -Property @{ LookupId = [int]$Value })
  }
  if ($Value -is [System.Collections.IEnumerable]) {
    $out = @()
    foreach ($v in $Value) {
      if ($v -is [Microsoft.SharePoint.Client.FieldLookupValue]) { $out += $v; continue }
      if ($v -is [int]) { 
        $out += New-Object Microsoft.SharePoint.Client.FieldLookupValue -Property @{ LookupId = $v }
        continue
      }
      if ($v -is [string] -and ($v -as [int])) {
        $out += New-Object Microsoft.SharePoint.Client.FieldLookupValue -Property @{ LookupId = [int]$v }
      }
    }
    return ,$out
  }
  return $null
}

function Convert-TaxonomyValueToGuids {
  <#
    Input: TaxonomyFieldValue | TaxonomyFieldValueCollection | string ("Label|Guid" or just Guid)
    Output: string (single GUID) or string[] (multi GUIDs)
  #>
  param([Parameter(Mandatory)] $Value)

  # Single
  if ($Value -is [Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValue]) {
    return $Value.TermGuid
  }

  # Multi
  if ($Value -is [Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection] `
      -or $Value -is [System.Collections.IEnumerable]) {
    $guids = @()
    foreach ($t in $Value) {
      if ($t -is [Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValue]) {
        $guids += $t.TermGuid
      } elseif ($t -is [string]) {
        if ($t -match '\|([0-9a-fA-F-]{36})$') { $guids += $Matches[1] }
        elseif ($t -match '^[0-9a-fA-F-]{36}$') { $guids += $t }
      }
    }
    return $guids | Select-Object -Unique
  }

  # Text formats
  if ($Value -is [string]) {
    if ($Value -match '^[0-9a-fA-F-]{36}$') { return $Value }
    if ($Value -match '\|([0-9a-fA-F-]{36})$') { return $Matches[1] }
    if ($Value -match ';#') {
      $parts = $Value -split ';#' | ForEach-Object {
        if ($_ -match '\|([0-9a-fA-F-]{36})$') { $Matches[1] }
        elseif ($_ -match '^[0-9a-fA-F-]{36}$') { $_ }
      }
      return $parts | Where-Object { $_ } | Select-Object -Unique
    }
  }

  return $null
}

function Get-BusinessFieldValues {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $List,            # destination list for schema
    [Parameter(Mandatory)] $SourceItem,               # item from Get-PnPListItem
    [string[]] $ExtraBlacklist = @(),
    [string[]] $Allowlist = @()
  )

  # Destination schema
  $fields = Get-PnPField -List $List -Includes InternalName,Hidden,ReadOnlyField,Sealed,TypeAsString,Title,SchemaXml,Id
  $byName = @{}
  foreach ($f in $fields) { $byName[$f.InternalName] = $f }

  # Blacklist set
  $blackset = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  (Get-DefaultFieldBlacklist + $ExtraBlacklist) | ForEach-Object { $null = $blackset.Add($_) }

  $values = @{}
  foreach ($kv in $SourceItem.FieldValues.GetEnumerator()) {
    $name  = [string]$kv.Key
    $value = $kv.Value

    if ($Allowlist.Count -gt 0 -and ($Allowlist -notcontains $name)) { continue }
    if ($blackset.Contains($name)) { continue }
    if ($name.StartsWith('_')) { continue }                 # systemish
    if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) { continue }

    $f = $byName[$name]; if ($null -eq $f) { continue }     # not on destination
    if ($f.Hidden -or $f.ReadOnlyField -or $f.Sealed) { continue }

    # Skip typical taxonomy/people backing note fields (usually Hidden anyway)
    if ($f.TypeAsString -eq 'Note' -and $f.Hidden) { continue }

    switch -Regex ($f.TypeAsString) {
      '^User(Multi)?$' {
        $emails = Convert-UserValueToEmails -Value $value
        if ($emails) { $values[$name] = $emails }
        continue
      }
      '^Lookup(Multi)?$' {
        $norm = Resolve-LookupValue -Value $value
        if ($norm) { $values[$name] = $norm }
        continue
      }
      '^TaxonomyFieldType(Multi)?$' {
        $guids = Convert-TaxonomyValueToGuids -Value $value
        if ($guids) { $values[$name] = $guids }
        continue
      }
      default {
        $values[$name] = $value
      }
    }
  }

  return $values
}

$src   = Get-PnPListItem -List 'Source'
# $vals  = Get-BusinessFieldValues -List 'Destination' -SourceItem $src
# Add-PnPListItem -List 'Destination' -Values $vals

foreach ($item in $src) {
  $vals = Get-BusinessFieldValues -List 'Destination' -SourceItem $item
  Add-PnPListItem -List 'Destination' -Values $vals
}
