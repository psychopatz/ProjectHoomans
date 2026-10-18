# Contextual Dialogue & Quest Framework — CURRENT progress

**Updated:** 2026-10-18, after fresh local worker verification of the G0D safe-regeneration sub-slice.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`, current commit `b1102486` (G0D safe regeneration; G0C `68c313fe`; G0B `b242e78c`; G0A `6290b3f74279731c7d80e97e077e88c10d35d676`).

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `d117d861730eaaf94c20e7b372c6ba37ac1f1b59`; PR #4 remains open/unmerged. The local implementation is intentionally ahead of that baseline.

**Current goal status:** **IN PROGRESS — G0D safe-regeneration sub-slice accepted; automatic coverage/reporting and visual-editing work remains open.**

**ONE Next Chunk:** **G0D-2 — Make remaining capability coverage actionable in Semantic Lab: expose exact metadata gaps/conflicts and add production-registry-backed visual editing/regeneration checks without allowing authored/generated collisions.**

## Accepted historic foundation (do not redo)

The historical ledger remains preserved in `HISTORY_20261018.md`. It records the accepted weather/context gate, real Lua worker FOLLOW/STAY/WAIT_AT/GIFT dispatch through mocked authority, reviewed single-FOLLOW compiler EN/TL modular generation, source preview, and earlier source-approval/restart X11 testing. Those proofs remain valid infrastructure, but they do not prove generic automatic flow population.

## G0A accepted — generic simple-command template

G0A implemented and verified one metadata-driven `simple_command` template shared by registered FOLLOW and STAY capabilities. The real production Lua worker enumerated 15 registered semantic action capabilities and returned deterministic coverage rather than silently omitting actions:

- `generated` (2): `FOLLOW`, `STAY`.
- `unsupported_workflow` (9 at G0A): `CAMP`, `CONSUME`, `DRINK`, `EAT`, `FETCH`, `GIVE`, `REFILL`, `WAIT_AT` required the later parameterized-task template; `GIFT` required a multi-stage template.
- `legacy` (2): `GO`, `STOP`.
- `recognition_only` (2): `HELP`, `TAKE`.
- `metadata_incomplete`, `eligible`, and `conflicting`: 0.

Generated IDs were `pnc.generated.simple_command.pnc.companion.follow` and `pnc.generated.simple_command.pnc.companion.stay`. Each exposed a context/authorization gate, typed capability binding, exactly one existing `PNC.Client.SendCompanionCommand` dispatch, queued/rejected/failed result transitions, and EN/TL response pools. `FLOW_GENERATE` and `FLOW_COVERAGE` were exposed through the existing Semantic Lab worker. Generated modules, manifests and translations loaded from normal modular paths and survived worker restart with deterministic IDs and fingerprints.

Real production traces covered PsychopatzCore IR → selected generated flow → authorization → typed request → existing command adapter → one mocked authoritative transport → result node → contextual NPC response. Authorized, denied, failed, missing-authorization, repeated preview, negated, question and ambiguous-request cases were verified; preview remained effect-free and TL FOLLOW keys resolved.

The existing Tk Semantic Lab was operated through X11/XTest on an Xvfb desktop. Real pointer clicks opened Flow editor and selected generated FOLLOW and STAY rows; both graphs displayed authorization, typed action and result edges. The user-provided screenshot showing only authored `greeting` is a stale/selected authored-flow view, not evidence that generated flows are absent; it predates worker reload or registry refresh. Project Zomboid SP/MP interaction and Workshop publication were not launched and remain user-owned acceptance boundaries.

## G0B accepted — generic parameterized-task template

G0B extended the same automatic generator with a reusable versioned `parameterized_task` template. Capability-owned metadata in the existing task adapter describes typed slots, context/authority gates, the existing `PNC.Client.RequestSemanticTask` handler, outcome mapping, and EN/TL responses. No parser, dispatcher, inventory handler, or arbitrary Lua execution path was added.

The live 15-capability inventory reported:

- `generated` (4): `FOLLOW`, `STAY`, `FETCH`, `WAIT_AT`.
- `unsupported_workflow` (7): `CAMP`, `CONSUME`, `DRINK`, `EAT`, `GIVE`, `REFILL` lacked parameterized metadata; `GIFT` required the multi-stage gift template.
- `legacy` (2): `GO`, `STOP`.
- `recognition_only` (2): `HELP`, `TAKE`.
- `metadata_incomplete`, `eligible`, and `conflicting`: 0.

Generated task IDs were `pnc.generated.parameterized_task.pnc.task.fetch` and `pnc.generated.parameterized_task.pnc.task.wait.at`. Both exposed `authorize → request → admitted → active → completed/rejected/failed`, typed slots, `existing_semantic_task` binding to `PNC.Client.RequestSemanticTask`, and `dispatchCount=1`. WAIT_AT and FETCH worker traces each used one task transport and the correct generated EN response; denied, failed, missing-authorization, unresolved-target, TL and restart/deterministic cases were verified. Existing domain-owned task responses remained authoritative where required, preventing duplicate replies.

## G0C accepted — generic multi-stage gift template

G0C added a reusable versioned `multi_stage_gift` template to the shared automatic generator and completed metadata on the existing `pnc:gift.offer` capability. The existing lifecycle remains authoritative: selection is owned by `GiftSelection`, dispatch by `PNC.Client.SendInventoryTransfer`, server validation/transfer by the inventory authority, and contextual success/failure/relationship replies by the existing gift receiver. The generator observes and progresses that route; it does not create a second gift dispatcher.

The live worker’s 15-capability inventory now reports:

- `generated` (5): `FOLLOW`, `STAY`, `FETCH`, `WAIT_AT`, `GIFT`.
- `unsupported_workflow` (6): `CAMP`, `CONSUME`, `DRINK`, `EAT`, `GIVE`, `REFILL` are registered task-adapter actions without the required parameterized metadata.
- `legacy` (2): `GO`, `STOP`.
- `recognition_only` (2): `HELP`, `TAKE`.
- `metadata_incomplete`, `eligible`, and `conflicting`: 0.

Generated gift ID: `pnc.generated.multi_stage_gift.pnc.gift.offer`. Its nodes are `authorize`, `request`, `selection_required`, `pending`, `completed`, `rejected`, and `failed`; `pending` is a nonterminal lifecycle stage, while the other result stages are terminal. The typed binding is `existing_inventory_transfer` → `PNC.Client.SendInventoryTransfer` with `dispatchCount=1`, and result mappings cover selector, pending, completion, rejection and failure outcomes.

Fresh worker traces verified `I want to give you an apple` selecting the generated flow, reaching `pending`, using the existing binding once, emitting one client `InventoryTransfer` and one mocked authoritative `InventoryResult`, and producing exactly one contextual NPC reply: `Thank you for the Apple.` The vague gift path reached `selection_required` with zero transport. Missing semantic authorization reached generated `rejected` before transfer with zero transport; the same gate resolved the generated TL rejection key. The production `ReceiveGiftResult` path now applies authoritative success/failure to the stored generated pending flow, advancing it to `completed` or `failed` while preserving the existing item-specific/preference-aware gift reply and duplicate protection.

## G0D safe-regeneration sub-slice accepted

The production Flow Registry now exposes `ReplaceGenerated`, which revalidates a generated definition and replaces an existing flow only when both definitions carry the same workflow kind. An authored or otherwise mismatched flow cannot be silently overwritten. The automatic generator uses this path on regeneration and reports `regeneratedFlowIDs`; the manifest now declares `simple_command`, `parameterized_task`, and `multi_stage_gift` template families.

Real worker `FLOW_GENERATE` called twice after all five generated flows were registered. Both calls returned the same generated flow IDs and replaced only matching generated definitions; no duplicate flow IDs were created. Registry validation, generated response registration, and deterministic coverage remained intact. The broader coverage/actionability and visual-editing portion is deliberately left as the single next chunk above.

## Verification evidence

- Focused automatic/task/gift/editor/binding suite: 21/21 passed.
- Full suite after G0D: `python3 -m unittest discover tools/semantic_harness/tests -v` — 131 tests, 127 passed. The only four failures are the pre-existing `ContextualSocialReactionTests.test_threat_uses_guarded_emotion_relationship_and_precedence` cases `trusted`, `withdrawn`, `stressed`, and `stress_precedes_withdrawn_and_busy`; they report the known unavailable semantic-social transport fallback and are unrelated to automatic flow generation.
- Harness doctor: `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — required Python, repository, virtualenv, Tkinter, display, core repository, Lua, worker syntax, worker boot, PING and CAPABILITIES checks passed.
- `luac5.3 -p` passed for every changed G0D Lua file; touched Python files compiled with `py_compile`; generated EN/TL JSON files parse; `git diff --check` passed.
- G0D code commit: `b1102486` (`feat: make generated flow regeneration safe`).

## Worktree boundary

Unrelated P0B persistence/import-plan edits from another agent are present as unstaged/untracked files and were deliberately preserved, not included in the G0D commit. They are not a blocker to continuing this job.

## Scope boundary

G0A, G0B, G0C, and the G0D safe-regeneration sub-slice are accepted implementation slices, not completion of all supported capability families. Do not mark the expanded goal READY FOR USER LIVE TEST until G0D-2, contextual/personality/memory integration, server-authoritative quest generation, full production-harness acceptance, performance checks, and the user-owned native-game gate are actually verified.
