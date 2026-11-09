# P1-A move matrix — Semantic Harness

This is a classification artifact, not a deletion list. The source tree and
callers remain authoritative; every move requires import-zero and behavior
gates before the adopter copy is removed.

## Already Core-backed compatibility paths

| Hoomans path | Current truth | Core authority | Remaining work |
| --- | --- | --- | --- |
| `tools/semantic_harness/runtime/process.py` | Compatibility adapter | `psychopatzCore/tools/semantic_harness/process.py` | Migrate remaining callers, then remove the façade |
| `tools/semantic_harness/runtime/protocol.py` | Compatibility re-export | `psychopatzCore/tools/semantic_harness/protocol.py` | Keep only while callers migrate |
| `tools/semantic_harness/runtime/worker_session.py` | Compatibility re-export | `psychopatzCore/tools/semantic_harness/worker_session.py` | Keep only while callers migrate |
| `tools/semantic_harness/runtime/scenario.py` | Mixed façade: Core helpers plus Hoomans defaults/validation | `psychopatzCore/tools/semantic_harness/scenario.py` | Extract generic document helpers; retain adopter defaults and policy |

These paths are not second implementations of the process/protocol/session
kernel anymore, but their import paths and Hoomans-facing tests remain.

## First safe Lua kernel extraction

| Hoomans source | Classification | First test gate | Target |
| --- | --- | --- | --- |
| `tools/semantic_harness/lua/worker/RuntimeState.lua` | Provider-neutral bounded worker containers with a few Hoomans extension fields | `tests/pnc_semantic_harness_worker_modules_smoke.lua` | Core worker runtime-state module with extension buckets; Hoomans supplies provider state |
| `tools/semantic_harness/lua/worker/Values.lua` | Provider-neutral bounded/production copy and scalar helpers | `tests/pnc_semantic_harness_worker_modules_smoke.lua` plus Core Lua smoke | Core worker value utility |
| `tools/semantic_harness/lua/worker/TransportEvidence.lua` | Mixed: generic partitioning, but currently reads `PNC.Const` | focused transport/projection tests | Core transport contract plus an adopter command-classification callback |

`RuntimeState.lua` and `Values.lua` are the first implementation candidates.
They have no gameplay authority and can be moved without moving the
Hoomans-specific production module graph.

## Mixed seams requiring an adapter contract first

| Hoomans family | Why it is not a direct move |
| --- | --- |
| `ScenarioSession*.lua` | Lifecycle and projection mechanics are reusable, but payloads and rehydration directly expose Hoomans/PNC records. |
| `Conversation*.lua` | Session/view mechanics are reusable, while production conversation policy, identity, relationship, and response catalogs are Hoomans-owned. |
| `OutputProjection*.lua` | Response shaping is generic in outline, but action labels and transport evidence currently encode Hoomans command semantics. |
| `CommandRouter*.lua` | Dispatch plumbing is reusable, but the command catalog and handlers are provider policy and authoring surface. |
| `RuntimeEnvironment*.lua` | It crosses Project Zomboid engine, packaged-file, and Core actor boundaries. |

These families move only after Core defines typed capability callbacks and a
provider-neutral payload schema. They are not part of the first deletion gate.

## Adopter-owned for now

Keep these in Project Hoomans until their policy is represented by Core
capabilities rather than copied implementation:

- `ProductionModules*.lua` and `ProductionRehydration*.lua`;
- `SemanticAdapters*.lua` and Hoomans relationship/knowledge/identity wiring;
- `InventoryFixtures.lua`, `FlowEditor.lua`, and `InteractionEditor.lua`;
- combat/scene observatories, translations, commitments, and Hoomans-specific
  command handlers;
- Hoomans runtime UI/authoring modules and provider acceptance tests.

DynamicTrading is an adopter, not a second harness target. Its current
DTCommon/DTAbstract/DTHoomans provider modules and tests must register against
the Core capability contracts in a later adapter phase; no DynamicTrading
worker tree is deleted by P1-A.

## P1-A acceptance

- Core process/protocol/session delegation is confirmed by source inspection.
- Hoomans has no duplicate Lua protocol implementation.
- The first safe extraction boundary is limited to `RuntimeState` and `Values`.
- Mixed policy families are explicitly deferred behind capability contracts.
- No source or test file was deleted during classification.
