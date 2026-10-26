# Semantic Observatory & Dialogue Quality Harness

**Status: IN PROGRESS — P3/P7 reopened for Startup & Session Parity after live Semantic Lab findings; P0/P1/P2/P4/P5/P6 remain accepted.** Parent goal is not complete. Reverify the actual checkout/worktree before acting; do not rely on this overview for a current commit SHA.

## Complete goal

Make the existing Project Hoomans Semantic Lab the trustworthy, agent-first observability and dialogue-quality workbench. Human users and agents (including ChatGPT through authorized repository/desktop access and Codex locally) must be able to discover the **actual loaded** semantic dialogue/response behavior, inspect why a choice or response won or failed, exercise it safely across grounded contexts and EN/TL, find coverage and repetition gaps, propose new variants, and prove those variants work through real production Lua without changing gameplay authority.

**Agents own semantic structure and gameplay logic. Simulation is the single GUI execution/test workbench; Studio becomes the human/agent content workbench: Explore + Dialogue Content + Review.** Phrase wording is edited through a reviewed canonical CodeBuilder source, while structural flow/block/interaction mutation moves to Developer Tools. Do not build a competing simulator, runtime dialogue database, Python semantic policy, standalone app, or inference service.

## Job documents

- [AUDIT.md](AUDIT.md) — source-verified baseline, incomplete capabilities and risks.
- [ARCHITECTURE.md](ARCHITECTURE.md) — durable runtime/catalog/provenance/agent contracts.
- [SURFACE_CONSOLIDATION.md](SURFACE_CONSOLIDATION.md) — mandatory Simulation/Studio/World Browser/Log ownership and redundancy-removal design.
- [DIALOGUE_CONTENT_REGISTRY.md](DIALOGUE_CONTENT_REGISTRY.md) — content-only phrase registry, EN/TL authoring, anti-repeat realization and Studio Dialogue Content design.
- [ROADMAP.md](ROADMAP.md) — entire P0–P7 developer-side objective and acceptance gates.
- [HARNESS_ACCEPTANCE.md](HARNESS_ACCEPTANCE.md) — required evidence for real Lua, EN/TL, safety, scale and GUI/CLI parity.
- [AGENT_RUNBOOK.md](AGENT_RUNBOOK.md) — safe execution, test and Git procedure for unattended implementation.
- [PROGRESS.md](PROGRESS.md) — reconciled current phase state, verified evidence and immediate Next Chunk; read last.

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

Target UI ownership: **Simulation = execute/test/compare**, **Studio = Explore + Dialogue Content + Review**, **World Browser = saved-target discovery**, **Log = activity timeline**. The former Studio Test Lab/Coverage runner is now removed from the user-facing Studio surface; its shared matrices and selector coverage run from Simulation → Compare / Regression. See SURFACE_CONSOLIDATION.md. Agent CLI remains the bounded headless parity surface over the same worker/services.

## Scope boundary

No Steam Workshop publishing, native PZ launch, user-save mutation, save-file rewrites, additional gameplay commands, new unrelated NPC conversation policy, bulk external-corpus ingestion, or runtime online model dependency. Native SP/MP final test remains user-owned after all developer gates pass.
