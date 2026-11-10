---
handoff_schema: 2
checkpoint_mode: "documentation_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
state: "READY_FOR_P1_DESIGN"
parent_status: "IN_PROGRESS"
phase: "P0"
chunk: "documentation-baseline"
retrieval_tier: "verify"
---

# Handoff — Unified NPC Population and Expansion Architecture

## What is now documented

The target ownership model is explicit:

- PsychopatzCore is the only canonical actor/group generation and persistence
  authority.
- Project Hoomans is the only NPC/PNC physical materialization owner and owns
  abstract/live projection mechanics.
- Dynamic Trading and future domain expansions register sources and provide
  domain profiles/behavior; they do not create parallel actor or body
  records.
- `abstract` and `live` are the only valid presence modes. `UNKNOWN` is an
  incomplete projection that must be rejected or repaired.

The ordered implementation is P1 Core contract, P2 Hoomans materializer and
policy extension, P3 Dynamic Trading adapter, P4 future-expansion proof, and
P5 diagnostics/migration/native acceptance.

## Resume action

Begin P1 in PsychopatzCore only. Define and test the generic source
registration/activation/orchestration contract around the existing
`SurvivorWorld.Generation` plan/commit seams. Keep the first change
provider-neutral and avoid editing Dynamic Trading or Hoomans generation code
until the Core contract is stable.

## Evidence and repository state

- `STATIC_ONLY`: this checkpoint is an architecture/audit baseline; no native
  Project Zomboid acceptance is claimed.
- Project Hoomans was clean before this documentation update.
- Dynamic Trading and PsychopatzCore contain pre-existing generated
  `.architecture-refactor/output/architecture-audit.md` modifications from
  the audit. Preserve them; they are not part of this documentation change.
- No Workshop publication or native game launch was performed for this
  checkpoint.
