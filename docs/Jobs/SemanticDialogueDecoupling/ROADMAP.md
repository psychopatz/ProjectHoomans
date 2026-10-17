# One unified roadmap — Codex implementation, Semantic Lab validation, user live test

Current state: real candidate, flow kernel, response plan and translation-shard infrastructure exists; more development remains. The earlier C0B `blocked` state was caused by the **incorrect requirement for Workshop publication/native PZ process** and is therefore **superseded**. Don't discard successful local C0B code; recheck source.

| Phase | Implementation output / developer exit gate |
| --- | --- |
| **D0 — CURRENT: Semantic Lab repair + Core source preflight** | Confirm local Core/Hoomans APIs, reconcile Core GitHub main now supporting candidate/router/manifest features, preserve local C0B edits; make the existing Semantic Lab interface/worker useful for observing real production conversations, not headless JSON-only results. One working identity/wellbeing multi-turn trace with selected reply and side effects. No PZ required. |
| **D1 — Flow controls conversation responses** | Wire registered flow response pool/plan and transition into production reply selection after safety checks, preserving legacy authority adapters and the fixed identity behavior. Actual selected NPC text and next flow node must agree in Semantic Lab. |
| **D2 — Third flow extensibility demonstration** | Add a safe separate Lua dialogue type with one contextual response and follow-up. No per-flow branch in shared intent switch/resolver; register once and test from Semantic Lab GUI/worker. |
| **D3 — Real Semantic Lab flow browser/editor** | Browse production flow registry and graph (nodes/edges), visualize selected candidate/transition/response, edit/validate flow definition and use same Lua registration and runner. The UI must be practical, not just a JSON serializer or a static diagram. |
| **D4 — Real compositional dialogue** | Make bounded two-act response plans influence actual NPC reply/queue, with coherent EN/TL formatting and flow-selected text; not merely `ResponsePlan.Attach` wrapping a one-line response. |
| **D5 — Integration and regression sweep** | Confirm EN/TL shard keys via public Core manager, identity/social/gossip/trading/task/group integration, optional PBrainZ-off semantics, server action invariants and no new tick-time cost. Fix relevant regressions. Harness must be usable enough to guide further authoring. |
| **D6 — Developer handoff to user** | Final exact commits/evidence, actual harness results, known limitations and minimal USER-RUN PZ SP/MP/translation/performance checklist. Mark `READY FOR USER LIVE TEST` and stop. **Never wait for native app or Workshop publication to call the implementation work finished.** |

## One bounded Next Chunk
See `PROGRESS.md`; complete one chunk at a time, progressing autonomously after its **developer** acceptance gate. The optional user live test happens only after D6 and may open a new correction chunk if the user reports a problem.

## Explicit non-goals for Codex
Workshop distribution/update/upload/republish, starting or polling Project Zomboid, demanding SP/MP test reports before continuing, treating missing app surface as blocked, separate goal/branch/PR, multiple competing progress ledgers, duplicate parser/rule engine, JSON-only fixture churn.
