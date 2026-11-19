# Agent Runbook — Project Hoomans Portable Social State Adoption

## Parent authority

This is a participant of PsychopatzCore Docs/portable_social_state/.

Read the Core parent job first. Parent P0-P9 is the completion boundary.

## Hoomans responsibility

Hoomans owns game-specific social/world policy and adapts it into Core portable social state. It must not fork Core actor/social/compiler mechanisms.

Before editing:

1. read root AGENTS.md;
2. verify current Git/worktree/concurrent changes;
3. read Core parent PROGRESS/HANDOFF;
4. read this participant PROGRESS;
5. inspect exact current Hoomans source/tests.

## Mandatory reuse

Reuse:

- PsychopatzCore Actors/PsychopatzSocial;
- Core CodeBuilder compiler/package routing;
- Hoomans SocialEvent/Relationship/Conduct/Knowledge services during audited migration;
- Unified Semantic Evidence;
- Semantic Social Conversation Director.

Do not create SocialMemory2, RelationshipV2, a Hoomans event ledger, or a second compiler.

## Migration discipline

Never remove a current Hoomans writer because architecture prose says Core owns it.

Prove:

- current writer/readers;
- generic vs Hoomans-specific meaning;
- migration path;
- caller-zero for superseded generic state;
- save/schema behavior;
- focused and full regressions.

Avoid permanent compatibility shims. Use explicit bounded migration when required, then remove the superseded path.

## CodeBuilder

Hoomans owns Hoomans social policy source packages; Core owns schema/compiler/IR/runtime mechanism.

Generated artifacts are downstream and never hand-edited.

## Git safety

The repository currently has substantial unrelated dirty Conversation/CodeBuilder/translation work. Stage only participant-owned paths. Never reset/stash/discard uncertain changes. Participant phase commits are allowed only when exact ownership is safe; do not push.

## Validation

Prefer focused Lua/service tests, semantic worker fixtures, CodeBuilder determinism, multiplayer protocol fixtures, storage measurements and full relevant regressions.

Native Project Zomboid remains user-owned acceptance.
