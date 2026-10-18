# Contextual Dialogue & Quest Framework — current progress

**Updated:** 2026-10-18
**Audited branch/ref:** `docs/contextual-dialogue-quest-framework-20261018` @ `382e93a342f1d6ee13fc2007a7fbbdf66a7afa7c` (remote)
**PR:** #4 → main, OPEN (not merged); **main baseline:** `a3eb2e4db553f9c03b7f66a6ff6717878e1668e0`
**Status:** PHASE 2 — Action binding / real end-to-end workbench usefulness **PLANNED / NOT ACCEPTED**. Existing source advances are partially implemented; this document update changes plan only.
**ONE Next Chunk:** **2A — FOLLOW typed capability trace, approved dispatcher and honest result in existing Semantic Lab.**

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
