# ONE unified roadmap — corrective integration after decoupling audit

**Current state:** historical phases 0A–8 have implemented Lua modules with agent-reported production-worker acceptance; their **end-to-end product gates remain OPEN**. Phase 9 native SP/MP is still unaccepted. This roadmap introduces ordered **corrective phases C0–C6** without discarding previous implementation or changing historical evidence.

| Phase | Required product outcome / exit gate |
| --- | --- |
| **C0 — Deployed dependency parity (ACTIVE)** | Reconcile actual installed/published Hoomans and Core revisions. Core must supply candidate parser/router hooks and manifest loader, Hoomans must detect missing capabilities, and installed EN/TL Conversation shards must load correctly. Safe Core publication after its own authorizations, not Hoomans-only workarounds. |
| **C1 — Native dialogue baseline** | Obtain controlled Build 42 SP dialogue trace from actual installed pair: identity/wellbeing interruption and response, selected flow/node and authoritative identity consequences. Add minimal opt-in production debug trace if needed. Hosted MP evidence remains mandatory but may be completed in C6. |
| **C2 — Flow owns real behavior** | Wire flow response-pool/plan and transition to actual selection after safety checks; retain legacy policy for unmigrated command/authority domains. Identity and wellbeing replies/follow-up controlled by registered flows, with no duplicate messages or central per-flow branches. Prove a third harmless module can decide an in-game reply without central-policy edit. |
| **C3 — Visual flow inspector/editor** | Extend existing Semantic Lab or approved in-game debug tooling to browse real production registry, view node/edge graph and candidate/transition/reply facts, edit/register bounded flow definitions safely, and verify edits using the same actual Lua production path. GUI mock or JSON-only visualization cannot close the gate. |
| **C4 — Actual response composition** | Flow-selected typed dialogue acts produce two or more cohesive localized clauses/turns through actual NPC UI queue, with correct EN/TL grammar/placeholders and bounded sequencing. `Plan.Attach` of a preselected one-liner alone is not sufficient. |
| **C5 — Localization and domain integration** | Confirm every migrated Conversation key/shard resolves with installed Core, check/fix evidenced Trading lookup if required, preserve existing authored/native catalogs, and test social/gossip/trade/tasks/group context/PBrainZ without changing server authority. |
| **C6 — Native SP/MP/performance acceptance** | Full controlled PZ Build 42 SP+hosted MP including save/rejoin, identity/trust authority, session isolation, PBrainZ-off and optional on, EN/TL restart, no new per-tick parsing, measured latency/memory. Record precise evidence and unresolved failures; only then maintenance-ready. |

## Transition rule
Implement exactly ONE bounded `Next Chunk` in `PROGRESS.md` at a time. C0 is not permission to rewrite dialogue. C1 native-baseline instrumentation should be minimal and read-only. Proceed to behavioral refactoring only after compatible installed dependency and real-game trace reveal concrete gaps. Preserve all previously implemented flow, candidate, response-plan and translation shard code.

The headless suites are diagnostic support, never the primary acceptance metric. Twelve reported baseline failures remain tracked rather than automatically ignored. Do not reopen separate goals, create new branches/PRs, or run a JSON-only acceptance theater.
