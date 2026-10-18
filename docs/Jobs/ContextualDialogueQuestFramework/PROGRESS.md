# Contextual Dialogue & Quest Framework — current progress

**Updated:** 2026-10-19, after the G3B generated quest wiring, Lua regressions, real-worker and X11/Tk verification.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`; implementation is committed through the current G3B commit (generated Clinic Supplies semantic flows and existing quest transport), following `77300f59` (G0I stale scoped-cognition rejection). Earlier accepted slices remain `0cfcc345` (all dispatchable actions), `b1102486` (safe regeneration), `68c313fe` (multi-stage gifts), `b242e78c` (parameterized tasks), and `6290b3f74279731c7d80e97e077e88c10d35d676` (simple commands). Shared branch history also preserves unrelated concurrent P0B import-planner commits.

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `d117d861730eaaf94c20e7b372c6ba37ac1f1b59`; PR #4 remains open and unmerged. The local implementation is intentionally ahead of that baseline.

**Current goal status:** **IN PROGRESS — G3B accepted; full production-harness/performance and user-owned native-game gates remain open.**

**ONE Next Chunk:** **G3C — exercise generated quest flows through the real client/server semantic command boundary and worker restart/reload, preserving one authoritative result per request.**

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

## G0G accepted — bounded previous-action memory

The existing `semanticDialogueContext.recentTurns` state now supplies a bounded `previousAction` selector fact. The resolver skips the current player sequence before selecting a repeated generated-command variant, so a current-action echo cannot masquerade as memory. The response catalog exposes the existing last-intent/action/speaker fields without changing dispatch ownership.

Real worker traces verified first FOLLOW uses the reviewed withdrawn response and the second FOLLOW selects the reviewed repeated response. Both turns still selected the same generated flow, queued through one existing command handler, dispatched once, and used one transport. EN/TL memory translation assets are modular and declared by both manifests.

## G0H accepted — authoritative cognition and gossip memory

The response catalog now exposes a factual `memoryAvailable` condition derived only from the bounded `npcGossip.statements` projection. The existing cognition request/payload seam is loaded in the real Lua worker; the harness supplies only scenario-owned authoritative test evidence through `PNC.Client.RequestSemanticCognition` and the existing server-to-client `SemanticCognition` payload path. No client-side fact or alternate dispatcher was added.

EN and TL worker traces verified registered gossip code `1001` renders the authoritative memory statement, selects `semantic.gossip.memory`, and records one cognition request plus one server-to-client event. With no configured cognition evidence, the same request remains `semantic.gossip.unknown` and emits no cognition transport. The existing target/request matching and bounded gossip-code validation remain in force.

## G0I accepted — target-scoped cognition freshness

Semantic cognition responses now carry the requested target ID through the existing server-to-client envelope. The real client rejects a pending response with a stale request ID or mismatched/missing target before merging its projection or gossip, clears the pending request, and preserves a bounded rejection reason for the existing dialogue completion path. No client-side memory fact is created.

The real Lua worker fixture supports expected target IDs plus deliberately stale response request/target IDs. Worker traces verified the same target ID across a repeated request after an NPC rename, unavailable target mismatch with no cognition transport, and a stale response target that falls back to `semantic.gossip.unknown` without the old statement. Lua smoke tests also cover stale request IDs and matching request IDs crossing target scopes. The change is limited to existing cognition transport/correlation and does not add a parser or dispatcher.

## G3A accepted — server-owned Clinic Supplies quest contract

The first bounded quest slice now uses a versioned data-only `pnc.quest.clinic_supplies` definition and a server-only compact ModData repository. Instances are scoped by character identity, quest ID, and giver NPC ID; revisions, source medical-task IDs, objective progress, reward IDs, terminal status, and reward-claim dedupe survive reload without storing native objects, inventories, or transcripts. Unknown definitions quarantine instead of being improvised.

`QuestService.OfferQuest` and `AcceptQuest` revalidate the live giver and the existing `MedicalCareService` missing-bandage supply task. `ServerInventory.Transfer` emits the existing task-event-bus seam only after an authoritative player-to-NPC item mutation commits. The quest subscriber accepts only a committed, character-scoped, giver-scoped `Base.Bandage` transfer tied to the source medical task; free-text claims, wrong-character evidence, stale scope, and repeated transfer events do not advance it. Turn-in transitions `READY_TO_TURN_IN` → `COMPLETED` → `REWARDED`, emits the authored dialogue-acknowledgement reward event, and is idempotent across repeats and reloads. No quest VM, parser, inventory mutation, or second dispatcher was introduced.

## G3B accepted — generated Clinic Supplies semantic wiring

The existing metadata-driven `simple_command` generator now discovers and registers `HELP`, `QUEST_ACCEPT`, `QUEST_STATUS`, and `QUEST_TURN_IN` for the server-owned Clinic Supplies contract. All four use the reusable production template, typed `existing_quest_contract` binding, one authoritative quest request, queued/rejected/failed flow outcomes, and modular EN/TL response pools. Live coverage is **17 generated / 18 registered capabilities**, with one explicit recognition-only capability and no metadata-incomplete, conflicting, or unsupported generated quest row.

The real production Lua worker verified input → PsychopatzCore IR → generated flow → typed binding → mocked authoritative result → one NPC response for offer, accept, status, and turn-in. Available, accepted, active, and rewarded results; denied/failed responses; preview-only and repeated-request behavior; EN/TL fallbacks; client/server command envelopes; worker restart-safe catalog loading; and bounded handshake/catalog payloads are covered. The existing Semantic Lab was operated through X11 pointer/button events: Flow editor, Refresh registry, Coverage (`22 production flows loaded`, `coverage generated=17/18`), and Compile source preview (`valid; no files written`, seven planned paths) all completed. This is real mouse-event evidence, not programmatic callback equivalence.

## Verification evidence

- G3B focused semantic generation/worker suite: `python3 -m unittest tools.semantic_harness.tests.test_quest_flow_binding tools.semantic_harness.tests.test_automatic_flow_generation tools.semantic_harness.tests.test_flow_editor tools.semantic_harness.tests.test_gift_capability_binding -q` — **25/25 passed**. The broader automatic-flow, translation, and harness regression slice passed **36/36**; authoritative quest service smoke `python3 tests/run_tests.py pnc_quest_service_smoke --verbose` passed **1/1**.
- G3B source checks: `pz_verify --kahlua --severity ERROR` passed all touched mod Lua files; the only harness Lua finding is the intentional worker `dofile()` sandbox warning outside the PZ mod scan. `luac5.3 -p` passed all touched Lua files. `git diff --check` and deterministic worker catalog/handshake checks passed.

- G3A Lua evidence: `python3 tests/run_tests.py pnc_quest_service_smoke --verbose` passed; the affected medical/inventory/gift regression set passed **6/6**. The test covers existing medical-task eligibility, authoritative committed-transfer event subscription, free-text and wrong-character rejection, stale/repeated evidence, revisioned turn-in, reward idempotency, and ModData reload persistence.
- G3A source checks: `luac5.3 -p` passed for the new quest definition/repository/service, server composition, and inventory transfer boundary; `pz_verify --kahlua` reported **0 errors / 0 warnings** for each touched Lua file; `git diff --check` passed.

- Current G0I real-worker checks: **2/2 passed**; cognition client/service/fact Lua smoke tests: **3/3 passed**; the broader automatic-flow, translation, and harness slice: **36/36 passed**.
- Full suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py'` — **141 tests, 137 passed**. Four failures remain the known pre-existing `ContextualSocialReactionTests.test_threat_uses_guarded_emotion_relationship_and_precedence` cases (`trusted`, `withdrawn`, `stressed`, and `stress_precedes_withdrawn_and_busy`), which exercise unavailable semantic-social transport fallback and are unrelated to automatic flow generation or G0I cognition correlation.
- Harness doctor: `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tkinter/display, core repository, Lua, worker syntax, worker boot, and PING/CAPABILITIES checks.
- Touched Lua passed `luac5.3 -p`; touched Python passed `py_compile`; generated EN/TL JSON parsed; and `git diff --check` passed.
- X11/XTest evidence used real pointer motion/button events against the Tk Semantic Lab. It is distinct from invoking Tk callbacks programmatically. No repeated CUA probing was needed.
- No Project Zomboid process, multiplayer hosting, mod installation, or Steam Workshop publication was launched.

## Scope boundary

G0A, G0B, G0C, G0D/G0D-2, G0E, G0F, G0G, G0H, G0I, G3A, and G3B are accepted implementation slices, not completion of the expanded goal. G3B's Semantic Lab/X11 gate is verified; native Project Zomboid SP/MP and Workshop actions remain user-owned. Continue with G3C before any READY FOR USER LIVE TEST claim.
