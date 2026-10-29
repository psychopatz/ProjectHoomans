# Semantic NPC Group Conversation

This job generalizes the accepted combat-banter/tactical-intent foundation so companions, neutral NPCs, hostile NPCs and faction squads can participate in the same bounded semantic encounter conversations.

## Product target

NPC speech must stop being structurally player-centric.

NPCs should be able to:
- coordinate with members of their own local combat cohort;
- warn, propose, agree, disagree, challenge, reassure and acknowledge one another;
- make coherent short tactical exchanges during real encounters;
- address the player only when the player is actually the semantic recipient;
- let nearby players overhear NPC-to-NPC speech without automatically receiving response buttons;
- express personality, relationship, faction standing, fear/confidence and current combat pressure without inventing gameplay facts;
- remain silent frequently enough that combat stays readable.

Examples are behavioral targets, not hardcoded scripts:

```text
Raider A -> Raider B: horde warning
Raider B -> squad: propose hold
Raider C -> Raider B: disagree / fear
Raider B -> squad: retreat decision
```

or:

```text
Neutral A -> Neutral B: warning
Neutral B -> group: propose avoid
Neutral C -> group: agree
leader/group authority -> avoid
```

The rendered English/TL text is downstream of semantic acts. NPCs never parse one another's rendered sentence to determine the next turn.

## Core architecture rule

**NPC->NPC, NPC->player, companion, neutral and hostile dialogue are projections of the same semantic interaction and encounter authorities. Audience identity changes; the semantic system does not.**

Do not create:
- a neutral-NPC dialogue engine;
- a hostile-NPC dialogue engine;
- a second companion dialogue engine;
- a per-NPC conversation tick;
- a durable NPC chat transcript;
- another combat scanner;
- a text-reparsing loop between NPCs.

Reuse and generalize the accepted:
- Combat Moment;
- Combat Banter Arbiter;
- Semantic Interaction Lifecycle / NPCSpeech envelope;
- Response Catalog / SpeechRealization / CodeBuilder;
- faction/relationship authority;
- SpatialIndex / Perception event facts;
- runtime Combat Encounter Intent, migrated away from owner-only identity.

## Current state

Planning base: ProjectHoomans `6c11d218` on existing `main`.

The predecessor job `docs/Jobs/SemanticCombatBanterTacticalIntent/` is developer-complete and remains accepted foundation.

Current production truth:
- nearby neutral/hostile managed NPCs can already participate in portions of combat-banter candidate selection;
- NPC kill commentary already exists, but presentation is still normally transported to a nearby player;
- the Interaction Lifecycle envelope already supports `actorID` and `targetID`;
- faction identity and indexed `memberIDs` already exist;
- the faction/social layer already distinguishes ally/friendly/neutral/stranger/hostile;
- the current Combat Encounter Intent is follower-only and keyed by player owner;
- current NPC threat-group propagation is also owner-group oriented;
- there is no generic local combat-cohort authority and no bounded NPC-to-NPC semantic exchange director.

See:
- `AUDIT.md` — verified production gaps and reusable authorities;
- `ARCHITECTURE.md` — stable ownership/invariants;
- `ROADMAP.md` — mandatory G0-G8 implementation sequence;
- `HARNESS_ACCEPTANCE.md` — acceptance matrices and performance gates;
- `AGENT_RUNBOOK.md` — execution rules;
- `PROGRESS.md` — current truth and immediate Next Chunk.
