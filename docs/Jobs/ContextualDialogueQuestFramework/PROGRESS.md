# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-20. **Documentation-only planning update on existing `main`; NO production code changes or new tests performed in this update.**
**PARENT STATUS:** **IN PROGRESS — H0–H4 REQUIRED. NOT READY FOR USER LIVE TEST under the full authoring/translation/Knowledge/Dossier contract.**
**EXACTLY ONE CURRENT EXECUTION CHUNK:** **H0 — actual Semantic Lab/CodeBuilder/real-worker baseline and failure classification.** Agent must continue H1→H4 autonomously after successful H0; chunk acceptance is not parent completion.

## Verified remote source baseline

- Hoomans `main` before these docs: `baec079e9718606f8510f72fb129f4cd82ae24db`; no `docs/Jobs/ContextualDialogueQuestFramework/` directory at that checkpoint.
- EXISTING old development branch `docs/contextual-dialogue-quest-framework-20261018` at `4755622022f244f9cd890039b705c0badf0cf57a`; code has B0–B6 and the previous ledger. PR #4 OPEN, unmerged, GitHub mergeable=false at inspection. The agent's local worktree state and `codex/contextual-dialogue-quest-framework-0a` were not independently inspected.
- Paired PsychopatzCore remote main `2179ee19307a993e186e6da661ad4212e984e0b4`, which already contains Core-backed `PsychopatzCustomTranslationManager`. No need for a new translator.
- Core Foundation P1–P9 is separately agent-reported developer accepted; this does not implement semantic CodeBuilder/translation recovery.

## What actually exists in old branch

- Real B0–B3 Lua/worker tests, plus B4 dossier and B5 continuity Lua tests and B6 synthetic persistence measurements; agent ledger says B0–B6 accepted. Production backstory provider and Knowledge/Dossier/PBrainZ adapters exist there.
- Existing `tools/semantic_harness` includes working GUI/CLI/shared `SemanticLabAuthoringService`, `semantic.codeblocks.v1`, compiler/writer, persistent real Lua worker and translation instrumentation; new B0–B6 authoring was not end-to-end generated through CodeBuilder.
- New backstory response IDs are not mapped in semantic client translation-key resolver; EN/TL response sentence catalogs have no such entries; `content` is not picked up by current response argument mapping. Older `conversation/backstory/shared/EN|TL/facts.json` localizes nouns via legacy TextLoader; e.g. B2 smoke asserts TL `doktor`, not a whole TL sentence through Core's custom catalog manager.
- B2/B3 worker `BACKSTORY_FACT` diagnostic uses privileged `authoritativeBackstoryAccess=true`; not gameplay-equivalent ordinary player conversation. `suspected` fact projection may substitute canonical seed truth where only unconfirmed player observation was allowed.
- Progress claim "full Python semantic harness passed" contradicts supplied terminal `251 tests in 164.991s; FAILED(errors=30)` (exit 1). Full Lua ledger `839/853`, 14 failures agent-classed preexisting, not independently confirmed. Reported B6 synthetic serialized payload `2664 bytes/one NPC; 269760 bytes/100; 2706037 bytes/1000` is not real native ModData proof. No new full run in this docs turn.

## H0 — ONE NEXT CHUNK, exact acceptance

1. Verify local/main/old branch divergence and matched Core/DT source, working tree, concurrent files and watched-media safety; NO new branch or further new commits on old dev branch. Find safe existing-main integration path; report concrete conflicts if unsafe rather than reset/rebase/force-push or invent a replacement branch.
2. Run **the existing Semantic Lab**: inspect GUI CodeBuilder/Flow/Simulation where feasible, existing `SemanticLabAuthoringService`, production compiler, generated assets and persistent Lua worker. Document `NPC_BACKSTORY` unsupported authoring fields, absent backstory translation key/arg bindings, missing person-scoped disclosure and dossier visual trace.
3. Reproduce a minimal EN/TL player-conversation scenario using real worker input and visible rendered NPC replies, not only `BACKSTORY_FACT` or internal fact IDs. Record parser candidates, backstory fact provenance, player permission/Knowledge state, translation lookups and actual output/transport. If hooks are missing, mark explicit untested/evidence gap; do not fake server permission through Python.
4. Re-run actual `python3 -m unittest discover -s tools/semantic_harness/tests -v` at exact source/paired Core state; preserve 30-error traceback classification and terminal exit code. Compare known 14 failing Lua modules to the earlier baseline with precise evidence; keep valid B0–B6 focused passes in historical context, no false green. Do not trigger native Project Zomboid or Workshop.
5. Make necessary bounded harness/inspection correction only if needed to establish a usable baseline, then commit source/tests/docs to safely authorized EXISTING `main`, update this ledger with exact SHAs/results and set H1 next; immediately continue H1–H4 in same assignment.

**Stop rule:** developer-ready requires all H0–H4 acceptance gates, actual generated + translated NPC conversations, factual privacy, Dossier and full testing/integration on existing main. If integration unsafe, report proven blocker while completing independent safe work; do NOT report `COMPLETED` because a partial chunk passed.

See `HARNESS_FIRST_CODEBUILDER_TRANSLATION_RECOVERY.md` and `GIT_INTEGRATION_AND_NO_NEW_BRANCHES.md`. The user receives the actual `/goal` **only in chat**, not in a repository MD file.
