# Roadmap — Test Suite Rationalization

**Parent goal:** Review the complete maintained developer test estate, remove or consolidate only evidence-proven redundancy/legacy coverage, improve test infrastructure and execution topology, and finish with equal-or-stronger meaningful regression protection plus measured before/after results.

## Reconciled state

The first pass produced a valid inventory/baseline and several useful repairs, but its P6 completion is revoked because 1,217/1,424 families remained `pending_family_review`. The continuation below preserves useful evidence and resumes from the actual product gap.

| Phase | Mandatory acceptance |
| --- | --- |
| **R0 — Correct review-state model and preserve evidence** | Reconcile the current dirty worktree without discarding user/agent work. Preserve valid baseline/repair/deletion evidence. Update the audit generator so executable tests start `UNREVIEWED`, not `UNKNOWN_KEEP`; migrate generic `pending_family_review` entries to `UNREVIEWED`; ensure `UNKNOWN_KEEP` can only be emitted with specific reviewed evidence. P6 remains revoked. |
| **R1 — Root Lua domain-by-domain review** | Review all 1,007 root Lua smoke tests by production domain/authority, prioritizing the 855 non-semantic entries previously almost entirely unresolved. For each domain, inspect production subjects/callers, assertion intent, overlap, legacy status, repeated fixtures/mocks and fragmentation. End each family with a real reviewed disposition; run focused validation after changes. |
| **R2 — Consolidate repeated contract families** | Evaluate high-density families such as presence-boundary, inventory, MP/network, persistence, body/presence, NPC/actor, faction/community, facility/building, abstract world/traversal, combat/zombie, map, companion/tasking/work and other repeated domains. Prefer parameterized/table-driven contract matrices or shared fixtures when the execution boundary is identical and per-case failures remain diagnosable. |
| **R3 — Legacy/migration/refactor cleanup** | Cross-reference tests against current production paths and Git history. Delete truly retired compatibility layers, unsupported migration bridges, removed APIs/composition paths and temporary refactor invariants only after deletion-gate proof. Preserve still-supported migrations and historical regressions that remain possible. |
| **R4 — Semantic Python/Harness rationalization** | Re-review the 209-module Semantic Python estate independently of root Lua. Analyze the measured slow tail (response observatory matrix, sweep acceptance, fixture parity, harness, contextual talk parity, behavior parity, social reactions, speech behavior) for duplicate scenario coverage, repeated worker startup and incorrect execution tier. Merge/move/optimize only with isolation/parity proof. |
| **R5 — Suite topology and affected-test routing** | Make fast/default, focused-domain, integration and acceptance lanes explicit using existing runners where possible. Keep the fast 1,007-file Lua suite when useful, but improve domain selectors/ownership so agents can run/read relevant slices without treating the entire estate as one undifferentiated set. |
| **R6 — Real final acceptance** | Manifest has zero `UNREVIEWED` / `pending_family_review`; every `UNKNOWN_KEEP` has specific review evidence; every substantive domain has a review summary; all removals/merges pass proof gates; focused/default/full suites pass; before/after file/LOC/assertion/runtime/tier metrics recorded; worktree status reported accurately; remaining native acceptance clearly user-owned. |

Each phase is an execution gate, **not a stop condition**. Continue automatically R0 -> R6 until the full developer-side objective is actually accepted or a genuine blocker prevents safe work.

There is no mandatory target test count. A suite remaining above 1,000 tests is acceptable only after those tests have genuinely been reviewed and their retained structure is justified.
