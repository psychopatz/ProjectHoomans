# Progress — Pragmatic Interaction Director Recovery

**Status:** RECOVERY / RE-ARCHITECTURE REQUIRED.
**Current branch:** `main`.
**Documentation baseline commit:** `bd98962a2358ed904a382669b2187c7f20c0fa29`.
**Current phase:** R0 — freeze, classify, and protect useful evidence.

## Important worktree state

The current implementation prototype is uncommitted.

Do not commit it wholesale.

It contains useful experiments mixed with architecture that must be replaced.

## Audit findings

### Protected useful behavior

Keep acceptance coverage for:

- typoed `fuck ypuuuu` preserving recognized `HOSTILE_REMARK`;
- same semantic hostility selecting different grounded reactions:
  - warning;
  - retaliation;
  - de-escalation;
- argument → apology → reconciliation;
- low-forgiveness refusal/exit behavior;
- suspicious first-contact persistence;
- bounded director session state;
- candidate/predicate/modifier worker observations;
- multi-turn timeline concept;
- non-mutating draft preview concept.

### Rework

- director state/context integration;
- structural beat/behavior definitions;
- compiler support for structural records;
- worker-local draft overlay;
- structural harness authoring;
- explanation/trace UI;
- prototype predicate logic;
- behavior scoring.

These concepts may survive but their APIs/ownership are not frozen.

### Remove/replace

Do not preserve these as accepted architecture:

- `DialogueDirector.ResolveResponse` as a response authority;
- director-specific response pools;
- `responses/director.json` as wording authority;
- catch-all `Conversation/Director.json` wording bucket;
- `flow response → director response → LocalResponse` realization precedence;
- generated registry copied into separate production Beat/Behavior registries;
- giant catch-all `beats/social.json` and `behaviors/social.json`;
- special-case director canonical-authoring service as the long-term model;
- standalone Beat Studio as a separate wording workflow;
- partially implemented old P7 override path.

## Immediate Next Chunk — R0A

1. Produce a file/hunk recovery matrix for every current prototype change:
   `KEEP`, `REWORK`, or `REMOVE`.
2. Identify the exact hostile-recognition parity fix and its minimum regression
   coverage independently from the rest of the prototype.
3. Identify the exact worker-observation/timeline pieces worth retaining.
4. Map existing:
   - ResponsePlan/Dialogue Content authority;
   - Flow predicate/state machinery;
   - suggestion eligibility;
   - Conversation Registry/index;
   - Dialogue Content harness authoring;
   - world/context/relationship/knowledge providers.
5. Map which prototype files can be reverted/replaced without losing protected
   behavioral tests.
6. Record the recovery matrix here.
7. Continue into R1 automatically.

## Mandatory R1 direction

The first implementation recovery after R0 is:

> restore one ResponsePlan / Dialogue Content realization path.

Do not begin third-party adapters, ambient scenes, or performance scheduling
until the split response authority is removed.

## Later required capabilities

The parent goal still owns R0–R9, including:

- typed stimuli;
- normalized actor/world/social projections;
- third-party actor adapters;
- pragmatic resolver;
- one-shot behavior arbitration;
- optional beat state;
- event-driven candidate indexing;
- LOD;
- NPC-to-NPC semantic scenes;
- multi-NPC scenes;
- emote/flavor reuse;
- grounded gossip/world events;
- integrated interaction workbench.

## Stop conditions

Under autonomous implementation, stop early only for:

- unsafe concurrent worktree ownership;
- irreconcilable external dependency;
- an architecture choice that genuinely requires user direction;
- completion of all R9 developer gates.

Do not stop merely because a recovery chunk or one example scene works.

## Safety

- no new branch;
- no push without explicit authorization;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated artifacts.
