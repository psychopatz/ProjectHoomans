# Contextual Dialogue & Quest Framework — current progress

**Updated:** 2026-10-18
**Audited branch/ref:** `codex/contextual-dialogue-quest-framework-0a` @ `b99d27505220fd21b1e49a00cb28e1b35c9aaa86` (source commit)
**PR:** #4 → main, OPEN (not merged); **main baseline:** `a3eb2e4db553f9c03b7f66a6ff6717878e1668e0`
**Status:** PHASE 4 — Practical integrated authoring UX. **2A, 2B, 2C, 3A, 4A, and 4B ACCEPTED** at source/headless gates; GUI click-through remains pending because the computer-use surface exposes no app. Native PZ runtime remains unrun by instruction.
**ONE Next Chunk:** **4C — perform the GUI author → compile-preview → approved-generate → worker-restart click-through when a native app surface is available.**

## 2A acceptance ledger — FOLLOW

- **Implementation commit:** `02ed6246e9c7c81f8a45dcae2dbdfd86f0c056ff` (`Wire semantic FOLLOW capability through existing command dispatcher`).
- **Discoverable binding:** live `PNC.Semantics.CapabilityCatalog` reports `FOLLOW` as recognized/dispatchable with `pnc:companion.follow`, owner `PNC.CompanionCommands`, route `existing_companion_command`, command `follow`, handler `PNC.Client.SendCompanionCommand`, and typed `arguments/requires/result` metadata. The adapter uses the existing command registry and dispatcher; no second parser or callable field was added.
- **Committed positive trace:** `Follow me` → Core IR `REQUEST/FOLLOW`, provenance `pnc.command.follow` → policy branch `COMMAND_ACCEPTED` → existing adapter → one mocked-authority `CompanionCommand` transport with `commandID=follow`, `requestID=1`, `npcID=npc_mara`, accepted `network_queued` → one normalized tool call (`authority=mock`) → rendered NPC reply `Okay.`. The observation exposes capability binding, request, action result, flow `matched=false/noFlow=true`, and side-effect facts.
- **Preview purity:** two previews of `Follow me` produced the same recognized action/binding and zero transport/tool calls/side effects; Preview remains non-dispatching.
- **Negative safety:** `Don't follow me` produced the existing `STOP` → `stay` route and no `follow`; `Are you following me?`, `maybe follow me`, and `I followed you yesterday` remained clarification/no-dispatch cases. No new command path was introduced.
- **Unauthorized result:** mocked `unauthorized_companion` returns rejected action status/reason, one observable `follow` transport/tool call, and truthful localized reply `I can't follow you right now.` / TL `Hindi kita masusundan ngayon.`; the stale `Okay.` acknowledgement is not emitted. EN/TL keys are in the canonical Conversation translation catalog.
- **Workbench surface:** Flow Editor action discovery now shows binding ID/command when present and explicitly labels recognition-only actions; adding a trigger remains trigger-only and reports that Preview never dispatches. A native Tk click-through was not recorded because no native app surface was exposed to the CUA session; headless GUI construction tests remain covered.

## 2A verification

- `tools/semantic_harness/run_harness.sh --doctor --doctor-json` — PASS (Lua worker syntax/boot, repository and display diagnostics).
- `tools/semantic_harness/.venv/bin/python -m unittest tools.semantic_harness.tests.test_follow_action_binding -v` — PASS, 4/4 (real Lua worker, positive/preview/negative/unauthorized EN+TL).
- Focused Python flow/context suite — PASS, 25/25; `test_contextual_baseline_matrix` — PASS in isolation.
- Focused Lua regression suite (`pnc_semantic_command_adapter_smoke`, dialogue/input/flow/response/identity/local-question cases) — PASS, 7/7.
- `pz_verify.py --file --kahlua --severity ERROR --no-snippets` on all four changed production Lua files — PASS; `luac5.3 -p`, Python `py_compile`, JSON validation, and `git diff --check` — PASS.
- Full Python discovery still exits nonzero in the existing suite-wide contextual-baseline ordering; the isolated baseline file passes, and the changed FOLLOW acceptance test is green. `pnc_semantic_local_route_smoke` still expects one greeting response while the existing authored greeting plan queues two; this was not changed because it is outside 2A.

## 2B acceptance ledger — STAY vs WAIT_AT

- **Implementation commit:** `5836179c3aa0dd2ed16f423aa81646e43c652e8d` (`Trace STAY and WAIT_AT through distinct task routes`).
- **Discoverable bindings:** live catalog now reports `STAY` as `pnc:companion.stay` → `PNC.Client.SendCompanionCommand` / `stay`, and `WAIT_AT` as `pnc:task.wait_at` → `PNC.Client.RequestSemanticTask` / existing semantic-task route. WAIT_AT advertises destination, actor, scope, and bounded-duration argument metadata plus resolved-destination authority requirement and admitted/active/completed result states.
- **STAY trace:** `Stay here` → Core IR `REQUEST/STAY`, provenance `pnc.command.wait` → one existing `CompanionCommand(stay)` with accepted `network_queued` result → one normalized `stay` action call → NPC `Okay.`. It does not emit a semantic-task request.
- **WAIT_AT trace:** `Wait at the campfire` → Core IR `REQUEST/WAIT_AT`, provenance `pnc.command.wait_at`, resolved `CAMPFIRE` target → one existing `SemanticTaskRequest` with `target.category=CAMPFIRE` → mocked authority admission `status=admitted`, `planID=mock-plan-wait-at` → one WAIT_AT action call plus the authority request fact → NPC `Okay.`. It does not emit `CompanionCommand`.
- **Target safety:** `stay at the recycle bin` remains WAIT_AT but the harness authority rejects unresolved target data as `target_unresolved`; exactly one task-result line says `I can't find that place nearby.`. Question `Are you waiting at the campfire?` remains clarification with zero transport/tool calls. Two WAIT_AT previews remain side-effect-free.
- **Workbench and authority boundary:** the same live action inspector metadata now differentiates command versus task ownership; the task path uses the existing `RequestSemanticTask` contract and a harness-only authority response bridge, not a new parser, dispatcher, tick loop, or callable editor field.

## 2B verification

- `tools/semantic_harness/.venv/bin/python -m unittest tools.semantic_harness.tests.test_stay_wait_at_binding -v` — PASS, 2/2.
- Combined focused Python suite (FOLLOW, STAY/WAIT_AT, flow editor, identity/wellbeing, weather) — PASS, 31/31.
- Focused Lua regression suite including `pnc_semantic_wait_at_smoke`, `pnc_semantic_task_adapter_smoke`, companion commands, command adapter, dialogue/input, dialogue and response catalog — PASS, 7/7.
- Harness doctor — PASS; changed production Lua Kahlua checks, `luac5.3`, Python compilation, JSON validation, and `git diff --check` — PASS.
- Full Python discovery remains nonzero only in the already recorded suite-wide contextual-baseline ordering; no 2B acceptance test fails in isolation or in the focused set. Native PZ SP/MP and GUI click-through remain intentionally unrun/unverified.

## 2C acceptance ledger — GIFT

- **Implementation commit:** `9c8d99676c24780fc5a2fbb0d2611d9fb212cefe` (`Expose semantic gift capability and authority trace`).
- **Discoverable binding:** live catalog reports `GIFT` as `pnc:gift.offer` → `PNC.Client.SendInventoryTransfer`, route `existing_inventory_transfer`, with inventory selection, target revision, conversation lease, authority requirements, and requested/pending/rejected/applied/completed result states. This metadata observes the existing GiftLifecycle/selection/transfer owners; it adds no second gift dispatcher.
- **Committed real-worker trace:** `I want to give you an apple` → Core IR `OFFER/GIFT`, provenance `pnc.social.gift_give_you` → branch `GIFT_OFFER_DISPATCHED` → MarketSense resolves `player_apple_1` / `Base.Apple` → one existing `InventoryTransfer` request (`semantic-gift:npc_mara:1`) → existing server-result bridge emits `InventoryResult` with applied gift/relationship delta → NPC `Thank you for the Apple.`. Observation/tool facts expose the binding, transfer request, pending action result, applied relationship result, and authority statuses.
- **Preview and selection safety:** two previews of the same offer expose the GIFT binding but produce zero transport/tool calls. Vague `I have a gift for you` stays `GIFT_SELECTION_REQUIRED`; in the headless harness the selector is unavailable and the action is rejected without an InventoryTransfer. Existing Lua consent coverage verifies one-recipient confirmation routes through the same transfer path, refusal does not dispatch, ambiguous multi-recipient consent does not dispatch, and a closed group expires the stale offer.
- **Authority boundary:** the worker uses the existing inventory transfer and result pipeline with scenario-backed inventory/authority fixtures; it does not claim native PZ SP/MP completion. No duplicate parser, dispatcher, inventory mutation, or tick scan was added.

## 2C verification

- `tools/semantic_harness/.venv/bin/python -m unittest tools.semantic_harness.tests.test_gift_capability_binding -v` — PASS, 2/2.
- Combined focused Python suite (FOLLOW, STAY/WAIT_AT, GIFT, flow editor, identity/wellbeing, weather) — PASS, 33/33.
- Focused Lua gift/task/dialogue suite including `pnc_semantic_gift_offer_smoke` and `pnc_semantic_task_dispatch_smoke` — PASS, 4/4; the gift smoke includes consent, refusal, ambiguity, stale-group and existing-transfer assertions.
- Harness doctor — PASS; changed production Lua Kahlua checks, `luac5.3`, Python compilation, and `git diff --check` — PASS.
- Full Python discovery retains the previously recorded suite-wide contextual-baseline ordering failure; no 2C focused test fails. Native PZ SP/MP and GUI click-through remain intentionally unrun/unverified.

## Accepted / supported foundation

- **Phase 0A accepted only by earlier recorded developer evidence** at `1a754dc8`: shared Conversation Blocks gate status PASS/FAIL/UNKNOWN; `weather_context` response-only flow; earlier real worker outcomes rain/clear/unknown, EN/TL and side-effect-free preview; `108 OK` tests belonged to that earlier revision, not independently rerun here.
- `382e93a3` source now includes graphical add/duplicate/rename/delete/connect/drag/zoom/pan/undo, live trigger and action discovery, typed engine facts/recent event bus and a producer for server-observed zombie kills. This is **source present**, not latest GUI or worker acceptance.
- Existing game production routes own commands (`FOLLOW`, `STAY`, `GO HOME`, `CAMP`), tasks (`WAIT_AT`, `GIVE/FETCH`) and multi-stage gift offers. Flow Editor currently adds an `action` TRIGGER, **not executable action binding**.
- Current compiler `tools/semantic_compiler` now additionally compiles the reviewed `pnc.semantic_authoring.v1` FOLLOW source into modular patterns/flow/response/EN+TL/explicit-manifest artifacts; the source remains one bounded definition, not a general arbitrary-code generator.

## Mandatory unaccepted results

- Latest branch has not been newly tested or GUI click-through verified by this audit. Phase 1 node operations may leave invalid graph state, lack layout persistence and do not show execution.
- No production-validated action/result binding from flow draft to dispatcher, no integrated action inspector and no full gift sequence in editor.
- GUI click-through remains unverified; the 3A compiler/restart proof is source-backed and worker-backed, not a GUI claim. JSON authoring remains offline source input, while checked-in generated Lua/translation artifacts are loaded by the fresh worker.
- Contextual memory and Quest domain still future.
- No native PZ SP/MP, Workshop or fresh hosted CI claim. Remote branch state says nothing about an agent's local uncommitted files.

## Historical 2A execution plan (completed)

1. Inspect actual local branch/HEAD/status, Core+Hoomans module versions, and current `382e93a3` code and relevant tests; preserve user/other-agent changes. Locate Core parser, FlowRegistry/Kernel, `PNC_SemanticCapabilityCatalog`, `PNC_SemanticDialogueInput_Actions`, CommandAdapter/CompanionCommands, worker OutputProjection/Conversation, and existing mock command transport.
2. Implement a **minimal typed, discoverable FOLLOW binding/route trace** compatible with the existing policy, client-approved dispatcher and server command authority. The Flow Editor's Add action may expose action metadata and binding availability, but cannot invoke a function or treat an added trigger as a game command. Avoid introducing another parser/dispatcher or arbitrary callable Lua fields.
3. Make the EXISTING Simulation/Turn facts and related editor inspector show the actual selected pattern, parsed action, handler/command ID, request/authority mock status, rendered NPC reply, side effects and reason when no command occurs. Avoid false "Okay, I'll follow" after denial. Preserve Preview purity.
4. Execute a real Lua worker positive "Follow me" with eligible mock permission and **exactly one** observed outgoing `follow` command, plus unauthorized, negated ("don't follow me"), question ("are you following me?") and low-confidence/ambiguous variants with no unauthorized dispatch. Prove selected response and observable result; if worker lacks a realistic authority mock, extend only the required boundary and label it.
5. Run focused existing weather/identity/wellbeing, core flow/command regression tests and harness doctor; no mass JSON fixture campaign. If Tk view available, exercise action picker + simulation once; otherwise mark GUI click-through unverified with exact reason.
6. Update `PROGRESS.md` with SHA, exact input→IR→route→result→reply traces and test counts; select ONE Next Chunk (2B Stay vs Wait At) if accepted or keep 2A open with a specific defect. Do NOT switch to compiler/gift/quest before 2A acceptance.

### Exit condition

**One existing FOLLOW capability is visibly bound to and invoked through its own approved production path in the harness, with a truthful acknowledgement or denial.** A new action graph box, a catalog listing, successful generic NLP parse, JSON registration or a prettier canvas does not satisfy 2A.

## 3A acceptance ledger — compiler/source/restart

- **Canonical source:** `tools/semantic_compiler/semantic_definitions.json`, schema `pnc.semantic_authoring.v1`, one typed FOLLOW definition with reviewed positive/negative examples, existing capability reference `pnc:companion.follow`, bounded flow, response pool, and EN/TL text.
- **Generated outputs:** explicit `PNC_SemanticGeneratedDefinitions.lua` manifest plus patterns/flows/responses shards under `42.20/media/lua/shared/PNC/Semantics/`; EN/TL generated translation shards under `common/media/translation/.../Conversation/Semantic/`; existing `Conversation.json` manifest contains both paths.
- **Production integration:** existing semantic catalog, flow catalog, and response catalog load the explicit manifest; generated flow triggers can match only their authored pattern provenance, so hand-authored `Follow me` remains `noFlow` while generated phrases enter `pnc.dialogue.follow.flow`.
- **Fresh-worker trace:** `Keep close behind me` and `Please keep close behind me` → generated exact pattern → Core IR `REQUEST/FOLLOW` → existing `PNC.SemanticCommandAdapter` → one mocked-authority `CompanionCommand` with `commandID=follow` and `capabilityID=pnc:companion.follow`; negated/question/past examples clarify with zero transport/tool calls. Preview is side-effect-free; restart reloads the same generated artifacts and routes again.
- **Negative/determinism coverage:** compiler rejects unknown capabilities, existing/reserved utterance collisions, duplicate cross-definition utterances, non-imperative positive examples, unknown authored flow patterns, unreachable nodes, and translation collisions. Rebuild hash comparison is byte-identical; `git diff --check`, JSON, Python, `luac5.3`, and Kahlua verification pass.

## 4A acceptance ledger — effect-free source preview

- **Semantic Lab seam:** existing Flow editor toolbar now exposes `Compile source…`; it opens the canonical JSON source and calls the offline compiler adapter, not the Lua worker or a second parser.
- **Preview report:** valid source reports schema, definition/capability/pattern/flow/response IDs, EN/TL keys, exact planned Lua/translation/manifest paths, `previewOnly=true`, `effectFree=true`, and `writes=[]`. Invalid source reports a bounded diagnostic and zero planned writes.
- **Focused proof:** compiler/worker/Flow editor/app/source-preview tests — PASS, 38/38. `py_compile`, `git diff --check`, and doctor remain PASS. Native PZ SP/MP and real GUI click-through are not claimed; CUA exposes no native app surface in this environment.

## 4B acceptance ledger — approved generation/reload handoff

- **Explicit approval boundary:** Flow editor now separates `Compile source…` (zero-write preview) from `Generate source…` (confirmation dialog, then existing compiler writer). The GUI callback restarts the existing Lua worker after successful generation; no alternate parser or runtime registry is introduced.
- **Determinism proof:** temp-repository generation writes the modular Lua/EN/TL/manifest set; a second generation over unchanged source produces identical SHA-256 hashes. Invalid source remains diagnostic-only and writes nothing.
- **Focused proof:** compiler/source-preview/worker/Flow editor/app tests — PASS, 39/39; Lua smoke tests — PASS, 4/4; doctor, Python compilation, JSON, Kahlua, `luac5.3`, and `git diff --check` pass.

## 4C pending GUI gate

- The GUI entrypoint constructs successfully and the source controls are wired, but real Tk click-through cannot be performed in this environment: computer-use state currently exposes `apps=[]`, `browsers=[]`. Do not claim human GUI authoring acceptance until that surface is available. Native PZ SP/MP remains user-owned.

## Agent routing and Git

Job is in PR #4 branch as of this source audit. Agent should inspect its own local tree, use an already authorized exact branch (or coordinate if a different implementation branch is active), avoid overwriting changes, and never force/stash/reset to catch up. The docs update does not authorize moving/merging main, starting PZ, server hosting or Workshop publishing. See `ROADMAP.md`, `CAPABILITY_ACTION_BINDINGS.md`, `HARNESS_ACCEPTANCE.md`.
