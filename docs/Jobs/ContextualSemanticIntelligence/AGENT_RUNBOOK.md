# Contextual Semantic Intelligence — agent operating rules

This document governs **only** `docs/Jobs/ContextualSemanticIntelligence` and the implementation explicitly assigned by its ROADMAP/PROGRESS. `AGENTS.md` and the canonical Project Hoomans domain contract still take precedence for repository-wide safety and ownership.

## Parallel-agent isolation

- Read this job's `PROGRESS.md`, not another job's. Keep exactly one active Next Chunk here.
- Treat `docs/Jobs/<OtherJob>/` as read-only. Do not update global roadmaps, AGENTS.md, or other jobs' ledgers to record this job's progress.
- Before editing production files, identify their owners, outstanding in-flight changes, and whether another agent is modifying the same files. Overlap requires a non-destructive integration plan, not simultaneous uncoordinated edits.
- A documentation namespace **does not** by itself grant exclusive ownership of shared source files. Shared Semantics/Core/Conversation files need coordinated change windows or separate integration branches.
- Use task-specific branches/worktrees when concurrently implementing jobs; no reset, forced checkout, force push, or destructive reconciliation of another agent's changes.
- Before publishing, inspect worktree/branch/upstream divergence and the expected remote SHA. Do not assume that remote GitHub proves a local worktree clean.
- Direct pushes to main are **not** authorized by this job document. Use the repository's actual standing policy; otherwise publish a reviewed branch/PR.
- Only report commit/PR/CI IDs that actually exist.

## Working loop

1. Reconcile source, tests, runtime evidence and the current Next Chunk; check current HEAD.
2. Choose one bounded vertical slice; inspect existing implementation before adding any abstraction.
3. Modify the smallest production boundary that solves the demonstrated gap; keep regression tests adjacent.
4. Test using the real Lua Semantic Lab worker **and** direct focused Lua tests; enforce `HARNESS_ACCEPTANCE.md`.
5. When relevant, perform Project Zomboid runtime SP/MP acceptance. If unavailable, mark it **not tested** and keep its gate open.
6. Update this job's `PROGRESS.md` to current truth; advance only after the documented gate passes. Adjust `ROADMAP.md` only for scope/gate changes.
7. Commit coherent code, tests and job docs safely; report evidence and the next exact chunk.

## Mandatory technical rules

- PsychopatzCore owns general normalizer, parser, matching, IR and generic bounded state primitives.
- Project Hoomans owns gameplay-aware situation projection, reaction eligibility, social policies, presentation and server task dispatch.
- PBrainZ is optional and must never be required for the offline path.
- Gameplay effects remain server authoritative; semantic interpretation never grants gameplay permission.
- Known safe deterministic turns must not call an LLM; unknown state must not be invented.
- Preserve IR version 1 and existing public response, input, network and save contracts unless a separately accepted migration is necessary.
- Parser/policy/response code should be side-effect-free; preview cannot commit a relationship effect, obligation or task.
- Preserve MarketSense authority over item semantics and the reviewed WordNet compiler; no full WordNet runtime dependency.
- No Jess port, competing response-pool framework, generic DSL, giant content-generation sweep or JSON-only implementation in this job.
- Respect bounded event-driven work; do not add per-NPC per-tick semantic scans.
- Do not use ordinary `pcall`/`xpcall` for normal control flow. Follow `AGENTS.md`.
- Never stage temporary directories inside live watched `media/` trees.

## Stop/report semantics

True blockers: unsafe overlapping edits, missing authorization, proven missing runtime capability, or unsafe repository divergence. Missing runtime evidence is **not** a pass. An unfinished gate stays unfinished. After all mandatory gates pass, set **maintenance-ready**, do not invent features.
