# Agent Runbook — Semantic Test Subsystem

**State:** COMPLETE / maintenance-ready.

For future changes:

1. Read PROGRESS and HANDOFF before touching the subsystem.
2. Keep semantic scenario/outcome acceptance in semantic.harness-test.v1 fixtures.
3. Keep imperative Python only for concrete implementation mechanisms.
4. Any direct-worker imperative method must keep a specific mechanism reason in TEST_CLASSIFICATION.json.
5. Reusable test helpers belong in support modules, never another test module.
6. Preserve workspace-relative multi-repository discovery; never hardcode the live developer checkout.
7. Broad acceptance must restore worker/Tk resources to baseline.
8. If behavior fixtures or imperative tests change, regenerate TEST_CLASSIFICATION.json and rerun guards, lint and the relevant broad suites.
9. Preserve unrelated DynamicTrading work recorded in HANDOFF.
10. Do not push, publish, amend, rebase, tag or force-update without explicit authorization.
