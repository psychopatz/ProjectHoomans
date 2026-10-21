# Contextual Semantic Suggestions — progress

Updated: 2026-10-22

Status: S0 COMPLETE / S1 COMPLETE / S2 COMPLETE / S3 COMPLETE / S4 IN PROGRESS. This is an implementation checkpoint, not final acceptance.

## Repository and authority state

- ProjectHoomans is the verified checkout at `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, branch `main`, current source SHA `a2633a74ef40c57d727f2961515625475985da8b`, local-only commits ahead of the unchanged `origin/main` (`2bcefd74d3c46df0f707467a7e9b8a6ba42cb185`).
- psychopatzCore is the verified checkout at `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, branch `main`, SHA `159df9e2f12cb4a3911f50d6c27dcc1d48a861fc`; no Core change was required for S0/S1.
- No branch, Workshop upload, release, or republish action was taken. Native PZ SP/MP remains `UNTESTED` and user-owned.

## S0 evidence — source ownership and before-state

- The existing typed input seam is Hoomans `PNC_SemanticDialogueInput.lua` / `PNC_SemanticDialogueInput_Lifecycle.lua`; it calls the Core actor service/router, `Preview`, `ProcessIR`, Hoomans `DispatchAction`, and the existing response-plan queue in `PNC_SemanticDialogueInput_Presentation.lua`.
- The existing action boundary is `PNC_SemanticDialogueInput_Actions.lua` (`Internal.DispatchAction`), with command/task/gift/quest adapters remaining the only effect owners.
- The existing Core conversation view has text entry/send and authored choices; Hoomans extension parts did not have semantic suggestion buttons. The existing Semantic Lab `tools/semantic_harness/runtime/worker.py`, persistent Lua worker, Tk shell, Studio, and conversation inspector are the reusable validation path.
- `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` passed before-state discovery: Python 3.12.3, Tk/display, Core checkout, Lua 5.3.6, worker syntax, and `READY/PING/CAPABILITIES`.
- Before-state real-worker scenario `identity_wellbeing_flow_case.json` accepted `Are you okay?` as `QUESTION/WELLBEING` and `What happened?` through contextual recovery; response plans and flow transitions were present, side effects were zero, and EN lookups were Core-backed with `fallbackUsed=false`. No suggestions, click frame, predicate trace, or GUI button existed.

## S1 evidence — canonical non-executing proposal contract

Source SHA: `a2633a74ef40c57d727f2961515625475985da8b` (`feat(semantic): expose flow and capability suggestion sources`), following `f0b204e0` and the S0 audit commit `7ed714b4`.

- Added the production Hoomans module `PNC_SemanticDialogueSuggestions.lua`. It derives versioned, stable-ID candidates from the existing interpreted IR and NPC response plan; it does not parse, dispatch, queue, or mutate state.
- Candidate frames are typed `semantic_click_frame` data with schema version, pattern provenance, intent/speech-act, subject/action, slots, request revision, and no callback. Projection is bounded to five candidates with deterministic IDs and deduplication.
- The same projection now records `typed_input`, `npc_response_plan`, `active_flow`, and `permitted_capability` sources. Active flow metadata comes from the existing flow result; FOLLOW/STAY/WAIT_AT descriptors come from the live `CapabilityCatalog` and existing adapter bindings. WAIT_AT is marked `requires_destination` until a target is available.
- EN/TL labels and utterances are registered as real `Conversation/Semantic/Suggestions.json` shards in the existing manifest and resolve through the existing Core-backed Hoomans translation manager.
- The worker projection exposes suggestions in both `preview` and `turn` observations. No synthetic JSON or second worker was introduced.

Exact S1 checks and observations:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s1 -v` — 3 passed. Preview repeated identically, remained message/transport/tool-call free, and preserved transcript/trace/relationship state. Turn output contained five-or-fewer candidates, typed and response-plan provenance, active `wellbeing` flow, and live FOLLOW/STAY/WAIT_AT bindings.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s1 tools.semantic_harness.tests.test_harness` — 27 passed.
- `bash tools/semantic_harness/run_harness.sh --no-gui --language TL --jsonl --scenario tools/semantic_harness/scenarios/identity_wellbeing_flow_case.json --input "Are you okay?"` — TL labels and utterances resolved, suggestion fallback count remained zero.
- `python3 .../pz_verify.py --file .../PNC_SemanticDialogueSuggestions.lua --kahlua --severity ERROR --no-snippets` — zero Kahlua errors/warnings; direct Lua 5.3 syntax load passed; JSON manifest/shards parsed; `git diff --check` passed.
- Coverage check was run for every new/modified S1 path. The graph reported no recorded issue, but new files were `not_tracked` and modified worker files were `metadata_changed`; source was read directly as required. Core `common/media` remains graph-excluded by design.

## S2 evidence — constraints, privacy, and fail-closed policy

- Added typed declarative `all` / `any` / `not` predicates with strict comparisons, bounded traces, unknown/private results, and redacted private paths. Capability policy remains in ProjectHoomans; existing Core catalog bindings remain the discovery source.
- FOLLOW/STAY reject hostile, combat, busy, dead, or incapacitated NPCs. WAIT_AT remains visible only as a safe `requires_destination` state until a destination is known. Unknown and private values never become eligible, and private/secret/undiscovered values are not copied into player-facing suggestions.
- No romance or consent candidate is synthesized from orientation or another single trait; unsupported/private social facts fail closed. Existing relationship/knowledge/identity providers remain the only sources for future policy.

## S3 evidence — typed click frames and replay-safe execution

- Canonical suggestion frames are converted directly through `PsychopatzCore.Semantics.IR.New`; click text is never reparsed. `SUGGESTION_CLICK` reuses the existing production `Conversation.turn`, `ProcessIR`, presentation, and action dispatch owners.
- Preflight projection and click-time recheck are separate. Revision checks reject stale frames, per-conversation receipts reject duplicates, and ineligible frames produce no transport or action side effect.
- Real worker observations: question click produced `provenance.parser=semantic_click_frame`; FOLLOW produced one existing `CompanionCommand` transport/action result; WAIT_AT rejected with `suggestion_click_ineligible_unknown`; replay returned `duplicate_suggestion`; stale frame returned `stale_suggestion` without transcript/trace/transport mutation.

Exact S2/S3 checks:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s1 tools.semantic_harness.tests.test_contextual_suggestions_s2 tools.semantic_harness.tests.test_contextual_suggestions_s3 -v` — 10 passed.
- `python3 .../pz_verify.py --file .../PNC_SemanticDialogueSuggestionPredicates.lua --kahlua --severity ERROR --no-snippets` — zero Kahlua errors/warnings; direct Lua worker syntax/load checks passed.
- Coverage check was rerun for every S1–S3 source/test/translation path. The graph reported no recorded issue, but new paths were `not_tracked` and modified worker paths `metadata_changed`; source was read directly as required.

## S4 evidence — existing Core UI and Semantic Lab interaction

- Added one Hoomans-owned `semanticSuggestions` extension part to the existing Core conversation view. It uses Core layout persistence, opacity/debug controls, and native Core-themed buttons; it submits only canonical frames through `DialogueInput.SubmitSemanticFrame` and reuses the existing group `Submit` path.
- Added EN/TL panel title and safe unavailable/destination tooltip keys to the existing Suggestions translation shards. No second translation manager, parser, response generator, or UI application was introduced.
- Existing Semantic Lab Simulation now renders the production projection as six bounded buttons, disables fail-closed capabilities, and exposes the full bounded suggestion/predicate projection in a dedicated inspector tab. Button clicks call the real Lua worker `SUGGESTION_CLICK` command and refresh the existing transcript/authority/raw views.

Exact S4 checks and observed results:

- `xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s4 -v` — 1 passed. Existing Tk app rendered six buttons; WAIT_AT was disabled; predicate trace was visible; clicking a question produced a new turn and `semantic_click_frame` in the inspector.
- Captured `/tmp/semantic-lab-s4-simulation.png` from the real existing app: Simulation tab visibly showed three dialogue buttons, FOLLOW, STAY, disabled WAIT_AT, revision/trace status, transcript, and inspector tabs. The image is validation evidence only, not a repository artifact.
- `python3 -m py_compile tools/semantic_harness/ui/shell.py tools/semantic_harness/tests/test_contextual_suggestions_s4.py`; `git diff --check`; S1–S3 focused worker suite — all passed.
- Coverage check was rerun for every S1–S4 source/test/translation path. The graph reported no recorded issue; new paths were `not_tracked` and modified paths `metadata_changed`, so each was read directly as required.

Open gates: S5 full Semantic Lab scenario editing/inspection coverage, S6 full regressions/perf/doctor/Kahlua and final review, and user-owned native PZ SP/MP live test. Final handoff must remain `READY FOR USER LIVE TEST`; no Workshop release.
