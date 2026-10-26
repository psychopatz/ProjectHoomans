# Semantic Observatory & Dialogue Quality Harness

**Status: PLANNED — documentation and implementation handoff only.** Parent goal is not complete. Base audit: ProjectHoomans main at 0e2d5a23a36badef3a61d35c4a6cdc2d1336f017 (2026-10-26).

## Complete goal

Make the existing Project Hoomans Semantic Lab the trustworthy, agent-first observability and dialogue-quality workbench. Human users and agents (including ChatGPT through authorized repository/desktop access and Codex locally) must be able to discover the **actual loaded** semantic dialogue/response behavior, inspect why a choice or response won or failed, exercise it safely across grounded contexts and EN/TL, find coverage and repetition gaps, propose new variants, and prove those variants work through real production Lua without changing gameplay authority.

**Agents author existing canonical source files; Studio observes, tests, reviews, and compares.** Do not build a competing manual dialogue editor, database, Python semantic policy, standalone app, or inference service.

## Job documents

- [AUDIT.md](AUDIT.md) — source-verified baseline, incomplete capabilities and risks.
- [ARCHITECTURE.md](ARCHITECTURE.md) — durable runtime/catalog/provenance/agent contracts.
- [ROADMAP.md](ROADMAP.md) — entire P0–P7 developer-side objective and acceptance gates.
- [HARNESS_ACCEPTANCE.md](HARNESS_ACCEPTANCE.md) — required evidence for real Lua, EN/TL, safety, scale and GUI/CLI parity.
- [AGENT_RUNBOOK.md](AGENT_RUNBOOK.md) — safe execution, test and Git procedure for unattended implementation.
- [PROGRESS.md](PROGRESS.md) — initial phase, observed baseline and immediate Next Chunk; read last.

No checked-in GOAL_PROMPT.md; provide the short executable /goal in ChatGPT only under root AGENTS.md policy.

## Existing owners / dependencies

- tools/semantic_harness/ — sole application: UI, CLI, persistent Lua worker, scenario/fixture support, inspections and tests.
- tools/semantic_harness/codebuilder/ — existing compiler, reviewed datasets and canonical writer. No replacement compiler.
- ProjectHoomans 42.20 shared/client/server Lua — actual flows, response catalog, realization, commands and presentation.
- PsychopatzCore — generic NLU/IR and translation contracts; never bypass or duplicate it.
- [ContextualDialogueQuestFramework](../ContextualDialogueQuestFramework/) — accepted Studio/CodeBuilder foundation and pre-existing consolidation roadmap; do not reimplement it.
- [SemanticInteractionLifecycle](../SemanticInteractionLifecycle/) — current native conversation and semantic lifecycle authority; do not silently re-open user-owned live acceptance.
- [ContextualSemanticSuggestions](../ContextualSemanticSuggestions/) — typed choice eligibility/presentation owner.

## User-facing destination

Default Studio: **Catalog → Test Lab → Coverage → Review**. Keep advanced graph authoring accessible but secondary. Agent CLI: bounded queries, targeted replay, comparison and review manifests over the **same** worker observations. Neither path may claim a dialogue worked merely because a JSON preview or synthetic-only test succeeded.

## Scope boundary

No Steam Workshop publishing, native PZ launch, user-save mutation, save-file rewrites, additional gameplay commands, new unrelated NPC conversation policy, bulk external-corpus ingestion, or runtime online model dependency. Native SP/MP final test remains user-owned after all developer gates pass.
