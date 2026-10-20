# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-20. **Documentation-only acceptance reconciliation**, against published ProjectHoomans `main` at `4b4fcd675a6a41d729d53b05a646bd3b3625a5f6` before this commit. No production code or tests executed by this documentation update.
**PARENT STATUS: IN PROGRESS — FINAL ACCEPTANCE REPAIR F1–F4.** Prior H0–H4 developer gate was agent-reported READY, but subsequent source audit found user-required product gaps. Preliminary user smoke testing may proceed, but no full developer-complete claim for the original Semantic Lab/CodeBuilder/Knowledge objective.
**EXACTLY ONE CURRENT EXECUTION CHUNK: F1 — make selected visual CodeBlocks control canonical source and generated dialogue output.** After F1 passes, CONTINUE automatically through F2, F3, F4 in the SAME /goal until entire product works.

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

**Developer/native boundary:** all developer-owned GUI/worker/service tests are in scope. Native Project Zomboid SP/MP live gameplay, Workshop install/hosting/publication remain user-owned and are never prerequisite actions performed by Codex.
