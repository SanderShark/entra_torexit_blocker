[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/settings.json')
)

$ErrorActionPreference = 'Stop'

function ConvertTo-NormalizedIpCidr {
    param([Parameter(Mandatory)][string]$AddressText)

    $parsed = $null
    if (-not [System.Net.IPAddress]::TryParse($AddressText.Trim(), [ref]$parsed)) {
        return $null
    }

    $prefix = if ($parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) { 32 } else { 128 }
    return "$($parsed.IPAddressToString)/$prefix"
}

function ConvertTo-GraphIpRange {
    param([Parameter(Mandatory)][string]$Cidr)

    $addressText = $Cidr.Split('/')[0]
    $address = [System.Net.IPAddress]::Parse($addressText)
    $odataType = if ($address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
        '#microsoft.graph.iPv4CidrRange'
    }
    else {
        '#microsoft.graph.iPv6CidrRange'
    }

    return @{
        '@odata.type' = $odataType
        CidrAddress   = $Cidr
    }
}

function Get-RangeSignature {
    param([object[]]$Ranges)

    return (@(
        $Ranges | ForEach-Object { [string]$_.CidrAddress } | Sort-Object -Unique
    ) -join "`n")
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

if ([int]$config.ChunkSize -lt 1 -or [int]$config.ChunkSize -gt 2000) {
    throw 'ChunkSize must be between 1 and 2000.'
}
if ([string]::IsNullOrWhiteSpace([string]$config.DisplayNamePrefix)) {
    throw 'DisplayNamePrefix cannot be empty.'
}

Write-Output "Downloading Tor-node feed: $($config.FeedUrl)"
$response = Invoke-WebRequest -Uri $config.FeedUrl -TimeoutSec ([int]$config.RequestTimeoutSeconds)
if ($response.StatusCode -ne 200) {
    throw "Feed returned HTTP status $($response.StatusCode). No Graph changes were made."
}

$rows = @($response.Content | ConvertFrom-Csv)
if ($rows.Count -eq 0) {
    throw 'Feed contains no CSV rows. No Graph changes were made.'
}

$columns = @($rows[0].PSObject.Properties.Name)
if ('ipaddr' -notin $columns) {
    throw "Feed is missing required 'ipaddr' column. Found: $($columns -join ', '). No Graph changes were made."
}

$invalidCount = 0
$normalized = @(
    foreach ($row in $rows) {
        if ([string]::IsNullOrWhiteSpace([string]$row.ipaddr)) {
            $invalidCount++
            continue
        }

        $cidr = ConvertTo-NormalizedIpCidr -AddressText ([string]$row.ipaddr)
        if ($null -eq $cidr) {
            $invalidCount++
            continue
        }

        $cidr
    }
) | Sort-Object -Unique

if ($normalized.Count -lt [int]$config.MinimumExpectedIpCount) {
    throw "Feed safety check failed: $($normalized.Count) unique valid IPs is below minimum $($config.MinimumExpectedIpCount). No Graph changes were made."
}

# Retrieve existing managed locations before evaluating the change threshold.
$allLocations = @(Get-MgIdentityConditionalAccessNamedLocation -All)
$managedLocations = @(
    $allLocations | Where-Object {
        $_.DisplayName -like "$($config.DisplayNamePrefix)*"
    }
)

$existingRanges = @(
    foreach ($location in $managedLocations) {
        foreach ($range in $location.IpRanges) {
            [string]$range.CidrAddress
        }
    }
) | Sort-Object -Unique

if ([int]$config.MaximumAllowedChangePercent -gt 0 -and $existingRanges.Count -gt 0) {
    $oldSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$existingRanges)
    $newSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$normalized)
    $union = [System.Collections.Generic.HashSet[string]]::new($oldSet)
    foreach ($item in $newSet) { [void]$union.Add($item) }

    $changed = 0
    foreach ($item in $oldSet) { if (-not $newSet.Contains($item)) { $changed++ } }
    foreach ($item in $newSet) { if (-not $oldSet.Contains($item)) { $changed++ } }

    $changePercent = if ($union.Count -eq 0) { 0 } else { [math]::Round(($changed / $union.Count) * 100, 2) }
    Write-Output "Feed change compared with existing managed ranges: $changePercent%"

    if ($changePercent -gt [double]$config.MaximumAllowedChangePercent) {
        throw "Feed change $changePercent% exceeds configured maximum $($config.MaximumAllowedChangePercent)%. No Graph changes were made."
    }
}

$chunks = [System.Collections.Generic.List[object]]::new()
for ($offset = 0; $offset -lt $normalized.Count; $offset += [int]$config.ChunkSize) {
    $last = [math]::Min($offset + [int]$config.ChunkSize - 1, $normalized.Count - 1)
    $chunks.Add(@($normalized[$offset..$last]))
}

Write-Output "Feed rows: $($rows.Count); unique valid IPs: $($normalized.Count); invalid/blank rows: $invalidCount; locations required: $($chunks.Count)."

$created = 0
$updated = 0
$unchanged = 0

for ($index = 0; $index -lt $chunks.Count; $index++) {
    $part = $index + 1
    $name = '{0} - Part {1:D2}' -f $config.DisplayNamePrefix, $part
    $desiredCidrs = @($chunks[$index])
    $desiredRanges = @($desiredCidrs | ForEach-Object { ConvertTo-GraphIpRange -Cidr $_ })

    $existing = @($managedLocations | Where-Object DisplayName -eq $name) | Select-Object -First 1
    $desiredSignature = Get-RangeSignature -Ranges $desiredRanges

    if ($null -ne $existing) {
        $currentSignature = Get-RangeSignature -Ranges @($existing.IpRanges)

        if ($currentSignature -eq $desiredSignature -and [bool]$existing.IsTrusted -eq [bool]$config.Trusted) {
            Write-Output "Unchanged: $name ($($desiredCidrs.Count) ranges)"
            $unchanged++
            continue
        }

        $body = @{
            '@odata.type' = '#microsoft.graph.ipNamedLocation'
            DisplayName   = $name
            IsTrusted     = [bool]$config.Trusted
            IpRanges      = $desiredRanges
        }

        if ($PSCmdlet.ShouldProcess($name, "Update named location with $($desiredRanges.Count) IP ranges")) {
            Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $existing.Id -BodyParameter $body
            Write-Output "Updated: $name"
            $updated++
        }
    }
    else {
        $body = @{
            '@odata.type' = '#microsoft.graph.ipNamedLocation'
            DisplayName   = $name
            IsTrusted     = [bool]$config.Trusted
            IpRanges      = $desiredRanges
        }

        if ($PSCmdlet.ShouldProcess($name, "Create named location with $($desiredRanges.Count) IP ranges")) {
            New-MgIdentityConditionalAccessNamedLocation -BodyParameter $body
            Write-Output "Created: $name"
            $created++
        }
    }
}

$stale = @(
    $managedLocations | Where-Object {
        $_.DisplayName -match ' - Part \d+$' -and
        [int]($_.DisplayName -replace '^.* - Part ', '') -gt $chunks.Count
    }
)

if ($stale.Count -gt 0) {
    Write-Warning "Found $($stale.Count) stale managed location(s): $($stale.DisplayName -join ', '). They were NOT deleted. Review Conditional Access policy references and remove them manually if appropriate."
}

# Verify the desired partitions after writes. In WhatIf mode, report that verification was skipped.
if (-not $WhatIfPreference) {
    $verifiedLocations = @(Get-MgIdentityConditionalAccessNamedLocation -All)
    for ($index = 0; $index -lt $chunks.Count; $index++) {
        $name = '{0} - Part {1:D2}' -f $config.DisplayNamePrefix, ($index + 1)
        $verified = @($verifiedLocations | Where-Object DisplayName -eq $name) | Select-Object -First 1
        if ($null -eq $verified) {
            throw "Verification failed: named location '$name' was not found."
        }

        $expected = Get-RangeSignature -Ranges @($chunks[$index] | ForEach-Object { [pscustomobject]@{ CidrAddress = $_ } })
        $actual = Get-RangeSignature -Ranges @($verified.IpRanges)
        if ($expected -ne $actual) {
            throw "Verification failed: IP ranges in '$name' do not match the desired feed partition."
        }
    }
    Write-Output 'Verification passed for all desired named locations.'
}
else {
    Write-Output 'WhatIf enabled: Graph writes and post-write verification were skipped.'
}

[pscustomobject]@{
    FeedRows       = $rows.Count
    UniqueIpRanges = $normalized.Count
    InvalidRows    = $invalidCount
    Locations      = $chunks.Count
    Created        = $created
    Updated        = $updated
    Unchanged      = $unchanged
    StaleLocations = $stale.Count
    WhatIf         = [bool]$WhatIfPreference
}
