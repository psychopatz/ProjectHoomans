# Roadmap — Contextual Dialogue & Quest Framework

**State:** Phase 0 gate bridge vertical slice **ACCEPTED** by developer evidence in commit `1a754dc8`; Phase 1 is selected and its first chunk is not yet implemented. Every mandatory phase requires product-path proof plus safety/regression evidence. JSON fixtures, synthetic graphs, and conflict-ledger green results alone are insufficient.

| Phase | Mandatory product output | Developer acceptance gate |
| --- | --- | --- |
| **0 — Gate bridge vertical slice — ACCEPTED** | Audit existing Blocks conditions and flow registry/preview/commit, then give one semantic dialogue flow a typed, pure weather condition through the existing gate ownership path | Semantic Lab real Lua proves rain TRUE, clear FALSE, and unknown branches with gate status/reason, rendered replies, no side effects, and identity/wellbeing regressions |
| **1 — Graph editing foundations — NEXT** | Extend existing `flow_editor.py` with robust node add/rename/delete/duplicate/connect/disconnect, undo/redo, preserved layout, and structural error inspection | Human/agent can build a valid branch in the existing GUI; production registry accepts it and rejects a broken graph; no second engine or JSON-only UI |
| **2 — Context continuity and memory** | Bounded speaker-aware dialogue references, interruption/resumption, and retrieval of verified significant NPC knowledge/commitment; personality/relationship/world context remains owned by existing providers | Multi-turn “what happened”/“get you some”/return-to-topic, isolated two-NPC sessions, unknown memory, and worker/session boundaries behave correctly in production Lua |
| **3 — Code authoring and durable flows** | Supported declarative code editor synchronized with graph; safe source export plus manifest/translation integration; worker-restart durability | Authored definition has the same real-Lua reply before/after restart; unsupported Lua is preserved rather than rewritten; visual/code round trip and EN/TL are correct |
| **4 — Quest domain core** | Separate server-owned quest registry, scoped instances, objective event ingestion, save/migration, and exactly-once reward path | Clinic Supplies test proves authoritative transfer advances the objective, duplicate packet/restart cannot reward twice, and client claims cannot complete it |
| **5 — Quest–NLP–personality integration** | Quest gate/status queries and pending offer/accept/turn-in through the same natural-language flow; personality shapes willingness/tone without bypassing authority | Real-worker conversations cover locked/available/active/ready/rewarded, trusted/distrustful, weather variants, cross-speaker denials, and the authoritative action-result boundary |
| **6 — End-to-end acceptance and handoff** | Integrated editor plus real Lua scenario tests, performance/ModData bounds, B42.20 syntax checks, offline EN/TL, optional PBrainZ parity, and concise user-only PZ checklist | No known relevant regressions; GUI click-through where available or explicitly pending; developer READY FOR USER LIVE TEST, native SP/MP unclaimed |

## Phase and Next Chunk discipline

Only `PROGRESS.md` names the current Next Chunk. The next implementation chunk is **1A**: bounded CRUD/connect/disconnect and structural inspection in the existing Semantic Lab editor, proven through the production Lua registry. Keep each chunk behavior-preserving, scoped, and evidence-backed before selecting the next one.

Phase 1 must preserve the shared parser/candidate IR, the production flow registry/kernel, existing translation and networking contracts, and the 0A gate ownership path. Do not turn the editor into an alternate parser, authority, quest executor, arbitrary Lua evaluator, or JSON-only simulator.

Phases 2–3 establish usable contextual authoring and durable definitions before quest work. Phases 4–5 add a separately owned authoritative quest domain and integrate it through the same dialogue path. Phase 6 closes development without launching Project Zomboid or publishing Workshop content.

## Phase exit statuses

Use `NOT STARTED -> IN PROGRESS -> IMPLEMENTED / NOT ACCEPTED -> ACCEPTED`, or genuine `BLOCKED` with evidence. A lower-priority native gate may remain `USER-OWNED`; do not claim native SP/MP acceptance from Semantic Lab. When all mandatory implementation gates are accepted, stop at READY FOR USER LIVE TEST rather than inventing further feature work.
