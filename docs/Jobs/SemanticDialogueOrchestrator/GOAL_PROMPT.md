# Copyable /goal — Semantic Dialogue Orchestrator

```text
/goal
Repository: psychopatz/ProjectHoomans; verify local checkout, branches, current HEAD and dependency revisions.
Job: docs/Jobs/SemanticDialogueOrchestrator/ (job-local; do not edit other Jobs/ ledgers).
Read in order: AGENTS.md, this job's AGENT_RUNBOOK.md, AUDIT.md, ARCHITECTURE.md, INTEROP.md, ROADMAP.md, ACCEPTANCE.md, PROGRESS.md, then tools/semantic_harness/README.md and docs/Systems/Semantics.md.
Product objective: lightweight offline hierarchical dialogue flows, typed candidate eligibility, safe interruptions and compositional dialogue; preserve Core NLU, existing PNC conditional response catalog, stable translation keys, game authority and optional PBrainZ.
Current phase: 0, collision correctness. Execute ONLY the one Next Chunk in this job's PROGRESS.md: reproduce screenshot's identity→wellbeing→"im fine thanks" failure through production Lua and trace pending identity/request/relationship effects. Coordinate with ContextualSemanticIntelligence agent; existing feature branch may not be merged. Do not build a new flow framework before observing the failure.
Mandatory test: Semantic Lab doctor + production Lua worker, actual IR/diagnostics, decision branch, context, relationship before/after, transport/toolCalls/LLM count, module manifest; Lua semantic regression and safety controls. JSON fixture validity or conflict-free replay alone does NOT satisfy acceptance. Distinguish native SP/MP from mocks.
Then follow ROADMAP one accepted bounded phase chunk at a time, updating only this job's PROGRESS.md with exact SHAs, commands, results and next chunk. Follow the shared INTEROP.md with translation goal; no overlapping production edits, no force/reset/plain git pull, no unauthorized direct main push.
Report changes, tests, failures, publish revision, native status, and the next bounded chunk. Stop only for genuine safety/authorization/toolchain blocker or when all mandatory gates are maintenance-ready.
```
