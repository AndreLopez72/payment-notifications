# INC-0412 response — Colombian paid policies remain suspended

## First 30 minutes (08:12–08:42 Colombia time)

| Time | Action |
|---|---|
| 08:12–08:15 | Acknowledge the proposed SEV-2, open the incident bridge, and involve the Payments Integration on-call, Salesforce/policy-core support, and Colombia operations. Preserve the 08:15 snapshot and avoid deleting or replaying queue messages. |
| 08:15–08:20 | Confirm scope by country and current impact. Colombia shows 4,312 DLQ messages and 43,120 Salesforce `400` responses; Mexico and Chile have no reported customer complaints and much smaller DLQs. Signature failures are zero. Check current CO queue/DLQ depth, consumer activity, Salesforce API-budget use (66% of the rolling budget), and whether new permanent `400`s are still being abandoned. |
| 08:20–08:27 | Trace the supplied correlation IDs and transaction IDs across the CO consumer logs and DLQ. Compare the DLQ reason, delivery count, Salesforce status/error code, and original references. Keep the investigation to sanitized identifiers and error details. |
| 08:27–08:35 | Ask Salesforce/policy-core support to verify whether `referencia` values such as `000215560` and `pol-co-000198004` exactly match existing `Policy_Number__c` external IDs and whether the relationship field/API mapping changed. Compare the specific failed response with the Saturday Salesforce validation-rule release and the Friday integration release; timing alone does not establish causation. |
| 08:35–08:42 | Stop rapid redelivery of known permanent CO validation failures using the approved consumer control; if it cannot classify them safely, pause only the CO consumer under incident/change controls. Keep the DLQ intact, agree which payment references can be authoritatively corrected, and communicate the verified scope and next update time to Colombia operations. Do not alter Mexico or Chile. |

## Most likely cause and evidence

The immediate failure mode is a permanent Salesforce `400 INVALID_FIELD` caused by a `Policy_Number__c` external ID relationship that Salesforce cannot resolve. V1 abandons every failed message and immediately redelivers it; after 10 deliveries, Service Bus dead-letters it. The sample shows the external-ID-not-found response, delivery count 10, and `MaxDeliveryCountExceeded`. The snapshot's 43,120 `400` responses equal 4,312 DLQ messages multiplied by 10 delivery attempts, which strongly supports this retry loop. The 4,198 `APROBADA` messages are the largest affected state group, while the contact center reported 37 customer cases. No complaints were reported from Mexico or Chile.

The underlying reason the policy reference does not resolve is not established. It could be provider reference data or the integration's mapping; the samples show different reference formats. The Salesforce release introduced a validation rule, but the supplied error names the external-ID relationship, not the cancellation-reason rule. Confirm by checking the exact Salesforce external IDs and deployed field/API mapping with the Salesforce owner. Do not normalize, pad, lowercase, or otherwise rewrite references based only on the examples.

## Remediation and safe recovery

1. Keep the CO DLQ unchanged as evidence. Do not purge it, bulk-resubmit all 4,312 messages, or replay rejected/refunded states without validating their event and business meaning.
2. Have the policy-core owner and authorized operations staff identify the correct policy reference for each affected payment from an authoritative source. Record corrections and approvals according to the approved process; the correction authority is unresolved in A-13.
3. Change the consumer's error handling so a permanent Salesforce `400` is not abandoned for immediate retry. Route it to a durable failed/held state for correction; reserve retry/backoff for transient failures such as `5xx` or lock errors. Test the exact reference and Salesforce mapping before resuming CO processing.
4. Replay only records whose policy reference and provider state have been verified. Use a controlled, auditable replay path; preserve the original provider transaction/business-event identity and correlation context so the Salesforce upsert remains idempotent. Keep the source DLQ record until the replay outcome is verified. Reconcile replayed records against Salesforce and the DLQ/status inventory.
5. The incident materials do not describe a v1 DLQ replay tool or runbook. Use only an approved platform mechanism; if none exists, keep messages held until the Salesforce/platform owners approve a controlled replay procedure (A-31). The target design's SQL outbox replay process is not evidence that v1 already has that capability.

## Prevention

- Classify Salesforce errors: do not retry permanent validation `400`s unchanged. Keep failed work discoverable and replayable after correction.
- Alert on DLQ depth/growth for every country, Salesforce `400` error rate, queue age, freshness, accepted-but-unaccounted notifications, and API-budget use. The scenario says only Mexico had a DLQ alert; the target proposal defines per-country alerts in `OPERATIONS.md`.
- Add deployment verification for policy external-ID mapping and Salesforce relationship fields, including realistic Colombia references with leading zeros and provider prefixes. Verify Salesforce validation-rule changes against payment upserts before production rollout.
- Keep per-country dashboards and traceable correlation/business-event identifiers. Review the Friday integration and Saturday Salesforce changes against exact deployment diffs; do not attribute cause without confirming the failed field and mapping.
