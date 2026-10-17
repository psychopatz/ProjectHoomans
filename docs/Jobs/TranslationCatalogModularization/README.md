# Translation Catalog Modularization — independent goal

**Status:** planned/documentation only. **Scope:** Project Hoomans custom EN/TL translation file structure and *reusable* backwards-compatible PsychopatzCore custom-translation loader support. Deliver fine-grained per-subsystem/subfile bundles without turning gameplay routing into JSON content.

## Read order
1. Project Hoomans `AGENTS.md`, then this job's `AGENT_RUNBOOK.md`.
2. `AUDIT.md`, `ARCHITECTURE.md`, `MIGRATION_MATRIX.md`.
3. `ROADMAP.md`, `ACCEPTANCE.md`.
4. `PROGRESS.md` for the only Next Chunk, then `GOAL_PROMPT.md`.
5. Source: `docs/Systems/TranslationAudit.md`, `tools/semantic_harness/README.md`, `tests/pnc_translation_catalog_smoke.lua`, PsychopatzCore `PsychopatzCustomTranslationManager.lua` and its tests.
6. Read-only cross-job contract: `docs/Jobs/SemanticDialogueOrchestrator/INTEROP.md`.

**Outcome:** A new dialogue response variant can be added to a small EN/TL translation bundle registered through an explicit manifest, preserving current `PNC.Translation` public calls, English fallback, live packaged-mod reads and Semantic Lab output; no one must edit the 500+-key `Conversation.json` monolith.

## Repository boundaries
- PsychopatzCore owns generic catalog-loading implementation and public API compatibility; its code change requires its own verified branch/commit/PR or standing authorization. A Project Hoomans documentation PR does **not** grant permission to rewrite Core main.
- Project Hoomans owns manifest declarations, catalog shards, translation bootstrap/segment compatibility and its own Semantic Lab translation tests.
- Existing `common/media/conversation/<type>/<audience>/<language>/<bundle>.json` is **already modular authored dialogue**; leave its source/loader intact unless a specific shared lookup improvement is justified.
- `common/media/lua/shared/Translate/<LANG>/*.json` are **native PZ** translations; do not move or replace them.
