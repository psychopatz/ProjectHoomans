# Contextual Dialogue & Quest Framework — current progress

**Updated:** 2026-10-19, after the C4-C real-worker dataset-assisted weather slice.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`; implementation is committed through `cbd1de71` (C4-C reviewed dataset-assisted weather topic mapping), following C4-B `fc6d450d`, C4-A `7eb42777`, C3-D `f41ad18a`, C3-C `536b7141`, C3-B `a22b1d78`, C3-A `9ef46d2e`, C2-A `8a4e0b0e`, C1-A `470bb915`, C0-A `ca65049c`, G3C `9946fe69`, and documentation commit `32aceac7`. Earlier accepted slices remain `0cfcc345` (all dispatchable actions), `b1102486` (safe regeneration), `68c313fe` (multi-stage gifts), `b242e78c` (parameterized tasks), and `6290b3f74279731c7d80e97e077e88c10d35d676` (simple commands). Shared branch history also preserves unrelated concurrent P0B import-planner commits.

**Upstream baseline:** `origin/docs/contextual-dialogue-quest-framework-20261018` at `a79b01ff14be33178f699c50623a20524b04d46c`; the local implementation is intentionally ahead of that documentation baseline.

**Current goal status:** **IN PROGRESS — G3C, C0-A, C1-A, C2-A, C3-A, C3-B, C3-C, C3-D, C4-A, C4-B, and C4-C accepted; C4-D–C6, full production-harness/performance, and user-owned native-game gates remain open.**

**ONE Next Chunk:** **C4-D — extend the existing Semantic Code Builder with one bounded reviewed causal/wellbeing follow-up mapping through the existing wellbeing flow, then verify unknown-fact truthfulness and nearby-negative abstention on the real worker.**

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

## G3C accepted — production quest command boundary and worker reload

The worker now loads the production persistence, quest definition/repository/service, server command router, server semantic quest handler, client request, and client result-router modules together. Multiplayer quest input uses the current production client facade; `sendClientCommand` records `client_to_server`, invokes `PNC.ServerCommandRouter.Handle`, and the real server handler calls `PNC.QuestService.HandleRequest` before `sendServerCommand` returns `server_to_client`. The existing `DialogueInput` pending/result correlation remains the only presentation owner. A bounded 64-entry server request cache keys player identity, request ID, giver, quest, and operation; duplicate requests return a compact `duplicate_request` result and cannot repeat the authoritative transition or visible response.

Focused real-worker evidence in `9946fe69` used `runtime.mode=multiplayer` and input `Can you help me?`: the worker reported `questBoundary=production`; PsychopatzCore produced `HELP` IR; the generated Clinic Supplies offer flow selected; the action result was `status=pending`, `reason=network_queued`; the generated flow advanced to `resultNodeId=queued`; transport was exactly `client_to_server/SemanticQuestRequest` followed by `server_to_client/SemanticQuestResult`; and the displayed response was `UI_PNC_Conversation_Semantic_QuestOffer`. The authoritative result came from the production quest service using the existing giver and medical-supply authority fixtures, not the former scenario quest-response stub.

The captured request was replayed through the production server router with the harness-only `REPLAY_SEMANTIC_QUEST` inspection command. The result was marked `duplicate=true`, `reason=duplicate_request`; transcript and queued-message counts did not change. `LuaSemanticWorker.restart()` then loaded the same production quest service and a fresh offer produced the same two-direction boundary and response. This proves one result per request and worker reload; it does not claim native Project Zomboid networking or multiplayer hosting.

## C0-A accepted — production-worker contextual baseline and social authority repair

The real production Lua worker characterized the mandatory sequence `Are you okay?` → `What happened?` → `Do you need anything?` → `How many?` → `I'll get some` → weather → resume. The first two turns produced deterministic `QUESTION/WELLBEING` IR and wellbeing responses. The remaining five turns stayed at `ASK_CLARIFICATION` with `semantic.ask_clarification`, no action result, no transport, no tool call, and zero LLM calls; the worker therefore did not invent a need, quantity, weather fact, offer, quest commitment, or resumed topic. This is a confirmed baseline gap, not an acceptance claim for C1.

The previously reported insult and four THREAT candidates were reproduced and traced. The failure was in the harness production boundary: it loaded the client social dispatcher but not the existing server `PNC.SemanticDialogueSocialAuthority` and its relationship/conduct/social-event services, so directed hostility returned `semantic_social_authority_unavailable` and displayed the generic unavailable line. C0-A loads those canonical production modules and supplies only bounded worker identity/conduct fixtures; it adds no social dispatcher, relationship store, or response engine. `fuck you` and `you are useless` now produce `INSULT` IR, `HOSTILE_REMARK_RECEIVED`, an applied `player_dialogue_insult` event with negative relationship deltas, and visible `semantic.social.hostile_withdrawn`. The four THREAT cases now produce `THREAT_RECEIVED`, applied `player_dialogue_threat` events with negative deltas, and the expected trusted/withdrawn/stressed/stressed authored response variants.

Focused real-worker evidence in `ca65049c`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c0 tools.semantic_harness.tests.test_contextual_social_reactions -q` — **8/8 passed**.
- Existing contextual/paraphrase/flow/weather/wellbeing/identity/quest slice — **44/44 passed**.
- Full worker suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **145/145 passed**.
- `luac5.3 -p` passed the changed worker Lua; `python3 -m py_compile` passed changed Python; `git diff --check` passed. `pz-verify` was clean for the changed Project Zomboid Lua in the preceding G3C slice; its C0-A run against the harness loader reports the loader's existing `dofile()` as `KAHL-E022`, outside the Project Zomboid mod tree. No Project Zomboid process, multiplayer hosting, mod installation, or Workshop publication was launched.

C0-A did not implement generalized needs/quantity/reference resolution, topic interruption/resumption, episodic commitments, or the final mandatory conversation. C1-A now covers only the bounded topic interruption/resumption contract; the remaining capabilities stay open.

## C1-A accepted — bounded pending follow-up and topic resumption

C1-A extends the existing `DialogueContextState` with a bounded agenda (`pendingFollowUp`, fulfilled history, and prior-topic history), adds a pure `ContextResolver` trace that distinguishes a same-topic follow-up from an interruption, and carries the contract through the existing `DialogueFlowKernel`. A terminal weather flow now suspends an active non-terminal flow instead of discarding it; the next compatible turn resumes the suspended flow. The context object remains the sole conversation-local owner and stores no full transcript or gameplay authority.

The real production Lua worker exercised `Are you okay?` → `Is it raining?` → `What happened?`: wellbeing opened a flow-owned question agenda entry; weather produced `contextualFollowUp.status=interrupted`, changed the topic to weather, and left wellbeing suspended with no action; the recovered wellbeing follow-up produced `contextualFollowUp.status=matched`, resumed the suspended flow, fulfilled the agenda entry, and returned to wellbeing. All responses were deterministic, fact-bounded, and side-effect-free.

Focused real-worker evidence in `470bb915`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c1 -q` — **1/1 passed**.
- C0/C1, social, context, weather, flow, paraphrase, wellbeing, identity, translation, and provider-parity slice — **51/51 passed**.
- Full worker suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **146/146 passed**.
- `luac5.3 -p` passed every changed production Lua file; `pz-verify --kahlua --severity ERROR` reported zero errors for every changed production Lua file; `git diff --check` passed. No Project Zomboid process, multiplayer hosting, mod installation, or Workshop publication was launched.

C1-A does not yet implement quantity-slot fulfillment, durable episodic commitments, dialogue-act planning, dataset compilation, Semantic Lab inspection, performance/isolation measurement, or the final mandatory conversation. Those remain C2+ work.

## C2-A accepted — owner-linked acknowledged conversation commitments

C2-A keeps durable conversation commitments inside the existing server-authoritative `PNC.NPCKnowledge` journal. `PNC.NPCKnowledgeAPI.RecordConversationCommitmentForPlayer` validates the current player identity, NPC owner, conversation lease, and a successful processed conversation outcome before writing. It records only bounded primitive fields (`commitmentID`, topic/intent, owner and target identities, validated source fact references, acknowledgement event/outcome, optional validated quest instance, expiry, status, and owner provenance); it does not create a transcript store, quest instance, action dispatcher, or client-side identity path. Cognition references are accepted only when the existing cognition service returns a known fact, and quest references are accepted only after the existing quest service returns the same character/giver-scoped instance.

The production Lua worker now loads the real Knowledge registry/service/API and exposes a bounded `COMMITMENT` inspection command. Its save/reload fixture discards the in-memory Knowledge registry, reloads the same ModData-backed service, and reads through the player-scoped API. The focused trace proves `ack-1` → acknowledged commitment → `conversation_commitment:bandages-1` journal entry → save/reload → one authoritative commitment owned by `npc_mara` and `char_patrick`; replay is idempotent and does not issue a second persistence commit. Missing/unknown evidence, absent acknowledgement, and `npc_other` owner mismatch all fail closed before any journal write. The worker fixture uses the existing lease acknowledgement event as the validated evidence source; this is one bounded vertical slice, not the final mandatory conversation.

Focused C2-A evidence in `8a4e0b0e`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c2 -v` — **2/2 passed**.
- Full worker suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **148/148 passed**.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed repository, Core, Tk/display, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p` passed all changed production/worker Lua; `python3 -m py_compile` passed changed Python; `pz-verify --kahlua --severity ERROR` reported **0 errors / 0 warnings** for each changed production Knowledge Lua; `git diff --check` passed.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C2-A does not yet implement quantity-slot fulfillment, the generalized response planner, dataset-assisted compilation, Semantic Lab context inspection, performance/isolation measurement, or the final mandatory conversation. Those remain C3+ work.

## C3-A accepted — grounded personality-aware response plans

C3-A extends the existing `PNC.Semantics.ResponsePlan`, response catalog, flow resolver, and EN/TL presentation path. It adds bounded dialogue-act metadata (`WELLBEING_REPORT`), topic, uncertainty, tone/personality style, and validated source fact references without adding a second dialogue engine, dispatcher, or memory database. The authored grounded wellbeing pools are selected only for explicitly authored personality styles and known injury/health facts; the existing inferred-reserved/default path remains unchanged. Unknown health facts select the existing unknown response and do not invent injury or needs.

The real production worker shows semantic IR → existing flow → response plan/catalog selection → final EN/TL displayed response. Friendly and withdrawn NPC variants carry the same `npc.healthState` provenance with distinct grounded tone metadata, while no transport, tool, quest, gift, task, or PBrainZ side effect is emitted. Queued presentation preserves the plan metadata. This is one bounded response-plan vertical slice, not the final mandatory multi-turn conversation.

Focused and regression evidence for `9ef46d2e`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c3 -v` — **3/3 passed**.
- C3 plus C1 and semantic-flow regressions — **12/12 passed**.
- Full worker suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **151/151 passed**.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed repository, Core, Tk/display, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p`, `python3 -m py_compile`, and EN/TL `python3 -m json.tool` checks passed; `pz_verify --kahlua --severity ERROR` reported **0 errors / 0 warnings** for every changed production Lua file; `git diff --check` passed.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C3-A did not implement the quantity-aware needs follow-up, dataset-assisted compilation, Semantic Lab context inspection, performance/isolation measurement, optional PBrainZ parity measurement, or the final mandatory conversation. C3-B now covers the bounded needs-to-quantity obligation; the remaining items are later bounded chunks.

## C3-B accepted — quantity-aware needs follow-up

C3-B adds one authored `needs` flow to the existing FlowKernel and response-plan/catalog path. The real worker recognizes “Do you need anything?” as a `NEEDS` question, selects an EN/TL `NEEDS_REPORT` plan from authoritative NPC need pressure, opens a bounded pending agenda entry requiring `quantity`, then recognizes “How many?” as a `QUANTITY` follow-up and resolves the existing obligation with a `NEEDS_QUANTITY` plan. The flow registry now preserves bounded node `requiredSlots` and `sourceFactRefs` into the shared pending context; it does not add a dispatcher, transcript store, or second quest/memory authority.

When the NPC need is known, the plan carries `npc.needs.hunger` or `npc.needs.thirst` provenance but explicitly reports that no exact amount is available. When the need is unknown, the response is an `ASK_CLARIFICATION` plan with no grounded fact refs. Standalone “How many?” remains clarification-only. All paths emit no transport, tool, task, gift, quest, or PBrainZ side effect, and the existing C0 characterization was updated to verify the new bounded behavior plus the unchanged “I’ll get some” and weather safety stop.

Focused and regression evidence for `a22b1d78`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c3b -v` — **3/3 passed**.
- C0/C3-B/flow-editor regression slice — **9/9 passed**; C3-A + C3-B + C1-A + semantic-flow slice — **15/15 passed**.
- Full worker suite: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **154/154 passed**.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed repository, Core, Tk/display, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p`, `python3 -m py_compile`, EN/TL `python3 -m json.tool`, and `git diff --check` passed; `pz_verify --kahlua --severity ERROR` reported **0 errors / 0 warnings** for every changed production Lua file.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C3-B did not implement an authoritative numeric supply amount, the confirmation-safe “I’ll get some” offer/promise path, the full weather interruption/resumption sequence, dataset-assisted compilation, Semantic Lab context inspection, performance/isolation measurement, optional PBrainZ parity measurement, or the final mandatory conversation. C3-C now covers only the confirmation-safe offer/promise path; the other items remain later bounded chunks.

## C3-C accepted — confirmation-safe needs proposal

C3-C routes the authored “I’ll get some” / “I will get some” utterance through the existing deterministic Lua semantic worker and the existing `needs` FlowKernel/response-plan path. The new exact patterns emit `PROMISE` with `subject=NEEDS` and deliberately omit `action=FETCH`, so the promise cannot enter the gameplay task dispatcher. The `needs` flow now advances from its quantity answer into an open `PROPOSAL` agenda entry requiring confirmation; generic `ACCEPT`/`AGREE` keeps that proposal open until a later authority-backed confirmation slice exists. The generalized flow registry preserves a bounded node `pendingKind`, and the kernel closes the prior quantity/offer obligation as fulfilled before opening the next bounded obligation.

Known hunger/thirst responses select the existing response catalog with `PROMISE_ACKNOWLEDGEMENT`, `NEEDS` topic, `pending` uncertainty, and the corresponding `npc.needs.*` fact provenance. Unknown needs remain fact-empty and clarifying. No numeric amount, quest instance, Knowledge commitment, task dispatch, inventory mutation, transport, tool call, or PBrainZ call is created. EN/TL presentation keys are authored in the existing semantic response files.

Focused and regression evidence for `536b7141`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c3c -v` — **1/1 passed** across EN/TL subcases.
- C0/C3-B/C3-C production-worker regression slice — **5/5 passed**; the offer path verifies semantic IR, flow transition, pending proposal, prior-obligation closure, selected plan, final displayed response, and zero side effects.
- Full worker suite via `unittest` discovery — **155/155 passed** (`testsRun=155`, `failures=0`, `errors=0`).
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tk/display, Core, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p`, `python3 -m py_compile`, EN/TL `python3 -m json.tool`, and `git diff --check` passed. `pz_verify --kahlua --severity ERROR` reported **0 errors / 0 warnings** for each of the six changed production Lua files.
- Codebase-memory coverage for all nine changed source/test paths returned `no_recorded_issue`; the indexed generation predates the edits and marked changed files `metadata_changed`/`not_tracked`, so the acceptance relies on direct source reads and real-worker tests rather than stale graph freshness.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C3-C intentionally does not confirm the proposal into an authoritative quest or Knowledge commitment, implement an exact weather interruption/resumption turn after the proposal, supply a numeric item amount, add dataset-assisted compilation, extend Semantic Lab inspection, measure performance/isolation, measure optional PBrainZ parity, or claim the final mandatory conversation. C3-D is the next bounded topic-interruption/resumption slice.

## C3-D accepted — weather interruption and needs-proposal resumption

C3-D reuses the existing weather concept, response-only weather flow, suspended-flow stack, and `DialogueContextState` instead of adding another topic engine. The authored weather vocabulary now recognizes the required “What’s the weather?” wording. In the real worker, an open needs `PROPOSAL` is preserved while the weather flow takes the active turn (`interrupt_start`), the topic changes to `weather`, and the pending proposal remains open. A following “Okay” is resolved as acceptance of that proposal’s own topic despite the lexical wellbeing hint; the suspended needs node resumes with `resume_match`, the topic returns to `needs`, and the proposal remains open and unconfirmed.

Focused and regression evidence for `f41ad18a`:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_conversation_c3d -v` — **1/1 passed** across EN/TL subcases.
- C0/C1/C3-C/C3-D production-worker slice — **4/4 passed**; the exact weather wording, interruption, preserved proposal, resumed flow, final displayed response, and zero side effects are verified.
- Full worker suite via `unittest` discovery — **156/156 passed** (`testsRun=156`, `failures=0`, `errors=0`).
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tk/display, Core, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p`, `python3 -m py_compile`, and `git diff --check` passed. `pz_verify --kahlua --severity ERROR` reported **0 errors / 0 warnings** for each changed production Lua file.
- Codebase-memory coverage for all eight relied-on source/test paths returned `no_recorded_issue`; the indexed generation predates the edits and marked changed files `metadata_changed`/`not_tracked`, so acceptance relies on direct source reads and real-worker tests rather than stale graph freshness.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C3-D does not implement dataset-assisted compilation, Semantic Lab context inspection, numeric needs evidence, authoritative commitment confirmation, performance/isolation measurement, optional PBrainZ parity, or the final mandatory conversation. C4-A is the next bounded compiler slice.

## Semantic Lab naming audit

The generator's canonical IDs remain unchanged for registry lookup, persisted manifests, coverage rows, policy observations, and saved drafts. The Flow editor now presents generated entries as compact labels such as `Quest / Clinic Supplies / Accept`, keeps the full canonical ID in the editable Flow ID field, and shows the workflow kind in the graph header. Selection still maps labels back to the canonical ID; duplicate labels receive a deterministic ID suffix. This is a presentation-only improvement, not a second flow namespace.

## C4-A accepted — reviewed dataset-assisted needs/promise mapping

C4-A extends the existing offline `tools/semantic_compiler` Code Builder and
does not add a runtime corpus, synonym expander, parser, dispatcher, flow
engine, or response authority. The reviewed `common_interactions.json` source
now records license/review metadata for WordNet 3.0, MASSIVE, SGD, and the
existing dialogue references. Its one contextual candidate maps the exact
English paraphrase “I'll pick some up” to the existing `PROMISE`/`NEEDS`
semantic frame and `NEEDS_PROPOSAL` flow, with the existing `FETCH` concept as
review metadata. It carries no `action`, so it cannot enter the gameplay task
dispatcher. The nearby negative “I won't pick some up” is compiler-only and is
not emitted into production Lua.

The same generated response pool adds one reviewed thirst-conditioned
`PROMISE_ACKNOWLEDGEMENT` plan with `npc.needs.thirst` provenance,
`pending` uncertainty, and EN/TL translation text. The builder emits the
existing modular dialogue Lua shards plus `GeneratedDialogue.json` EN/TL
shards and manifest entries; raw WordNet, MASSIVE, and SGD data never enters
the mod.

Focused acceptance evidence `7eb42777`:

- `python3 -m unittest tools.semantic_compiler.tests.test_dialogue_dataset tools.semantic_harness.tests.test_contextual_conversation_c4a -q` — **5/5 passed**. The production worker recognized the reviewed positive in EN/TL, selected the generated localized plan, preserved the proposal, and emitted zero transport/tool/LLM side effects; the negative remained unknown and non-dispatching.
- `python3 -m unittest discover -s tools/semantic_compiler/tests -p 'test_*.py' -q` — **12/12 passed**.
- Full production Lua worker suite via `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **158/158 passed** (`testsRun=158`, `failures=0`, `errors=0`).
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tk/display, Core, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p`, `python3 -m py_compile`, EN/TL/manifests `python3 -m json.tool`, and `git diff --check` passed. `pz_verify --kahlua --severity ERROR` reported **0 errors / 0 warnings** for each changed generated production Lua file.
- Codebase-memory search/trace found the existing compiler entrypoint and build caller. Coverage for all relied-on compiler/source/test/worker/runtime paths returned `no_recorded_issue`, but the indexed generation predates local edits and marked changed files `metadata_changed`/`not_tracked`; acceptance therefore relies on direct source reads and fresh-worker evidence rather than stale graph freshness.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C4-A does not implement SGD correction/clarification generation, Semantic Lab
dataset approval UI, numeric needs evidence, authoritative commitment
confirmation, performance/isolation measurement, optional PBrainZ parity, or
the final mandatory conversation. C4-B is the single next bounded chunk.

## C4-B accepted — reviewed dataset-assisted needs clarification

C4-B extends the same offline Code Builder and existing needs-flow authority
with one reviewed SGD/MASSIVE-style correction mapping. The exact
“Which item do you mean” candidate emits `CLARIFY`/`NEEDS` with the existing
`NEEDS_QUANTITY` follow-up, and maps review metadata to the existing
`ANY_ITEM` concept. It is accepted only by the active needs flow: the new
bounded `onClarify` transition moves to a clarification node that keeps the
quantity obligation open. No new parser, clarification engine, dispatcher,
transcript store, or quest/memory authority was introduced.

The generated `semantic.question.needs.quantity` extension provides an
EN/TL `ASK_CLARIFICATION` plan with `npc.needs.thirst` provenance and
`ambiguous` uncertainty. The nearby plural negative “Which items do you mean”
is compiler-only and remains an unknown, non-dispatching input. The existing
promise and weather interruption behavior remains unchanged.

Focused acceptance evidence `fc6d450d`:

- `python3 -m unittest tools.semantic_compiler.tests.test_dialogue_dataset tools.semantic_harness.tests.test_contextual_conversation_c4a tools.semantic_harness.tests.test_contextual_conversation_c4b tools.semantic_harness.tests.test_contextual_conversation_c3b tools.semantic_harness.tests.test_contextual_conversation_c3c tools.semantic_harness.tests.test_contextual_conversation_c3d -v` — **13/13 passed**.
- `python3 -m unittest discover -s tools/semantic_compiler/tests -p 'test_*.py' -q` — **13/13 passed**.
- Full production Lua worker suite via `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **160/160 passed** (`testsRun=160`, `failures=0`, `errors=0`).
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tk/display, Core, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac5.3 -p`, `python3 -m py_compile`, EN/TL/manifests `python3 -m json.tool`, and `git diff --check` passed. `pz_verify --kahlua --severity ERROR` exited cleanly with **0 errors / 0 warnings** for every changed production Lua file.
- Codebase-memory coverage for the compiler, generated source, needs-flow, kernel/registry, and C4A/C4B test paths returned `no_recorded_issue`; the indexed generation predates local edits and marked changed files `metadata_changed`/`not_tracked`, so acceptance relies on direct reads and fresh-worker evidence rather than stale graph freshness.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C4-B does not implement dataset-assisted weather/topic switching, Semantic Lab
dataset approval UI, numeric needs evidence, authoritative commitment
confirmation, performance/isolation measurement, optional PBrainZ parity, or
the final mandatory conversation. C4-C was the single next bounded chunk for
the following implementation turn.

## C4-C accepted — reviewed dataset-assisted weather topic mapping

C4-C extends the same offline Code Builder with one reviewed exact weather
topic-switch paraphrase: “Can we talk about the weather”. It maps to the
existing `QUESTION`/`WEATHER` IR and `WEATHER_TOPIC` review concept, while the
existing weather flow, gate, suspended-flow stack, and context state remain
authoritative. The generated response pool extends the existing raining pool
only for this generated pattern ID, so the authored “What’s the weather?”
route retains its established response. The generated EN/TL plan reports
`WEATHER_REPORT`, grounds the result in `world.weather.raining`, and leaves the
open needs proposal untouched.

The nearby negative “Can we talk about weather” is compiler-only and is not
emitted as a runtime pattern. No second parser, response engine, topic stack,
dispatcher, memory store, or runtime dataset was added. Response selection now
preserves the selected semantic pattern as a bounded catalog condition so an
approved generated response cannot shadow an authored response in the same
pool.

Focused acceptance evidence `cbd1de71`:

- `python3 -m unittest tools.semantic_compiler.tests.test_dialogue_dataset tools.semantic_harness.tests.test_contextual_conversation_c4c -q` — **7/7 passed**. The real production Lua worker recognized the reviewed weather paraphrase in EN/TL, selected the existing weather flow, reported `interrupt_start`, preserved the open `PROPOSAL`, selected the generated `WEATHER_REPORT` plan with `world.weather.raining` provenance, resumed the needs topic on “Okay”, and emitted zero transport/tool/LLM side effects; the negative abstained without dispatch.
- `python3 -m unittest discover -s tools/semantic_compiler/tests -q` — **14/14 passed**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q` — **162/162 passed** (`testsRun=162`, `failures=0`, `errors=0`), including the unchanged authored C3-D weather response regression.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tk/display, Core, Lua, worker syntax, boot, PING, and CAPABILITIES checks.
- `luac -p`, `python3 -m py_compile`, EN/TL `python3 -m json.tool`, `git diff --check`, and `pz_verify` on every changed production Lua file passed; Kahlua reported **0 errors / 0 warnings**. Token-bloat notices for pre-existing large catalog/shard files were warnings only, not syntax or compatibility errors.
- Codebase-memory coverage for the compiler, generated dialogue, response catalog, selector, weather-flow, and test paths returned `no_recorded_issue`; the indexed generation predates local edits and marks changed files `metadata_changed`/`not_tracked`, so acceptance relies on direct source reads and fresh-worker evidence rather than stale graph freshness.
- No Project Zomboid process, multiplayer hosting, mod installation, Workshop publication, or native-game test was launched.

C4-C does not implement the causal/wellbeing follow-up, Semantic Lab dataset
approval UI, numeric needs evidence, authoritative commitment confirmation,
performance/isolation measurement, optional PBrainZ parity, or the final
mandatory conversation. C4-D is the single next bounded chunk.

## Verification evidence

- G3B focused semantic generation/worker suite: `python3 -m unittest tools.semantic_harness.tests.test_quest_flow_binding tools.semantic_harness.tests.test_automatic_flow_generation tools.semantic_harness.tests.test_flow_editor tools.semantic_harness.tests.test_gift_capability_binding -q` — **25/25 passed**. The broader automatic-flow, translation, and harness regression slice passed **36/36**; authoritative quest service smoke `python3 tests/run_tests.py pnc_quest_service_smoke --verbose` passed **1/1**.
- G3B source checks: `pz_verify --kahlua --severity ERROR` passed all touched mod Lua files; the only harness Lua finding is the intentional worker `dofile()` sandbox warning outside the PZ mod scan. `luac5.3 -p` passed all touched Lua files. `git diff --check` and deterministic worker catalog/handshake checks passed.
- G3C focused boundary suite: `python3 -m unittest tools.semantic_harness.tests.test_quest_flow_binding -v` — **5/5 passed**; the expanded generation/worker/editor/gift slice — **27/27 passed**; `python3 tests/run_tests.py pnc_quest_service_smoke --verbose` — **1/1 passed**. `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed worker boot, Lua, PING, and CAPABILITIES checks.
- G3C source checks: `luac5.3 -p` passed all changed Lua; `python3 -m py_compile` passed changed Python; `for file in $(git diff --name-only -- 'Contents/mods/ProjectHoomans/**/*.lua' 'Contents/mods/ProjectHoomans/*.lua'); do python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py --file "$file" --kahlua --severity ERROR --no-snippets || exit 1; done` exited cleanly for every changed production Lua file; and `git diff --check` passed.

- G3A Lua evidence: `python3 tests/run_tests.py pnc_quest_service_smoke --verbose` passed; the affected medical/inventory/gift regression set passed **6/6**. The test covers existing medical-task eligibility, authoritative committed-transfer event subscription, free-text and wrong-character rejection, stale/repeated evidence, revisioned turn-in, reward idempotency, and ModData reload persistence.
- G3A source checks: `luac5.3 -p` passed for the new quest definition/repository/service, server composition, and inventory transfer boundary; `pz_verify --kahlua` reported **0 errors / 0 warnings** for each touched Lua file; `git diff --check` passed.

- Current G0I real-worker checks: **2/2 passed**; cognition client/service/fact Lua smoke tests: **3/3 passed**; the broader automatic-flow, translation, and harness slice: **36/36 passed**.
- Full suite after C1-A: `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **146/146 passed**. The C0 social regressions remain green, and the C1 pending-follow-up/topic-resumption worker trace is included. The required multi-turn conversation still stops safely before unsupported needs/quantity commitment, as recorded above.
- Harness doctor: `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed Python, repository, virtualenv, Tkinter/display, core repository, Lua, worker syntax, worker boot, and PING/CAPABILITIES checks.
- Touched Lua passed `luac5.3 -p`; touched Python passed `py_compile`; generated EN/TL JSON parsed; and `git diff --check` passed.
- X11/XTest evidence used real pointer motion/button events against the Tk Semantic Lab. It is distinct from invoking Tk callbacks programmatically. No repeated CUA probing was needed.
- No Project Zomboid process, multiplayer hosting, mod installation, or Steam Workshop publication was launched.

## Scope boundary

G0A, G0B, G0C, G0D/G0D-2, G0E, G0F, G0G, G0H, G0I, G3A, G3B, G3C, C0-A, C1-A, C2-A, C3-A, C3-B, C3-C, C3-D, C4-A, C4-B, and C4-C are accepted implementation slices, not completion of the expanded goal. G3B's Semantic Lab/X11 gate, G3C's real-worker boundary, C0-A's worker authority regression gate, C1-A's context/resumption gate, C2-A's Knowledge commitment gate, C3-A/C3-B/C3-C/C3-D response-plan gates, C4-A's reviewed compiler/worker gate, C4-B's clarification/worker gate, and C4-C's weather/resumption worker gate are verified; native Project Zomboid SP/MP and Workshop actions remain user-owned. Continue with the single C4-D chunk above before any READY FOR USER LIVE TEST claim.


## Approved future goal expansion — Contextual Conversational Intelligence (2026-10-19 planning only)

User-approved target: offline Lua NPCs should understand elliptical follow-ups, topic interruptions and resumption, pending questions/offers/corrections, personality-aware dialogue plans and sparse evidence-backed promises with relevant world/quest/knowledge context; optional PBrainZ may rephrase the SAME authorized plan. Improve `tools/semantic_compiler` and Semantic Lab with reviewed dataset-assisted language/conversation-state generation and a context/plan/evidence inspector. See NEW `CONVERSATIONAL_INTELLIGENCE.md`, `DATASET_CONVERSATION_PIPELINE.md` and `CONVERSATION_ACCEPTANCE.md`, and the refreshed `ROADMAP.md`.

G3C, C0-A, C1-A, C2-A, C3-A, C3-B, C3-C, C3-D, C4-A, C4-B, and C4-C are genuinely accepted locally with the evidence above. The next implementation task is exactly the single C4-D chunk named at the top; it is one reviewed causal/wellbeing follow-up mapping with fresh-worker unknown-fact truthfulness and negative protection, not a claim of C4–C6 completion, corpus import, or native-game validation.

Remote branch may not reflect the local Codex working checkout. Agent must reconcile current local HEAD/dirty/parallel work, and not discard implementation changes. C0-A measured and repaired the previously recorded four social THREAT test failures and insult final-response problem at the canonical worker authority boundary; C1-A measured topic interruption/resumption at the same worker boundary. Neither slice claims the mandatory multi-turn conversation complete.
