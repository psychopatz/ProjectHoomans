# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — planning accepted; implementation has not started.

## Parent objective

Complete the P0-P8 Domain & Context Architecture Refactor defined in `ROADMAP.md`.

The parent objective is not complete until final acceptance in `ACCEPTANCE.md` passes.

## Verified starting state

At planning time:

- repository: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`;
- branch: `main`;
- HEAD: `2c4bdc433df4f2f534842a1e117b0cfea1f8dfe8`;
- worktree was clean;
- local main was 6 commits ahead of `origin/main`;
- current runtime tree contained 3,260 Lua files;
- direct source scan found ~472k Lua LOC excluding the two giant DebugCatalog files;
- root `AGENTS.md` was already lean/durable;
- checked-in architecture snapshot reported 33 dependency-cycle findings and highest pressure in Conversation, Persistence, UI, Semantics and Composition;
- historical refactor documentation is archival and must not be used as current phase truth.

These values are planning evidence only. P0 must refresh graph/test evidence before implementation claims.

## Current phase

**P0 — Fresh architecture and MCP context baseline**

No production architecture changes are accepted yet for this job.

## Immediate Next Chunk — P0A

Establish fresh repository and graph truth without modifying production architecture.

Required work:

1. re-verify branch/HEAD/status/upstream and concurrent work;
2. refresh Codebase MCP / code graph / architecture-audit evidence against the actual current HEAD;
3. classify maintained runtime, tooling, tests, generated and declarative paths;
4. identify the real current cross-domain cycles and collapse duplicate manifestations into root architectural cycle groups;
5. capture current composition-domain versus leaf-provider fan-out;
6. establish the current full developer-side test baseline;
7. record any stale/false-positive analyzer findings;
8. update this `PROGRESS.md` with the accepted P0A evidence;
9. continue automatically into P0B.

## P0A acceptance

P0A passes only when:

- graph/analyzer evidence is fresh enough for implementation decisions;
- current test baseline is recorded;
- cycle groups are understandable at domain level;
- no production refactor was performed prematurely;
- the evidence is sufficient to build the P0B representative retrieval probes.

## Remaining mandatory work

P0B and all P1-P8 phases remain mandatory.

Do not mark the parent goal complete after P0.
