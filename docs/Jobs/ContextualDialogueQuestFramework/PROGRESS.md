# Contextual Dialogue & Quest Framework — current progress

**Updated:** 2026-10-18, after the G0F worker, regression, manifest, and X11 Semantic Lab verification.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`; code is committed through `b5123d0c` (`feat: select generated responses from social context`). Earlier accepted slices remain `0cfcc345` (all dispatchable actions), `b1102486` (safe regeneration), `68c313fe` (multi-stage gifts), `b242e78c` (parameterized tasks), and `6290b3f74279731c7d80e97e077e88c10d35d676` (simple commands). Shared branch history also preserves unrelated concurrent P0B import-planner commit `72455cd1`.

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `d117d861730eaaf94c20e7b372c6ba37ac1f1b59`; PR #4 remains open and unmerged. The local implementation is intentionally ahead of that baseline.

**Current goal status:** **IN PROGRESS — G0F accepted; memory, server-authoritative quest, full production-harness/performance, and native-game gates remain open.**

**ONE Next Chunk:** **G0G — thread bounded conversation-memory facts into generated response-pool selection without inventing facts or changing action/result ownership.**

## Accepted historic foundation (do not redo)

The historical ledger remains preserved in `HISTORY_20261018.md`. It records accepted weather/context gates, the real Lua worker, existing FOLLOW/STAY/WAIT_AT/GIFT dispatch through mocked authority, the compiler-authored FOLLOW flow, and prior X11/UI evidence. Native Project Zomboid SP/MP interaction and Workshop publication remain user-owned boundaries.

## G0A accepted — generic simple-command template

The implementation discovered registered companion-command metadata and generated FOLLOW and STAY from one reusable `simple_command` template. The generated flows contain context/authorization gates, typed capability bindings, exactly one existing `PNC.Client.SendCompanionCommand` dispatch, queued/rejected/failed transitions, and EN/TL response pools. PsychopatzCore produced the semantic IR and the production Flow Registry/Kernel selected and progressed the generated flow.

Real worker traces covered authorized, denied, failed, missing-authorization, repeated preview, negated, question, and ambiguous-request cases. Preview remained effect-free and TL FOLLOW keys resolved. The existing Tk Semantic Lab was operated through X11/XTest on an Xvfb desktop: real pointer clicks opened Flow editor, selected generated FOLLOW/STAY rows, and displayed authorization, typed action, and result edges. The attached screenshot showing only authored `greeting` was a stale/selected authored-flow view before worker reload or registry refresh; it was not evidence that generated flows were absent.

## G0B accepted — generic parameterized-task template

The same metadata-driven generator produced WAIT_AT and FETCH through the existing `PNC.Client.RequestSemanticTask` binding. Typed target/item slots, authority gates, admission/active/completed/rejected/failed transitions, EN/TL responses, and one-dispatch behavior were verified with the real production worker. Domain-owned task result presentation remained authoritative, preventing duplicate response lines.

## G0C accepted — generic multi-stage gift template

The generator produced `pnc.generated.multi_stage_gift.pnc.gift.offer` from the registered gift metadata. Its nodes are `authorize`, `request`, `selection_required`, `pending`, `completed`, `rejected`, and `failed`; `pending` is nonterminal and result stages are terminal. The typed binding is `existing_inventory_transfer` → `PNC.Client.SendInventoryTransfer` with `dispatchCount=1`.

Fresh worker traces verified item-specific selection, pending transfer, one client `InventoryTransfer`, one mocked authoritative `InventoryResult`, completion/failure progression, vague-gift clarification with zero transport, missing-authorization rejection with zero transport, TL rejection, and duplicate protection. Existing item-specific and preference-aware gift replies remain the result owner.

## G0D accepted — safe regeneration and actionable coverage

The production Flow Registry exposes `ReplaceGenerated`. It revalidates generated definitions and replaces an existing flow only when both definitions have the same workflow kind. Authored or mismatched flows cannot be silently overwritten. Automatic regeneration reports sorted `regeneratedFlowIDs` and the manifest declares the `simple_command`, `parameterized_task`, and `multi_stage_gift` templates.

Semantic Lab reads live worker coverage, shows bounded summary counts, renders exact per-capability classification/reason/flow-ID lines, exposes generated metadata in the graph model, and refuses authored registration of a generated flow under its regeneration-owned ID. Rename or duplicate is required before authored registration.

## G0E accepted — all currently dispatchable registered actions generated

Existing command and task descriptors were extended with explicit versioned metadata; no parser, interpreter, dispatcher, inventory handler, or arbitrary Lua execution path was added. The generator now emits five `simple_command` flows (FOLLOW, STAY, GO HOME, STOP, CAMP), seven `parameterized_task` flows (FETCH, WAIT_AT, GIVE, EAT, DRINK, REFILL, CONSUME), and the existing generated multi-stage GIFT flow.

The live 15-capability coverage is:

- `generated` (13): `pnc:companion.follow`, `pnc:companion.stay`, `pnc:companion.go_home`, `pnc:companion.stop`, `pnc:companion.camp`, `pnc:task.fetch`, `pnc:task.wait_at`, `pnc:task.give`, `pnc:task.eat`, `pnc:task.drink`, `pnc:task.refill`, `pnc:task.consume`, and `pnc:gift.offer`.
- `recognition_only` (2): HELP and TAKE, exact reason `recognized_without_registered_dispatch_binding`.
- `metadata_incomplete`, `eligible`, `conflicting`, `unsupported_workflow`, and `legacy`: 0.

The generator retains exact coverage rows and does not silently omit capabilities. The live worker reports `total=15`, `generated=13`, `unsupported_workflow=0`, `legacy=0`, and `recognition_only=2`.

Real worker action traces covered CAMP, GO, STOP, GIVE, EAT, DRINK, REFILL, and CONSUME. Each selected a generated production flow, used its existing typed handler (`PNC.Client.SendCompanionCommand` or `PNC.Client.RequestSemanticTask`), dispatched once through the existing transport, and produced a contextual NPC response. Denied and failed task results reached generated rejected/failed nodes; semantic authorization denial stopped before transport; repeated preview stayed effect-free; and TL responses resolved from the new modular `GeneratedTaskCommands.json` files. The existing domain-specific task/CAMP result presenters remain authoritative when they provide a result response, so generation does not double-speak.

The response catalog capacity was increased from 64 to a still-bounded 128 pools because automatic generation registers one bounded pool per result outcome for every compatible capability. The automatic-flow manifest and Conversation translation manifest both include the modular EN/TL task-command files. Regeneration remains restart-persistent and deterministic.

## G0F accepted — relationship and personality response selection

The reusable generator now accepts optional reviewed response variants in capability metadata. It copies their bounded `when` conditions and priorities into the existing response catalog; it does not add parser branches or effect dispatch. The registered simple-command descriptors expose friendly, trusted-relationship, and withdrawn variants for the queued response of FOLLOW, STAY, STOP, GO HOME, and CAMP.

The real worker selected distinct FOLLOW responses for friendly personality, trusted relationship, and withdrawn personality. The same generated flow retained `resultOutcome=queued`, `dispatchCount=1`, and one existing command transport in all cases. EN/TL context keys are in separate modular translation files and are present in both the Conversation manifest and automatic-flow manifest. Existing task/CAMP result presenters still win when they own an authoritative result response.

## Verification evidence

- Focused automatic/task/gift/editor/binding checks: **23/23 passed**.
- Full suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py'` — **133 tests, 129 passed**. The four failures are the known pre-existing `ContextualSocialReactionTests.test_threat_uses_guarded_emotion_relationship_and_precedence` cases (`trusted`, `withdrawn`, `stressed`, and `stress_precedes_withdrawn_and_busy`), which exercise unavailable semantic-social transport fallback and are unrelated to automatic flow generation.
- Harness doctor: `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tkinter/display, core repository, Lua, worker syntax, worker boot, and PING/CAPABILITIES checks.
- Touched Lua passed `luac5.3 -p`; touched Python passed `py_compile`; generated EN/TL JSON parsed; and `git diff --check` passed.
- X11/XTest evidence used real pointer motion/button events against the Tk Semantic Lab. It is distinct from invoking Tk callbacks programmatically. No repeated CUA probing was needed.
- No Project Zomboid process, multiplayer hosting, mod installation, or Steam Workshop publication was launched.

## Scope boundary

G0A, G0B, G0C, G0D/G0D-2, G0E, and G0F are accepted implementation slices, not completion of the expanded goal. Do not mark the expanded goal READY FOR USER LIVE TEST until the later memory/context, server-authoritative quest, full production-harness/performance, and user-owned native-game gates are actually verified.
