# Semantic Dialogue Decoupling — current evidence and Next Chunk

**As of 2026-10-17:** Phases **0A** (baseline adoption), **1** (typed
candidates/contextual eligibility), and **2** (bounded dialogue-flow kernel)
are **ACCEPTED** for the Semantic Lab gate. Phase **3** (identity/wellbeing
modular pilots) is the active next chunk. Native Build 42
singleplayer/multiplayer acceptance remains **NOT TESTED**.

## Repository state and preserved work

- The authorized Hoomans checkout is
  `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, on `main`, at local
  revision `69e223b48215fee094a8a47f5a7f16ecc640d8f0`. `origin/main` remains
  at the pre-phase revision `98e8875cf9ed49250247dac2ac3ad5b0c0b9e9d9`.
  The protected regression commit
  `105dadedd31c57be64a3622c4a1f6d2d6f402d35` is an ancestor and was not
  reimplemented.
- The companion Core checkout is
  `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, on `main`, at local
  revision `9e46a8e07e6dea60dd42ff982ae798d49376fa40`. It has substantial
  unrelated in-flight radio/UI/asset edits in its working tree; the semantic
  commit was path-limited and did not include or overwrite those staged
  changes.
- Hoomans is clean at the phase-2 commit. Core remains dirty only from the
  pre-existing unrelated work plus the isolated semantic commits; the new
  router hook is committed at `9e46a8e07e6dea60dd42ff982ae798d49376fa40`
  while 174 unrelated cached paths remain untouched. Neither checkout was
  reset, stashed, force-pushed, or published.

## Phase 0A production-worker trace

Added
`tools/semantic_harness/scenarios/identity_wellbeing_original_trace_case.json`
and a permanent test in
`tools/semantic_harness/tests/test_semantic_identity_wellbeing_collision.py`.
The case runs the real production Lua worker with LLM disabled and records
four accepted turns. The observed EN trace was:

| Input | Semantic IR / provenance | Route / branch | Observed response key and text | Pending identity |
| --- | --- | --- | --- | --- |
| `who are you` | `QUESTION` / `IDENTITY`; `pnc.question.identity` | deterministic / `QUESTION_RECEIVED` | `semantic.question.identity.stranger_alt_2` — “Let's get to know each other first. What do people call you?” | `{kind=PLAYER_NAME, requestedAt=1}` |
| `are you okay` | `QUESTION` / `WELLBEING`; `pnc.question.wellbeing_okay` | deterministic / `QUESTION_RECEIVED` | `semantic.question.wellbeing.dataset.hanging_in` — “I'm hanging in there. Thanks for asking.” | preserved |
| `im fine thanks` | `INFORM` / `WELLBEING`; `pnc.state.self_wellbeing_im_plain_fine_thanks` | deterministic / `SELF_STATE_RECEIVED` | `semantic.self_state.wellbeing_alt` — “That's good to hear. I appreciate you asking.” | preserved |
| `My name is Patrick` | `INFORM` / `IDENTITY`; `pnc.identity.my_name_is` | deterministic / `IDENTITY_CLAIM_RECEIVED` | `semantic.identity.exchange`; authoritative `UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed` — “Okay Patrick, nice to meet you. I'm Mara Vale.” | cleared |

The first three turns had empty transport/tool-call collections and unchanged
relationship snapshots. The final turn emitted one client-to-server
`SemanticIdentityRequest`, one server-to-client `SemanticIdentityResult` plus
the expected event mirror, and tool calls `SemanticIdentityRequest` and
`AdjustRelationship`. Relationship state changed from unknown/revision 1 with
zero approval, respect, and familiarity to trusted/revision 2 with approval 1,
respect 2, and familiarity 6. All four turns used EN, `llmCalls=0`, and the
loaded-module manifest included the real Core semantic parser, Hoomans
translation bootstrap, dialogue policy, presentation, and identity exchange
modules. The case runner reported `conflicts=[]` and sequences 1–4.

## Phase 1 typed candidates and contextual eligibility

Phase 1 is implemented in separate commits: Core
`56906aa75342f028583460c9de1b88d560c7b398` and Hoomans
`033a603ee9b68fa8c2438bd1cbf2af46ecf01c74`.

- Core now exposes additive `Parser.ParseCandidates`, with a default limit of
  8 and a hard limit of 16. Each bounded candidate carries its pattern ID,
  exact/fuzzy pass, confidence, match metrics, typed captures, provenance, and
  an IR v1 value. Candidate diagnostics include exact/fuzzy counts, selected
  winner, deterministic tie state, and registry revision. Existing
  `Parser.Parse` behavior and IR v1 were retained; the Core semantic smoke
  test compares the legacy winner and candidate winner.
- Core `DialogueRouter` has optional candidate-parser/selector hooks. The
  Hoomans lifecycle supplies them without creating a second parser or state
  store. Preview uses the same pure candidate selection path and does not
  record a turn or dispatch an action; accepted results retain bounded
  candidate evidence for the Semantic Lab.
- Hoomans `DialogueCandidateEligibility` validates IR v1, honors authored
  pattern priority, supports bounded required-context/required-capture
  metadata, rejects fuzzy mutating actions before policy dispatch, and
  clarifies when distinct same-priority candidates remain tied. It reports
  positive selection and bounded negative reasons without changing dialogue
  state, relationships, transport, or tools.
- Real worker case
  `tools/semantic_harness/scenarios/candidate_eligibility_case.json` sends
  `folow me`. Production Lua emits the typed fuzzy candidate
  `pnc.command.follow` (score `0.91`), rejects it as
  `fuzzy_mutating_action`, returns `ASK_CLARIFICATION`, and records no
  transport, tool call, action result, or relationship change. The existing
  `I'm starving` collision remains `pnc.state.self_hunger_im`; authored
  priority disambiguates it without a global stop-word expansion.

The Phase 1 gate is satisfied: candidate evidence is produced by the real
Core/Hoomans production worker, invalid mutating interpretations are rejected
with inspectable reasons, legacy identity/wellbeing behavior remains green,
and PREVIEW remains side-effect-free.

## Phase 2 bounded dialogue-flow kernel

Phase 2 is implemented in Hoomans `69e223b48215fee094a8a47f5a7f16ecc640d8f0`
and Core `9e46a8e07e6dea60dd42ff982ae798d49376fa40`. The protected fix
`105dadedd31c57be64a3622c4a1f6d2d6f402d35` remains an ancestor.

- `PNC_SemanticDialogueFlowRegistry.lua` validates bounded stable flow IDs,
  typed trigger/accept frames, transitions, slot schemas, duplicate frames,
  conflicting slot owners, unreachable nodes and the finite registry limit.
  Identity and wellbeing are separate registered definition modules loaded by
  the catalog; the central policy does not gain one branch per flow.
- `PNC_SemanticDialogueFlowKernel.lua` provides pure `Preview` and commit-only
  `Commit` paths. It stores bounded active/suspended sessions in the existing
  `PNC_SemanticDialogueContextState`, keyed by speaker/addressee, and supports
  start, interruption, match, resume, cancellation and retirement. It emits
  existing response-pool IDs and slot evidence; it never dispatches gameplay.
- The Core router commits the policy's flow preview exactly once after the
  semantic event is recorded. Invalid/fuzzy/ambiguous turns still use the
  prior safe policy paths. Direct `Policy.Process` returns the committed flow
  evidence as well.
- Real-worker case
  `tools/semantic_harness/scenarios/identity_wellbeing_flow_case.json`
  observed transitions `start -> interrupt_start -> match -> match`, statuses
  `started -> started -> advanced -> retired`, identity suspension/resumption,
  and an empty flow-session snapshot after completion. A second NPC received a
  distinct `player-one|npc-b` session. All turns remained deterministic with
  no LLM calls or unintended transport/tool effects.

The Phase 2 gate is satisfied for the Semantic Lab: the Lua flow smoke passed,
the real worker proves preview purity and one-time commit/resume behavior, and
the existing identity/wellbeing regression suite remains green. Native SP/MP
remains open.

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
- EN/TL key sets have zero missing and zero extra names. Key-by-key
  placeholder signatures have zero mismatches.
- `PNC_TranslationBootstrap.lua` registers 15 systems and their registered
  catalogs contain 2,825 keys in each language. The Core manager baseline API
  is `registerSystem`, `forMod`, `load`, `get`, `getLanguage`,
  `setLanguageOverride`, `clearLanguageOverride`,
  `SetTranslationAuditEnabled`, `GetTranslationAuditSnapshot`,
  `GetTranslationCoverageRevision`, `GetTranslationCoverageSnapshot`, and
  `getLanguageOverride`. It loads one nested per-system JSON lazily, with a
  legacy flat-file fallback.
- `Trading/Trading.json` exists separately with 20 EN and 20 TL keys but is
  not among the 15 registered systems. The real facade smoke assertion records
  the current lookup: `Translation.Systems.Trading == nil` and
  `Translation.GetKey("UI_PNC_Trading_Title", "Trading") == "Trading"`
  under the TL test setup, because the segment map/native lookup does not
  resolve the unregistered custom catalog. This is a Phase 5/6 migration item,
  not a Phase 0/1 fix.

## Verification evidence

Doctor passed all required checks: Python 3.12.3, Lua 5.3.6, Hoomans/Core
paths, worker syntax, and `READY/PING/CAPABILITIES`.

Phase 1 verification:

- `lua5.3 tests/psychopatz_semantic_pattern_matcher_smoke.lua` in Core —
  **PASS**.
- `python3 -m unittest tools.semantic_harness.tests.test_semantic_identity_wellbeing_collision -q` — **9/9 PASS**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q` —
  **92/92 PASS**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic` —
  **66/66 PASS**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/phase1-semantic-report-after-fix.json` — **66/66 PASS**.
- `python3 tests/run_tests.py` — **FAIL 12/834 executed in 8.25s**, the
  unchanged headless baseline set: `pnc_building_catalog_local_recipes_smoke.lua`,
  `pnc_building_favorites_smoke.lua`, `pnc_building_tab_selection_smoke.lua`,
  `pnc_colony_management_ui_model_smoke.lua`,
  `pnc_colony_management_workshop_catalog_smoke.lua`,
  `pnc_constants_presence_boundary_smoke.lua`, `pnc_inventory_ui_smoke.lua`,
  `pnc_live_body_heavy_held_items_smoke.lua`,
  `pnc_pbrainz_native_button_smoke.lua`, `pnc_persisted_shell_cleanup_smoke.lua`,
  `pnc_puppet_opera_animation_tab_modules_smoke.lua`, and
  `pnc_server_inventory_presence_boundary_smoke.lua`.
- `git diff --check` — **PASS** on both repositories after commits.
- `pz_verify` `--kahlua --severity ERROR` — **PASS** for every changed
  production Lua file in both repositories. No new Kahlua errors were found;
  the pre-existing test-file warning profile is not a production regression.

Phase 2 verification:

- `lua5.3 tests/pnc_semantic_dialogue_flow_smoke.lua` — **PASS**.
- `python3 -m unittest tools.semantic_harness.tests.test_semantic_dialogue_flows -q` — **2/2 PASS**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q` — **94/94 PASS** in 48.394s.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic` — **67/67 PASS** in 2.16s.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/phase2-semantic-report.json` — **67/67 PASS** in 2.20s.
- `python3 tests/run_tests.py` — **FAIL 12/835 executed in 8.06s**. The
  12 failing UI/native headless tests are the unchanged Phase 1 baseline set;
  the added flow smoke accounts for the increase from 834 to 835 tests.
- `pz_verify --kahlua --severity ERROR` — **PASS** for each changed Hoomans
  flow/context/policy Lua file and the Core shared router. No Kahlua errors
  were found. `git diff --check` passed before the phase commits.
- The graph coverage check at generation `2026-10-08T03:19:15Z` reported the
  new flow files as not tracked or metadata-changed and the Core router as
  missing from that project index; those paths were read and tested directly
  from source. This is a graph freshness limitation, not a claim of indexed
  completeness.

The Hoomans graph index was ready with no parse-partial or skipped files at
generation `2026-10-08T03:19:15Z`; changed/untracked evidence files were read
from source because their graph metadata was stale or not tracked. The Core
semantic paths were source-verified because the graph did not index them.

## Phase 2 gate and next bounded chunk

Exit 2 is satisfied: registered identity and wellbeing modules now own typed
flow transitions over bounded existing context, real production Lua proves
interrupt/resume/isolation and preview idempotence, and the existing
full-suite failures are unchanged and unrelated. The native SP/MP gate remains
explicitly open.

**Next Chunk: Phase 3 — identity and wellbeing modular pilots.** Exercise the
two registered flow modules against the existing response/catalog and
authoritative identity boundary, add one flow-owned refusal/variant branch
without a central policy branch, and record the real-worker transition,
response-key and no-side-effect evidence before moving to Phase 4.

Native SP/MP, hosted CI, and live PBrainZ provider acceptance remain
**NOT TESTED**.
