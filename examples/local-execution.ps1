# Example interactive execution from the repository root.
$ErrorActionPreference = 'Stop'

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.SignIns

Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess' -NoWelcome

# Preview first. Remove -WhatIf only after reviewing the planned operations.
./scripts/Update-TorNamedLocations.ps1 -ConfigPath ./config/settings.json -WhatIf

# Apply:
# ./scripts/Update-TorNamedLocations.ps1 -ConfigPath ./config/settings.json

Disconnect-MgGraph
