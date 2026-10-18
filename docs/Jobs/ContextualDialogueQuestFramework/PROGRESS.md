# Contextual Dialogue & Quest Framework — current progress

**Updated:** 2026-10-18
**Audited branch/ref:** `codex/contextual-dialogue-quest-framework-0a` @ `02ed6246e9c7c81f8a45dcae2dbdfd86f0c056ff` (source commit)
**PR:** #4 → main, OPEN (not merged); **main baseline:** `a3eb2e4db553f9c03b7f66a6ff6717878e1668e0`
**Status:** PHASE 2 — Action binding / real end-to-end workbench usefulness. **2A ACCEPTED** for the bounded FOLLOW slice; 2B is next. The native PZ runtime remains unrun by instruction.
**ONE Next Chunk:** **2B — STAY vs WAIT_AT typed capability trace and truthful result in the existing Semantic Lab.**

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

## Accepted / supported foundation

- **Phase 0A accepted only by earlier recorded developer evidence** at `1a754dc8`: shared Conversation Blocks gate status PASS/FAIL/UNKNOWN; `weather_context` response-only flow; earlier real worker outcomes rain/clear/unknown, EN/TL and side-effect-free preview; `108 OK` tests belonged to that earlier revision, not independently rerun here.
- `382e93a3` source now includes graphical add/duplicate/rename/delete/connect/drag/zoom/pan/undo, live trigger and action discovery, typed engine facts/recent event bus and a producer for server-observed zombie kills. This is **source present**, not latest GUI or worker acceptance.
- Existing game production routes own commands (`FOLLOW`, `STAY`, `GO HOME`, `CAMP`), tasks (`WAIT_AT`, `GIVE/FETCH`) and multi-stage gift offers. Flow Editor currently adds an `action` TRIGGER, **not executable action binding**.
- Current compiler `tools/semantic_compiler` already emits reviewed WordNet alias and common interaction patterns/responses; it does not yet compile entire flows/actions/translation manifests from the editor.

## Mandatory unaccepted results

- Latest branch has not been newly tested or GUI click-through verified by this audit. Phase 1 node operations may leave invalid graph state, lack layout persistence and do not show execution.
- No production-validated action/result binding from flow draft to dispatcher, no integrated action inspector and no full gift sequence in editor.
- JSON draft save and temporary flow registration are not real generated mod source. Synchronized code/graph view, procedural compiler with source diffs/restart proof, authored modular output missing.
- Contextual memory and Quest domain still future.
- No native PZ SP/MP, Workshop or fresh hosted CI claim. Remote branch state says nothing about an agent's local uncommitted files.

## EXACT Next Chunk 2A (one bounded implementation iteration)

1. Inspect actual local branch/HEAD/status, Core+Hoomans module versions, and current `382e93a3` code and relevant tests; preserve user/other-agent changes. Locate Core parser, FlowRegistry/Kernel, `PNC_SemanticCapabilityCatalog`, `PNC_SemanticDialogueInput_Actions`, CommandAdapter/CompanionCommands, worker OutputProjection/Conversation, and existing mock command transport.
2. Implement a **minimal typed, discoverable FOLLOW binding/route trace** compatible with the existing policy, client-approved dispatcher and server command authority. The Flow Editor's Add action may expose action metadata and binding availability, but cannot invoke a function or treat an added trigger as a game command. Avoid introducing another parser/dispatcher or arbitrary callable Lua fields.
3. Make the EXISTING Simulation/Turn facts and related editor inspector show the actual selected pattern, parsed action, handler/command ID, request/authority mock status, rendered NPC reply, side effects and reason when no command occurs. Avoid false "Okay, I'll follow" after denial. Preserve Preview purity.
4. Execute a real Lua worker positive "Follow me" with eligible mock permission and **exactly one** observed outgoing `follow` command, plus unauthorized, negated ("don't follow me"), question ("are you following me?") and low-confidence/ambiguous variants with no unauthorized dispatch. Prove selected response and observable result; if worker lacks a realistic authority mock, extend only the required boundary and label it.
5. Run focused existing weather/identity/wellbeing, core flow/command regression tests and harness doctor; no mass JSON fixture campaign. If Tk view available, exercise action picker + simulation once; otherwise mark GUI click-through unverified with exact reason.
6. Update `PROGRESS.md` with SHA, exact input→IR→route→result→reply traces and test counts; select ONE Next Chunk (2B Stay vs Wait At) if accepted or keep 2A open with a specific defect. Do NOT switch to compiler/gift/quest before 2A acceptance.

### Exit condition

**One existing FOLLOW capability is visibly bound to and invoked through its own approved production path in the harness, with a truthful acknowledgement or denial.** A new action graph box, a catalog listing, successful generic NLP parse, JSON registration or a prettier canvas does not satisfy 2A.

## Agent routing and Git

Job is in PR #4 branch as of this source audit. Agent should inspect its own local tree, use an already authorized exact branch (or coordinate if a different implementation branch is active), avoid overwriting changes, and never force/stash/reset to catch up. The docs update does not authorize moving/merging main, starting PZ, server hosting or Workshop publishing. See `ROADMAP.md`, `CAPABILITY_ACTION_BINDINGS.md`, `HARNESS_ACCEPTANCE.md`.
