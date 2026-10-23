# P11J — Native Talk Parity

**Status:** PARTIALLY IMPLEMENTED / REOPENED FOR NATIVE SHARED-ENTRY PARITY  
**Opened from audit:** 2026-10-23  
**Current remote baseline audited:** ProjectHoomans `main` at `c9385c4f2b1b86feb09ed24144896e473bd6fec8`.  
**Existing P11J implementation commit:** `b0a4850b6d9082cc5cc9909832a6277c3999356e`.  
**Native Project Zomboid SP/MP:** user-owned and not required for developer-side code acceptance.

## Goal

Make Semantic Lab test the same **Talk target entry, classification, route decision, opening definition, and first-turn semantics** that the real Project Zomboid context-menu Talk action uses.

The harness must not merely create scenarios that resemble Colonist/Follower/Neutral/Hostile behavior. It must exercise one reusable production-owned Talk-start projection that the native `PNC.Conversation.Open` path also consumes.

## Source audit baseline

### Native Talk path

The real context action is:

```text
PNC_ContextProvider_Conversation
    -> PNC.Conversation.Open(entry, player)
    -> Conversation.BuildDefinition(entry, player, time)
    -> PsychopatzCore.Conversation.Open(definition)
```

Current source locations include:

- `PNC/UI/Context/Providers/PNC_ContextProvider_Conversation.lua`;
- `PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle.lua`;
- `PNC/Conversation/Definition/PNC_ConversationDefinition_Builder.lua`;
- `PNC/UI/PNC_NPCTypePalette.lua`.

The production builder already resolves NPC type through `PNC.NPCTypePalette.ResolveType(entry)` and resolves the normal conversation definition from the real entry/player context.

### Production target truth

Normal Talk target classes are:

```text
colonist
follower
neutral
hostile
```

Definitions:

- **Colonist** — owned/recruited, tactical class colonist.
- **Follower** — colonist ownership plus active follow order.
- **Neutral** — non-owned neutral tactical class.
- **Hostile** — tactical class hostile with player hostility such as `attackPlayers=true`.

`enemy` is a UI/harness synonym only. The production tactical class remains `hostile`.

Trader is not a Talk target class. Trader behavior is an orthogonal Dynamic Trading/provider capability.

Dead/unavailable is diagnostic availability state, not a normal tactical class.

## What P11J already implemented

Commit `b0a4850b6d9082cc5cc9909832a6277c3999356e` added:

- production-owned `PNC.Conversation.TalkParity`;
- canonical catalog:
  - current;
  - colonist;
  - follower;
  - neutral;
  - hostile;
- `TALK_CATALOG`;
- `TALK_START`;
- `TALK_MATRIX`;
- GUI and CLI use the same `LuaSemanticWorker` methods;
- a Simulation `Talk parity` trace surface;
- first utterance field;
- one-target Start Talk;
- all-target matrix;
- matrix rows containing target type, audience, route, response, choices, standing, bond, graph, and speech context;
- scenario restoration after matrix rows;
- headless hostile fallback visibility;
- focused Python/Tk acceptance.

This work is retained.

## Remaining architectural gap

The strongest parity contract from the audit is not yet complete:

> Native Talk and the harness must consume the same Talk-start projection.

Current state:

```text
NATIVE
ContextProvider
 -> Conversation.Open(real entry, player)
 -> BuildDefinition(real entry, player)
 -> Palette/Audience/Rules...

HARNESS
scenario
 -> TalkParity.BuildEntry(...)
 -> TalkParity.Resolve(...)
 -> Palette/Audience/route reconstruction
 -> Conversation.turn(...)
```

The two paths share several production helpers, but `Conversation.Open` does **not** currently call `TalkParity`.

Therefore P11J is not accepted as full native parity merely because target labels/routes match in harness tests.

## Required architecture

Extract or normalize one production-owned reusable Talk-start projection.

Conceptually:

```text
real/native entry OR harness scenario adapter
               ↓
       canonical Talk target entry
               ↓
       production type resolution
               ↓
       relationship/audience resolution
               ↓
       availability / safety decision
               ↓
       hostile inline/full route decision
               ↓
       production conversation definition
               ↓
       opening choices / graph state
```

Both:

```text
PNC.Conversation.Open(...)
```

and:

```text
TALK_START / TALK_MATRIX
```

must consume that same projection/boundary.

The harness may adapt a synthetic scenario into the canonical entry shape. It must not own a second route/classification policy.

## Route expectations

### Colonist

```text
targetType = colonist
route = full_conversation
```

Uses the normal full conversation definition and appropriate owned/companion choices.

### Follower

```text
tacticalClass = colonist
follow order = active
targetType = follower
route = full_conversation
```

Follower is derived, not a separate tactical class.

### Neutral

```text
targetType = neutral
route = full_conversation
```

No owned-companion authority should be fabricated.

### Hostile

If real PBrainZ/inline integration is available:

```text
targetType = hostile
route = hostile_inline
```

Otherwise use the production hostile full-conversation fallback/ceasefire route:

```text
targetType = hostile
route = hostile_full_conversation
```

The harness must report the real integration availability rather than pretending inline support exists.

### Dead / unavailable / unsafe

Return a visible rejection/unavailable reason from the same production start policy.

Do not silently turn an unavailable target into a neutral test case.

## Talk start versus first utterance

`TALK_START` must represent the real opening state before the first semantic utterance is processed.

Correct sequence:

```text
Talk target selected
 -> production Talk start projection
 -> opening definition / choices / route established
 -> first utterance such as "hello"
 -> Conversation.turn(...)
```

Do not treat `Conversation.turn("hello")` by itself as proof of native Talk parity.

## Matrix contract

Each row starts from an isolated copy of the same base scenario.

Rows must not leak:

- relationship changes;
- conversation tokens;
- visited graph state;
- temporary target override;
- provider state;
- proposal/cooldown state;
- runtime `semanticLabTalkTarget`.

Return at least:

```text
canonical target ID
production target type
tactical class
ownership/recruited/follow facts
audience
Talk route
availability/reason
opening node/choices
first NPC response
semantic suggestion IDs
runtime graph kind/path
SpeechStyleContext
relationship standing
durable bond
provider/integration availability
```

GUI and CLI use the identical worker schema.

## Trader rule

Trader remains an orthogonal capability overlay.

Do not add `trader` as a fifth tactical Talk type.

A neutral/colonist/follower may also be a trader if Dynamic Trading says so.

Talk parity tests should verify that enabling trader capability does not change the canonical tactical target class.

## Milestones

### P11J0 — Audit and target truth

**Status: complete.**

Verified:

- native Talk context action;
- `Conversation.Open` path;
- production target classes;
- follower derivation;
- hostile truth;
- trader as overlay;
- old harness profile mismatch.

### P11J1 — Harness Talk surface and matrix

**Status: implemented in `b0a4850b...`.**

Retain:

- production-owned target catalog;
- `TALK_CATALOG`;
- `TALK_START`;
- `TALK_MATRIX`;
- GUI/CLI parity;
- target selector;
- matrix;
- isolated rows;
- route/graph/relationship/speech output.

### P11J2 — Native shared Talk-start projection

**Status: CURRENT MANDATORY CHUNK.**

Required:

1. audit `Conversation.Open`, `BuildDefinition`, Audience, Rules, Palette, hostile/PBrainZ route and TalkParity side-by-side;
2. extract the smallest reusable production Talk-start projection/boundary;
3. make native `Conversation.Open` consume that projection;
4. make `TalkParity.Start/Matrix` consume the same projection;
5. keep scenario-to-entry adaptation harness-only;
6. remove duplicated classification/route decisions from TalkParity when the new shared boundary owns them;
7. preserve existing native behavior exactly where semantics are unchanged;
8. add source/unit smoke proving native and harness call the same boundary;
9. keep GUI/CLI schema stable unless a versioned addition is required.

**Gate:** one production Talk-start projection is used by both native Open and harness Talk operations.

### P11J3 — Route/availability parity matrix

Required:

- colonist;
- follower;
- neutral;
- hostile inline available;
- hostile inline unavailable/full fallback;
- dead/unavailable;
- trader overlay;
- EN/TL;
- normal relationship standing/bond combinations.

Prove:

- target type;
- audience;
- route;
- opening choice IDs;
- first semantic response;
- graph kind/path;
- reason/status

are produced by the shared boundary.

**Gate:** no harness-only route decision remains.

### P11J4 — Regression + native handoff

Developer-side:

- focused Talk Python/Tk tests;
- CLI JSON parity;
- conversation smoke;
- P10/P11 graph, hub, identity, relationship, inventory regressions;
- Lua syntax;
- Kahlua;
- doctor;
- translation validation;
- diff checks;
- no new ModData state.

Then hand off to user-owned native validation.

Native user test should verify:

1. real context-menu Talk on colonist;
2. follower;
3. neutral;
4. hostile with actual installed PBrainZ state;
5. hostile fallback if inline unavailable;
6. actual opening choices and first utterance;
7. Talk parity GUI output matches observed native route/classification.

Do not claim native verification until the user supplies this evidence.

## Hard invariants

- One production Talk-start route policy.
- Native entry remains authoritative.
- Harness scenario is only an adapter into the production entry contract.
- Follower is derived from colonist + follow order.
- Hostile is production `hostile`; `enemy` may only be a display alias.
- Trader is an overlay, never a tactical Talk type.
- No Python reimplementation of target classification.
- No fake inline support.
- No native UI creation required in the headless worker.
- No extra persisted Talk-parity state.
