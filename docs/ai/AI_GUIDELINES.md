# AI assistant guidelines — Payments Integration

## Allowed use and data handling

Use approved AI assistants to help draft code, tests, API contracts, documentation, migration plans, and operational runbooks. Treat generated output as a suggestion that requires human review.

Never submit secrets, access tokens, credentials, production payloads, real customer data, payer names, national IDs, emails, payment tokens, or material from current/former employers. Use fictional samples or sanitized synthetic data. Remove personal data from prompts, logs, traces, screenshots, and test fixtures before sharing them with any assistant.

## Validation before merge

The author owns every AI-assisted change. Before merge:

1. Review the generated diff line by line against requirements, provider specifications, Salesforce constraints, and applicable ADRs.
2. Run the automated test suite, including MUnit/JUnit tests for signature verification, raw-body handling, duplicate retries, out-of-order events, error handling, and contract compatibility.
3. Validate OpenAPI and JSON Schema contracts and run the code quality, dependency, secret, and security checks in CI.
4. Confirm no generated code logs personal data or secrets and that identity/permissions follow least privilege.
5. Record material corrections or rejected suggestions in the repository's AI usage disclosure when required by the assessment.

AI output is not evidence that a test passed or that a security property is satisfied. Do not claim a check was run unless it was run and its result was reviewed.

## Pull request disclosure

For material AI assistance, add a concise PR note stating:

- which assistant/tool was used;
- what parts it helped draft or analyze;
- what validation was performed; and
- any material generated suggestions that were corrected or discarded.

Do not disclose sensitive prompt contents. Complete the repository `../../AI_USAGE.md` truthfully for this assessment.

## Services that call an LLM

An LLM feature is not part of the payment-notification flow described in the assessment. If a future service summarizes dead-lettered notifications, apply these minimum controls before launch:

- **Prompt injection:** treat every notification, DLQ field, retrieved document, and operator input as untrusted data; delimit data from instructions; do not let model output trigger replay, payment updates, or other actions. Any action remains behind deterministic application logic and authorized human approval.
- **Content controls:** screen inputs and outputs for disallowed content and leakage; constrain output to a defined summary schema; reject malformed or unsupported output.
- **Data minimization:** send only fields required for the summary. Remove names, national IDs, emails, payment tokens, secrets, and raw payload content unless a documented, approved need and lawful basis exists. Prefer aggregate or pseudonymous identifiers.
- **Traceability:** record model/deployment version, prompt-template version, correlation ID, timestamp, policy/filter outcome, latency, and token/cost metrics. Do not log sensitive prompt or completion content by default.
- **Cost and reliability:** set per-request and per-period token limits, budget alerts, rate limits, timeouts, and fallback behavior. LLM failure must not block payment intake, Salesforce recording, DLQ access, or safe replay.
- **Security and governance:** use an approved Azure OpenAI/Azure AI Foundry deployment if selected; protect it with managed identity and least privilege; define retention and residency; test adversarial prompts, data leakage, and unsafe output before release; require human review for operational decisions.

