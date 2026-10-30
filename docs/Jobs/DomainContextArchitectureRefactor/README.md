# Domain & Context Architecture Refactor

**Status:** Planning accepted; implementation not started.

## Parent objective

Refactor Project Hoomans into an MCP-friendly domain architecture that reduces redundancy, dependency ambiguity, and the amount of code/document context a human or coding agent must retrieve to safely change one behavior, while preserving established gameplay behavior, SP/MP authority, persistence, network, performance, and public runtime contracts.

This job is the continuation of the historical monolith-decoupling effort, but it changes the optimization target.

The goal is **not** to minimize file count, maximize file splitting, or force every file under an arbitrary line limit.

The governing rule is:

> **Fine-grained internally, coarse-grained externally.**

Within a domain, meaningful decomposition is encouraged when it improves retrieval precision, ownership, testability, runtime boundaries, or independent changeability. Across domains, consumers should depend on small public contracts rather than implementation files.

## Why this job exists

The codebase has already benefited from decomposing many large modules. Codebase MCP makes that fine-grained structure valuable because an agent can retrieve a narrow implementation slice instead of ingesting a giant file.

The remaining problem is different:

- some domains expose too much implementation surface;
- provider trees can become fragmented even when they always change together;
- composition roots know hundreds of implementation paths;
- dependency cycles make it difficult to know where a reasoning graph should stop;
- UI, persistence, conversation and other domains still cross ownership boundaries;
- the existing architecture analyzer emphasizes large files/functions more strongly than agent retrieval locality;
- the historical refactor log has become an archival document rather than a useful always-current execution guide.

This job preserves good modular decomposition while adding domain capsules, public facades, dependency-direction rules, and MCP context-cost measurements.

## Core outcomes

1. Define one standard Project Hoomans domain contract.
2. Extend architecture analysis with MCP/context-locality evidence.
3. Prove the contract on a mature vertical slice before broad migration.
4. Make composition depend on domains rather than implementation providers.
5. Break high-value cross-domain dependency cycles.
6. Move persistence and UI behind domain-owned contracts.
7. Reorganize Conversation/Semantics around navigable public subdomains without recreating monoliths.
8. Consolidate artificial micro-fragmentation where evidence shows files always travel together.
9. Continue useful splitting where it improves retrieval precision or ownership.
10. Compress/refocus architecture documentation so current agents do not need historical refactor archaeology.

## Documents

- **AUDIT.md** — verified starting evidence and risks.
- **ARCHITECTURE.md** — target domain-capsule contracts and decomposition/consolidation rules.
- **ROADMAP.md** — mandatory implementation phases and gates.
- **ACCEPTANCE.md** — behavioral, architecture, MCP-context, performance and documentation acceptance.
- **AGENT_RUNBOOK.md** — execution procedure, Codebase MCP workflow and standing constraints.
- **PROGRESS.md** — current phase and immediate Next Chunk.

There is intentionally no checked-in `GOAL_PROMPT.md`. Project Hoomans repository policy keeps the executable `/goal` bootstrap in ChatGPT.

## Historical relationship

`docs/architecture/PROJECT_HOOMANS_REFACTOR.md` and `PROJECT_HOOMANS_MONOLITH_REFACTOR_2026-09.md` remain historical evidence. Do not append the new roadmap's phase-by-phase progress to those files.

The new job owns current architectural migration truth. Git history remains the detailed archive.
