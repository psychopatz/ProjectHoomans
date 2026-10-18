# Contextual Dialogue & Quest Framework — CURRENT progress

**Updated:** 2026-10-18 after fresh local implementation and worker verification.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`, commit `6290b3f74279731c7d80e97e077e88c10d35d676`.

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `d117d861730eaaf94c20e7b372c6ba37ac1f1b59`; PR #4 remains open/unmerged. The local implementation is intentionally ahead of that baseline.

**Current goal status:** **IN PROGRESS — G0A accepted; expanded automatic-generation goal remains open.**

**ONE Next Chunk:** **G0B — Generic parameterized task generation: generate WAIT_AT and one additional compatible task capability through a reusable task template.**

## Accepted historic foundation (do not redo)

The historical ledger remains preserved in `HISTORY_20261018.md`. It records the accepted weather/context gate, real Lua worker FOLLOW/STAY/WAIT_AT/GIFT dispatch through mocked authority, reviewed single-FOLLOW compiler and EN/TL modular generation, source preview, and earlier source-approval/restart X11 testing. Those proofs remain valid infrastructure but did not prove generic automatic flow population.

## G0A accepted evidence

### Live capability inventory and generation

The real production Lua worker enumerates 15 registered semantic action capabilities and reports deterministic coverage:

- `generated` (2): `FOLLOW`, `STAY`.
- `unsupported_workflow` (9): `CAMP`, `CONSUME`, `DRINK`, `EAT`, `FETCH`, `GIVE`, `REFILL`, and `WAIT_AT` are `task_adapter_requires_parameterized_task_template`; `GIFT` is `gift_lifecycle_requires_multi_stage_template`.
- `legacy` (2): `GO`, `STOP` — `registered_dispatch_route_has_no_versioned_generation_metadata`.
- `recognition_only` (2): `HELP`, `TAKE` — `recognized_without_registered_dispatch_binding`.
- `eligible`, `metadata_incomplete`, and `conflicting`: zero in this live catalog; no capability is silently omitted.

Generated stable flow IDs are `pnc.generated.simple_command.pnc.companion.follow` and `pnc.generated.simple_command.pnc.companion.stay`. Both are built by the same `simple_command:v1` template fingerprint, with context authorization gates, typed slots/bindings, exactly one dispatch declaration, queued/rejected/failed result mapping, and EN/TL response pools.

### Production source and restart persistence

The worker’s loaded manifest proves the modular paths:

- `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticAutomaticFlowGenerator.lua`
- `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticAutomaticFlowManifest.lua`
- `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticGeneratedAutomaticFlows.lua`
- `Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/Generated.json`
- `Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Semantic/Generated.json`

Fresh worker restart preserves the same generated flow IDs and template fingerprint. `FLOW_GENERATE` is exposed in the existing Semantic Lab worker; `FLOW_COVERAGE` returns the complete live classification report.

### Real production turn traces

- `Follow me` and `Stay here`: PsychopatzCore IR → selected generated flow → `authorize:onPass` → typed request node → existing `PNC.Client.SendCompanionCommand` binding → one mocked authoritative transport → `queued` result node → generated contextual EN response. The corresponding command IDs are `follow` and `stay`, with capability IDs `pnc:companion.follow` and `pnc:companion.stay`.
- Denied authority takes the generated `rejected` result branch and returns the generated rejection text; the transport remains the single existing approved dispatch.
- A mocked failed authority result takes the generated `failed` result branch and returns the generated failure text.
- Missing semantic authorization fails the generated context gate before dispatch, produces no transport, and returns the generated rejection response.
- TL resolution was verified for generated FOLLOW, including `UI_PNC_Conversation_Semantic_GeneratedFollowQueued` and `UI_PNC_Conversation_Semantic_GeneratedFollowRejected`.
- Repeated preview is effect-free: no transport or tool calls. Negated FOLLOW resolves to STOP, question and ambiguous FOLLOW stay on clarification with no FOLLOW transport.

### Semantic Lab and verification

The existing Tk Semantic Lab was operated through X11/XTest on an Xvfb desktop: the Flow editor was opened with a real pointer click, the generated FOLLOW and STAY rows were selected, and both generated graphs displayed their authorization, typed action, and result edges. The earlier screenshot showing only `greeting` was a stale/selected authored-flow view; it predates the worker reload or did not refresh the registry. Native Project Zomboid SP/MP interaction and Workshop publication remain user-owned and were not launched.

Verification evidence:

- `python3 -m unittest discover tools/semantic_harness/tests -v`: 128 tests run, 124 pass; the only four failures are the pre-existing `ContextualSocialReactionTests.test_threat_uses_guarded_emotion_relationship_and_precedence` cases `trusted`, `withdrawn`, `stressed`, and `stress_precedes_withdrawn_and_busy`. No G0A test failed.
- `python3 -m unittest tools.semantic_harness.tests.test_automatic_flow_generation -v`: 4/4 pass.
- Fresh Lua worker, restart/regeneration, EN/TL, source manifest, coverage, authorized/denied/failed/gated, preview, graph, and existing-flow regression tests pass.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json`: all required checks pass, including worker boot/PING/CAPABILITIES.
- `luac5.3 -p` passes for all changed/new Lua files; `git diff --check` passes.

## Scope boundary

G0A is accepted as a generic simple-command slice, not as completion of all supported capability families. G0B is the single next chunk; do not mark the expanded goal READY FOR USER LIVE TEST until later task, gift, coverage/regeneration, contextual, quest, authority, performance, and remaining acceptance gates are actually verified.
