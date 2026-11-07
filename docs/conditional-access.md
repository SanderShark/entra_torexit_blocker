# Conditional Access policy configuration

This project only maintains named locations. It deliberately does not create or modify Conditional Access policies.

After confirming the locations are populated:

1. Open Microsoft Entra admin center → Protection → Conditional Access → Named locations.
2. Confirm each `Managed - Tor Exit Nodes - Part NN` location contains the expected ranges and is not marked trusted.
3. Create or update a Conditional Access policy using the appropriate user and workload scope.
4. Under Network/Locations, include the managed Tor locations as appropriate.
5. Configure the intended access control, such as Block access, only after evaluating business requirements.
6. Begin in Report-only mode.
7. Review sign-in logs, report-only results, emergency access accounts, service accounts, and legitimate research use cases.
8. Enable enforcement only after approval and testing.

## Important considerations

- Do not exclude emergency access accounts from your operational review.
- A Tor exit-node IP is not proof of malicious intent.
- Tor feeds can change quickly and can contain stale or incomplete data.
- Named locations are not a substitute for risk-based controls, MFA, device compliance, or sign-in monitoring.
- The feed's `port` value is not used because named locations match IP ranges, not ports.

Microsoft documentation:
- https://learn.microsoft.com/entra/identity/conditional-access/concept-assignment-network
- https://learn.microsoft.com/entra/identity/conditional-access/policy-block-by-location
