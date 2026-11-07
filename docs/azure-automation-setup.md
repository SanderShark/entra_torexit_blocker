# Azure Automation deployment

## 1. Create the Automation Account

1. Create an Azure Automation Account in your approved subscription and resource group.
2. Select a supported PowerShell runtime. This project targets PowerShell 7.2 or later.
3. Enable the system-assigned managed identity under Account Settings → Identity.

## 2. Grant Microsoft Graph permission

Follow [permissions.md](permissions.md) and grant the managed identity the Microsoft Graph application permission `Policy.ReadWrite.ConditionalAccess`, with admin consent.

## 3. Import modules

Import these modules into the Automation Account's module gallery, using versions tested in your environment:

- `Microsoft.Graph.Authentication`
- `Microsoft.Graph.Identity.SignIns`

Ensure the modules are available to the selected runbook runtime. Allow import and deployment to complete before running the job.

## 4. Create the runbook

1. Create a PowerShell runbook.
2. Select the PowerShell 7.2 runtime (or a newer supported runtime tested with the modules).
3. Copy the contents of `scripts/Update-TorNamedLocations.ps1` into the runbook.
4. Add the JSON from `config/settings.json` as an Automation variable named `TorNamedLocationsConfig`, or adapt the runbook to read a securely deployed configuration file.

For a simple first deployment, you can embed the reviewed configuration values in the runbook or store the JSON in an approved storage location. Do not store credentials in the configuration.

## 5. Connect and execute

The runbook should authenticate using:

```powershell
Connect-MgGraph -Identity -NoWelcome
```

If using the script as a runbook asset, make sure its config path points to a file available in the Automation sandbox. Azure Automation does not automatically contain your local Git repository. A common deployment approach is to paste the script into the runbook and embed the reviewed JSON configuration, or have the runbook retrieve version-controlled script/configuration from an approved source.

Run a test job with `-WhatIf` first. Inspect output and confirm the target names and expected number of ranges. Then run without `-WhatIf`.

## 6. Schedule

Create a daily schedule at a time appropriate for your tenant. Link it to the runbook and configure any required runbook parameters. Avoid overlapping jobs; a run should finish before the next scheduled execution.

## 7. Monitor

- Configure Azure Automation job failure alerts.
- Retain job output and error streams according to your logging policy.
- Review feed count and change percentages.
- Alert on validation failures, Graph authorization failures, and stale partitions.
- Periodically verify that the Graph module versions and runbook runtime remain supported.

## Production deployment note

The repository script expects a JSON config file. A runbook deployment must make that file available in the Automation sandbox or adapt the script to receive configuration as parameters/Automation variables. Do not assume files in your local checkout are present in Azure Automation.
