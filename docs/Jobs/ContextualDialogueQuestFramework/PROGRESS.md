# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-20. **F1–F3 implementation is committed on existing `main`; F4 product acceptance remains open.** H0–H4 is preserved as historical implementation evidence.
**PARENT STATUS: IN PROGRESS — FINAL ACCEPTANCE REPAIR F1–F4.** The remaining developer-owned work is the integrated generated-interaction, worker-reload, privacy, translation, context, and persistence acceptance. Native Project Zomboid live gameplay remains user-owned.
**EXACTLY ONE CURRENT EXECUTION CHUNK: F4 — complete the Semantic Lab authoring-to-real-worker acceptance and record exact evidence.** Continue until the developer-owned requirements pass or an unavoidable blocker is documented.

## Accepted implementation to PRESERVE

- Prior B0–B6 source and H0–H4 commits were integrated to **existing `main`** via merge `a3c5b5a7`; published current main was `4b4fcd675a6a41d729d53b05a646bd3b3625a5f6`, and PR #4 is **closed and merged**. The former branch is only historical, not a development target.
- Real `grounded_personal_dialogue.json` source, typed `NPC_BACKSTORY`, generated `PNC_SemanticGroundedPersonalDialogue_*.lua`, registered EN/TL `GroundedPersonalDialogue.json`, production loader hooks, worker answers and deterministic direct writer tests exist.
- Backstory generation, sparse state, actual server Knowledge disclosure, selected observed/suspected privacy fixes, player-A/B dossier isolation, follow-ups and PBrainZ filtering have production modules and source-backed tests.
- Former agent reported full Python Semantic Lab **264/264**, focused H0–H4 **31/31**, Lua **853/853**, doctor required checks and changed-file Kahlua **0 errors**. These are **previous recorded runs**, not repeated here. The historical 251/30 Python worker protocol failure and 14+ Lua failures were recorded as resolved in that evidence.
- Earlier per-player Knowledge worker metrics: untouched 0 serialized bytes, one disclosure 746, 100 synthetic NPC notes/200 evidence 72,145 bytes. Synthetic worker-protocol JSON measurements, NOT native PZ runtime sizes or like-for-like 0/1/10 discovery comparison. Additional B6 whole-NPC payload tests used different scopes; see archival ledger.
- Historic complete `PROGRESS.md` preserved verbatim in `HISTORY_H0_H4_ACCEPTANCE_20261020.md`, with exact commands, SHAs and worker outputs.

## Audited remaining product gaps

1. **F1: CodeBlocks composition:** `tools/semantic_harness/codebuilder/service.py::generate_workflow` uses selected block IDs to validate selection, but without caller-supplied `interaction_spec`, it writes the unchanged entire selected dataset via `generate_dialogue_source(source_path)`. The GUI `workflow.py` passes only source ID + block IDs. Two different selections can therefore pass validation yet generate the *same behavior*—not an actual CodeBlocks visual compiler/composer.
2. **F2: Locale value:** H3 real worker TL final response is `Nagtrabaho ako bilang farmer bago ang lahat ng ito.` despite legacy TL fact data containing `occupation.farmer = magsasaka`. Full-sentence translation key resolves, but the authorized dynamic fact value is not correctly localized. Trace stable fact IDs and existing Core-backed translation seam.
3. **F3: Gradual Knowledge:** `PNC_KnowledgeBuiltins.lua` currently gives all ten backstory descriptors `privacy="private"`, `minimumFamiliarity=50`. Disclosure itself is server-authorized and player-scoped; differentiated ordinary/private/sensitive gates and approval/willingness tuning remain.
4. **F4: GUI/evidence/size:** H2 tests prove headless canonical dataset generation and worker restart, but no source-backed end-to-end GUI composition with selected blocks changing output. Historical measured ModData samples lack same-NPC 0/1/10 and comparable pre/post backstory-record overhead.

## F1 current chunk acceptance

- Inspect local status/upstream/other-agent edits and paired Core `2179ee19307a993e186e6da661ad4212e984e0b4` / DT `950b4f887e6f3cb3e311c659b852cbf3ec6f3883` as historical snapshots; verify latest dependency HEAD at runtime. NO new branches, no new PR branches, no blind `git pull`, no destructive user edits; only existing `main`.
- Extend EXISTING `SemanticLabWorkflowPane` + `SemanticLabAuthoringService` + existing InteractionSpec/CodeBuilder hooks to create a real typed **canonical interaction** from selected+connected parameterized CodeBlocks. Preserve existing dataset authoring, existing schema, pure preview, explicit approval, generated-PZ-media output, source provenance and gameplay-policy ownership. Do not invent a second compiler/DSL/GUI or promote UI IDs to direct Lua execution.
- Show two valid block compositions (e.g., a former-job question and a hobby question or different authorized response branches) produce **different** reviewed source, generated Lua/EN/TL artifacts AND actual real-worker final NPC replies. Reject missing required ports/wiring or unauthorized disclosure and keep preview write-/effect-free. Generate proper actual asset paths; byte-stable rerun. Use GUI via Tk/X11 if available; otherwise record graphical gate as unverified, not passing.
- Run focused real worker/CodeBuilder/GUI/service regression and changed-file static checks, commit coherent source/tests/docs, record SHAs and exact outcome. Then immediately advance and IMPLEMENT F2, then F3 and F4 without a new user prompt. Keep final status IN PROGRESS until complete.

**Full acceptance contract:** `FINAL_ACCEPTANCE_CLOSEOUT.md` and `CONVERSATION_ACCEPTANCE.md`. `ROADMAP.md` tracks all F gates. Do NOT write `GOAL_PROMPT.md`: user receives the actual /goal only via ChatGPT.


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
## F2 evidence — authorized fact localization (2026-10-20)

- Source baseline: `007d3fba`; F2 changes are the current uncommitted worker/localization patch and will be committed as the next coherent chunk.
- The existing production path remains authoritative: the server retains the stable fact value (`farmer`) for the authorized disclosure result, while the client lifecycle resolves the current language through `Memory.GetBackstoryText` and the existing Core-backed `PNC.Translation` path.
- The semantic fact source now uses the authorized NPC record only after the existing Knowledge status gate. Suspected observations remain player evidence and are never replaced by canonical private truth.
- Real Lua-worker acceptance for identity seed `90210`, authorized former-job disclosure, TL: final NPC sentence `Nagtrabaho ako bilang magsasaka bago ang lahat ng ito.`; response argument `content=magsasaka`; translation lookups reported `fallbackUsed=false`. EN remains `I worked as farmer before all this.`.
- `python3 -m unittest tools.semantic_harness.tests.test_grounded_personal_dialogue_h3 tools.semantic_harness.tests.test_grounded_personal_dialogue_h2 tools.semantic_harness.tests.test_interaction_spec tools.semantic_harness.tests.test_codebuilder_consolidation -q` — `30` OK, exit `0`.
- Changed Lua files passed `luac5.3 -p`; `git diff --check` passed.
- GUI limitation remains unchanged: CUA exposed no native app surface (`apps=[]`, `browsers=[]`), so graphical interaction evidence is still open and not claimed.

**Next mandatory chunk:** F4 end-to-end Semantic Lab generation, real-worker reload, changed-block behavior proof, translation inspection, privacy/context assertions, and persistence measurements.
## F3 evidence — graduated personal disclosure (2026-10-20)

- Source baseline: `354dcba9`.
- Reused the existing `PNC_KnowledgeDescriptors`, `PNC_NPCKnowledge.CanDisclose`, relationship familiarity scale, and dossier persistence. No second Knowledge store or new NPC biography persistence was added.
- Backstory disclosure tiers are aligned to existing relationship milestones: public `former_job`/`hometown` at familiarity `25`; personal education/hobby/family/value/date-of-birth at `50`; sensitive survival origin/fear/tragedy at `75`.
- All backstory descriptors remain `private`, `allowInference=false`, and `allowObservation=false`; eligibility does not create evidence or automatically reveal a dossier value.
- `python3 tests/run_tests.py pnc_backstory_knowledge_disclosure --jobs 1` — `PASS 1/1`, exit `0`. This covers threshold eligibility, refusal below threshold, no automatic discovery, two-player isolation, confirmed/suspected dossier states, and canonical-truth protection.
- `luac5.3 -p Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Knowledge/PNC_KnowledgeBuiltins.lua` passed; `git diff --check` passed.

**Developer/native boundary:** all developer-owned GUI/worker/service tests are in scope. Native Project Zomboid SP/MP live gameplay, Workshop install/hosting/publication remain user-owned and are never prerequisite actions performed by Codex.

