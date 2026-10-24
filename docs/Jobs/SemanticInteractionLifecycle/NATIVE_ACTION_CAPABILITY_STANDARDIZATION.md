# P12 — Native Action & Semantic Capability Standardization

**Opened:** 2026-10-25  
**Status:** MANDATORY — native user test reopened developer acceptance.  
**Audit baseline:** ProjectHoomans main at `bc13d3775cb03816d34dafce6e676d278de5997e`.  
**Preserve:** P0–P11 lifecycle, persistence, native-presentation parity and single-authority foundations unless a P12 regression proves a defect.  
**Product rule:** one semantic system owns conversational meaning and capability representation; existing authored/gameplay systems remain authoritative executors.

## Why P12 exists

After P10/P11 were marked complete, native Project Zomboid testing exposed production failures that the existing automated acceptance did not catch:

- **That's all. Stay safe.** is presented but does not close the Conversation UI.
- **Tell them to leave the group** is presented but does not execute the expected authored departure flow correctly.
- semantic emote replies can be selected but are not visibly delivered by the NPC.
- unrevealed NPC identity can leak the internal label **Unknown survivor** into player-facing speech instead of a natural address such as **stranger**.
- companion commands such as Follow / Stay / Wait are exposed as separate root choices instead of a contextual command hierarchy.
- existing **Camp** and **Go Home** capabilities are not represented in the desired conversation command structure.
- Camp already has production room/campfire discovery and validation infrastructure, but the Conversation capability surface does not expose dynamic valid destinations.

P12 standardizes these through the existing semantic system rather than adding another authored-menu subsystem.

## Core standardization

The semantic system must standardize three first-class concepts:

### 1. Semantic Capability

A semantic capability describes **what the interaction can do** and points to the existing authoritative executor.

Examples:

- `conversation.farewell`
- `conversation.departure`
- `companion.movement.follow`
- `companion.movement.wait_here`
- `companion.camp`
- `companion.return_home`
- future recruit/trade/quest/order capabilities

The capability contract may include:

- semantic act/topic/action;
- group/subgroup;
- current availability/eligibility;
- required slots/targets;
- presentation label/variants;
- authoritative executor identity;
- lifecycle behavior such as close/next;
- response-plan/acknowledgement mapping;
- semantic provenance.

The semantic capability does **not** duplicate gameplay execution. Existing authoritative owners still mutate state.

### 2. Semantic Realization

Semantic realization describes **how an already-decided meaning is expressed**.

It owns:

- response plan;
- realization family;
- realization ID;
- EN/TL authored variants;
- persona/relationship/tone constraints;
- bounded anti-repetition.

It must not create a second gameplay action path.

### 3. Semantic Address

Semantic address describes **how one actor refers to another in speech**.

It must distinguish:

- internal/debug/transport identity;
- known player-facing name;
- unknown player-facing address form;
- relationship/title/habitual address where allowed.

The internal sentinel `Unknown survivor` may remain for transport/debugging if useful, but it must not leak into ordinary player-facing dialogue.

## Authored capability adoption

Authored Conversation choices and gameplay registries should contribute capabilities to semantics rather than compete with it.

Desired model:

~~~text
AUTHORED / GAMEPLAY SOURCE
    |
    +-- Conversation root choice
    +-- CompanionCommands
    +-- ConversationBlocks
    +-- Camp-site resolver
    +-- Recruitment/departure
    +-- Trade/quest/etc.
    |
    v
SEMANTIC CAPABILITY REGISTRY / PROVIDER
    |
    +-- meaning
    +-- current eligibility
    +-- group/subgroup
    +-- required slots
    +-- authoritative executor reference
    |
    v
ONE INPUT / PRESENTATION PIPELINE
    |
    +-- typed input
    +-- semantic buttons
    +-- emotes
    +-- headless/harness
    |
    v
EXISTING AUTHORITATIVE EXECUTOR
~~~

Do not copy the authoritative effect into semantics.

## Authored-choice execution rule

The current semantic wrapping of authored Core choices must not recursively call `Session:selectChoice(original)` from inside another synthetic `Session:selectChoice`.

That re-entrant pattern can lose/overwrite authored choice behavior such as:

- `response`;
- `next`;
- `close`;
- `closeReason`;
- `onHighlightChanged`;
- pending lifecycle state.

Semantic presentation of an authored choice must preserve the original normalized Core behavior while adding semantic identity/provenance.

The implementation may standardize a capability/action-dispatch seam, but it must not create a duplicate executor.

## Native action fixtures

### Farewell

The semantic capability for farewell must preserve the authoritative authored behavior.

Acceptance:

~~~text
player selects semantic Farewell
    -> original/standardized farewell capability executes
    -> NPC farewell response is delivered when applicable
    -> Conversation session closes
    -> native UI closes
    -> lifecycle close reason is correct
~~~

A semantic frame merely returning accepted=true is insufficient.

### Leave group / departure

The semantic departure capability must preserve:

- current eligibility;
- relationship preview/highlight if supported;
- warning stage;
- confirm/cancel stage;
- server-authoritative departure;
- resulting relationship/faction effects;
- terminal close on successful departure.

Do not bypass `Conversation.Authority.HandleDeparture` / existing departure service.

## Resolved semantic speech delivery

An already-selected semantic realization needs one delivery seam.

Desired flow:

~~~text
semantic response plan
    -> realization selected
    -> resolved text / realization ID
    -> semantic speech delivery
        -> active Conversation log/session when appropriate
        -> world nameplate/bubble
        -> TTS when enabled
~~~

Do not send a resolved semantic line back through Flavor selection.

The current emote result path must not merely assign `resolvedText` to a result/diary field. It must visibly deliver the NPC response exactly once.

## Semantic Address Resolver

Introduce or standardize one conversational address resolver.

Conceptually:

~~~text
identity knowledge
+ perceived sex/gender information when authoritative/appropriate
+ relationship/familiarity
+ persona/speech style
+ current beat/tone
+ language
+ recent address variants
        |
        v
semantic address family
        |
        v
address realization
~~~

### Unknown-address variants

Initial English candidates may include:

- **stranger** — neutral, any/unknown sex;
- **mate** — casual/friendly, any sex;
- **pal** — casual/friendly, non-hostile;
- **bro** — very casual, male, persona/style permits slang;
- **mister** — formal/neutral, male;
- **miss** — formal/neutral, female.

These are examples/seed variants, not a hard-coded random list.

Selection must be contextual and constrained. Do not randomly alternate incompatible registers.

If sex/gender is unavailable or unsuitable for the decision, use gender-neutral candidates.

TL/localized address families may use language-appropriate forms rather than literal translations.

### Known identity

The same resolver should eventually support known-name/title/relationship forms where authoritative data permits, for example name, surname/title, role, or relationship address.

The semantic address resolver must not invent identity facts.

### Anti-repetition

Keep only a tiny bounded recent address-realization history, preferably active-thread/runtime state. Do not persist full sentences merely to vary address forms.

## Companion Orders capability hub

Remove permanent independent root presentation of Follow / Stay / Wait At.

Expose one root semantic navigation capability:

**I need you to do something...**

Inside it, project currently eligible authoritative companion capabilities.

Initial structure:

~~~text
I need you to do something...
    |
    +-- Follow me.        OR
    +-- Wait here.        (mutually exclusive contextual toggle)
    |
    +-- Let's camp...
    |
    +-- Go home.
    |
    +-- Back
~~~

### Follow / Wait toggle

The visible row is derived from actual authoritative movement state.

- if currently following the player: show **Wait here**;
- if not currently following and commandable: show **Follow me**.

Do not show contradictory Follow and Stay rows simultaneously.

`WAIT_AT` with an explicit destination remains a valid semantic capability for natural language/world-target requests, but is not a permanent generic root/menu row.

After command execution, reproject capability state immediately so the menu reflects the new truth.

### Go Home

Reuse the existing authoritative `return_home` command and its cancellation/home-duty behavior.

Only expose when the target is commandable and the command is currently meaningful/eligible.

## Dynamic Camp subbranch

Reuse existing production infrastructure:

- `PNC.Semantics.CampSite`;
- room-type vocabulary;
- `CampSiteGeometry.EnumerateRooms`;
- `Geometry.DescribeRoom`;
- client camp-site hints;
- server `CampSiteResolver`;
- authoritative `CompanionCommands.camp`.

Do not create a second camp implementation.

The semantic capability provider should dynamically project a bounded set of currently valid nearby sites, such as:

- Living room
- Bedroom
- Kitchen
- Garage
- other valid recognized rooms
- nearby valid campfire
- generic safe-site fallback when appropriate

Only actual valid discovered sites should appear.

For repeated room types, use bounded ranking/deduplication or disambiguated labels rather than unbounded rows.

Selection sends only the primitive site identity/hint. The server independently resolves/validates the requested site before committing the camp order.

Client discovery is presentation assistance, not authority.

## P12 ordered chunks

### P12A — Native regression freeze + capability inventory

**Status:** COMPLETE in planning/audit.

Record the user native failures and map each to:

- current presented choice/capability;
- existing authoritative owner/executor;
- current semantic wrapper;
- current failure;
- target standardized semantic capability.

Include at minimum farewell, departure, emote speech delivery, unknown address, Follow/Wait, Camp and Go Home.

### P12B — Authored action/capability execution bridge

Eliminate re-entrant synthetic-choice -> original-choice `Session:selectChoice` execution.

Standardize authored root choices as semantic capabilities while preserving their original Core action/lifecycle fields.

Acceptance first-wave:

- Goodbye executes and closes native Conversation.
- Leave Group executes warning/confirmation/departure correctly.
- semantic provenance remains available.
- no duplicate action execution.

### P12C — Semantic speech delivery

Create/reuse one semantic delivery seam for already-resolved NPC speech.

Fix emote `resolvedText` delivery.

Acceptance:

- emote semantic reply is visibly delivered exactly once;
- active Conversation integration is correct when the target is the current NPC;
- world/nameplate/TTS delivery remains correct outside an active Conversation;
- no re-resolution through legacy Flavor intelligence.

### P12D — Semantic Address Resolver

Separate internal/debug identity from player-facing address.

Implement contextual bounded unknown-address realization with constrained variants such as stranger/mate/pal/bro/mister/miss.

Audit all conversational speaker/target-name paths for `Unknown survivor` leakage.

Acceptance:

- unrevealed NPC is naturally addressed;
- no invented name;
- gendered forms are used only when authoritative/appropriate;
- persona/tone constraints prevent random register switching;
- anti-repeat state remains bounded.

### P12E — Companion Orders semantic hub

Replace root Follow/Stay/Wait rows with **I need you to do something...**.

Inside it:

- contextual Follow/Wait toggle;
- Let's camp...
- Go home.
- Back.

Use actual capability eligibility and existing authoritative executors.

### P12F — Dynamic Camp destinations

Project bounded valid room/campfire choices from existing CampSite geometry/hints.

Server revalidates selected primitive site before authoritative camp mutation.

Acceptance includes at least recognized room labels, generic valid-room fallback, invalid/stale-site rejection, and no client-authoritative camp placement.

### P12G — Stateful capability refresh

After any command/action:

- refresh semantic capability state from authoritative truth;
- update Follow/Wait toggle;
- update Camp/Go Home eligibility;
- avoid stale contradictory rows;
- preserve active thread/beat context.

### P12H — Native-effect + harness acceptance

For the same production state, prove both presentation and effect:

- Goodbye closes;
- departure warning/confirm/cancel/depart/close works;
- emote NPC response is visible exactly once;
- unknown NPC conversational address uses semantic address forms, not the transport sentinel;
- Follow/Wait toggles mutually exclusively and mutates the real order;
- Go Home mutates the real authoritative command state;
- Camp dynamic room choice reaches server validation and commits the selected valid site;
- typed input / semantic button / headless equivalent requests reach the same capability where appropriate;
- Semantic Lab mirrors native capability/action state;
- P10/P11 parity and no-split invariants remain green.

## Acceptance principle

A button existing, a frame being accepted, or a semantic response being selected is **not enough**.

For an action capability the acceptance chain is:

~~~text
presented capability
-> semantic frame
-> authoritative executor
-> real gameplay/lifecycle mutation
-> semantic acknowledgement/realization
-> visible delivery
-> capability re-projection
~~~

Tests must prove the relevant end state.

## Relationship to P10/P11

P10 and P11 remain accepted foundation only where native P12 evidence does not reveal a regression.

P12 extends their standardization:

- P10 ensures the harness mirrors production presentation.
- P11 ensures one semantic conversational-intelligence authority.
- P12 ensures authored/gameplay actions are represented as standardized semantic capabilities and still execute their real native effects.

The project cannot return to READY FOR USER LIVE TEST until P12 passes.
