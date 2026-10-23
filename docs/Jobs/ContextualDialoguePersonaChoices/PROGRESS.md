# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23  
**Parent status:** REOPENED — P11 runtime-parity foundation retained; P11J native Talk shared-entry parity is mandatory.  
**Current mandatory phase:** P11J2 — Native shared Talk-start projection.  
**Current remote baseline audited:** ProjectHoomans `main` at `c9385c4f2b1b86feb09ed24144896e473bd6fec8`.  
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Stable accepted foundation

Preserve the already-implemented work:

- P10 contextual What's Up hub and structured Simulation controls;
- actor-centric Player/NPC/Relationship/World workbench;
- first-class Player/NPC needs and production traits/personality;
- dynamic durable friend promotion;
- proposal/lover relationship policy and harness simulation;
- relationship live preview and Compare;
- unified semantic Flow / Hub / ConversationBlock graph renderer;
- modular speech realization packs;
- deterministic identity/backstory/Core content work;
- shared activity logging and readable action transcript;
- production target catalog and harness Talk matrix from P11J1.

## P11J audit reconciliation

The original Talk audit was correct that a normal semantic turn is not proof of native Talk parity.

P11J1 later implemented:

```text
PNC.Conversation.TalkParity
TALK_CATALOG
TALK_START
TALK_MATRIX
GUI Talk parity surface
CLI Talk matrix/start
```

with canonical cases:

```text
current
colonist
follower
neutral
hostile
```

and truthful production mapping:

- follower derives from colonist + follow order;
- hostile is the real tactical type;
- "Hostile / Enemy" is only a display label;
- trader remains a Dynamic Trading/provider overlay.

However, source audit at the current baseline shows the native context-menu path still enters:

```text
PNC_ContextProvider_Conversation
 -> PNC.Conversation.Open(real entry, player)
 -> Conversation.BuildDefinition(real entry, player)
```

while the harness enters:

```text
scenario
 -> TalkParity.BuildEntry
 -> TalkParity.Resolve
 -> Conversation.turn
```

Both reuse production helpers such as NPCTypePalette and Audience, but native `Conversation.Open` does not currently call `TalkParity` or another common Talk-start projection.

Therefore the P11J1 harness matrix is useful and retained, but **P11J is not yet accepted as full native parity**.

## Current Exact Next Chunk — P11J2

On the user's actual local checkout:

1. read root `AGENTS.md` and the ContextualDialoguePersonaChoices docs in documented order, including `NATIVE_TALK_PARITY.md`;
2. inspect local ProjectHoomans/Core/DynamicTrading branches, HEADs, upstream/divergence, dirty/concurrent work; existing `main` only;
3. trace side-by-side:
   - `PNC_ContextProvider_Conversation.lua`;
   - `PNC_ConversationDefinition_Lifecycle.lua`;
   - `PNC_ConversationDefinition_Builder.lua`;
   - Audience/Relationship/Rules/Palette;
   - hostile/PBrainZ inline/full fallback logic;
   - `PNC_ConversationTalkParity.lua`;
   - worker `TALK_START/TALK_MATRIX`;
4. identify the smallest production-owned reusable Talk-start projection that can accept a canonical entry/player and return:
   - target type;
   - tactical class;
   - ownership/follow facts;
   - relationship/audience;
   - availability/safety;
   - hostile inline/full route;
   - conversation definition/opening choices;
5. make native `PNC.Conversation.Open` consume that shared production projection;
6. make TalkParity consume the same projection;
7. keep scenario-to-entry conversion harness-only;
8. remove duplicated target classification/route policy from TalkParity where the shared projection owns it;
9. preserve native behavior where semantics are unchanged;
10. keep existing P11J1 worker/GUI/CLI schema stable unless a versioned additive change is required;
11. add focused source/runtime tests proving native and harness use the same shared projection;
12. run conversation smoke, P11J focused tests, relevant graph/hub/relationship regressions, Lua syntax/Kahlua and diff checks;
13. update this ledger with exact evidence and continue automatically to P11J3 if green.

## P11J2 acceptance

Developer evidence must prove:

```text
REAL NATIVE TALK
real entry
 -> shared Talk-start projection
 -> Conversation.Open

SEMANTIC LAB
scenario adapter
 -> canonical entry
 -> SAME shared Talk-start projection
 -> TALK_START / TALK_MATRIX
```

A test that merely compares two independently computed route strings is insufficient.

## Remaining P11J milestones

After P11J2:

- **P11J3:** route/availability parity matrix for colonist/follower/neutral/hostile inline/hostile fallback/dead-unavailable/trader overlay/EN-TL;
- **P11J4:** focused + impacted regression, then user-owned native Project Zomboid validation.

See `NATIVE_TALK_PARITY.md`.

## Known separate relationship boundary

The server relationship proposal policy/service and Semantic Lab proposal action exist.

A separate source audit found no normal production dialogue/provider caller of `PNC.Relationships.Propose` yet. Do not silently claim that the real player proposal UX is native-complete unless a production semantic/action route is verified or added under its own bounded chunk.

This is distinct from P11J Talk parity and must not be hidden by native Talk work.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** solely because P11J1 matrix tests pass.

After P11J2-P11J4 developer gates pass, hand native Project Zomboid SP/MP verification to the user.

Native verification remains **UNTESTED / user-owned** until the user supplies evidence.
