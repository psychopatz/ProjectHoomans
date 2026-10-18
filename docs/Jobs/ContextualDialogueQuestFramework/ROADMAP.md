# Roadmap — Semantic Lab procedural NLP + Contextual Dialogue & Quest Framework

**Reconciled:** 2026-10-18, branch source `382e93a3`. Historical weather-gate Phase 0A is accepted by previously recorded developer worker evidence; current node CRUD and engine observation changes are **source-present, not fully GUI/real-action accepted**. This roadmap changes priority without discarding the unclosed GUI gate.

| Phase | Status | Concrete deliverable | Developer acceptance gate |
| --- | --- | --- | --- |
| **0 — Shared world condition bridge** | **ACCEPTED (historical)** | `weather_context` real-Lua PASS/FAIL/UNKNOWN branch, reusable Blocks evaluator, EN/TL response | Prior PROGRESS evidence at `1a754dc8`; no claim of rerun on latest branch |
| **1 — Graph/editor foundations** | **PARTIAL, carried forward** | Existing node CRUD, layout, trigger/action discovery, typed fact/event catalog | Verify actual UI CRUD and undo, structural recovery, layout persistence, no misleading Add action; regressions; remaining UX defects closed during workbench phase |
| **2 — Typed action-binding path** | **ACTIVE / NEXT** | Capability discovery resolved to authorized command/task/gift route and real result; visible worker trace | First **FOLLOW** positive/denied/negated/question real-Lua trace (2A); then Stay vs Wait At (2B), multi-stage Gift (2C); no duplicate dispatch, no false NPC success |
| **3 — Procedural semantic compiler** | PLANNED | One canonical declarative semantic model; augment existing compiler to generate modular patterns/flows/responses/EN+TL/manifests | One authored FOLLOW definition produces actual source in correct mod paths, fresh worker loads it and routes real utterances; identical regeneration byte-stable; negative recognition/collision tests |
| **4 — Practical integrated authoring UX** | PLANNED | Language/Dialogue/Actions/Simulator/Compiler surfaces, graph/text sync, error repair, source diff, persistent editor layout | Human/agent authors a valid interaction **in Semantic Lab** and inspects its actual route; no JSON-only or screenshots-only acceptance |
| **5 — Conversational context, personality and memory** | PLANNED | Participant-scoped references and significant durable commitments reusing Knowledge/Social/Personality; interrupt/resume | Real multi-turn and reopened-session worker examples; unknown fact and second NPC don't hallucinate/cross-contaminate |
| **6 — Authoritative quest domain + NLP** | PLANNED | Server-owned quest lifecycle, objectives, event evidence, idempotent rewards; conditional dialogue via same compiler | Clinic Supplies quest through real semantic/gate/action/result path; duplicate delivery/reward cannot mutate twice; SP/MP authority contract |
| **7 — Integration, limits and handoff** | PLANNED | Deterministic parser collision sweep, translations, Kahlua, performance/ModData budgets, standalone worker/UI validation, concise handoff | Measured bounds, focused real production Lua traces, no known relevant regressions; **READY FOR USER LIVE TEST** with native PZ SP/MP and Workshop exclusively user-owned |

## Next Chunk source of truth

`PROGRESS.md` names **exactly ONE Next Chunk**. Start with Phase 2A FOLLOW, not the obsolete 0A weather task or blind reimplementation of Phase 1 GUI CRUD. The first few minutes of that chunk must reconcile actual HEAD/tests with the source-present feature set, then produce a functioning, observable action-binding vertical slice. Do not stop after another audit/prose report when the required source/runtime work is possible.

Phase 1 outstanding click-through and structural issues are mandatory before Phase 4 exit, not grounds to erase existing implementation or postpone the value-bearing action/compilation pipeline. Later phases can be subdivided only after earlier acceptance. Each phase needs positive, negative and fallback cases in the actual production Lua worker, not source-count metrics or synthetic JSON-only success.

## Scope non-goals

Not a second NLP parser or alternative Tk simulator, unrestricted LLM-level language generation, unrestricted WordNet synonyms, automatic generation of arbitrary callable Lua functions, new inventory/command/gameplay engines, workshop publishing, native PZ process launches, CI pass claims without runs, or replacing unrelated legacy jobs.

Refer to `CAPABILITY_ACTION_BINDINGS.md` and `PROCEDURAL_NLP_COMPILER.md` for detailed phase contracts.
