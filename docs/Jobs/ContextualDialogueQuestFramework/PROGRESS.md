# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-20

**Parent status:** **IN PROGRESS — F1–F4 product acceptance remains open. H0–H4 is preserved as historical implementation evidence.**

**Current chunk:** F1 CodeBuilder/Workflow composition wiring — accepted locally; next chunk is F2 authorized fact localization and worker trace correction.

## Repository and dependency evidence

- Work is on the existing local `main` only. No new branch or worktree was created.
- Prior B0–B6 history was merged locally in `a3c5b5a7` after read-only divergence and `git merge-tree` review. Current-main canonical documentation was retained; the forbidden checked-in `GOAL_PROMPT.md` was excluded.
- Matching PsychopatzCore `main`: `2179ee19307a993e186e6da661ad4212e984e0b4`.
- Matching DynamicTrading `main`: `950b4f887e6f3cb3e311c659b852cbf3ec6f3883`.
- Local Hoomans `main` has not been pushed; remote integration must not be claimed until confirmed.

## H0 baseline and Semantic Lab trace

- Untouched `origin/main` with its paired Core ran `105` Python tests successfully. The broad Lua baseline exited 1 only for `pnc_semantic_local_route_smoke.lua` and `pnc_server_inventory_presence_boundary_smoke.lua`. An archived checkout without the sibling Core produced setup-only `105 tests / 112 errors` and is not a product baseline.
- The merged B0–B6 tree reproduced the reported harness failure: `python3 -m unittest discover -s tools/semantic_harness/tests -q` returned `251 tests in 153.627s`, exit 1, `FAILED (errors=30)`. All 30 errors shared the worker response-limit failure while fetching the generated flow catalog.
- Direct measurement was `22,646` bytes for the handshake and `269,763` bytes for `FLOW_CATALOG` against the prior `262,144`-byte bound. The bounded protocol repair was verified by `17/17` protocol tests and `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json`.
- The real Semantic Lab worker reproduced the B0 ambiguity cases through ordinary `INPUT` turns: social compliments selected the compliment candidates without inventory side effects; genuine inventory questions selected `SemanticInventoryQuery`; undisclosed backstory questions created `KnowledgeDisclosureRequest`; and fresh-context follow-ups clarified. The privileged `BACKSTORY_FACT` command was not used as an ordinary conversation test.
- The initial authoring gap was confirmed: `NPC_BACKSTORY` was absent from the reusable `semantic.codeblocks.v1` compiler contract, and the presentation catalog lacked backstory response bindings.

## Accepted chunks

- `2948fb23ffe45eb058f5be7704cb00e7f548d6ee` — H0 Semantic Lab baseline trace, candidate/side-effect evidence, and confirmed authoring/disclosure gaps.
- `5cd2ec796e488212ca15d095024fb1de277337e9` — H1 Core-backed EN/TL backstory catalogs, manifest registration, template mapping, `content` argument binding, and catalog regression.
- `6b783d09` — progress-ledger integration, exact baseline reproduction, protocol repair, doctor, and full post-fix Python evidence.
- `e7a6adb8ffd2a77a7936016d22db95825b637aa` — shared 512 KiB worker protocol/config bound regression coverage.
- `a3c5b5a7` — local existing-main integration of prior B0–B6 history with current canonical H0–H4 documentation.
- `98b54dc0` — H2 typed `NPC_BACKSTORY` CodeBuilder contract, deterministic supplemental Lua/EN/TL generation, production catalog registration, and fresh-worker load regression.
- `cf5b34c9` — H2 authored `CONTEXT_REFERENCE` backstory follow-ups (`where?`, `do you miss it?`), typed authoring mappings, deterministic generated Lua/EN/TL assets, and updated compiler counts.
- `7ec2e79a` — H3 production disclosure result/snapshot seam, filtered Knowledge/Dossier worker projections, suspected-fact truth-preserving projection, bounded backstory follow-ups, and real-worker regression coverage.
- `eac26ff2` — H3 existing production player-bootstrap hook, two-player Knowledge/Dossier isolation after reload, and suspected observation regression against canonical truth.
- `c5bdd06d` — H4 actual worker ModData-size metrics, bounded synthetic scaling, and optional PBrainZ-context projection regression.

## H1/H2 evidence

- The existing Core-backed translation manager is used for EN/TL response catalogs; no second translation manager or hardcoded language selector was added.
- The canonical source is `tools/semantic_compiler/grounded_personal_dialogue.json`. H2 preview after the follow-up extension returned `previewOnly=True`, `effectFree=True`, `patternCount=7`, `responsePoolCount=13`, `translationCounts={"EN": 13, "TL": 13}`, and review summary `approved=7`, `rejected=0`, `not_candidate=13`.
- Existing Semantic Lab generation wrote the actual Project Hoomans Lua shards, EN/TL translation catalogs, and existing manifest reference. Regeneration is deterministic and uses the existing writer and production catalog loaders.
- H2 regression command: `python3 -m unittest tools.semantic_harness.tests.test_grounded_personal_dialogue_h2 tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_authoring_compiler -q` — 18 tests OK, exit 0 before the new H3 regression file; `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — required checks OK, exit 0.
- Changed Lua passed `/usr/bin/luac5.3 -p`; changed Python passed `py_compile`; `git diff --check` passed for the accepted H2 chunk.

## H3 evidence and next required chunk

The accepted H3 chunk connects the production server disclosure result to the existing client Knowledge snapshot and lifecycle response seam, projects suspected observations without replacing them with canonical private truth, and exposes bounded player-filtered Knowledge/Dossier state to the worker inspector. The shared policy permits an authored unresolved `CONTEXT_REFERENCE` only when recent bounded context contains an NPC backstory answer; unrelated unresolved references still route to clarification.

Real-worker evidence for commit `7ec2e79a` with identity seed `90210` and familiarity `80`:

- `what was your old job` selected `pnc.backstory.question.former_job.old_job`, requested the authoritative disclosure, and produced the complete EN sentence `I worked as farmer before all this.` with `UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob` and typed `content`.
- The same conversation then answered `where?` with the authored follow-up key `UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation` and `do you miss it?` with `UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss`.
- Familiarity `0` produced the translated refusal `I'm not ready to talk about that yet.` without a player Knowledge snapshot.
- TL produced `Nagtrabaho ako bilang farmer bago ang lahat ng ito.` with all translation lookups reporting `fallbackUsed=false`.
- `python3 -m unittest tools.semantic_harness.tests.test_grounded_personal_dialogue_b0 tools.semantic_harness.tests.test_grounded_personal_dialogue_b2 tools.semantic_harness.tests.test_grounded_personal_dialogue_b3 tools.semantic_harness.tests.test_grounded_personal_dialogue_h2 tools.semantic_harness.tests.test_grounded_personal_dialogue_h3 tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_authoring_compiler -q` — 28 tests OK, exit 0.
- `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all required checks OK, exit 0; changed Lua passed `luac5.3 -p`, changed Python passed `py_compile`, and `git diff --check` passed.

- `python3 tests/run_tests.py pnc_backstory_knowledge_disclosure --jobs 1` — `PASS 1/1`, exit 0; the smoke now asserts a suspected observation remains distinct from canonical NPC truth.
- H4 worker metrics: unchanged `PNC_NPCKnowledge` persisted bytes `0`; one disclosed backstory evidence entry `746` bytes; `100` synthetic NPC notes with `2` evidence entries each `72,145` bytes. The metric reports the production table key and `worker_protocol_json_of_production_moddata_table` measurement encoding without serializing generated biographies.
- `python3 -m unittest tools.semantic_harness.tests.test_grounded_personal_dialogue_b0 tools.semantic_harness.tests.test_grounded_personal_dialogue_b2 tools.semantic_harness.tests.test_grounded_personal_dialogue_b3 tools.semantic_harness.tests.test_grounded_personal_dialogue_h2 tools.semantic_harness.tests.test_grounded_personal_dialogue_h3 tools.semantic_harness.tests.test_grounded_personal_dialogue_h4 tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_authoring_compiler -q` — 31 tests OK, exit 0.
- `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all required checks OK, exit 0.

Next mandatory chunk: run the complete Python harness, relevant full Lua suite, deterministic CodeBuilder/translation generation checks, and final integrated authoring-to-worker audit. Reconcile any remaining baseline failures with exact evidence before deciding whether H4 is complete. Keep all work inside the existing Core, Knowledge, persistence, translation, Semantic Lab, and dialogue contracts; do not add a second parser, policy, profile store, or dossier database.

## H4 final integrated acceptance evidence

- Implementation commit: `17adf765`; changes are bounded to production compatibility fixes, Semantic Lab worker normalization, fallback argument rendering, and regression fixtures. The pre-commit audit source was `cbda04ae`.
- Full Semantic Lab Python suite: `python3 -m unittest discover -s tools/semantic_harness/tests -q` — `Ran 264 tests in 173.380s`, `OK`, exit 0.
- Focused H0–H4 suite: `python3 -m unittest tools.semantic_harness.tests.test_grounded_personal_dialogue_b0 tools.semantic_harness.tests.test_grounded_personal_dialogue_b2 tools.semantic_harness.tests.test_grounded_personal_dialogue_b3 tools.semantic_harness.tests.test_grounded_personal_dialogue_h2 tools.semantic_harness.tests.test_grounded_personal_dialogue_h3 tools.semantic_harness.tests.test_grounded_personal_dialogue_h4 tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_authoring_compiler -q` — `Ran 31 tests in 17.176s`, `OK`, exit 0.
- Full Lua regression suite through the real harness: `python3 tests/run_tests.py --jobs 1` — `PASS 853/853 in 17.53s`, exit 0. The previously observed 15 direct broad-suite failures are resolved; the historical `251 tests / 30 errors` worker-limit failure is now reconciled by the `264/0` Python result.
- Direct target regressions: 15/15 passed, including UI fixture loading, persistence provenance, live-body passage behavior, inventory boundary loading, stale-shell safety, generated fallback `content`, and Semantic Lab adapter identity normalization.
- Worker health: `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — required Python, Tk/display, sibling Core, Lua syntax, worker `READY`, `PING`, and `CAPABILITIES` checks all `true`, exit 0.
- Static/regression checks: changed Lua `luac5.3 -p`, changed Python `python3 -m py_compile`, production changed-file `pz_verify.py --kahlua --severity ERROR --no-snippets`, and `git diff --check` all exit 0.
- Acceptance behavior remains verified through the existing worker: EN/TL full NPC sentences, Core-backed translation keys and typed arguments, disclosure/refusal, player-scoped Knowledge/Dossier, follow-up context, suspected-evidence preservation, sparse persistence metrics, and optional PBrainZ filtering. Native Project Zomboid SP/MP and Workshop testing remain user-owned.

**F1 bounded chunk accepted (2026-10-20):**

- Extended the existing `semantic.interaction_spec.v1` contract with typed NPC backstory subject/fact/provider blocks, private server authority, localized typed response arguments, and required semantic/fact/response edges. Existing action specs remain compatible.
- Updated the existing `SemanticLabAuthoringService` and workflow pane so selected backstory blocks materialize a canonical `grounded_personal_dialogue` definition. Preview remains effect-free; approved generation uses the existing dialogue compiler/writer and actual Project Zomboid Lua, EN/TL, and manifest paths.
- Added regression proof that former-job and hometown block compositions produce different canonical definitions, fingerprints, Lua/translation artifacts, and rejection of incomplete typed graphs. Temp-repository generation was byte-stable across regeneration.
- Source SHA before chunk: `4b4fcd675a6a41d729d53b05a646bd3b3625a5f6`. Tests: `python3 -m unittest tools.semantic_harness.tests.test_interaction_spec tools.semantic_harness.tests.test_codebuilder_consolidation tools.semantic_harness.tests.test_grounded_personal_dialogue_h2 tools.semantic_harness.tests.test_grounded_personal_dialogue_h3 -q` — `30 tests OK`; changed Python compiled; `git diff --check` — all exit 0.
- Native Tk/X11 GUI surface is not exposed to the available CUA session (`getState` reported no apps), so graphical interaction evidence remains open; the GUI code path is covered by compilation and service contracts only.

**Next mandatory chunk:** F2 authorized fact localization — pass the bounded authorized NPC record through the existing worker/semantic context without exposing generator truth, format localized fact content through `Memory.GetBackstoryText`/Core translation, and update the real-worker TL acceptance from `farmer` to `magsasaka`.
