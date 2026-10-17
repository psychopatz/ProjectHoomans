# ONE unified roadmap — Semantic Dialogue Decoupling

All steps belong to **one** active goal `docs/Jobs/SemanticDialogueDecoupling/`. They are phases, not independently managed agents. Detailed phase history belongs in PROGRESS, not a second project ledger.

| Phase | Outcome / bounded gate |
| --- | --- |
| **0 — Preserve fixed baseline (ACCEPTED)** | Confirm committed Hoomans `105dadedd31c57be64a3622c4a1f6d2d6f402d35`, Core version, real-worker identity regression, one complete reported conversation trace, existing test results, and EN/TL 521-key snapshot. Native SP/MP remains outstanding. |
| **1 — Typed candidates and contextual eligibility (ACCEPTED)** | Extend Core with bounded multi-candidate diagnostics while preserving `Parse`/IR v1. Hoomans rejects fuzzy mutating interpretations and same-priority ambiguity with inspectable reasons; authored priority remains effective and no unintended command mutation occurs. |
| **2 — Minimal bounded dialogue-flow kernel (ACCEPTED)** | Reuse existing PNC dialogue state, register flow IDs/triggers/nodes/transitions; suspend/resume/cancel/retire with per-speaker/addressee isolation. PREVIEW is pure; accepted turns commit once. No alternate dialogue memory store. |
| **3 — Identity and wellbeing modular pilots (ACTIVE)** | Move behavior/transition ownership into two small registered modules while retaining catalog response keys, server authoritative identity validation and earlier wellbeing/social outputs. Demonstrate adding one new variant/branch without a central policy change. |
| **4 — Semantic Lab flow authoring/debugging** | Production worker emits candidates, eligibility reasons, flow/node transitions, actions and translation lookup provenance. CLI/tests and existing GUI inspect the SAME production facts. Detect duplicate/conflicting/unreachable flow registrations. |
| **5 — Optional reusable Core multi-file translation reader** | Define/test bounded explicit manifest, duplicate ownership failure, lazy per-shard or measured per-system cache, EN per-key fallback, language invalidation, legacy API parity. Core changes made/reviewed in the Core repo, tracked in this ONE goal. |
| **6 — Full Conversation custom EN/TL sharding** | Pilot one group, then migrate all exact latest 521+ keys to subsystem files. EN/TL key/value/placeholder, response ID and lookup parity, real Lua worker; never drop newer variants or touch already-modular authored conversation/native PZ files. |
| **7 — Composable response plans** | Small typed dialogue-act plans over existing contextual pools and localized grammar-safe text; NPC state/personality differences and coherent multi-turn messages in both EN/TL without giant duplicated sentences. |
| **8 — Domain integration** | Extend social, gossip, offers, trade and task dialogue only where needed; preserve MarketSense classifications, server actions, optional PBrainZ, group speaker/recipient isolation and legacy response IDs. |
| **9 — Native Build 42 acceptance/performance** | Controlled SP/MP game sessions, UI, identity authority, save/rejoin, translation and provider-disabled operation. Measure conversation-path CPU/memory; no per-NPC OnTick scan. Record exact evidence before maintenance-ready. |

## Discipline
One Next Chunk at a time in `PROGRESS.md`. Existing 2026-10-17 collision patch is ALREADY IN CODE, not Phase 0 future implementation. A phase may be adjusted based on evidence but must not rebuild already working features. Translation loader and flow system must remain compatible during phased rollouts. Correctness gates cannot be replaced by source-only or JSON-only audits.
