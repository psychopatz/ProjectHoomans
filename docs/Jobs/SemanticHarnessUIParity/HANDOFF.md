---
handoff_schema: 2
checkpoint_mode: "developer_acceptance"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos:
  - "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
  - "/home/psychopatz/Zomboid/Workshop/DynamicTrading"
branch: "main"
status: "READY_FOR_PHASE_COMMIT"
updated_at: "2026-11-11T00:00:00Z"
---

## Current truth

The old fully featured Semantic Lab is restored under Core and launches from
the Core `run_harness.sh`. Project Hoomans no longer contains the duplicate
`tools/providers/pnc/lab` or `tools/providers/pnc/codebuilder` harness trees.
Provider selection remains manifest/preset driven and supports Core-only,
Project Hoomans, DTAbstract, DTHoomans, and combined PNC+DTHoomans modes.

## Exact next action

Review the participant-repository diffs, stage only this goal's paths, commit
Core first, then commit the PNC provider/docs changes in Project Hoomans.
Preserve the unrelated dirty audit files. Do not publish Workshop content.

## Acceptance already observed

Core tests, focused migrated PNC tests, headless provider matrix, semantic
identity input, and fresh Core/PNC/DTAbstract GUI launches all passed. The
remaining user-owned gate is optional live Project Zomboid validation.
