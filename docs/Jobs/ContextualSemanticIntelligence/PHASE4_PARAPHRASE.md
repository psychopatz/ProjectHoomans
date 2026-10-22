# Phase 4 — bounded wellbeing paraphrase

## Gate status

The bounded Phase 4 Semantic Lab slice is accepted on Project Hoomans branch
`feat/contextual-semantic-harness-phase0a`. It adds one reviewed wellbeing
paraphrase through the existing dialogue compiler and preserves the existing
IR, response catalog, deterministic route and authority boundary. It does not
claim broad paraphrase coverage, group dialogue, PBrainZ behavior or native
game acceptance.

Implementation revision: `78674253` (`feat(semantic): add reviewed wellbeing paraphrase`).
PsychopatzCore remained pinned at `0212491d2af3597cceaa7353e62f01ef54adca44`.

## Scope and baseline

Before the change, `how are you doing` was accepted by the real worker but
resolved to deterministic `ASK_CLARIFICATION` with no intent, subject or
pattern. Nearby authored forms such as `how are you holding up` already
resolved to `QUESTION/WELLBEING`, so this was a narrow missing dataset entry,
not a reason to add a new parser or reaction arbiter.

The source change adds only
`pnc.dataset.question.wellbeing.how_are_you_doing` to
`tools/semantic_harness/codebuilder/sources/common_interactions.json`, emitting
`QUESTION/QUESTION/WELLBEING` with confidence `0.99` and priority `120`.
The generated `PNC_SemanticGeneratedDialogue_Patterns_02.lua` shard was
rebuilt by the existing compiler. No WordNet allowlist, fuzzy command rule,
response catalog ID or gameplay action was changed.

The real worker now returns:

- `QUESTION_RECEIVED`, deterministic route, pattern
  `pnc.dataset.question.wellbeing.how_are_you_doing`;
- an existing `semantic.question.wellbeing.*` response variant;
- `llmCalls=0`, empty transport/tool traces, no action result and equal
  relationship snapshots.

The held-out command-shaped strings `walk with me`, `followed the trail` and
`we are following them` remain `ASK_CLARIFICATION` with no action, transport,
tool or LLM effect. The existing `how are you holding up` wellbeing
paraphrase remains recognized.

## Evidence

- `python3 -m unittest tools.semantic_harness.tests.test_semantic_paraphrases -v`:
  **PASS 2/2**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`:
  **PASS 7/7**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`:
  **PASS 67/67** in 38.865s.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`:
  **PASS**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`:
  **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report
  /tmp/contextual-semantic-suite-phase4.json`: **PASS 66/66**; 198 events,
  `conflicts=[]`, `audit_truncated=null`. These are protocol/replay
  observations and are not semantic proof.
- `luac5.3 -p` passed for the changed generated Lua shard.
- `pz-verify` over `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics`:
  76 files, **0 Kahlua errors and 0 warnings**. The changed generated shard
  also passed a single-file check with zero findings.
- JSON parsing and `git diff --check` passed. A broad mod-wide verifier scan
  still contains the repository's pre-existing hardcoded-string and
  token-bloat findings plus one existing Kahlua-warning file with zero
  Kahlua errors; those findings are outside this bounded gate.

The new harness test is `tools/semantic_harness/tests/test_semantic_paraphrases.py`.
It executes the persistent production Lua worker rather than a Python parser
mock or JSON-only replay.

## Limitations and transition

Native single-player: **NOT TESTED**. Native multiplayer: **NOT TESTED**. No
Semantic Lab transport result, empty conflict ledger or running Project
Zomboid process is promoted as native SP/MP acceptance evidence.

Phase 4 is accepted only for this one reviewed paraphrase and its held-out
false-positive boundary. Next chunk: the optional Phase 5 audit of read-only
PBrainZ/group-dialogue compatibility, retaining deterministic offline parity
and speaker/conversation scoping.
