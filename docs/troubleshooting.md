# Troubleshooting

## `Authorization_RequestDenied` or insufficient privileges

Confirm the signed-in identity has Microsoft Graph application permission `Policy.ReadWrite.ConditionalAccess`, admin consent has been granted, and permission propagation has completed. For managed identity, confirm the permission is assigned to the correct service principal.

## Graph cmdlet not found

Install/import `Microsoft.Graph.Authentication` and `Microsoft.Graph.Identity.SignIns` in the same PowerShell runtime used by the script. In Azure Automation, module availability is tied to the runbook runtime.

## Feed download fails

Check outbound HTTPS access, DNS, the configured raw GitHub URL, and GitHub availability. The script intentionally stops rather than replacing the current named locations with an empty feed.

## Feed count is below the minimum

Review the upstream CSV manually and adjust `MinimumExpectedIpCount` only after confirming the source format and expected volume. Do not lower the threshold simply to make a failed run pass.

## Change threshold exceeded

A large change can indicate an upstream format change, feed outage, or legitimate list turnover. Review the feed and current Entra locations before changing `MaximumAllowedChangePercent`.

## Stale locations remain

If the feed shrinks and fewer partitions are needed, the script warns about old partitions but does not delete them. Check whether any Conditional Access policies reference those locations. Update policy references and remove stale locations manually through the portal or a separately reviewed change.

## Partial update

A Graph or network failure can occur after one partition has been updated but before the remaining partitions are processed. Review the runbook output and current named locations, fix the underlying issue, then rerun. The script is intended to converge on rerun.
