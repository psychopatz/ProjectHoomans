# Semantic Dialogue Decoupling — current evidence and Next Chunk

**As of 2026-10-17:** Phase **0A** (baseline adoption) is **ACCEPTED**. The
identity/wellbeing regression fix remains preserved in the committed history;
the modular flow and translation-manifest architecture is still planned.
Native Build 42 singleplayer/multiplayer acceptance remains **NOT TESTED**.

## Repository state and preserved work

- The authorized Hoomans checkout is `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`,
  on `main`, tracking `origin/main`, at `98e8875cf9ed49250247dac2ac3ad5b0c0b9e9d9`.
  The protected regression commit `105dadedd31c57be64a3622c4a1f6d2d6f402d35`
  is an ancestor of this HEAD. It was not reimplemented.
- The companion Core checkout is `/home/psychopatz/Zomboid/Workshop/psychopatzCore`,
  on `main`, at local revision `0212491d2af3597cceaa7353e62f01ef54adca44`.
  It has substantial unrelated in-flight radio/UI/asset edits in its working
  tree; this goal did not modify, stage, stash, reset, or publish that checkout.
- Hoomans was clean before Phase 0A edits. The edits below are limited to the
  production-worker trace fixture, its Python regression assertions, the
  current translation lookup smoke test, and this evidence ledger.

## Phase 0A production-worker trace

Added
`tools/semantic_harness/scenarios/identity_wellbeing_original_trace_case.json`
and a permanent test in
`tools/semantic_harness/tests/test_semantic_identity_wellbeing_collision.py`.
The case runs the real production Lua worker with LLM disabled and records four
accepted turns. The observed EN trace was:

| Input | Semantic IR / provenance | Route / branch | Observed response key and text | Pending identity |
| --- | --- | --- | --- | --- |
| `who are you` | `QUESTION` / `IDENTITY`; `pnc.question.identity` | deterministic / `QUESTION_RECEIVED` | `semantic.question.identity.stranger_alt_2` — “Let's get to know each other first. What do people call you?” | `{kind=PLAYER_NAME, requestedAt=1}` |
| `are you okay` | `QUESTION` / `WELLBEING`; `pnc.question.wellbeing_okay` | deterministic / `QUESTION_RECEIVED` | `semantic.question.wellbeing.dataset.hanging_in` — “I'm hanging in there. Thanks for asking.” | preserved |
| `im fine thanks` | `INFORM` / `WELLBEING`; `pnc.state.self_wellbeing_im_plain_fine_thanks` | deterministic / `SELF_STATE_RECEIVED` | `semantic.self_state.wellbeing_alt` — “That's good to hear. I appreciate you asking.” | preserved |
| `My name is Patrick` | `INFORM` / `IDENTITY`; `pnc.identity.my_name_is` | deterministic / `IDENTITY_CLAIM_RECEIVED` | `semantic.identity.exchange`; authoritative `UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed` — “Okay Patrick, nice to meet you. I'm Mara Vale.” | cleared |

The first three turns had empty transport/tool-call collections and unchanged
relationship snapshots. The final turn emitted one client-to-server
`SemanticIdentityRequest`, one server-to-client `SemanticIdentityResult` (plus
the expected event mirror), and tool calls `SemanticIdentityRequest` and
`AdjustRelationship`. Relationship state changed from unknown/revision 1 with
zero approval, respect, and familiarity to trusted/revision 2 with approval 1,
respect 2, and familiarity 6. All four turns used EN, `llmCalls=0`, and the
loaded-module manifest included the real Core semantic parser, Hoomans
translation bootstrap, dialogue policy, presentation, and identity exchange
modules. The case runner reported `conflicts=[]` and sequences 1–4.

## Translation baseline

The current custom Conversation catalogs were read directly from the packaged
JSON files; no translation files were moved or rewritten.

- EN: 521 keys, 45,222 bytes, raw SHA-256
  `50d1f1c8c3d12d6ed7cdb10d7e79e5672e8a4fb3e1d59097ec2a7a4a6392d199`,
  canonical sorted key/value SHA-256
  `c6e208b9c900ed278c8ad662284a6b11015d8258a62a0625d64e21a4c243c5d4`.
- TL: 521 keys, 47,704 bytes, raw SHA-256
  `37a6d55a24b4c70e4b4b3a1533cb1c1a951f15289183d6870a351f707d9c86a4`,
  canonical sorted key/value SHA-256
  `bfe3c2c880a6030291bc12dcd3f1d4e587acd7996e6bdc91583d30bbd8f22b4b`.
- EN/TL key sets have zero missing and zero extra names. Key-by-key placeholder
  signatures have zero mismatches.
- `PNC_TranslationBootstrap.lua` registers 15 systems and their registered
  catalogs contain 2,825 keys in each language. The Core manager baseline API
  is `registerSystem`, `forMod`, `load`, `get`, `getLanguage`,
  `setLanguageOverride`, `clearLanguageOverride`,
  `SetTranslationAuditEnabled`, `GetTranslationAuditSnapshot`,
  `GetTranslationCoverageRevision`, `GetTranslationCoverageSnapshot`, and
  `getLanguageOverride`. It loads one nested per-system JSON lazily, with a
  legacy flat-file fallback.
- `Trading/Trading.json` exists separately with 20 EN and 20 TL keys but is
  not among the 15 registered systems. The new real facade smoke assertion
  records the current lookup: `Translation.Systems.Trading == nil` and
  `Translation.GetKey("UI_PNC_Trading_Title", "Trading") == "Trading"`
  under the TL test setup, because the segment map/native lookup does not
  resolve the unregistered custom catalog. This is a Phase 5/6 migration item,
  not a Phase 0 fix.

## Verification evidence

Doctor passed all required checks: Python 3.12.3, Lua 5.3.6,
Hoomans/Core paths, worker syntax, and `READY/PING/CAPABILITIES`.

Before the Phase 0A additions, the committed regression and baselines were
`7/7`, `90/90`, and `66/66`. After the additions:

- `python3 -m unittest tools.semantic_harness.tests.test_semantic_identity_wellbeing_collision -q` — **8/8 PASS**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q` — **91/91 PASS**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic` — **66/66 PASS**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/semantic-decoupling-regression-after.json` — **66/66 PASS**.
- `python3 tests/run_tests.py pz_custom_translation_manager_smoke` — **1/1 PASS**.
- `git diff --check` — **PASS**.
- `pz_verify` on the changed Lua test reported no Kahlua errors under
  `--kahlua --severity ERROR`; the default report had 10 warning-level
  `KAHL-W001 load(string)` findings and a 3,973-token test-file estimate over
  the 2,000-token warning threshold. No new production Lua file was changed.

The repository-wide Lua suite remained an unchanged headless baseline failure
before and after the Phase 0A additions:
`python3 tests/run_tests.py` — **FAIL 12/834 executed**. The 12 failing files
were `pnc_building_catalog_local_recipes_smoke.lua`,
`pnc_building_favorites_smoke.lua`, `pnc_building_tab_selection_smoke.lua`,
`pnc_colony_management_ui_model_smoke.lua`,
`pnc_colony_management_workshop_catalog_smoke.lua`,
`pnc_constants_presence_boundary_smoke.lua`, `pnc_inventory_ui_smoke.lua`,
`pnc_live_body_heavy_held_items_smoke.lua`,
`pnc_pbrainz_native_button_smoke.lua`,
`pnc_persisted_shell_cleanup_smoke.lua`,
`pnc_puppet_opera_animation_tab_modules_smoke.lua`, and
`pnc_server_inventory_presence_boundary_smoke.lua`. None is in the semantic
Phase 0A focused set; no failure was hidden or weakened.

The Hoomans graph index was ready with no parse-partial or skipped files at
generation `2026-10-08T03:19:15Z`; changed/untracked evidence files were read
from source because their graph metadata was stale or not tracked. The Core
translation manager path is excluded from the Core graph, so its API claims
above are source-verified rather than graph-derived.

## Phase 0A gate and next bounded chunk

Exit 0A is satisfied: the protected identity semantics are exercised through
real production Lua, the complete interruption/resumption trace has no false
identity or relationship effect, focused and semantic suites pass, the current
EN/TL catalog baseline is hashed, and the native SP/MP gate remains explicitly
open.

**Next Chunk: Phase 1 — typed candidates and contextual eligibility.** First
inspect the current Core/Hoomans candidate and diagnostic contracts, then make
the smallest compatibility-preserving extension only if the Phase 1 scenario
proves it necessary. Preserve `Parser.Parse`/IR v1, reject context-invalid
identity candidates with inspectable reasons, keep PREVIEW pure, and do not add
global stop-word priority or gameplay authority to the parser. Do not modify
the dirty Core checkout without a separately authorized Core change and
deployment decision.

Native SP/MP, hosted CI, and live PBrainZ provider acceptance remain
**NOT TESTED**.
