# Entra ID Dynamic Tor Exit Node Named Locations

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
