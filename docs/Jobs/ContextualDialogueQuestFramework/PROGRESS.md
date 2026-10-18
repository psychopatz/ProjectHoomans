# Contextual Dialogue & Quest Framework — CURRENT progress

**Updated:** 2026-10-18, after local worker, regression, and X11 Semantic Lab verification of G0D-2.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`; code commits through `05c89bbd` (`feat: expose live capability coverage in Semantic Lab`). Earlier accepted slices remain `b1102486` (safe regeneration), `68c313fe` (multi-stage gifts), `b242e78c` (parameterized tasks), and `6290b3f74279731c7d80e97e077e88c10d35d676` (simple commands). Shared branch history also preserves unrelated concurrent P0B import-planner commit `72455cd1`.

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `d117d861730eaaf94c20e7b372c6ba37ac1f1b59`; PR #4 remains open/unmerged. The local implementation is intentionally ahead of that baseline.

**Current goal status:** **IN PROGRESS — G0D-2 accepted; remaining compatible capability families and later contextual, quest, and native-game gates remain open.**

**ONE Next Chunk:** **G0E — make the remaining compatible registered task capabilities metadata-complete and generate their production flows through the existing parameterized-task template, while retaining exact unsupported/conflicting coverage reasons.**

## Accepted historic foundation (do not redo)

The historical ledger remains preserved in `HISTORY_20261018.md`. It records the accepted weather/context gate, real Lua worker FOLLOW/STAY/WAIT_AT/GIFT dispatch through mocked authority, reviewed single-FOLLOW compiler EN/TL modular generation, source preview, and earlier source-approval/restart X11 testing. Those proofs remain valid infrastructure, but do not prove generic automatic flow population.

## G0A accepted — generic simple-command template

G0A implemented and verified one reusable metadata-driven `simple_command` template. The initial 15-capability inventory classified FOLLOW and STAY as generated; CAMP, CONSUME, DRINK, EAT, FETCH, GIVE, REFILL, WAIT_AT, and GIFT as unsupported for that template; GO and STOP as legacy; and HELP and TAKE as recognition-only. Metadata-incomplete, eligible, and conflicting counts were zero.

Generated IDs were `pnc.generated.simple_command.pnc.companion.follow` and `pnc.generated.simple_command.pnc.companion.stay`. Each exposed a context/authorization gate, typed capability binding, exactly one existing `PNC.Client.SendCompanionCommand` dispatch, queued/rejected/failed result transitions, and EN/TL response pools. `FLOW_GENERATE` and `FLOW_COVERAGE` used the existing Semantic Lab worker.

Real production traces covered PsychopatzCore IR → selected generated flow → authorization → typed request → existing command adapter → one mocked authoritative transport → result node → contextual NPC response. Authorized, denied, failed, missing-authorization, repeated preview, negated, question, and ambiguous-request cases were verified; preview remained effect-free and TL FOLLOW keys resolved.

The existing Tk Semantic Lab was operated through X11/XTest on an Xvfb desktop. Real pointer clicks opened Flow editor and selected generated FOLLOW and STAY rows; both graphs displayed authorization, typed action, and result edges. The user-provided screenshot showing only authored `greeting` was a stale/selected authored-flow view, not evidence that generated flows were absent; it predates worker reload or registry refresh. Project Zomboid SP/MP interaction and Workshop publication were not launched and remain user-owned acceptance boundaries.

## G0B accepted — generic parameterized-task template

G0B extended the same automatic generator with a reusable versioned `parameterized_task` template. Capability-owned metadata in the existing task adapter describes typed slots, context/authority gates, the existing `PNC.Client.RequestSemanticTask` handler, outcome mapping, and EN/TL responses. No parser, dispatcher, inventory handler, or arbitrary Lua execution path was added.

The live inventory then reported four generated capabilities: FOLLOW, STAY, FETCH, and WAIT_AT. Seven remained `unsupported_workflow`: CAMP, CONSUME, DRINK, EAT, GIVE, and REFILL lacked parameterized metadata while GIFT required its multi-stage template. GO and STOP remained legacy; HELP and TAKE remained recognition-only. Metadata-incomplete, eligible, and conflicting counts were zero.

Generated task IDs were `pnc.generated.parameterized_task.pnc.task.fetch` and `pnc.generated.parameterized_task.pnc.task.wait.at`. Both exposed `authorize → request → admitted → active → completed/rejected/failed`, typed slots, an `existing_semantic_task` binding to `PNC.Client.RequestSemanticTask`, and `dispatchCount=1`. WAIT_AT and FETCH worker traces covered EN, missing authorization, unresolved target, TL, restart, and deterministic cases while preserving domain-owned responses where required.

## G0C accepted — generic multi-stage gift template

G0C added the reusable `multi_stage_gift` template using existing gift authority. The live inventory reported five generated capabilities: FOLLOW, STAY, FETCH, WAIT_AT, and GIFT; six `unsupported_workflow` task-adapter actions: CAMP, CONSUME, DRINK, EAT, GIVE, and REFILL; two legacy capabilities GO and STOP; and two recognition-only capabilities HELP and TAKE. Metadata-incomplete, eligible, and conflicting counts were zero.

Generated gift ID: `pnc.generated.multi_stage_gift.pnc.gift.offer`. Its nodes are `authorize`, `request`, `selection_required`, `pending`, `completed`, `rejected`, and `failed`; `pending` is nonterminal and the result stages are terminal. The typed binding is `existing_inventory_transfer` → `PNC.Client.SendInventoryTransfer` with `dispatchCount=1`; result mappings cover selector, pending, completion, rejection, and failure outcomes.

Fresh worker traces verified an item-specific gift selecting the generated flow, reaching `pending`, using the existing binding once, emitting one client `InventoryTransfer` and one mocked authoritative `InventoryResult`, and producing exactly one contextual NPC reply. Vague gift reached `selection_required` with zero transport. Missing semantic authorization reached generated `rejected` before transfer with zero transport; the same gate resolved the generated TL rejection key. The production `ReceiveGiftResult` path applies authoritative success/failure to the stored generated pending flow, advancing it to `completed` or `failed` while preserving existing item-specific/preference-aware gift replies and duplicate protection.

## G0D accepted — safe regeneration and actionable coverage

The production Flow Registry exposes `ReplaceGenerated`. It revalidates generated definitions and replaces an existing flow only when both definitions carry the same workflow kind. Authored or mismatched flows cannot be silently overwritten. The automatic generator uses this path on regeneration and reports `regeneratedFlowIDs`; the manifest declares the `simple_command`, `parameterized_task`, and `multi_stage_gift` template families.

The Semantic Lab now reads live generation coverage from the worker, shows a bounded summary, renders exact per-capability classification/reason/flow-ID lines, exposes generated metadata in the graph model, and refuses authored registration of a generated flow under its regeneration-owned ID. Rename or duplicate is required before authored registration. This keeps visual editing useful while preserving the production registry’s collision guard.

The current live 15-capability coverage is:

- `generated` (5): FOLLOW, STAY, FETCH, WAIT_AT, GIFT.
- `unsupported_workflow` (6): CAMP, CONSUME, DRINK, EAT, GIVE, REFILL; each reports `task_adapter_requires_parameterized_task_template`.
- `legacy` (2): GO and STOP; each reports `registered_dispatch_route_has_no_versioned_generation_metadata`.
- `recognition_only` (2): HELP and TAKE; each reports `recognized_without_registered_dispatch_binding`.
- `metadata_incomplete`, `eligible`, and `conflicting`: 0.

The real X11/XTest path was exercised after reload: Flow editor showed `coverage generated=5/15`; a pointer click opened the coverage dialog with the exact reasons; a pointer click selected generated STAY and displayed its authorization/request/result graph; and a pointer click on Register draft displayed the regeneration-owned collision guard without registering an authored collision.

## Verification evidence

- Focused automatic/task/gift/editor/binding modules: 20/20 passed.
- Flow editor module after the coverage UI change: 7/7 passed.
- Full suite: `python3 -m unittest discover tools/semantic_harness/tests -v` — 132 tests, 128 passed. The four failures are the known pre-existing `ContextualSocialReactionTests.test_threat_uses_guarded_emotion_relationship_and_precedence` cases (`trusted`, `withdrawn`, `stressed`, and `stress_precedes_withdrawn_and_busy`), which exercise unavailable semantic-social transport fallback and are unrelated to automatic flow generation.
- Harness doctor: `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed required Python, repository, virtualenv, Tkinter, display, core repository, Lua, worker syntax, worker boot, and PING/CAPABILITIES checks.
- Touched Python files passed `py_compile`; prior changed Lua passed `luac5.3 -p`; generated EN/TL JSON parsed; and `git diff --check` passed.
- G0D-2 code commit: `05c89bbd` (`feat: expose live capability coverage in Semantic Lab`).

## Worktree boundary

The unrelated P0B persistence/import-plan work from another agent remains preserved in commit `72455cd1` outside this job’s implementation scope. No Project Zomboid process, multiplayer host, or Workshop publication was launched.

## Scope boundary

G0A, G0B, G0C, and G0D/G0D-2 are accepted implementation slices, not completion of all supported capability families. Do not mark the expanded goal READY FOR USER LIVE TEST until G0E and the later contextual/personality/memory, server-authoritative quest, full production-harness/performance, and user-owned native-game gates are actually verified.
