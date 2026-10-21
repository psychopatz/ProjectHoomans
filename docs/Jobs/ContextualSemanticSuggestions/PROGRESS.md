# Contextual Semantic Suggestions — progress

Updated: 2026-10-22

Status: S0 COMPLETE / S1 COMPLETE / S2 COMPLETE / S3 COMPLETE / S4 COMPLETE / S5 COMPLETE / S6 COMPLETE. Developer-side acceptance is complete; native Project Zomboid SP/MP remains user-owned and `UNTESTED`.

## Repository and authority state

- ProjectHoomans is the verified checkout at `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, branch `main`, source SHA `6b39d640c35101946115922ba4ba91d001c7ca02`.
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

Final source SHA: `6b39d640c35101946115922ba4ba91d001c7ca02`.

- Full worker suite: `env -u DISPLAY -u WAYLAND_DISPLAY python3 -m unittest discover -s tools/semantic_harness/tests -p 'test*.py' -v` — 297 passed, 2 expected GUI tests skipped without a display.
- Doctor: `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all 9 checks passed, including Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3.6, worker syntax, and `READY/PING/CAPABILITIES` boot.
- Lua/Python checks: changed Lua files parse with `luac5.3`; Python harness files compile; `git diff --check` passes. Targeted Kahlua scans report zero errors/warnings for the 91-file conversation directory and 109-file shared-semantic directory. Full-mod scan covers 3,063 files with zero Kahlua findings.
- The full-mod `pz-verify` report still contains repository-wide baseline findings (184 i18n-flagged files and 542 token-bloat files); those are not represented as a clean whole-mod i18n/bloat gate. No changed-slice Kahlua issue was found.
- Bounded suggestion preview performance: 20 real Lua-worker samples, maximum 55.56 ms, average 45.83 ms, with candidates bounded to five and predicate trace bounded to seven. The existing performance benchmark also completed successfully.
- Codebase-memory coverage was checked for all relied-on source, test, translation, and progress paths at generation `2026-10-20T16:15:18Z`; no recorded coverage issue was reported. New/unindexed or metadata-changed paths were read directly, per the coverage caveat.

Final handoff: READY FOR USER LIVE TEST. Native Project Zomboid SP/MP, actual in-game install, multiplayer authority, and Workshop publication remain `UNTESTED` and user-owned. No release action was taken.
