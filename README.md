# Entra ID Dynamic Tor Exit Node Named Locations

<<<<<<< HEAD
Automatically maintain Microsoft Entra ID Conditional Access Named Locations using publicly available Tor exit node data.

## Overview

Microsoft Entra ID Conditional Access supports named locations based on public IP addresses and CIDR ranges. However, maintaining lists of potentially malicious or unwanted IP addresses manually can become tedious and difficult to scale.

This project automates that process by retrieving an updated list of Tor exit nodes from [alireza-rezaee/tor-nodes](https://github.com/alireza-rezaee/tor-nodes), validating the addresses, and synchronizing them with Microsoft Entra ID using Microsoft Graph PowerShell.

## Features

- Automatically retrieve Tor exit node IP addresses.
- Validate and normalize IP addresses.
- Create and update Conditional Access Named Locations.
- Automatically divide IP addresses into groups of 2,000.
- Authenticate using Azure Automation Managed Identity.
- Support scheduled daily execution.
- Maintain execution logs and update statistics.
- Support standalone PowerShell execution.

## Requirements

- Microsoft Entra ID with Conditional Access licensing.
- Azure Automation Account (recommended).
- PowerShell 7.2 or later.
- Microsoft.Graph.Identity.SignIns module.
- Managed Identity with Microsoft Graph `Policy.ReadWrite.ConditionalAccess` application permission.

## How It Works

1. Retrieve the latest Tor exit node CSV.
2. Parse and validate the IP addresses.
3. Remove duplicate entries.
4. Convert addresses into CIDR notation.
5. Divide the addresses into groups of no more than 2,000.
6. Create missing Entra ID Named Locations.
7. Update existing Named Locations.
8. Verify the resulting configuration.
9. Record execution results.

## Deployment

See the [Azure Automation Implementation Guide](docs/azure-automation-setup.md) for deployment instructions.

## Disclaimer

This project uses a third-party public Tor exit node feed. The accuracy, availability, and completeness of that feed are not guaranteed.

Blocking Tor exit nodes can affect legitimate users. Test Conditional Access policies in Report-only mode before enforcement.
=======
Synchronize publicly available Tor exit-node IPv4/IPv6 addresses into Microsoft Entra ID Conditional Access named locations using Microsoft Graph PowerShell.

The project is designed for scheduled execution in Azure Automation with a system-assigned managed identity. It can also run from a server or workstation using any supported Microsoft Graph authentication method.

> **Important:** This project consumes a third-party feed. Feed availability, accuracy, and completeness are not guaranteed. Validate the source and test Conditional Access policies in **Report-only** mode before enforcement. Tor exit-node blocking can affect legitimate users.

## What it does

1. Downloads the configured CSV feed.
2. Checks the response, expected columns, row count, and IP address validity.
3. Normalizes addresses into `/32` IPv4 or `/128` IPv6 CIDR ranges.
4. Removes duplicates and sorts the result.
5. Splits the ranges into groups no larger than 2,000.
6. Creates missing named locations and updates existing managed locations only when their ranges differ.
7. Verifies the resulting named locations and reports stale managed locations.

The script manages only locations with the configured name prefix. It does not create or modify a Conditional Access policy.

## Repository layout

```text
.
├── config/settings.json
├── docs/
│   ├── architecture.md
│   ├── azure-automation-setup.md
│   ├── conditional-access.md
│   ├── permissions.md
│   ├── standalone-server.md
│   └── troubleshooting.md
├── examples/
│   └── local-execution.ps1
├── scripts/
│   ├── Install-Requirements.ps1
│   ├── Test-TorNodeFeed.ps1
│   └── Update-TorNamedLocations.ps1
├── tests/
│   └── Validate-TorNodes.Tests.ps1
├── .gitignore
├── LICENSE
└── CHANGELOG.md
```

## Requirements

- Microsoft Entra tenant with Conditional Access licensing appropriate for the policies you intend to use.
- PowerShell 7.2 or later.
- `Microsoft.Graph.Authentication` and `Microsoft.Graph.Identity.SignIns`.
- Microsoft Graph application permission `Policy.ReadWrite.ConditionalAccess` with admin consent for unattended managed-identity execution.
- Outbound HTTPS access to the configured feed and Microsoft Graph.

## Quick start: interactive test

Install the modules:

```powershell
./scripts/Install-Requirements.ps1
```

Authenticate interactively:

```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"
```

Run a dry run first:

```powershell
./scripts/Update-TorNamedLocations.ps1 -ConfigPath ./config/settings.json -WhatIf
```

If the output looks correct, run without `-WhatIf`:

```powershell
./scripts/Update-TorNamedLocations.ps1 -ConfigPath ./config/settings.json
```

The script uses the `New-MgIdentityConditionalAccessNamedLocation` cmdlet to create IP named locations and `Update-MgIdentityConditionalAccessNamedLocation` to update them.

## Azure Automation

See [docs/azure-automation-setup.md](docs/azure-automation-setup.md). The recommended deployment is a PowerShell 7.2 runbook using the Automation Account's system-assigned managed identity.

## Configuration

Edit `config/settings.json` before deployment:

- `FeedUrl`: raw CSV URL. The default points at the repository's `main` branch; pin a commit if reproducibility is more important than automatically following upstream changes.
- `DisplayNamePrefix`: prefix used to identify locations owned by this script.
- `ChunkSize`: maximum ranges per named location. Keep at or below 2,000.
- `MinimumExpectedIpCount`: minimum accepted number of unique addresses. Set this based on your review of the feed; it is a safety threshold, not a guarantee of feed quality.
- `MaximumAllowedChangePercent`: reject unusually large changes compared with the previous managed set. Set to `0` to disable this guard.
- `Trusted`: whether Entra treats the location as trusted. Leave `false` for Tor exit nodes.
- `CleanupObsoleteLocations`: leave `false` by default. Review and remove stale locations manually after checking Conditional Access policy references.

## Safety behavior

The script fails before making Graph changes if the feed cannot be downloaded, required columns are absent, too few valid unique addresses are found, or the configured change threshold is exceeded. It does not replace the current configuration with an empty or clearly incomplete feed.

A successful run may still produce a warning if more named-location partitions exist than are currently needed. Those stale locations are intentionally not deleted automatically because they may be referenced by Conditional Access policies. Review and remove them manually after updating policy references.

`-WhatIf` previews the intended create/update operations. It does not make Graph changes.

## Operational notes

- The Entra named-location IP range limit is 2,000 ranges per location. The script enforces a configured chunk size no greater than 2,000.
- This implementation treats each feed IP as a single-host CIDR (`/32` or `/128`).
- The feed's `port` column is not used: Conditional Access named locations match IP ranges, not source ports.
- Graph permissions are powerful. Use a dedicated Automation Account identity and grant only the required application permission.
- The script does not change sign-in risk, MFA, device, or other Conditional Access controls.
- Consider alerting on runbook failures and reviewing sign-in logs before enforcing a blocking policy.

## License

See [LICENSE](LICENSE). The upstream Tor-node feed has its own licensing and terms; review those separately before redistribution or operational use.
>>>>>>> 2bad612 (Initial commit: Entra ID dynamic Tor exit node blocker)
