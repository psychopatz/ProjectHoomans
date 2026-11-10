# Agent Runbook — Unified NPC Population and Expansion Architecture

## Scope

This job spans three existing repositories:

- Project Hoomans: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
- Dynamic Trading: `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
- PsychopatzCore: `/home/psychopatz/Zomboid/Workshop/psychopatzCore`

Project Hoomans is the primary job-document repository. Use the existing
`main` branches. Never create a branch, push, publish Workshop content, or
discard uncertain work.

## Before each implementation chunk

1. Read the root `AGENTS.md` in every repository being edited.
2. Check actual branch, `HEAD`, status, upstream/ahead-behind state, and
   worktrees in all three repositories.
3. Preserve unrelated modifications. The current audit has generated
   architecture-report edits in Dynamic Trading and PsychopatzCore; do not
   overwrite or stage those edits unless explicitly assigned.
4. Recheck Codebase Memory coverage for source files relied on by the chunk,
   then read any reported missed lines directly.
5. Update `PROGRESS.md` only with verified truth and keep exactly one immediate
   `Next Chunk`.

## Implementation order

### P1 — Core

Work only on the generic source registration/orchestration and canonical
generation contract. Keep Core free of adopter imports. Add tests for source
activation, caps/cooldowns, deterministic/idempotent requests, provenance,
collision handling, and Core-only loading.

### P2 — Project Hoomans

Work only on the materializer and extensible faction/role/actor policy seams.
Use the Core group result as input. Preserve Hoomans ownership of PNC records,
physical bodies, abstract/live switching, NPC monitor, map integration, and
debug override. Add tests that an arbitrary registered profile materializes
without adding a new Hoomans generation writer.

### P3 — Dynamic Trading

Register the trader source through Core. Retain trader presets, commercial
state, caravan lifecycle, and trader behavior in Dynamic Trading. Keep
`DTAbstract` as the abstract representation and `DTHoomans` as the Hoomans
materializer adapter. Prove both paths retain the exact Core actor IDs.

### P4/P5 — Extension proof and acceptance

Use a test-only gang-like source to prove that new domain content needs only
registration and policy. Then run diagnostics, save/restart repair checks, and
the user-owned native Project Zomboid acceptance matrix.

## Required verification

For changed Lua:

- run the focused owner tests for the changed boundary;
- run `pz-verify` on changed Project Zomboid Lua;
- run direct Lua/load checks where the existing repository provides them;
- run `git diff --check` in every changed repository.

For cross-repository changes, verify at least:

- Core-only loading without adopters;
- Hoomans materialization of a Core-created group;
- Dynamic Trading source activation and repeated-generation behavior;
- DTAbstract → DTHoomans handoff with no replacement actor;
- map/monitor hover never exposing `UNKNOWN` as a valid state;
- save/reload preserving canonical IDs and provenance.

The native Project Zomboid process is not launched by ordinary developer-side
work. Fresh-save, restart, nearby-body, SP/MP, and visual map acceptance are
user-owned unless the user explicitly authorizes native operation.

## Commit discipline

Commit exact phase-owned paths locally after the phase gates pass. For a
cross-repository phase, commit participant repositories first and the primary
Project Hoomans repository last with updated roadmap/progress/handoff docs.
Never use broad staging. Do not amend, rebase, reset, stash, force-update, or
push without explicit authorization.

## Runtime safety

The Project Zomboid `media/` tree is watched while the game runs. Do not
create staging directories inside a watched `media/` tree or perform directory
swaps while the game is live. Use file creation or rename-into-place only, or
stop the game before staging.

Do not use `pcall`/`xpcall` for ordinary validation or control flow. A
protected call is acceptable only at an unavoidable external/addon callback
boundary, with the reason documented beside it.

## Evidence labels

Use these labels in `PROGRESS.md` and `HANDOFF.md`:

- `CODE_VERIFIED`: source ownership or implementation is confirmed by direct
  inspection;
- `TEST_VERIFIED`: focused automated gate passed;
- `STATIC_ONLY`: architecture or source audit only;
- `USER_ACCEPTANCE`: native Project Zomboid evidence still required;
- `UNVERIFIED`: a claim has not yet been demonstrated.
