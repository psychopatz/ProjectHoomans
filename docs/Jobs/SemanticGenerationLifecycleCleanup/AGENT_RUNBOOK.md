# Agent Runbook — G8R7 Portability Closure

## Startup

For every participant repo:
1. read root `AGENTS.md`;
2. inspect branch/HEAD/upstream/worktree;
3. preserve unrelated work;
4. read `PROGRESS.md`, `HANDOFF.md`, then active ROADMAP gate;
5. inspect exact source/tests before editing.

Primary job repo: ProjectHoomans.
Compiler/toolchain owner: PsychopatzCore.
Current generated adopters: ProjectHoomans and DTCommon.

Do not create a branch.

## Reuse before invention

Reuse accepted compact-PSDL, portable-plan, capability, descriptor and inspection systems. For G8R7B reuse the existing Lua ConvoProbe/studio trace infrastructure where practical; do not create a second PZ simulator.

## Backend discipline

Generic compiler code resolves descriptors and dispatches through one backend interface. Backend-specific renderers live behind that interface. Do not add game-specific semantics to dispatch.

## Acceptance discipline

Projection equivalence is weaker than runtime equivalence. Execute both Reference VM and Lua/PZ runtime and compare normalized semantic traces.

## Git/docs

Preserve unrelated work; stage exact phase-owned paths only; participant commits first; ProjectHoomans/job docs last; no push/publication without authorization.

ROADMAP = remaining gates. PROGRESS = current truth + one Next Chunk. HANDOFF = current baton. ARCHITECTURE = stable contracts. Git history = archive.
