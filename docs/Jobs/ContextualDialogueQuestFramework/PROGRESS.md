# Contextual Dialogue & Quest Framework — CURRENT progress

**Updated:** 2026-10-18, after fresh local worker verification of G0B.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`, current commit `b242e78c` (parent G0A implementation `6290b3f74279731c7d80e97e077e88c10d35d676`, progress record `a5ff86bd`).

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `d117d861730eaaf94c20e7b372c6ba37ac1f1b59`; PR #4 remains open/unmerged. The local implementation is intentionally ahead of that baseline.

**Current goal status:** **IN PROGRESS — G0B accepted; the expanded automatic-generation goal remains open.**

**ONE Next Chunk:** **G0C — Generic multi-stage gift workflow generation: add a reusable lifecycle template for the registered `GIFT` capability, preserving explicit unsupported coverage until its metadata, stages, authority and result contract are implemented.**

## Accepted historic foundation (do not redo)

The historical ledger remains preserved in `HISTORY_20261018.md`. It records the accepted weather/context gate, real Lua worker FOLLOW/STAY/WAIT_AT/GIFT dispatch through mocked authority, reviewed single-FOLLOW compiler EN/TL modular generation, source preview, and earlier source-approval/restart X11 testing. Those proofs remain valid infrastructure, but they do not prove generic automatic flow population.

## G0A accepted evidence — generic simple-command template

G0A implemented and verified a metadata-driven `simple_command` template shared by registered FOLLOW and STAY capabilities. The real production Lua worker enumerates 15 registered semantic action capabilities and returns deterministic coverage rather than silently omitting actions:

- `generated` (2): `FOLLOW`, `STAY`.
- `unsupported_workflow` (9 at G0A): `CAMP`, `CONSUME`, `DRINK`, `EAT`, `FETCH`, `GIVE`, `REFILL`, `WAIT_AT` required the later parameterized-task template; `GIFT` required a multi-stage template.
- `legacy` (2): `GO`, `STOP`.
- `recognition_only` (2): `HELP`, `TAKE`.
- `metadata_incomplete`, `eligible`, and `conflicting`: 0.

Generated flow IDs were `pnc.generated.simple_command.pnc.companion.follow` and `pnc.generated.simple_command.pnc.companion.stay`. Each exposed a context/authorization gate, typed capability binding, exactly one existing `PNC.Client.SendCompanionCommand` dispatch, queued/rejected/failed result transitions, and EN/TL response pools. `FLOW_GENERATE` and `FLOW_COVERAGE` were exposed through the existing Semantic Lab worker. Generated modules, manifests and translations loaded from normal modular paths and survived worker restart with deterministic IDs and template fingerprints.

Real production traces covered PsychopatzCore IR → selected generated flow → authorization → typed request → existing command adapter → one mocked authoritative transport → result node → contextual NPC response. Authorized, denied, failed, missing-authorization, repeated preview, negated, question and ambiguous-request cases were verified; preview remained effect-free and TL FOLLOW keys resolved.

The existing Tk Semantic Lab was operated through X11/XTest on an Xvfb desktop. Real pointer clicks opened Flow editor and selected generated FOLLOW and STAY rows; both graphs displayed authorization, typed action and result edges. The user-provided screenshot showing only authored `greeting` is a stale/selected authored-flow view, not evidence that generated flows are absent; it predates worker reload or registry refresh. Project Zomboid SP/MP interaction and Workshop publication were not launched and remain user-owned acceptance boundaries.

## G0B accepted evidence — generic parameterized-task template

G0B extends the same automatic generator with a reusable versioned `parameterized_task` template. Capability-owned metadata in the existing task adapter now describes typed slots, context/authority gates, the existing `PNC.Client.RequestSemanticTask` handler, outcome mapping, and EN/TL responses. No parser, dispatcher, inventory handler, or arbitrary Lua execution path was added.

The live 15-capability inventory now reports:

- `generated` (4): `FOLLOW`, `STAY`, `FETCH`, `WAIT_AT`.
- `unsupported_workflow` (7): `CAMP`, `CONSUME`, `DRINK`, `EAT`, `GIVE`, `REFILL` are registered task-adapter actions without parameterized metadata; `GIFT` requires the multi-stage gift template.
- `legacy` (2): `GO`, `STOP`.
- `recognition_only` (2): `HELP`, `TAKE`.
- `metadata_incomplete`, `eligible`, and `conflicting`: 0.

The generated task flow IDs are `pnc.generated.parameterized_task.pnc.task.fetch` and `pnc.generated.parameterized_task.pnc.task.wait.at`. Both expose `authorize → request → admitted → active → completed/rejected/failed`, typed slot definitions, `existing_semantic_task` binding to `PNC.Client.RequestSemanticTask`, and `dispatchCount=1`. The real Flow Registry/Kernel selects the generated flow and applies authoritative result mappings; synchronous task-specific responses remain authoritative for unresolved targets and other domain-owned rejection reasons, so generated and legacy responses are not duplicated.

Fresh worker traces verified:

- `Wait at the campfire` produced generated `parameterized_task` flow `pnc:task.wait_at`, one task transport, result node `admitted`, and exactly one response: `Okay, I'll wait there.`
- `Bring me the can opener` produced generated `parameterized_task` flow `pnc:task.fetch`, one task transport, result node `admitted`, and exactly one response: `I'll fetch that.`
- Mocked WAIT_AT rejection and failure selected the generated `rejected` and `failed` nodes with their contextual EN responses. Missing semantic authorization reached `rejected` before dispatch with zero transport. An unresolved target retained the existing contextual response `I can't find that place nearby.` exactly once.
- Generated task EN/TL response pools were registered from `common/media/translation/{EN,TL}/Conversation/Semantic/Generated.json`; worker restart and deterministic regeneration were verified.

## Verification evidence

- Focused G0A/G0B suite: `python3 -m unittest tools.semantic_harness.tests.test_automatic_flow_generation tools.semantic_harness.tests.test_flow_editor tools.semantic_harness.tests.test_follow_action_binding tools.semantic_harness.tests.test_stay_wait_at_binding -v` — 18/18 passed.
- Full suite: `python3 -m unittest discover tools/semantic_harness/tests -v` — 130 tests, 126 passed. The only four failures are the pre-existing `ContextualSocialReactionTests.test_threat_uses_guarded_emotion_relationship_and_precedence` cases `trusted`, `withdrawn`, `stressed`, and `stress_precedes_withdrawn_and_busy`; they report the known unavailable semantic-social transport fallback and are unrelated to automatic flow generation.
- Harness doctor: `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — required Python, repository, virtualenv, Tkinter, display, core repository, Lua, worker syntax, worker boot, PING and CAPABILITIES checks passed.
- `luac5.3 -p` passed for every changed Lua file; touched Python files compiled with `py_compile`; `git diff --check` passed.
- Code commit: `b242e78c` (`feat: generate parameterized task flows from task metadata`).

## Scope boundary

G0A and G0B are accepted implementation slices, not completion of all supported capability families. The next bounded chunk is G0C above. Do not mark the expanded goal READY FOR USER LIVE TEST until gift, all-compatible coverage/regeneration, visual editing, contextual/personality/memory integration, server-authoritative quest generation, full production-harness acceptance, performance checks, and the remaining user-owned native-game gate are actually verified.
