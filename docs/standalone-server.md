# Standalone server execution

The script can run from a Windows or Linux host with PowerShell 7.2+ and network access to the CSV feed and Microsoft Graph.

## Requirements

```powershell
./scripts/Install-Requirements.ps1 -CurrentUser
```

## Authentication options

For an interactive administrative test:

```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"
```

For unattended execution, prefer a managed identity on an Azure-hosted VM or another supported workload identity. A certificate-based app registration is another option where managed identity is unavailable. Follow your organization's secret and certificate lifecycle requirements.

Do not use username/password authentication or store client secrets in source control.

## Run

```powershell
./scripts/Update-TorNamedLocations.ps1 -ConfigPath ./config/settings.json -WhatIf
./scripts/Update-TorNamedLocations.ps1 -ConfigPath ./config/settings.json
```

Schedule the script using your organization's approved scheduler. Ensure logs are retained and failures generate alerts.
