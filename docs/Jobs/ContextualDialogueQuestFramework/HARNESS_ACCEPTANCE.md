# Semantic Lab acceptance matrix — observable real Lua behavior

## Mandatory distinction

A successful Python/JSON fixture or a screenshot of a node graph is not enough. Semantic Lab must run the **actual production PsychopatzCore parser and Hoomans semantic policy/flow/dispatch adapters** in its worker. Its engine, inventory, server and network edges can be mocked, but must be explicitly labeled **mocked**, not reported as native Project Zomboid confirmation.

Trace every turn: input, selected candidate/pattern, IR, intent/negation/references, flow/gate node transition, capability binding ID and actual registered owner, authorization request, outgoing command/task/gift transport, authority/admission result, any eventual result (or `unobservable`), rendered NPC text and translation key/fallback, state before/after, LLM calls and side effects. Distinguish Preview vs Submit.

## Tier A — now (FOLLOW action binding)

| Utterance/scenario | Required evidence |
| --- | --- |
| Authorized "Follow me" | Actual parsed REQUEST/FOLLOW (or concrete equivalent), registered command `follow`, exactly one mocked transport/request from existing dispatcher, authoritative mock accepted/queued, truthful outcome-dependent reply |
| "Don't follow me" | No accidental FOLLOW dispatch; negation semantics preserved |
| "Are you following me?" | QUESTION does not become order; no transport |
| "I followed you yesterday" | Informative/past tense does not become imperative order |
| Unresolved/addressee ambiguity or invalid lease | Clarification or explicit denial; zero side effects, no "order completed" speech |
| Two repeated previews | Same candidate/decision and **zero** commands, messages persisted or quest mutations |
| Repeated/late submit | Correct request/correlation/dedupe contract; no duplicate authority effect where supported |
| Current existing identity/wellbeing/weather | Same real-Lua selected flow, response and expected allowed effects as baseline; no regression |

## Tier B — diversified dispatch

- **Stay vs Wait At**: explicit differences between local stay order and destination-dependent task request, correct target/destination schema, rejection and admission results.
- **Gift**: offer/consent/selector/real item transfer boundary in harness, correct item and NPC, denial and multi-turn follow-up, no duplicate transfer.
- **Engine facts/events**: rain true/false/unknown and event publication are **observations**, not commands; unknown fact and player claim cannot grant effects.
- **Action capability discovery**: a discovered pattern without handler shows recognition-only, unsupported command is disabled, server denied action remains denied despite parser success.

## Tier C — compiler and editor

- Action binding and authored speech examples compile to separate production Lua definition/pattern/flow/response/translation/manifest artifacts under the correct watched-mod paths. No generated files only under tools, tmp or arbitrary unrelated directories.
- Fresh worker startup loads those exact files, and output matches authored behavior before/after restart. Unsupported Lua is not silently rewritten; stale source causes an explicit error.
- Idempotent generator rerun on same inputs produces identical bytes and no modified tracked files. Recognizer collision detection includes command negatives and cross-definition priority conflicts.
- GUI: real Add/Rename/Duplicate/Delete/Connect/Undo/drag operations demonstrated if available; no silent graph corruption; advanced inspector reveals raw worker proof, not synthetic outcome.

## Tier D — later context/quests

Participant identity isolation, reference resolution, interrupted-topic resume, verified memory provenance, personality/relationship context, locked/active/completed quest queries, authenticated objective events, duplicate packet idempotency, reward once, language EN/TL and optional PBrainZ parity, no new idle NPC tick load. Each accepted via actual production worker or server-owned Lua smoke with clearly marked mock boundaries. Native PZ SP/MP remains USER-OWNED.

## Execution / reporting

Recommended commands (only when present in actual checkout):
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`
- `python3 -m unittest tools.semantic_harness.tests.test_flow_editor -v`
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`
- `python3 -m unittest discover -s tools/semantic_compiler/tests -v` when compiler touched
- `python3 tests/run_tests.py pnc_semantic_dialogue_flow_smoke pnc_semantic_task_request_smoke` where supported
- Actual Kahlua-compatible syntax review, translation JSON validation, `git diff --check`.

Do not copy previous `108 OK` into new phase as a fresh run. Record precise input/output, command, mocked boundary and SHA, not only counts. Missing GUI automation may be marked PENDING while worker gates progress, but Phase 4 cannot be declared fully GUI-accepted without real UI evidence or explicit user disposition. Never initiate Workshop release or native PZ testing to satisfy developer acceptance.
