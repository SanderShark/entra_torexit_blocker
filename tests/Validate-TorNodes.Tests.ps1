# Pester 5 tests for basic IP normalization behavior.
# Run with: Invoke-Pester ./tests/Validate-TorNodes.Tests.ps1

BeforeAll {
    function ConvertTo-NormalizedIpCidr {
        param([Parameter(Mandatory)][string]$AddressText)

        $parsed = $null
        if (-not [System.Net.IPAddress]::TryParse($AddressText.Trim(), [ref]$parsed)) {
            return $null
        }

        $prefix = if ($parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) { 32 } else { 128 }
        return "$($parsed.IPAddressToString)/$prefix"
    }
}

Describe 'ConvertTo-NormalizedIpCidr' {
    It 'normalizes IPv4 addresses to /32' {
        ConvertTo-NormalizedIpCidr '192.0.2.10' | Should -Be '192.0.2.10/32'
    }

    It 'normalizes IPv6 addresses to /128' {
        ConvertTo-NormalizedIpCidr '2001:db8::1' | Should -Be '2001:db8::1/128'
    }

    It 'returns null for invalid addresses' {
        ConvertTo-NormalizedIpCidr 'not-an-ip' | Should -BeNullOrEmpty
    }

    It 'trims whitespace' {
        ConvertTo-NormalizedIpCidr ' 198.51.100.5 ' | Should -Be '198.51.100.5/32'
    }
}
