[CmdletBinding()]
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

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$response = Invoke-WebRequest -Uri $config.FeedUrl -TimeoutSec ([int]$config.RequestTimeoutSeconds)
if ($response.StatusCode -ne 200) {
    throw "Feed returned HTTP status $($response.StatusCode)."
}

$rows = @($response.Content | ConvertFrom-Csv)
if ($rows.Count -eq 0) { throw 'Feed contains no CSV rows.' }

$properties = @($rows[0].PSObject.Properties.Name)
foreach ($required in @('ipaddr')) {
    if ($required -notin $properties) {
        throw "Feed is missing required column '$required'. Found: $($properties -join ', ')"
    }
}

$valid = @(
    foreach ($row in $rows) {
        if ($row.ipaddr) {
            ConvertTo-NormalizedIpCidr -AddressText ([string]$row.ipaddr)
        }
    }
) | Where-Object { $_ } | Sort-Object -Unique

[pscustomobject]@{
    FeedUrl          = $config.FeedUrl
    HttpStatus       = $response.StatusCode
    CsvRows          = $rows.Count
    UniqueValidIps   = $valid.Count
    InvalidOrBlank   = $rows.Count - $valid.Count
    IPv4             = @($valid | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}/32$' }).Count
    IPv6             = @($valid | Where-Object { $_ -match ':' }).Count
    MinimumThreshold = $config.MinimumExpectedIpCount
    ThresholdPassed  = ($valid.Count -ge [int]$config.MinimumExpectedIpCount)
}

if ($valid.Count -lt [int]$config.MinimumExpectedIpCount) {
    throw "Feed validation failed: $($valid.Count) unique valid IPs is below configured minimum $($config.MinimumExpectedIpCount)."
}
