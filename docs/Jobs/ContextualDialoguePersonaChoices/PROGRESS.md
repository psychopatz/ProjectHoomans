# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23  
**Parent status:** REOPENED — P11 runtime-parity foundation retained; P11J native Talk shared-entry parity is mandatory.  
**Current mandatory phase:** P11J3 — Route and availability parity matrix.
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

P11J1 remains accepted with `PNC.Conversation.TalkParity`, `TALK_CATALOG`,
`TALK_START`, `TALK_MATRIX`, the GUI/CLI surfaces, and the canonical cases:

```text
current · colonist · follower · neutral · hostile
```

Production mapping remains truthful: follower derives from colonist ownership and
the follow order; hostile is the production tactical type; "Hostile / Enemy" is
only a display label; and trader remains a Dynamic Trading/provider overlay.

## P11J2 — accepted developer implementation

Added the production-owned `PNC.Conversation.TalkStart` projection at:

```text
Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/PNC_ConversationTalkStart.lua
```

The projection consumes a canonical entry and player and returns the target type,
tactical class, ownership and follow facts, conversation relationship and
audience, availability, hostile inline/full route, and the canonical greeting
opening state.

Native Talk now follows:

```text
real entry
 -> TalkStart.Project
 -> Conversation.BuildDefinition
 -> Conversation.Open
```

The builder carries the same projection into the production definition/context.
The Semantic Lab keeps its scenario-to-entry conversion in `TalkParity`, then
enters the same `TalkStart.Project` boundary for `TALK_START` and `TALK_MATRIX`.
Target classification, audience, relationship, availability, and route policy
were removed from the harness projection.

The harness relationship adapter now preserves the production conversation
relationship resolver and adds only its presentation receipt hook. This was
required because replacing that resolver would have created a second relationship
policy at scenario reset time.

Focused evidence on this checkout:

- `lua5.3 tests/pnc_conversation_talk_start_projection_smoke.lua` — PASS;
- `lua5.3 tests/pnc_conversation_audience_smoke.lua`,
  `pnc_npc_type_palette_smoke.lua`, and `pnc_conversation_smoke.lua` — PASS;
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j -v` — **5/5 PASS**;
- the P11J source/runtime test proves native lifecycle, definition builder, and
  harness parity callers reference `TalkStart.Project`, and the worker emits the
  shared projection schema;
- changed production Lua passed `pz_verify --kahlua --severity ERROR` with zero
  findings and `luac5.3 -p` passed; `git diff --check` passed.

The headless worker reports hostile inline unavailable unless the real PBrainZ
integration reports ready and exposes the inline target route. Native Project
Zomboid SP/MP remains **UNTESTED / user-owned**.

## Current Exact Next Chunk — P11J3

1. run the colonist, follower, neutral, hostile inline-available, hostile
   inline-unavailable, dead/unavailable, and trader-overlay cases through the
   shared Talk-start boundary;
2. keep follower derived from colonist ownership plus active follow order;
3. use the real PBrainZ availability check and never fabricate inline support in
   the headless worker;
4. expose canonical target ID, production target type, tactical class,
   ownership/recruitment/follow facts, audience, standing, durable bond,
   availability, route and reason, greeting opening, first response, semantic
   choices, SpeechStyleContext, graph path, and provider state in each row;
5. isolate every row from relationship, conversation, graph, provider, and
   cooldown mutations and restore the original scenario afterward;
6. prove Talk start establishes opening state before the first `hello` turn;
7. run the same `TALK_START` and `TALK_MATRIX` worker operations through GUI and
   CLI in EN and TL, keeping semantic IDs/routes stable;
8. update this file with exact evidence and continue to P11J4.

## Known separate relationship boundary

The server relationship proposal policy/service and Semantic Lab proposal action exist.

A separate source audit found no normal production dialogue/provider caller of `PNC.Relationships.Propose` yet. Do not silently claim that the real player proposal UX is native-complete unless a production semantic/action route is verified or added under its own bounded chunk.

This is distinct from P11J Talk parity and must not be hidden by native Talk work.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** solely because P11J1 matrix tests pass.

After P11J2-P11J4 developer gates pass, hand native Project Zomboid SP/MP verification to the user.

Native verification remains **UNTESTED / user-owned** until the user supplies evidence.
