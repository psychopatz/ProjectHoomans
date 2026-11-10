# Core Semantic Harness Migration Runbook

## Repository scope

- Primary: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
- Participant: `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
- Participant: `/home/psychopatz/Zomboid/Workshop/DynamicTrading`

Use the existing `main` branch in every repository. Preserve unrelated dirty work and never use broad staging, reset, stash, rebase, force-push, Workshop publication, or native-game automation.

## Required checks before each phase

```bash
git -C /home/psychopatz/Zomboid/Workshop/ProjectHoomans status --short
git -C /home/psychopatz/Zomboid/Workshop/psychopatzCore status --short
git -C /home/psychopatz/Zomboid/Workshop/DynamicTrading status --short
git -C <repo> worktree list
```

Use Codebase Memory for structural callers and exact source reads for current dirty files. Do not treat the committed graph as current when a file is dirty.

## Profile matrix

Run and record at each relevant gate:

1. Core-only harness.
2. PNC with Core and without DT.
3. DTAbstract with Core and without PNC.
4. DTHoomans with explicit PNC and DT providers.
5. Combined semantic suggestions, identity disclosure, and radio/world-discovery flow.

Run focused tests first, then the repository suites and deterministic CodeBuilder regeneration. Native Project Zomboid validation remains a user-owned handoff unless explicitly requested.

## Deletion checks

Before deleting old trees, verify every old path has a replacement and run targeted import/path scans. The final checks must prove:

```text
ProjectHoomans/tools/semantic_harness is absent
DynamicTrading/tools/semantic_harness is absent
No core_*_bridge.py remains
No adopter-local harness package remains
DTAbstract does not resolve or import PNC
PNC does not resolve or import DT
```

## Commit protocol

At an accepted phase boundary, commit exact phase-owned paths in participant repositories first, then commit the primary repository including its `HANDOFF.md`. Do not absorb unrelated staged or unstaged work. Continue to the next mandatory phase after verifying the committed checkpoint.
