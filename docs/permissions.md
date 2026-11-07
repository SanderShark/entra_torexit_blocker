# Microsoft Graph permissions

## Required permission

Grant the runbook identity the Microsoft Graph **application permission**:

`Policy.ReadWrite.ConditionalAccess`

An administrator must grant tenant-wide admin consent. Delegated permissions are suitable for an interactive test session, but unattended Azure Automation should use application permissions through its managed identity.

## Assigning the permission to a managed identity

1. Enable the Automation Account's system-assigned managed identity.
2. Open Microsoft Entra admin center → Identity → Applications → Enterprise applications.
3. Locate the service principal corresponding to the Automation Account managed identity.
4. Assign the Microsoft Graph application role `Policy.ReadWrite.ConditionalAccess`.
5. Grant admin consent as required by your tenant's process.
6. Allow time for permission propagation, then test Graph authentication and a read operation.

The exact portal navigation can change. Use your organization's approved process for assigning Microsoft Graph app roles to managed identities.

## Least privilege

This permission is powerful and can affect Conditional Access configuration. Use a dedicated identity, restrict who can edit or publish the runbook, monitor job history, and do not reuse the identity for unrelated automation.

References:
- https://learn.microsoft.com/graph/permissions-reference
- https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview
