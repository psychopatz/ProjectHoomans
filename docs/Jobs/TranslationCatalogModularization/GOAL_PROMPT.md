# Copyable /goal — Translation Catalog Modularization

```text
/goal
Repositories: psychopatz/ProjectHoomans and psychopatz/psychopatzCore; independently verify local checkout, branch, HEAD and publication permissions for EACH.
Job: docs/Jobs/TranslationCatalogModularization/ (own progress only, do not modify other job ledgers).
Read: Project Hoomans AGENTS.md, this job's AGENT_RUNBOOK.md, AUDIT.md, ARCHITECTURE.md, MIGRATION_MATRIX.md, ROADMAP.md, ACCEPTANCE.md, PROGRESS.md; docs/Systems/TranslationAudit.md; Core CustomTranslationManager source/tests; docs/Jobs/SemanticDialogueOrchestrator/INTEROP.md read-only.
Goal: migrate oversized single-file custom Conversation translations into explicit per-subsystem EN/TL manifest shards, through an OPTIONAL backwards-compatible generic Core loader. Preserve existing translation APIs, all stable keys, language fallback, English/Tagalog parity, authored conversation bundles, native PZ Translate, optional PBrainZ and server behavior.
Current phase: 0 baseline. Execute ONLY one Next Chunk from PROGRESS.md: inventory exact latest EN/TL catalogs including unmerged semantic branch additions, test current Core+Hoomans loader behavior in real Lua/Semantic Lab, verify Trading lookup, and specify bounded optional Core reader tests. Do not move/delete Conversation.json or rewrite Core before proving baseline and compatibility.
Mandatory test evidence: actual Core getModFileReader, Hoomans production translation lookups and selected response strings in EN/TL, placeholder/key ownership, fallback/audit, no duplicate keys, old system behavior, exact SHAs. JSON parse/parity alone does not prove runtime.
After gate acceptance follow ROADMAP one bounded chunk at a time; Core changes in separate Core branch/PR, Hoomans changes in its own controlled branch, coordinate shared files and use stable cross-job INTEROP. Update only this job's PROGRESS with exact commands/results and next chunk. No force reset, ambiguous git pull, unauthorized direct main push, or temporary dirs in watched media.
Report changes, actual test results, missing game SP/MP evidence, published SHAs and next chunk. Stop only for real blocker or complete maintenance-ready gates.
```
