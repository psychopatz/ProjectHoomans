# Contextual Semantic Intelligence — progress

**Updated:** 2026-10-17. **Phase:** 6 — native SP/MP and performance acceptance. **Status:** Phase 5 bounded compatibility Semantic Lab gate accepted; Phase 6 remains OPEN because no controlled native SP/MP environment is available. Native SP/MP acceptance remains NOT TESTED.

## Revision evidence

- Audited main: ProjectHoomans `c96cadda1570f59810552f9d3fc55d5c957ba670`; psychopatzCore `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`; PBrainZ `43cc879e673d8d0494d7e77b4ade28fd20a6d4c4`.
- Planning base: `7422dba0d4ea729d65af4284cca87c4af8d7693b`; initial implementation was `d948b9ee`, and the Phase 0A verification repair is `bddeaf3c`.
- The earlier source-only audit recorded that no local checkout or complete dependency closure was available at authoring time. That historical limitation is now cleared for Semantic Lab verification; native Project Zomboid SP/MP and hosted CI remain unexecuted.
- Static review established actual production context is created in `PNC_SemanticDialogueInput_ContextProjection.Build`, and the retained router context includes `dialogueSituation`.

## Implemented in branch; verified by the Phase 0A gate

- `tools/semantic_harness/scenario.py`: default NPC health/activity fields preserve legacy semantics; validates state shapes; explicit null/empty state can represent unknown.
- `tools/semantic_harness/lua/worker/Conversation.lua`: editable NPC health/activity/needs/conditionStats fed into existing `npcState` and snapshot fields with legacy `scenario.world` fallback only when a dedicated NPC state table is absent. Exposes the **production router's** `routedSituation` on each turn; no new fake semantic interpreter.
- `tools/semantic_harness/tests/test_wellbeing_projection.py`: actual `LuaSemanticWorker` checks for healthy/injured/thirst/panic/unknown, legacy world mock compatibility, output safety, multi-turn replay and editable state persistence. The real-worker suite now passes; the exact evidence is recorded below.
- Core NLU, Project Hoomans response catalog, gameplay authority and PBrainZ are unchanged.

## Phase 0A verification evidence — accepted for the Semantic Lab gate

- Revisions: Project Hoomans `bddeaf3c` (`feat/contextual-semantic-harness-phase0a`), PsychopatzCore `0212491d2af3597cceaa7353e62f01ef54adca44`; `/usr/bin/lua5.3` Lua 5.3.6; Python 3.12.3 in `tools/semantic_harness/.venv`.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. The real worker completed READY/PING/CAPABILITIES; Core repository and Lua executable were discovered; worker syntax parsed.
- Production manifest: **PASS**. The worker loaded the real PsychopatzCore semantic module, Project Hoomans catalog/policy/input entry, translation, inventory, identity, authority and network modules. The turn trace included `PNC/Semantics/PNC_SemanticDialogueInput.lua` and `PNC/Semantics/PNC_SemanticDialoguePolicy.lua`; `routedSituation` was read from the production router context after `Submit`.
- `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6**. This includes healthy, injured, severe-thirst, panic, unknown/empty state, legacy world fallback, multi-turn replay, shape validation and nullable context snapshots.
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 53/53**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66** in 1.94s; `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase0a.json`: **PASS 66/66**, report conflicts empty and no audit truncation.
- Real-worker baseline identifiers and observed outputs, all with utterance `wellbeing_okay: "Are you okay?"`, IR `QUESTION/WELLBEING`, pattern `pnc.question.wellbeing_okay`, confidence `0.99`, deterministic `QUESTION_RECEIVED`, `llmCalls=0`, empty `transport` and `toolCalls`, one NPC message, and no conflict:
  - `npc_state_healthy`: routed `healthState=healthy`, `activity.id=idle`, known needs `highest=thirst` at `urgency=normal`; response `semantic.question.wellbeing.default`, “I'm okay. How about you?”.
  - `npc_state_injured`: routed `healthState=injured`, `activity.id=treatment`, `busy=true`; response `semantic.question.wellbeing.injured`, “A little banged up, but I'll manage.”
  - `npc_state_severe_thirst`: routed `healthState=healthy`, `activity.id=fishing`, `needs.highest=thirst`, `urgency=emergency`; response `semantic.question.wellbeing.thirst`, requesting water.
  - `npc_state_unknown`: explicit null health/activity and empty needs/conditions remained absent/unknown in routed situation (`activity.id=unknown`, no `healthState`, no highest need/emotion); the existing default response still says “I'm okay”, a Phase 1 reaction-grounding limitation, not a projection pass.
  - `relationship_trusted` and `relationship_distrustful`: routed social facts remained distinct (`trusted`/friendly/0.9 familiarity versus `hostile`/withdrawn/0.1); the wellbeing response stayed neutral in Phase 0 because relationship reaction changes are later roadmap work.
  - `injured_follow_up`: in one persistent worker, `"What's wrong?"` advanced the real state to sequence 2 and returned deterministic `ASK_CLARIFICATION` with no action/provider call; this records the current Phase 2 continuity gap without claiming follow-up correctness.
- The repair preserves JSON object shape for first-turn `contextBefore` (`{"dialogue": null, "state": null}`) through the real worker protocol; it does not alter IR, policy, response catalog, gameplay authority, transport or PBrainZ behavior. Normal known needs retain the production weighted `highest` field while remaining `normal`, rather than being erased from the projection.
- Native SP: **NOT TESTED**. A Project Zomboid process was present, but no controlled in-game scenario was exercised and no game UI evidence is being promoted from the Semantic Lab mocks.
- Native MP: **NOT TESTED**. No controlled multiplayer session, server admission, lease validation or authoritative task result was exercised; harness `transport=[]` is not multiplayer evidence.

Phase 0A is accepted only for its documented Semantic Lab correctness baseline. The remaining native-game limitations and the Phase 1/2 semantic limitations stay open.

## Phase 0B verification evidence — accepted for the reviewed baseline gate

- `tools/semantic_harness/tests/test_contextual_baseline_matrix.py` at Project Hoomans `35c0e741` is the bounded reviewed matrix; the full observations are in `docs/Jobs/ContextualSemanticIntelligence/BASELINE_MATRIX.md`.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_baseline_matrix -v`: **PASS 3/3** in 2.30s on the final verification run.
- `tools/semantic_harness/run_harness.sh --cli --jsonl --case tools/semantic_harness/scenarios/identity_exchange_case.json`: **PASS** (`ok=true`), 2/2 turns accepted, `conflicts=[]`, no audit truncation; deterministic identity claim routing produced the existing `SemanticIdentityRequest`/`SemanticIdentityResult` boundary and bounded relationship adjustment.
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 56/56** in 20.51s.
- `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6** in 2.66s; `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66** in 1.92s.
- The matrix records greeting, injured wellbeing, fishing activity, time, identity exchange and injured wellbeing follow-up. All assertions read production IR/decision/context and traces from the real worker; deterministic cases used `llmCalls=0` and no unauthorized transport/tool effects. The wellbeing follow-up remains the observed `ASK_CLARIFICATION` continuity gap and was not repaired in Phase 0B.
- No reaction selector, catalog wording or gameplay behavior was changed in Phase 0B. The identity transport is the harness single-player boundary and is not native multiplayer evidence.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No controlled Project Zomboid UI/session/server acceptance is being promoted from these mocks.

## Phase 1A verification evidence — accepted for the Semantic Lab gate

- Implementation revision: Project Hoomans `2a74683a` (`feat/semantic: ground unknown wellbeing responses`); PsychopatzCore remains pinned at `0212491d2af3597cceaa7353e62f01ef54adca44`; `/usr/bin/lua5.3` Lua 5.3.6; Python 3.12.3 in `tools/semantic_harness/.venv`. The detailed evidence is in [`PHASE1A_WELLBEING.md`](PHASE1A_WELLBEING.md).
- The existing production path was retained: `QUESTION_RECEIVED` -> local response -> `resolveQuestion` -> `resolveWellbeing` -> response catalog selection. No second reaction arbiter or gameplay action was introduced.
- Missing health evidence is normalized to selector-only `healthState="unknown"` in `conditionContext`; the routed situation remains source-faithful and omits unavailable health. A separate one-variant unknown pool avoids expanding the already bounded generated wellbeing pool beyond its 16-variant limit. Known healthy, injured, urgent-thirst, panic and stress precedence remains on the existing catalog path.
- The same utterance, `Are you okay?`, now produces the contextual response identifiers `semantic.question.wellbeing.default`, `.unknown`, `.injured`, `.thirst`, `.panic` and `.stress` for the corresponding real-worker states. Unknown state no longer makes the unsupported “I'm okay” claim; its EN/TL translation key is `UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown`.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6**. `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 56/56**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report: **PASS 66/66**, `conflicts=[]`, `audit_truncated=null`, 198 events. Empty conflicts are protocol/replay observations, not semantic proof.
- `pz-verify` reported no new Kahlua or i18n errors in the changed catalog/presentation files. Its existing whole-file token-size warning on the response catalog and two existing identity fallback strings in the local-response file remain outside this bounded chunk; no monolith refactor was started.
- No PBrainZ call, transport effect, tool call or gameplay side effect occurred in the real-worker matrix (`llmCalls=0`); the unknown routed health field remained absent. Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No controlled Project Zomboid UI/session/server evidence is promoted.

## Phase 1B verification evidence — accepted for the Semantic Lab gate

- The audit found no new behavior boundary requiring a reaction-selector hook. resolveWellbeing owns only the unsupported-state guard; stronger need/emotion evidence returns to the existing wellbeing catalog, and Catalog.Select owns condition matching plus explicit priority scoring. The detailed decision and graph/source evidence are in [PHASE1B_SELECTOR_AUDIT.md](PHASE1B_SELECTOR_AUDIT.md).
- Added one focused real-worker regression method covering unknown health with urgent thirst, panic, and simultaneous panic-plus-thirst. The existing catalog returned thirst, panic, and panic respectively; panic precedence remains explicit through the existing priority values. No production selector or arbiter was added.
- python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v: PASS 7/7. python3 -m unittest discover -s tools/semantic_harness/tests -q: PASS 57/57. tools/semantic_harness/run_harness.sh --test pnc_semantic: PASS 66/66. CLI report: PASS 66/66, 198 events, conflicts=[], audit_truncated=null; these are protocol/replay observations, not semantic proof.
- The existing identity, gift, task and social coverage remained green through the broader Semantic Lab suite. Every new regression turn used llmCalls=0, with no transport events, tool calls or gameplay effects. Native SP: NOT TESTED. Native MP: NOT TESTED.

## Phase 2 verification evidence — accepted for the Semantic Lab gate

- Implementation revision: Project Hoomans `41ecbb4f` (`feat(semantic): resolve bounded wellbeing follow-ups`); the detailed evidence is in [`PHASE2_MULTITURN.md`](PHASE2_MULTITURN.md).
- The real production parser now recognizes authored `What's wrong?` and `What is wrong?` follow-ups as `QUESTION/WELLBEING` with a bounded wellbeing continuation marker. The existing response path uses compact prior-NPC-answer context and the existing catalog selector; no new reaction arbiter or gameplay action path was added.
- Persistent real-worker evidence: injured, thirst, panic, and unknown snapshots selected grounded follow-up variants. The two-turn case retained `currentTopic=wellbeing`, `lastSpeaker=npc`, advanced semantic state `1 -> 2` and dialogue context `2 -> 4`, used `llmCalls=0`, and emitted no transport/tool/action effects.
- The worker `PREVIEW` command ran the production router twice for `What is wrong?`; both results matched, each before/after context matched, and the surrounding state was unchanged apart from protocol request IDs. No response was queued and no context turn was recorded.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. Focused contextual/wellbeing tests: **PASS 12/12**. Full Python suite: **PASS 59/59**. Lua `pnc_semantic`: **PASS 66/66**. CLI report: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; those protocol/replay values are not semantic proof.
- EN/TL conversation JSON parsed with all eight follow-up keys present; a real TL worker turn resolved the new injured follow-up key. `pz-verify` reported zero Kahlua errors; existing hardcoded-string/token-size findings remain outside this bounded gate.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. Empty Semantic Lab transport and PZ process presence are not native acceptance evidence.

## Phase 3A verification evidence — accepted for the bounded Semantic Lab gate

- Implementation revision: Project Hoomans `bdb0a68b` (`feat(semantic): add contextual apology reactions`); the detailed evidence is in [`PHASE3A_SOCIAL_APOLOGY.md`](PHASE3A_SOCIAL_APOLOGY.md).
- The bounded slice uses the existing `APOLOGIZE` parser/IR and `SOCIAL_ACKNOWLEDGED` branch. It adds one `semantic.apology` catalog with five explicit variants: stressed, friendly, trusted, withdrawn and default. Catalog priority makes severe stress/panic win over friendly social style; no new reaction arbiter, parser family, task, obligation or relationship mutation was introduced.
- Focused real-worker tests: **PASS 3/3**. Full Python suite: **PASS 62/62**. Existing contextual social reactions for friendly compliments, busy threats and stressed self-reflection remained deterministic and local.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report `/tmp/contextual-semantic-suite-phase3a.json`: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; those protocol/replay values are not semantic proof.
- EN/TL conversation JSON each parsed with 509 keys and all five apology keys present. A real TL worker apology selected `UI_PNC_Conversation_Semantic_ApologyFriendly` and returned the TL text. Every focused turn used `llmCalls=0`, empty transport/tool traces, no action result, and equal `relationshipBefore`/`relationshipAfter`.
- `pz-verify` over the semantic directory: **0 Kahlua errors**. Existing hardcoded-string findings (12 files) and token-size warnings (26 files, including the already-large social catalog) remain documented; they are not treated as a Phase 3A correctness failure. Changed Lua files also passed `luac5.3 -p`.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. Semantic Lab transport emptiness and a present PZ process are not native acceptance evidence.

## Phase 3B verification evidence — accepted for the bounded Semantic Lab gate

- Implementation revision: Project Hoomans `c7d2124f` (`feat(semantic): add guarded threat reactions`); the detailed evidence is in [`PHASE3B_SOCIAL_THREAT.md`](PHASE3B_SOCIAL_THREAT.md).
- The existing `THREATEN` parser/IR, `THREAT_RECEIVED` policy branch, `semantic.threat` response pool and authorized social-dispatch boundary were retained. Three guarded catalog variants were added: stressed/panicked, withdrawn, and trusted. Explicit precedence is stress (5) > busy (3) > withdrawn (2) > trusted (1) > default; the existing busy response remains selected for the default reserved/busy worker.
- Focused contextual social tests: **PASS 4/4**. Full Python suite: **PASS 63/63**. Apology, friendly compliment and stressed self-reflection coverage remained green.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report `/tmp/contextual-semantic-suite-phase3b.json`: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; those protocol/replay values are not semantic proof.
- EN/TL conversation JSON each parsed with 512 keys and all three new threat keys present. Changed Lua files passed `luac5.3 -p`. `pz-verify` over the semantic directory reported **0 Kahlua errors**; existing hardcoded-string and token-size findings remain bounded maintenance findings.
- Threat turns remained deterministic (`llmCalls=0`), emitted no messages in the existing directed-hostility presentation path, no transport or tool calls, and no relationship mutation. The existing authorized social-dispatch result is reported as `accepted=false`, `semantic_social_transport_unavailable` by the harness; this is a harness boundary, not proof of native delivery.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No Semantic Lab result is promoted as native acceptance evidence.

## Phase 3C verification evidence — accepted for the bounded Semantic Lab gate

- Implementation revision: Project Hoomans `c74f5966` (`feat(semantic): add contextual offer reactions`); the detailed evidence is in [`PHASE3C_SOCIAL_OFFER.md`](PHASE3C_SOCIAL_OFFER.md).
- The existing `OFFER` parser/IR, `OFFER_RECEIVED` policy branch and `semantic.offer` catalog were retained. Four variants were added: stressed/panicked, friendly, trusted and withdrawn. Explicit precedence is stress (4) > existing hunger (2) > social tone (1) > default; generated hunger variants remain available and selected for hungry cases.
- Focused contextual social tests: **PASS 5/5**. Full Python suite: **PASS 64/64**. Phase 2, apology and guarded threat coverage remained green.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report `/tmp/contextual-semantic-suite-phase3c.json`: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; those protocol/replay values are not semantic proof.
- EN/TL conversation JSON each parsed with 516 keys and all four new offer keys present. Changed Lua files passed `luac5.3 -p`. `pz-verify` over the semantic directory reported **0 Kahlua errors**; existing hardcoded-string and token-size findings remain bounded maintenance findings.
- Offer turns emitted one deterministic NPC message, used `llmCalls=0`, empty transport/tool traces, no action result, and equal relationship snapshots. The stress-plus-hunger case selected the stressed offer response, proving the explicit precedence without mutating inventory, relationship, task or obligation state.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No Semantic Lab result is promoted as native acceptance evidence.

## Phase 3D verification evidence — accepted for the bounded Semantic Lab gate

- Implementation revision: Project Hoomans `864b118f` (`feat(semantic): add contextual dispute reactions`); the detailed evidence and Phase 3 closure audit are in [`PHASE3D_SOCIAL_DISPUTE.md`](PHASE3D_SOCIAL_DISPUTE.md).
- The existing `DISAGREE`/`REFUSE` parser/IR, `SOCIAL_ACKNOWLEDGED` policy branch and `semantic.refuse` pool were retained. Four guarded variants were added: stressed/panicked, friendly, trusted and withdrawn. Explicit precedence is pending request (5) > stress (4) > friendly (2) > trusted/withdrawn (1) > default, so an authorized pending request remains the stronger response context.
- Focused contextual social tests: **PASS 6/6**. Full Python suite: **PASS 65/65**. Existing reassurance behavior remains covered by the unchanged self-reflection relationship/trait test (friendly and established/reserved cases).
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report `/tmp/contextual-semantic-suite-phase3d.json`: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; those protocol/replay values are not semantic proof.
- EN/TL conversation JSON each parsed with 521 keys and all five dispute/request keys present. Changed Lua files passed `luac5.3 -p`. `pz-verify` over the semantic directory reported **0 Kahlua errors**; existing hardcoded-string and token-size findings remain bounded maintenance findings.
- Phase 3A–3D together cover apology, reassurance/self-reflection, threat, offer and dispute reactions through the existing production parser, policy and catalog paths. Deterministic cases used `llmCalls=0`; ordinary social turns emitted no transport/tool effects and kept relationship snapshots equal. Threat keeps the existing authorized social-dispatch boundary, which is unavailable in the harness; pending-dispute setup uses the existing follow command and the dispute itself emits no new command.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No Semantic Lab result is promoted as native acceptance evidence.

Phase 3 is accepted for this bounded Semantic Lab scope: authored apology, existing reassurance/self-reflection, guarded threat, contextual offer and contextual dispute responses, including explicit overlap precedence and no new unauthorized mutation. This does not accept paraphrase breadth, group dialogue, PBrainZ fallback, or native SP/MP behavior.

## Phase 4 verification evidence — accepted for the bounded Semantic Lab gate

- Implementation revision: Project Hoomans `78674253` (`feat(semantic): add reviewed wellbeing paraphrase`); the detailed evidence is in [`PHASE4_PARAPHRASE.md`](PHASE4_PARAPHRASE.md). PsychopatzCore remained at `0212491d2af3597cceaa7353e62f01ef54adca44`.
- The baseline probe showed `how are you doing` reaching deterministic `ASK_CLARIFICATION` without an IR intent, subject or pattern, while the authored `how are you holding up` form already reached `QUESTION/WELLBEING`. The bounded change adds only the exact reviewed dialogue-dataset entry `pnc.dataset.question.wellbeing.how_are_you_doing`, with `QUESTION/QUESTION/WELLBEING`, confidence `0.99` and priority `120`; the existing compiler regenerated the Lua data shard.
- Focused paraphrase tests: **PASS 2/2**. Compiler tests: **PASS 7/7**. Full Python suite: **PASS 67/67**. The focused test also preserves the existing wellbeing paraphrase and holds out `walk with me`, `followed the trail` and `we are following them` as clarification-only, with no action, transport, tool or LLM effect.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report `/tmp/contextual-semantic-suite-phase4.json`: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; these protocol/replay values are not semantic proof.
- Changed generated Lua passed `luac5.3 -p`. `pz-verify` over the semantic directory reported 0 Kahlua errors and 0 warnings; the broad mod-wide report remains noisy with pre-existing hardcoded-string/token-bloat findings and one existing Kahlua-warning file, but zero Kahlua errors.
- No WordNet allowlist or fuzzy command behavior was expanded. The reviewed source uses the existing exact dialogue compiler path; no response catalog ID, PBrainZ call, transport effect, gameplay action or relationship mutation was introduced. Native SP: **NOT TESTED**. Native MP: **NOT TESTED**.

Phase 4 is accepted only for this one reviewed paraphrase and its held-out false-positive boundary. It does not accept broad paraphrase coverage, group dialogue, PBrainZ fallback or native SP/MP behavior.

## Phase 5 verification evidence — accepted for the bounded Semantic Lab gate

- Implementation revision: Project Hoomans `338f97e7` (`test(semantic): verify provider and group parity`); the detailed audit is in [`PHASE5_PBRAINZ_GROUPS.md`](PHASE5_PBRAINZ_GROUPS.md). No production runtime code changed.
- The ownership audit traced `SubmitProviderFallback` through the optional PBrainZ submit path and confirmed fail-closed deterministic clarification on provider absence/rejection. The bounded provider payload retains semantic fallback/IR, dialogue situation, entity index and participant projections. Group refresh/submit/fan-out retains one canonical interpretation, actual member speaker identity, per-member context routing and one group-wide action dispatch.
- Real-worker provider parity tests: **PASS 2/2**. Recognized `follow me` had identical deterministic `REQUEST/FOLLOW` IR and authorized action with provider disabled/enabled; unknown input remained clarification-only, and the enabled harness adapter's rejected provider attempt did not authorize an action.
- Focused provider/group Lua cases: **PASS 3/3** (`pnc_semantic_group`, `pnc_pbrainz_context`, `pnc_pbrainz_provider_availability`). PBrainZ semantic/integration smoke cases excluding the unrelated native-button fixture: **PASS 11/11**. Full Python suite: **PASS 69/69**. Compiler tests: **PASS 7/7**.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report `/tmp/contextual-semantic-suite-phase5-semantic.json`: **PASS 66/66**, 198 events, `conflicts=[]`, `audit_truncated=null`; those protocol/replay values are not semantic proof.
- `pz-verify` over the semantic directory reported 0 Kahlua errors and 0 warnings. The broader PBrainZ selection remains `12/13` only because the unrelated `pnc_pbrainz_native_button_smoke.lua` fixture is stale/missing an `ISUI/ISImage` preload; it fails before semantic assertions and was not changed.
- Live provider-success behavior was **NOT TESTED**; the enabled worker adapter intentionally rejects the external request after recording the attempted call. Native SP: **NOT TESTED**. Native MP: **NOT TESTED**.

Phase 5 is accepted only for deterministic/provider-failure parity, bounded provider context and group speaker/participant isolation. It does not accept live provider-generated responses or native SP/MP behavior.

## Phase 6 status — native gate remains open

- The bounded status and evidence boundary are recorded in
  [`PHASE6_NATIVE_STATUS.md`](PHASE6_NATIVE_STATUS.md).
- Semantic Lab/live semantic parity is now contract-tested in
  [`PHASE6_SEMANTIC_LIVE_PARITY.md`](PHASE6_SEMANTIC_LIVE_PARITY.md): the
  worker loads the checked-out production input/lifecycle/provider modules,
  calls the public production `DialogueInput.Submit` entrypoint, and reads
  production-owned IR/decision/routed-situation results. The fresh parity
  contract passed **4/4**; the real-worker contextual slice passed **26/26**;
  the full Semantic Lab Python suite passed **81/81** after the native-retest
  discrepancy repair.
- No production semantic behavior changed after Phase 5. No controlled native
  single-player scenario or authoritative multiplayer session was completed
  in this checkpoint. A bounded non-native real-Lua-worker performance result
  is recorded in [`PHASE6_SEMANTIC_PERFORMANCE.md`](PHASE6_SEMANTIC_PERFORMANCE.md).
- The non-native measurement is Project Hoomans `3027891d` with
  PsychopatzCore `0212491d2af3597cceaa7353e62f01ef54adca44`, Python 3.12.3
  and Lua 5.3.6. The command was
  `python3 -m tools.semantic_harness.phase6_performance --samples 8 --warmup 2
  --serial-turns 24`; it passed for the real Lua worker and wrote
  `/tmp/contextual-semantic-phase6-performance-final.json`. The follow,
  reviewed wellbeing and unknown fallback branches remained deterministic;
  provider calls were `0/0/0` disabled and `0/0/1` enabled respectively.
- The static request-driven and server-boundary guards are Project Hoomans
  `804eff7b` and `ffad31f4`:
  `python3 -m unittest
  tools.semantic_harness.tests.test_phase6_static_boundaries -v` passed **3/3**;
  the full Semantic Lab Python suite is now **81/81**. It found no
  `Events.OnTick` registration in the `PNC_SemanticDialogueInput*.lua`
  modules and retained the server-side authority/lease/replay gates. This is
  a static/request-boundary result, not native game evidence.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. Existing process,
  console, profiler, Semantic Lab and replay observations are not promoted as
  native proof.
- Live PBrainZ provider success: **NOT TESTED**. The accepted Phase 5 result
  remains deterministic/provider-failure parity only.

### Native retest discrepancy repair

The first controlled native conversation exposed two parity gaps: the live
entry `whats wrong` had no authored alias, and a minor live wound arrived as
`healthState=normal` with bounded body-health/HP evidence rather than the
synthetic `injured` state used by the earlier harness cases. Production now
maps the exact unpunctuated alias and derives `injured` from the live wound/HP
contract; Semantic Lab accepts the same shape. A full PZ restart is required
before retesting because the running client has already loaded the old Lua
modules.

## ONE current Next Chunk — Phase 6 native SP/MP and performance acceptance

1. Run controlled Project Zomboid Build 42 single-player scenarios for the accepted semantic slices, including the reviewed paraphrase, contextual reactions, provider-disabled fallback and nearby group behavior.
2. Run controlled multiplayer/server-authority scenarios for action requests, group turns, leases, late callbacks and save/reload boundaries; record exact build and failures.
3. Measure dialogue overhead, queue/tick behavior, bounded context size and provider-disabled cost; preserve the existing action-plan and response queues.
4. Keep live PBrainZ success explicitly open until a real bridge/provider response has been exercised and normalized through the existing Semantic IR contract.

## Remaining roadmap

0B baseline characterization -> 1 wellbeing reactions -> 2 multi-turn -> 3 social -> 4 paraphrases -> 5 PBrainZ/groups -> 6 SP/MP + performance acceptance.

No new reaction arbiter or gameplay feature is claimed in Phase 5; the production runtime is unchanged and the new evidence is test/audit coverage.
