# Translation Catalog Modularization — Codex runbook

## Parallel job ownership
This job owns only `docs/Jobs/TranslationCatalogModularization/` and bounded implementation files selected in its `PROGRESS.md`. Do not edit other Jobs' ledgers. The SemanticDialogueOrchestrator agent owns candidate/flow policy; the existing ContextualSemanticIntelligence agent may still be working on the response catalog. Coordinate shared Hoomans `PNC_TranslationBootstrap*.lua`, `Conversation.json`, response catalog and Semantic Lab files before making edits.

Generic loader changes belong in a **separate PsychopatzCore branch/commit/PR**. Never assume Hoomans branch or repository authorization extends to Core production main. Verify Core and Hoomans local checkout and remote SHA. Do not introduce a Hoomans runtime dependency on an unmerged Core API unless you have arranged the corresponding compatible deployment.

## Work loop
1. Inspect current source, historical audit and feature branch; reconcile actual EN/TL latest key inventory and existing Core functionality.
2. Execute only ONE Next Chunk from this job's PROGRESS; produce bounded diff and regression tests, not an eager multi-system migration.
3. Validate actual Core Lua loader and Hoomans Semantic Lab, not a Python mock of the translation manager. Record precise test versions, results, fallback and loader diagnostics.
4. Follow `docs/Jobs/SemanticDialogueOrchestrator/INTEROP.md`, preserving semantic IDs and translator API calls.
5. Update only this job's PROGRESS and phase doc, advance after acceptance, commit coherently to authorized branch, and report actual SHA. Use reviewed PR when direct-main authorization is absent.

## Hard rules
- No deletion of monolithic catalog before verified manifest cutover; no dual divergent editable sources.
- No wildcard runtime folder scanning, arbitrary file execution, path traversal, duplicate-key overwrite, or unlimited string loading.
- Preserve engine-native Translate and authored conversation-data loaders; do not mix their source responsibilities with custom catalog shards.
- Original EN/TL strings and placeholders must be preserved unless a separate editorial change is approved/tested.
- Lazy resolution/English fallback/language override/audit visibility and existing custom translation public APIs are compatibility requirements.
- Avoid `pcall`/`xpcall` for normal flow; obey repo `AGENTS.md` on watched media paths and safe sync.
- Do not use `git pull` without a reviewed explicit strategy, force-reset/stash other work, or direct-push to main absent standing authorization.
- Runtime unavailable or repository conflict is reported as a real open gate, never a fictional pass.

## Completion
Maintenance-ready only when Core extension, complete Conversation migration, EN/TL parity, Semantic Lab production display, native Build 42 check and regressions are actually accepted.
