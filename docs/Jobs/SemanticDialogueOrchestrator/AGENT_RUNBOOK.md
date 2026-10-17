# Semantic Dialogue Orchestrator — Codex runbook

## Scope and concurrency
- This agent owns only this job's `docs/Jobs/SemanticDialogueOrchestrator/` ledger and the specific production files allocated by its current Next Chunk; it **does not** own all shared Semantics Lua simply by creating this folder.
- Treat `docs/Jobs/ContextualSemanticIntelligence/` and `docs/Jobs/TranslationCatalogModularization/` as read-only. Their goals may be executing concurrently. Check actual worktree, current branches and in-flight changes before touching shared parser, policy, response catalog, bootstrap or harness.
- Job-local worktree/feature branch, independent Semantic Lab processes and unique test report paths. Coordinate file-level change windows. Do not reset/stash/rebase/drop someone else's work or use ambiguous plain `git pull`.
- Publication destination follows actual policy; this document does **not** grant direct-push main authorization. Use reviewed branch/PR unless standing authorization clearly says otherwise. Check expected remote HEAD on publish.

## Mandatory first principles
1. Source audit and baseline before architecture work. Confirm whether the screenshot reproduces on the currently checked-out implementation revision.
2. Server authoritative gameplay and replay/lease/identity admission may not be weakened. NPC relationships may only change for an explicit validated event. Keep deterministic Lua offline without PBrainZ.
3. Reuse established parser/IR/state, response pools, translations and controlled NPC context; no Jess port, duplicate interpreter, new global JSON framework, huge regex priority inflation or broad unrelated refactor.
4. Preserve public APIs, save format, in-game presentation and Build 42 compatibility. Typed candidates are internal until proven safe.
5. Event-driven bounded state; no new per-tick grammar/rules scan. No ordinary `pcall`/`xpcall` for routine control flow; follow repository `AGENTS.md`.
6. Real Lua worker acceptance and source-level effect tracing required. Do not declare completion from JSON, Python mock alone, conflict-free replay or static scripts.
7. Observe `INTEROP.md` with translation job. Translation filesystem/multi-file Core reader implementation belongs to the other goal.

## Execution loop
Check SHAs -> read current `PROGRESS.md` -> execute **one** Next Chunk -> preserve failing baseline evidence -> implement smallest fix -> run doctor, focused real-Lua tests, Lua smoke, broader impacted suites -> record exact outputs and native-game status -> update only this job's `PROGRESS.md`, then advance its Next Chunk after actual gate acceptance. Do not rewrite roadmap every test or claim earlier ledger evidence as newly run. Stop for real ownership/auth/runtime blockers; maintenance-ready only after all mandatory gates.

## Native engine safety
Never stage temporary directories under a watched `Contents/mods/**/media/` while PZ runs; stop the game or stage outside it. Follow `AGENTS.md` throughout.
