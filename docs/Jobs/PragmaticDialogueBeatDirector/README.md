# Pragmatic Interaction Director

**Job directory:** `docs/Jobs/PragmaticDialogueBeatDirector/`

**Status:** RECOVERY / RE-ARCHITECTURE REQUIRED.

The folder name is retained for continuity, but the accepted parent objective is
now broader than a dialogue-only beat system.

## Parent objective

Upgrade the existing unified semantic interaction pipeline with:

- pragmatic interpretation;
- reusable behavior arbitration;
- optional bounded beat state for multi-interaction situations;
- typed actor/world/social stimuli;
- shared actor/world/relationship/knowledge projections;
- reusable semantic interaction plans that can drive dialogue, emotes, ambient
  flavor, NPC-to-NPC scenes, and existing gameplay-authority intents.

The target must remain modular, performant, agnostic, compiler-owned where
content is concerned, and compatible with both Project Hoomans and third-party
NPC implementations.

## Non-negotiable authority model

```text
human free-form text
        ↓
PsychopatzCore NLU
        │
engine/world event ───────────────┐
NPC semantic act ─────────────────┤
emote/task/social event ──────────┤
                                  ▼
                            Typed Stimulus
                                  ↓
                        Context Projection
               actor / social / world / knowledge
                                  ↓
                       Pragmatic Resolution
                                  ↓
                       Behavior Arbitration
                                  ↓
                    optional bounded Beat State
                                  ↓
                        InteractionPlan
                     ┌────────┼───────────┐
                     ▼        ▼           ▼
                 ResponsePlan EmotePlan GameplayIntent
                     │        │           │
               Dialogue Content       existing authority
                     │
               presentation / optional PBrainZ
```

There must be **one semantic authority, one conversation/context authority, one
ResponsePlan/Dialogue Content realization path, and one gameplay authority**.

A director is allowed to be a decision layer. It is not allowed to become a
parallel response engine, translation system, content catalog, parser, or
gameplay authority.

## What a beat means

A beat is:

> A bounded, temporary semantic situation that changes the relevance of
> available actor behaviors across multiple interactions.

A beat is **not**:

- a dialogue tree;
- a response pool;
- a random flavor-text generator;
- a parser;
- a gameplay-authority system;
- mandatory for every interaction.

Simple reactions such as a wave or one-shot emote may use behavior arbitration
without creating a beat.

## Required reuse

The interaction layer must be reusable for:

- direct player ↔ NPC conversations;
- NPC ↔ NPC and multi-NPC ambient scenes;
- emote reactions;
- nearby ambient/flavor text;
- gossip/news reactions grounded in real world state;
- world-event reactions;
- optional PBrainZ realization;
- third-party NPC actors through adapter/provider contracts.

## NPC-generated interactions

NPC-generated interactions must remain semantic internally.

Do not:

```text
NPC A generates English
→ NLU parses the generated English again
→ NPC B reacts
```

Use:

```text
NPC A semantic act / fact / topic
→ typed semantic event
→ NPC B behavior arbitration
→ optional realization for the player
```

Only human free-form input requires NLU.

## Performance model

The system must be:

- event-driven;
- stimulus-indexed;
- bounded;
- level-of-detail aware;
- free of whole-world/per-NPC/per-tick beat scans.

Only candidate situations indexed for the triggering stimulus should be
evaluated.

Nearby/audible scenes may realize speech/emotes. Distant scenes should retain
only meaningful semantic outcomes when required by an authoritative system.

Do not persist unbounded transcripts. Persist compact semantic facts/events only
when another system legitimately owns that memory.

## Compiler and content rule

First-party wording remains ordinary **Dialogue Content**.

Do not create a director-owned wording authority such as:

- `responses/director.json`;
- `Conversation/Director.json` as a catch-all content bucket;
- director-specific response-pool selection.

Beat/behavior structural definitions may be compiler-owned, but their wording
must resolve through the same modular Dialogue Content system used elsewhere.

The existing Dialogue Content harness editor remains the wording authoring
surface.

## Current prototype warning

The current uncommitted worktree contains an experimental dialogue-director
prototype.

Useful behavior and observability tests exist, but the implementation is **not
accepted as the architecture**.

Agents must read `AUDIT.md` and `PROGRESS.md` before modifying that prototype.

Do not continue the old P7/P8 implementation path.

## Read order

1. root `AGENTS.md`;
2. this `README.md`;
3. `AUDIT.md`;
4. `ARCHITECTURE.md`;
5. `AGENT_RUNBOOK.md`;
6. `ROADMAP.md`;
7. `HARNESS_ACCEPTANCE.md`;
8. `PROGRESS.md` **last**.
