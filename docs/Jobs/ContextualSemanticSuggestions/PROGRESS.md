# Contextual Semantic Suggestions — progress

Updated: 2026-10-22

Status: S0 COMPLETE / S1 COMPLETE / S2 COMPLETE / S3 COMPLETE / S4 COMPLETE / S5 COMPLETE / S6 COMPLETE. Developer-side acceptance is complete; native Project Zomboid SP/MP remains user-owned and `UNTESTED`.

## Repository and authority state

- ProjectHoomans is the verified checkout at `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, branch `main`; final implementation source SHA is `4037f057759c1d76ba1a3f93a8813bb88ea9a028` (the prior acceptance slice is `6b39d640c35101946115922ba4ba91d001c7ca02`).
- `origin/main` remains unchanged at `2bcefd74d3c46df0f707467a7e9b8a6ba42cb185`; local commits are not pushed.
- psychopatzCore is the verified checkout at `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, branch `main`, unchanged SHA `159df9e2f12cb4a3911f50d6c27dcc1d48a861fc`.
- Core owns the existing generic actor/relationship/public-query, capability-binding, IR, translation, UI-layout, and dispatch mechanisms. ProjectHoomans owns suggestion policy, privacy projection, predicates, frames, and gameplay eligibility. No Workshop upload, release, republish, or branch creation occurred.

## S0 — actual source and before-state audit

Source/evidence commit: `7ed714b4d3c46df0f707467a7e9b8a6ba42cb185`.

- Audited the real client typed-input/reply surfaces, canonical IR/response-plan path, active-flow state, Core public actor/relationship queries and capability catalog, existing action dispatcher, production Lua worker, and existing Tk Semantic Lab.
- Before-state doctor passed with Tk/display, Core repository, Lua, worker syntax, and `READY/PING/CAPABILITIES`.
- Real worker baseline `identity_wellbeing_flow_case.json` reproduced `Are you okay?` and `What happened?` with the existing IR/response/flow path, EN fallback false, and zero actions.
- Reusable seams were recorded before implementation. No second parser, response generator, translation backend, worker, Tk application, or state owner was introduced.

Next: S1 canonical projection.

## S1 — bounded contextual suggestion projection

Implementation/evidence commits: `f0b204e0` and `a2633a74`, recorded by `b6a2b29a`.

- Added the production `semantic_dialogue_suggestions` projection from existing typed input, NPC response-plan, active-flow, and permitted-capability sources.
- Candidates have stable IDs, canonical typed `semantic_click_frame` frames, intent/speech-act/subject/slots/modifiers/context, request revision, and localized display keys. Generation is bounded to five candidates and remains non-executing.
- FOLLOW/STAY/WAIT_AT rows reuse the live Core `CapabilityCatalog` bindings; WAIT_AT stays `requires_destination` until a destination exists.
- EN/TL labels are registered in the existing mod translation manifest/shards and resolve through the existing translation manager.
- Worker preview and turn observations expose the same production projection; repeated preview is deterministic, message/transport/tool-call free, and does not mutate transcript, trace, relationship, or action state.

Exact checks: S1 focused tests 3 passed; S1 plus existing harness subset 27 passed; real-worker TL scenario had zero suggestion fallback; direct Lua syntax, JSON, and targeted Kahlua checks passed.

Next: S2 constraints/privacy.

## S2 — typed constraints, privacy, and policy boundaries

Source/evidence commit: `c9139ae8` (final boundary coverage included in `6b39d640`).

- Added Hoomans-owned, side-effect-free typed `all` / `any` / `not` predicate evaluation with bounded traces, strict comparisons, unknown/private states, fail-closed behavior, and redacted private paths.
- FOLLOW/STAY reject hostile, combat, busy, dead, or incapacitated NPCs. WAIT_AT requires a public destination and does not become eligible from a private or unknown value.
- Relationship approval boundaries `-1`, `0`, and `1`, true traits, unknown traits, unsupported relationship/romance providers, knowledge privacy, secret/undiscovered markers, and orientation/consent non-inference are covered. No player-facing suggestion contains private values or romance/consent/orientation tokens.
- Preflight availability and click-time eligibility are separate; unknown/private fields remain unavailable rather than becoming eligible.

Exact checks: S2 tests cover predicate composition, hostile/busy/unknown state, private projection, relationship boundaries, traits, and unsupported social providers. Final S1–S3 focused run: 11 passed.

Next: S3 canonical click pipeline.

## S3 — replay-safe canonical click execution

Source/evidence commit: `c9139ae8`.

- `semantic_click_frame` is converted directly through Core IR construction and existing validation; the click path does not run a second parser or response generator.
- Click-time revision/receipt checks reject stale and duplicate frames without transcript, trace, transport, relationship, inventory, or action mutation.
- Question click reported `provenance.parser=semantic_click_frame` with no tool calls. FOLLOW produced exactly one existing `CompanionCommand` transport/action result. WAIT_AT rejected as `suggestion_click_ineligible_unknown` and produced no transport.
- Existing handlers remain the only side-effect owners; group submission reuses the existing group path.

Exact checks: canonical question, stale, duplicate, FOLLOW, and WAIT_AT worker tests passed; no unauthorized side effects were observed.

Next: S4 client UI and localization.

## S4 — existing client conversation UI and EN/TL

Source/evidence commit: `8095b6e3`, finalized by `6b39d640`.

- Added one Hoomans-owned `semanticSuggestions` extension part to the existing Core conversation view. It uses Core layout persistence, opacity/debug controls, native Core-themed buttons, and submits only canonical frames through `DialogueInput.SubmitSemanticFrame`.
- The visual slice is bounded to five rows: two dialogue prompts plus FOLLOW, STAY, and disabled WAIT_AT when its destination is unresolved. Labels and safe tooltips use existing EN/TL translation infrastructure.
- The existing Semantic Lab Simulation renders the same production projection and refreshes its transcript/authority/raw views after real worker clicks.

Exact Xvfb result: 1 passed. The real window visibly rendered the two prompt buttons, FOLLOW, STAY, disabled WAIT_AT, revision/trace status, and the `Suggestions + predicates` inspector. TL interaction displayed `Itanong ang kalagayan`.

Next: S5 existing Semantic Lab end-to-end proof.

## S5 — existing Semantic Lab worker/GUI integration

Source/evidence commit: `6b39d640`.

- No new harness or Tk app was created. The existing production Lua worker, existing editable scenario controls, existing Simulation tab, and existing inspector were extended in place.
- Xvfb acceptance clicked a question and then FOLLOW through the real worker. The transcript showed the NPC turn and `TOOL/ACTION` follow transition; the inspector showed the canonical click frame and bounded predicate trace.
- Existing scenario save/load round-trip coverage remained green in the full suite. Captured visual evidence: `/tmp/semantic-lab-s4-simulation.png` (validation evidence only, not a repository artifact).
- An initial preview-purity regression was found when localized suggestion lookup incremented worker instrumentation during preview. It was fixed with language-keyed production text caching plus worker-only translation instrumentation suppression around preview projection; localized output remained intact and purity regressions passed.

Exact checks: `xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s4 -v` — 1 passed.

Next: S6 final gates and handoff.

## S6 — regression, performance, and handoff

Final implementation source SHA: `4037f057759c1d76ba1a3f93a8813bb88ea9a028`.

- Full worker suite: `env -u DISPLAY -u WAYLAND_DISPLAY python3 -m unittest discover -s tools/semantic_harness/tests -p 'test*.py' -v` — 297 passed, 2 expected GUI tests skipped without a display.
- Doctor: `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all 9 checks passed, including Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3.6, worker syntax, and `READY/PING/CAPABILITIES` boot.
- Lua/Python checks: changed Lua files parse with `luac5.3`; Python harness files compile; `git diff --check` passes. Targeted Kahlua scans report zero errors/warnings for the 91-file conversation directory and 109-file shared-semantic directory. Full-mod scan covers 3,063 files with zero Kahlua findings.
- The full-mod `pz-verify` report still contains repository-wide baseline findings (184 i18n-flagged files and 542 token-bloat files); those are not represented as a clean whole-mod i18n/bloat gate. No changed-slice Kahlua issue was found.
- Bounded suggestion preview performance: 20 real Lua-worker samples, maximum 55.56 ms, average 45.83 ms, with candidates bounded to five and predicate trace bounded to seven. The existing performance benchmark also completed successfully.
- Codebase-memory coverage was checked for all relied-on source, test, translation, and progress paths at generation `2026-10-20T16:15:18Z`; no recorded coverage issue was reported. New/unindexed or metadata-changed paths were read directly, per the coverage caveat.

Final handoff: READY FOR USER LIVE TEST. Native Project Zomboid SP/MP, actual in-game install, multiplayer authority, and Workshop publication remain `UNTESTED` and user-owned. No release action was taken.

## Post-acceptance follow-up — greeting reply suggestions

Source/evidence commit: `4037f057759c1d76ba1a3f93a8813bb88ea9a028`.

- The user-provided Simulation screenshot exposed a real contextual gap: the greeting response plan already emitted the canonical NPC `check_in` turn (`How have you been?`), but the plan did not declare its existing `WELLBEING` topic. The Simulation had the suggestion UI, but that reply produced only capability rows.
- Added `topic = "WELLBEING"` to all three existing greeting-opening response plans. This reuses the response-plan source; it does not parse the NPC prose a second time.
- A fresh existing Semantic Lab launch now shows `hello` → `How have you been?` → `Ask what is wrong`, `Ask them to follow`, `Ask them to stay`, and disabled `Ask them to wait there`, with the `Suggestions + predicates` inspector populated. Visual evidence: `/tmp/semantic-lab-greeting-suggestions.png`.
- Exact checks after the fix: S1–S3 suggestion tests — 12 passed; Xvfb Simulation test — 1 passed; full harness — 298 passed, 2 expected GUI skips; doctor — all 9 checks passed; greeting response catalog Lua syntax/Kahlua — zero findings.

The already-running older Tk process must be closed and relaunched to load the updated Python UI and production Lua worker; `Restart worker` alone does not reload Python UI code.

## Post-acceptance follow-up — authored dynamic branch offers

Source/evidence commit: `5cff52529c7ddbbf0dbe500efcdbd3098f3e0c89`.

- Closed the gap exposed by the user’s Simulation screenshots: the visible branch set is now projected from the live flow node and NPC response-plan turn, not a fixed list of capability rows. The greeting flow contributes `greeting.thanks`; its response plan contributes `greeting.check_in.report_wellbeing`; typed input and NPC replies use the same bounded `semantic_click_frame` contract.
- Added one Hoomans-owned, data-only branch-offer contract with bounded IDs/text/frames and declarative `all` / `any` / `not` constraints. Unknown, private, secret, undiscovered, busy, hostile, combat, dead, and incapacitated conditions fail closed or remain hidden; no orientation/romance/consent inference was added. Flow and response-plan authoring/compiler/editor paths preserve the same contract, while empty legacy fields are omitted from generated artifacts to retain writer parity.
- Existing production click ownership remains unchanged: preview builds no effects; click-time revision/receipt and predicate checks run before `DialogueInput.SubmitSemanticFrame`; dynamic clicks re-enter the existing dialogue flow/response plan and produce no tool call or transport unless an existing handler owns that effect. A duplicate dynamic click returned `duplicate_suggestion`; stale behavior remains covered by the existing frame tests.
- EN/TL keys resolve through the existing translation manager. The existing Tk Semantic Lab Simulation renders both dynamic buttons, predicate trace, and inspector data; Xvfb acceptance clicked a dynamic NPC-reply offer and the flow offer, then clicked FOLLOW through the existing action transition. Flow Editor JSON authoring and worker `FLOW_REGISTER` were exercised with a constrained authored offer.
- Exact validation after this slice: `env -u DISPLAY -u WAYLAND_DISPLAY python3 -m unittest discover -s tools/semantic_harness/tests -q` — 304 passed, 2 expected GUI skips; `python3 tests/run_tests.py --jobs 4 --timeout 30 --max-output-lines 80 semantic` — 73/73; `env -u DISPLAY -u WAYLAND_DISPLAY xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s4 -v` — 1 passed; doctor — all 9 checks; changed-slice `pz_verify --kahlua --severity ERROR` — 10 files, zero findings; translation JSON — EN/TL 23-key parity; `luac5.3`, `py_compile`, and `git diff --check` passed.
- Bounded real-worker suggestion timing: 20 `hello` samples, maximum 94.817 ms, mean 91.194 ms; maximum candidates 3 and predicate-trace rows 11. Existing phase-6 worker benchmark also completed successfully. The first broad Python run found and fixed three implementation issues during this slice: generated-artifact parity from empty offer fields, worker depth-8 truncation of nested predicates, and a bounded predicate context copying `ir.intent` nondeterministically; the final headless suite is green.
- Next phase: no further developer-side feature phase remains. Native Project Zomboid SP/MP, actual in-game installation, multiplayer authority, and Workshop publication remain `UNTESTED` and user-owned. Handoff is `READY FOR USER LIVE TEST`; no release or Workshop action was taken.

## Corrective follow-up — dynamic topic groups and owned-action authority

Source/evidence commit: `6b176d175062f06673018aa3ec041149348c7215`.

- Reused the existing canonical topic annotation and response-plan topic path. TIME/DATE/WEATHER now produce topic-scoped frames; a time turn no longer receives generic wellbeing, needs, health, and identity buttons. Related choices are exposed in typed `groups`, with the current topic selected by default and an owned-companion action group separately selectable.
- Added public, privacy-safe `actorAuthority` projection from the existing client authority query and explicit worker scenario authority. FOLLOW/STAY/WAIT_AT require owned-companion authority, fail closed for unknown/private authority, and are hidden rather than rendered as misleading unavailable buttons for non-owned NPCs. Current follow state is a public predicate; accepted worker command fixtures refresh the production context so FOLLOW/STAY do not remain simultaneously eligible after a state transition.
- Added EN/TL labels and utterances through the existing translation manager. The production conversation part and the existing Tk Semantic Lab both render the bounded five-button slice per selected group; the Tk inspector continues to expose the complete production projection and predicate trace, while the production part has a group-cycle control.
- Exact validation: focused corrective worker/Tk tests — 5 passed; prior S1–S3 — 17 passed; semantic Lab GUI/entrypoint/session subset — 13 passed; non-Tk harness regression — 294 passed; semantic Lua regression `python3 tests/run_tests.py --jobs 4 --timeout 30 --max-output-lines 80 semantic` — 73/73; doctor — all required checks passed; changed Lua `luac5.3 -p` — pass; EN/TL Suggestions catalog — 38/38 key parity; bounded worker performance — 10 samples, maximum observed turn 111.508 ms, max candidate count 3, max predicate trace 11.
- The mixed full Python discovery command still ends with exit 134 from the repository's Tk/Tcl teardown path when all GUI and worker-session tests are run in one process; the four GUI/entrypoint/session tests pass together in isolation and the 294 non-Tk tests pass. This remains an infrastructure teardown limitation, not a feature assertion failure.
- Native Project Zomboid SP/MP, actual in-game installation, multiplayer authority, and Workshop publication remain `UNTESTED` and user-owned. Handoff remains `READY FOR USER LIVE TEST`; no release or Workshop action was taken.

## Corrective follow-up — dataset-backed `what's up` root and live registry branches

Source/evidence commit: `50675368` (`Add dataset-backed whats-up conversation suggestions`).

- S0 audit confirmed that `projecthoomans:whats_up` already owns the authored category and nine deterministic blocks (`local_activity`, `supply_pressure`, and `survivor_rumors` for `neutral`, `member`, and `special`). The implementation now reuses that category/selector/authority/composer path instead of maintaining a second branch catalog. The existing specific `WELLBEING`, `ACTIVITY`, and `GOSSIP` routes remain distinct.
- S1–S3 add nine reviewed dataset aliases (`what's up`, `whats up`, `what is up`, `what's new`, `whats new`, `anything new`, `what's happening`, `whats happening`, `anything going on`) mapped to one typed `CONVERSATION_TOPIC` frame and `projecthoomans:whats_up`. This is an explicit reviewed dataset expansion, not unrestricted fuzzy parsing.
- S3–S5 route the canonical category frame to the existing `Composer.RequestCategory`/server authority path, then project the selected authored node’s choices as typed `conversation_choice` frames. Choice clicks re-enter `Composer.RequestChoice` and the existing outcome handler. The native composer now exposes one read-only semantic block projection consumed by both the game context and Semantic Lab worker; the worker fallback is projection-only and does not own dialogue state.
- The existing five-button/group bound remains intact. The selected branch group can contain disabled authored choices with safe reason keys; hidden/private/unknown conditions are not exposed. Hostile authority with no eligible authored block hides the root; busy state continues to permit the read-only topic root under the existing authored category contract while movement capabilities remain separately constrained.
- EN/TL labels and authored node/choice text resolve through the existing translation manager. Root clicks emit `ConversationBlock`; detail clicks emit `ConversationOutcome` and advance to the authored `details` node. Root generation is effect-free; stale and duplicate frames return `suggestion_click_stale` / `suggestion_click_replayed` with no duplicate transport.

Exact validation and observed results:

- `PYTHONPATH=. python3 -m unittest ...` focused compiler/dataset/contextual/GUI set — **45 passed**; existing Tk Simulation acceptance with `DISPLAY=:0` — **2 passed**, including visual root/choice rendering and real registry transition.
- `PYTHONPATH=. python3 -m unittest discover tools/semantic_harness/tests -q` — **314 passed**; `python3 tests/run_tests.py --jobs 4 --timeout 30 --max-output-lines 120 semantic` — **73/73**.
- Dataset review — **45 patterns**, **31 response variants**, **18 approved**, **0 rejected**, **46 not-candidate**, and every generated artifact including `Conversation.json` **unchanged**. `--doctor-json` — all 9 checks passed, including real Lua worker boot. `pz_verify --kahlua --severity ERROR` — **2,954 files, zero findings**; changed worker/mod Lua parsed with `luac5.3`; Python compile and `git diff --check` passed.
- Real worker evidence: EN root `Ask what's up` → `conversation_category` → a live `projecthoomans:whats_up_local_activity_neutral` `ConversationBlock`; detail → `details` `ConversationOutcome`; stale/replay rejected safely; hostile authority produced no root candidate; busy retained only the safe topic root; TL resolved `Itanong kung ano ang balita` and `May mga gumagalaw sa paligid ng kapitbahayan ngayon.`
- Bounded performance benchmark completed with 3 samples, 1 warmup, 8 serial turns, bounded semantic-event history, and maximum measured p95 case latency of 283.84 ms. This remains a Semantic Lab worker measurement, not a native PZ tick/SP/MP measurement.

Failures found and fixed in this slice: the generated-artifact review first detected translation-manifest indentation drift; the shared composer projection first exposed a load-order/global-registry issue and was corrected with dynamic registry lookup plus the worker’s compatibility fallback. The final gates above are green.

Next: developer-side S0–S6 gates are complete for this slice. Native Project Zomboid SP/MP, actual in-game installation, multiplayer authority, and Workshop publication remain `UNTESTED` and user-owned. Handoff is `READY FOR USER LIVE TEST`; no release or Workshop action was taken.

## Corrective follow-up — Semantic Lab root matching and NPC profile controls

Source/evidence commit: c040e520 (c040e520302e5301798f9e370fe2a7e651fa53a3).

- Re-audited the real worker before-state after the user-reported gaps: compact whatsup was previously unrecognized; typo-level whaat up had no bounded fuzzy route; the Simulation exposed five fixed visual slots and discarded production group labels; the worker did not project category preflight diagnostics; and the mock runtime had no safe profile switch.
- Added the reviewed dataset forms whatsup and what up, retained the production generated-artifact path, and added the Hoomans-owned WHATS_UP concept route. Core's existing bounded fuzzy matcher now recognizes whaat up through the canonical conversation concept; mutating actions remain ineligible for fuzzy execution. No second parser or response generator was added.
- Added the Semantic Lab NPC profile combobox: Companion (owned), Neutral NPC, Enemy, Trader (Dynamic Trading), and Custom scenario. Presets mutate only the existing scenario/configure boundary. Trader toggles the existing compatibility seam for DTHoomans; it does not execute trading. Switching away from Trader clears the prior role/mod simulation.
- Exposed existing production category diagnostics in the worker context inspector. Real worker evidence: companion exposes owned_actions; neutral has no FOLLOW capability; enemy hides the whats_up root; Trader reports projecthoomans:trade visible only with the simulated mod seam.
- Group labels now come from the production projection and empty button slots are hidden; disabled rows remain only for real ineligible choices such as unresolved WAIT_AT. EN/TL translation manager and typed click frames remain unchanged.
- Exact validation: worker fuzzy/profile/dataset slice — 8 passed; Xvfb Semantic Lab GUI/worker/profile slice — 3 passed; combined focused contextual/follow-up slice — 12 passed; Python compile and git diff --check passed. Native PZ SP/MP remains UNTESTED, reserved for the user. No release or Workshop action.

Next: run the repository-wide Python/Lua/doctor/Kahlua/translation checks, inspect the final production projection and GUI evidence, then commit the progress record and hand off only after all developer-side gates pass.

## Corrective follow-up — final developer-side gates

Source/evidence commit: 163a7226 (163a72269c29ba67b93fa72a8044dd6ba09a59cb).

- Full headless Semantic Lab regression: 318 passed, 4 expected no-display skips. Xvfb app and Simulation acceptance: 12 passed, including visible topic group labels, hidden empty slots, TL labels, real NPC-reply and action clicks, and the NPC profile combobox. Semantic compiler suite: 18 passed.
- Semantic Lua regression: 73/73. Doctor: all required checks passed, including actual worker boot and READY/PING/CAPABILITIES. Full-mod pz-verify Kahlua scan: 2,954 files, zero findings. Changed Lua parsed with luac5.3; Python compile and git diff --check passed.
- Reviewed dataset preview now reports 47 exact patterns, 31 response variants, 20 approved with provenance, 0 rejected, and 44 not-candidate. Existing EN/TL catalogs remain parity-safe; no new player-facing translation backend or catalog was introduced for the harness-only profile labels.
- Bounded real-worker performance completed with 3 samples, 1 warmup, and 8 serial turns. Observed maximum turn p95 was approximately 138.8 ms in this run; the measurement is worker-protocol evidence only and not native Project Zomboid tick/SP/MP evidence.
- Final real-worker checks confirm: whatsup and what up route to CONVERSATION_TOPIC; whaat up selects the fuzzy WHATS_UP concept at edit distance 1; hostile profiles hide the root; neutral profiles do not expose owned actions; Trader alone exposes the existing trade category preflight; canonical root/detail clicks produce ConversationBlock/ConversationOutcome; stale/duplicate clicks remain rejected without duplicate transport.
- Unrelated user work remains uncommitted and untouched in the worktree: Core Presence Lua edits and tests/pnc_restored_body_identity_smoke.lua. No Workshop, release, publish, or push action was taken.

Final handoff: developer-side gates pass. Native Project Zomboid SP/MP, actual in-game installation, multiplayer authority, and Workshop publication remain UNTESTED and reserved for the user. READY FOR USER LIVE TEST.

## Post-S6 follow-up: responsive Semantic Lab Simulation layout

- Source/evidence commit: `0ee7d533fec71c3527edc0e72086ea16590a9667` (`Make Semantic Lab simulation layout responsive`). Existing `main` retained; no push, release, or Workshop action.
- Reworked only the existing Tk presentation layer: screen-aware initial geometry, resizable two-pane minimums, content-sized suggestion panel, organized action toolbar rows, and a separate runtime/profile/status row. Production Lua, worker protocol, semantic frames, translation manager, and click/effect ownership are unchanged.
- Exact validation: `python3 -m py_compile tools/semantic_harness/ui/shell.py tools/semantic_harness/tests/test_contextual_suggestions_s4.py`; focused Xvfb GUI/worker acceptance `test_contextual_suggestions_s4` — **4 passed**; contextual suggestion regression discovery — **31 passed**; related app/harness/profile tests — **35 passed**; `git diff --check` passed.
- Direct Xvfb geometry evidence at 1080x700: all seven action buttons mapped and inside the conversation pane; language, NPC profile, status, input, and send controls mapped; blank suggestion panel measured 50px and expanded to 87px only after the live `conversation.whats_up` branch produced a choice. The existing GUI test also verifies production suggestion rendering and real click transitions.
- Full discovery run reached 319 tests with one worker-timeout error in the existing `test_specific_routes_remain_distinct_from_root`; rerunning that exact test alone passed. The failure was not in the edited UI path and is recorded as a suite-level teardown/flakiness observation rather than hidden.
- Native Project Zomboid SP/MP, actual in-game installation, multiplayer authority, and Workshop publication remain **UNTESTED** and reserved for the user. Handoff remains **READY FOR USER LIVE TEST**.

## Semantic-first presentation migration: production root surface

- Source/evidence SHA: `67a3d9619c3319dfebe2ee54f4a77526b98c62fc` on existing `main`; Hoomans and PsychopatzCore worktrees were verified before edits. No branch, push, Workshop publication, or release action was performed.
- The existing production root registry is now the semantic source for the default player-facing suggestion surface. Root categories and root system/identity/companion choices carry bounded typed route metadata; semantic root clicks resolve back to the original choice/category closures, preserving existing authority, gates, lifecycle transitions, and side-effect handlers. Core owns only the generic optional choice-part visibility seam; Hoomans owns the gameplay policy and projection.
- The root projection is topic-grouped and privacy-safe. Candidate projection is bounded at 24 so the inspector/group selector can expose more authored root choices; the Tk/native visual slice remains five per selected group. Non-owned NPCs do not receive companion-only actions. The existing choices part remains an internal compatibility channel and is hidden only through the generic Core seam for this Hoomans definition.
- The worker now exposes initial root suggestions in HELLO/CAPABILITIES, SNAPSHOT, RESET, and LANGUAGE responses; root category clicks enter the real authored block; root action clicks use the existing session choice path. Worker context snapshots include bounded root/block projections without becoming a second state owner. Stale and duplicate typed root frames are rejected before mutation.
- Exact validation: full headless Python discovery — **320 OK, 5 expected GUI skips**; Xvfb `test_contextual_suggestions_s4` — **4/4 passed**; focused contextual S1–S3/what’s-up suites — **24 passed**; relevant production Lua regressions — **22/22 passed**; doctor — required checks **PASS** (optional venv warning only); changed PZ Lua Kahlua lint with `--severity=ERROR --luac` — **no issues**; JSON parity/compile, Python compile, `luac -p`, and `git diff --check` — **pass**.
- Real worker interaction evidence: initial root groups were rendered; `conversation.root:menu:projecthoomans:whats_up` entered the authored `ConversationBlock`; duplicate root replay was rejected; goodbye root action queued the existing response and produced no unauthorized side effect; EN/TL root labels resolved through the existing translation manager; profile switching hid companion actions for neutral NPCs. Bounded performance: 3 samples, 1 warmup, 12 serial turns; all sequences strictly increased, max recent semantic events stayed at the declared bound, and measured turn p95 remained bounded (non-native worker evidence).
- Remaining gate/next phase: native Project Zomboid SP/MP, actual in-game installation, server authority, and live multiplayer behavior remain **UNTESTED** and are reserved for the user. Developer-side handoff is **READY FOR USER LIVE TEST**; no release action is authorized or taken.
