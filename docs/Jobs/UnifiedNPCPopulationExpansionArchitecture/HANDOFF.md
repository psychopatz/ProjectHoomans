---
handoff_schema: 2
checkpoint_mode: "documentation_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
state: "READY_FOR_P2B_CORE_FACTION_WRITER"
parent_status: "IN_PROGRESS"
phase: "P2A"
chunk: "core-faction-writer-and-hoomans-adapter"
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
policy extension, P3 Dynamic Trading adapter, P4 a test-only conceptual
extension proof, and P5 diagnostics/migration/native acceptance. No Gang mod
will be created.

## Resume action

Continue P2A by moving canonical faction mutation and membership behind Core,
then make Hoomans a compatibility/materialization adapter. Keep Dynamic
Trading unchanged until the Core writer and Hoomans boundary are stable. The
Core-owned profile, map-presence, and monitor-presence slices are implemented
and verified.

## Evidence and repository state

- `CODE_VERIFIED`: Core P1 is committed as `6c16192` and its focused source,
  generation, registry, schema, bounds, bootstrap, and PNC-import smokes pass.
- `CODE_VERIFIED`: P2 Core map/hover presence normalization is committed as
  `cff123f`; Hoomans registered mobile profiles, supplemental map-directory
  normalization, and monitor normalization are present in the current primary
  worktree.
- `CODE_VERIFIED`: Core faction profiles are now owned by
  `SurvivorWorld.FactionProfiles`; Hoomans' archetype API is a compatibility
  façade over that registry. PsychopatzCore commit `4112111`.
- `TEST_VERIFIED`: Core faction-profile, Core composition, Hoomans/Core
  bridge, Hoomans faction-foundation, and mobile-group smokes pass. The
  existing faction-service declaration-count mismatch remains unrelated
  (`87` expected versus `88` actual).
- `TEST_VERIFIED`: focused Hoomans and Core P2 map/materializer smokes pass;
  the unrelated faction-boundary declaration-count smoke remains stale at
  `87` expected versus `88` actual.
- `STATIC_ONLY`: no native Project Zomboid acceptance is claimed.
- Project Hoomans has the P2 profile/presence implementation committed as
  `5417deac` and the Core profile bridge committed as `f10667c5`;
  canonical faction mutation remains the next chunk.
- Dynamic Trading and PsychopatzCore contain pre-existing generated
  `.architecture-refactor/output/architecture-audit.md` modifications from
  the audit. Preserve them; they are not part of this implementation phase.
- No Workshop publication or native game launch was performed for this
  checkpoint.
