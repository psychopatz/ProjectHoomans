# Phase 2 — bounded multi-turn wellbeing follow-up

**Status:** accepted for the Semantic Lab gate on 2026-10-17.

**Implementation revision:** ProjectHoomans `41ecbb4f` on
`feat/contextual-semantic-harness-phase0a`.

**Dependency/runtime evidence:** PsychopatzCore
`0212491d2af3597cceaa7353e62f01ef54adca44`; `/usr/bin/lua5.3` Lua 5.3.6;
Python 3.12.3 in `tools/semantic_harness/.venv`.

## Bounded slice

This chunk implements only the deterministic continuation of a wellbeing
question:

```text
player: Are you okay?
npc:    existing grounded wellbeing answer
player: What's wrong? / What is wrong?
npc:    bounded follow-up grounded in the current NPC snapshot
```

The production parser now recognizes both authored forms as
`QUESTION/WELLBEING` and emits the bounded `dialogueFollowUp = "WELLBEING"`
extension. The local resolver accepts the follow-up only when the bounded
dialogue context contains the most recent NPC `ANSWER` for a wellbeing
`QUESTION_RECEIVED` turn. It does not inspect or replay a transcript.

The follow-up uses a separate response pool so the generated wellbeing pool
remains bounded. Existing catalog matching and priority selection choose among
panic, stress, thirst, hunger, fatigue, injured, unknown, and safe default
variants. No second reaction arbiter, task activation, obligation, transport
request, or gameplay action was added.

The Semantic Lab worker exposes `PREVIEW`, which runs the real router
parse/resolve/decision path without `ProcessIR`, context recording, response
queueing, action dispatch, or provider fallback.

## Acceptance evidence

- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**;
  real worker READY/PING/CAPABILITIES boot and worker syntax checks passed.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_baseline_matrix tools.semantic_harness.tests.test_wellbeing_projection -q`:
  **PASS 12/12**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`:
  **PASS 59/59**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`:
  **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase2.json`:
  **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`.
  These are bounded protocol/replay observations and are not semantic proof.
- EN and TL conversation catalogs parse successfully and contain all eight
  follow-up translation keys. A real worker TL turn resolved
  `UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpInjured` with the
  authored Tagalog value.
- `pz-verify` found zero Kahlua compatibility errors in the semantic
  directory. Its existing hardcoded-string findings and token-size warnings
  remain documented repository findings; no new monolith refactor was started.
- Codebase Memory verification used the Project Hoomans graph generation
  `2026-10-08T03:19:15Z`. The changed production paths were reported as
  `metadata_changed` and the harness test paths as `not_tracked`; source was
  read directly and runtime tests were used for current-branch claims. The
  graph result is therefore not treated as proof of source completeness.
- The focused real-worker matrix selected injured, thirst, panic, and unknown
  follow-up variants with `llmCalls=0`, empty transport, empty tool calls, and
  no action result.
- The persistent two-turn case advanced semantic state from sequence 1 to 2;
  dialogue context advanced from sequence 2 to 4, retained `currentTopic`
  `wellbeing`, and exposed `lastSpeaker = "npc"` before the follow-up.
- Two identical `PREVIEW` calls for `What is wrong?` returned the same IR,
  decision, and response. Each preview had equal before/after context, and the
  surrounding snapshot was unchanged apart from the protocol request ID.

## Scope limits

This gate does not claim support for `Can I help?`, clarification repair,
changed-mind/correction, speaker-target interruption, paraphrase coverage,
social reaction, group dialogue, or PBrainZ fallback. Those remain later
bounded chunks. The context remains the existing compact state with its
configured turn/mention/focus limits; no transcript materialization was added.

Native Project Zomboid single-player: **NOT TESTED**. Native multiplayer:
**NOT TESTED**. The Semantic Lab worker's empty transport is not native MP
evidence, and process presence is not gameplay acceptance.

## Next chunk

Proceed to the roadmap's Phase 3 bounded social-reaction baseline only after
preserving this Phase 2 evidence: one persistent deterministic reaction case,
existing relationship/topic/speaker context, no new gameplay authority path,
zero provider calls unless explicitly gated, and focused plus full regression
coverage.
