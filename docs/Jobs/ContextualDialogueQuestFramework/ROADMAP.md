# Roadmap — Contextual Dialogue & Quest Framework

**State:** new development goal. Historical SemanticDialogueDecoupling D6 handoff remains intact. This job starts at Phase 0. Every mandatory phase requires both product-path proof and safety/regression evidence; a generated JSON fixture or green conflict ledger alone is insufficient.

| Phase | Mandatory product output | Developer acceptance gate |
| --- | --- | --- |
| **0 — Gate bridge vertical slice** | Audit existing Blocks conditions and flow registry/preview/commit, then give ONE semantic dialogue flow a typed, pure weather/time condition through the existing gate ownership path | Change mock weather/time in Semantic Lab, observe different selected real-Lua flow/reply/gate reason and unknown fact refusal; identity/wellbeing regression and no side effects pass |
| **1 — Graph editing foundations** | Extend existing flow_editor.py with robust node add/rename/delete/duplicate/connect/disconnect, undo/redo, preserved layout and structural error inspection | Human/agent can build a new valid branch in existing GUI; actual registry accepts it, rejects broken graph; no second engine, no JSON-only UI |
| **2 — Context continuity and memory** | Bounded speaker-aware dialogue references, interruption/resumption and retrieval of verified significant NPC knowledge/commitment; personality/relationship/world context consumed without owning copies | Multi-turn "what happened"/"get you some"/return-to-topic, isolated two-NPC sessions, unknown memory and worker/session boundary behave correctly in production Lua |
| **3 — Code authoring and durable flows** | Supported declarative code editor synchronized with graph; safe source export + manifest/translation integration; worker restart durability | New authored definition produces same real-Lua reply before/after worker restart, unsupported Lua preserved rather than rewritten, visual/code round trip and EN/TL correct |
| **4 — Quest domain core** | Small separate server-owned quest registry, scoped instances, objective event ingestion, save/migration and exactly-once reward path | Clinic Supplies game-domain test: authoritative transfer evidence advances objective, duplicate packet/restart cannot reward twice; client claim cannot complete |
| **5 — Quest–NLP–personality integration** | Quest gate/status queries and pending offer/accept/turn-in through same natural-language flow; personality shapes willingness/tone, shared social/world locks | Full real-worker conversations across locked/available/active/ready/rewarded, trusted vs distrustful, weather variants and cross-speaker denials with real authoritative action result boundary |
| **6 — End-to-end acceptance and handoff** | Integrated editor + real Lua scenario tests, performance/ModData bounds, B42.20 syntax checks, offline EN/TL and optional PBrainZ parity, concise user-only PZ checklist | No known relevant regressions; actual GUI interaction test where environment permits (otherwise explicitly pending); developer READY FOR USER LIVE TEST, native SP/MP unclaimed |

## Phase and Next Chunk discipline

Only **PROGRESS.md** names the current Next Chunk. An agent should implement one bounded chunk and record its actual selected Lua route, effects and test evidence before advancing. If a phase is still blocked by a higher-priority correctness/safety issue, complete that gate rather than introducing speculative downstream content.

Phase 0 first vertical slice: weather/time gate used by one already-registered or newly registered contextual conversation flow, tested in actual production worker. Before writing an adapter, locate the existing Blocks evaluator and see whether its public pure condition interface can be called; identify any semantic flow validation changes needed. Preserve parser/IR, older flows and their translations. A different interface is allowed only with a documented technical reason, stable compatibility and real-Lua proof.

Phases 1–3 build authoring usability early, because the user wants an agent/human to expand definitions without finding dozens of incidental Lua files. Phases 4–5 use the same editor/conditions to author one quest; they must not become an isolated quest-only harness. Phase 6 closes development without launching PZ or publishing Workshop content.

## Phase exit statuses

NOT STARTED -> IN PROGRESS -> IMPLEMENTED / NOT ACCEPTED -> ACCEPTED; alternatively genuine BLOCKED with evidence. A phase may preserve a lower-priority unrun native gate as USER-OWNED without preventing movement when the development product gap changes. No false "all passed" status. If all mandatory implementation gates accepted, stop as READY FOR USER LIVE TEST (later maintenance-ready), not invented feature work.
