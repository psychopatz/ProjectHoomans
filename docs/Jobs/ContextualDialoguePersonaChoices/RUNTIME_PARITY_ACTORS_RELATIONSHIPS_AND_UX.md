# P11 — Runtime-Parity Actors, Dynamic Relationships, and Semantic Lab UX

**Status:** ACTIVE / mandatory corrective phase  
**Opened:** 2026-10-23  
**Implementation baseline audited:** ProjectHoomans remote `main` at `c412d50c27a423965911e115c0947b65c1eb2b6c`.  
**Native Project Zomboid SP/MP:** user-owned and not required for developer-side P11 acceptance.

## Why P11 exists

P10 delivered substantial real infrastructure:

- contextual What's Up hub;
- legacy What's Up category removal;
- typed simulation controls;
- structured inventory editing;
- inline workbench;
- Apply + Replay;
- hub diagnostics;
- graph-history infrastructure.

The 2026-10-23 live UI/source audit nevertheless found important runtime-parity and usability gaps:

1. the main Simulation surface still exposes low-level developer controls such as Preview, Snapshot, Persona matrix, World knowledge refresh, Restart worker, Capture baseline, and Sweep;
2. Sweep/Persona Matrix is a hidden three-scenario comparison mechanism rather than an understandable user-facing comparison tool;
3. approval/respect/familiarity technically apply but give weak immediate feedback and do not clearly explain relationship-state thresholds;
4. the graph only projects ConversationBlocks, so semantic Flows such as greeting and semantic hubs remain blank/unvisualized;
5. NPC traits are not presented in a clean actor-centric surface and player traits are not first-class scenario state;
6. player needs are not first-class scenario state; the harness is asymmetric between the two actors;
7. normal personality editing presents manual numeric sliders as if that were the runtime source, although live NPC personality is generated from identity/archetype/traits and then normalized;
8. the relationship-kind registry exposes hypothetical/future kinds that the current mod cannot actually produce;
9. built-in speech realization content remains centralized enough to become another large semantic file as variants expand;
10. the durable friend/lover relationship model is still too manual and does not reflect actual social progression.

P11 corrects those gaps without replacing the semantic parser, relationship foundation, provider registry, or P10 hub.

---

# 1. Actor-centric Simulation model

The primary Simulation workbench must be organized around the two actual conversation actors and their shared context.

Top-level workbench tabs:

```text
NPC Target
Player
Relationship
World
```

For both `NPC Target` and `Player`, expose:

```text
Overview
Needs
Personality & Traits
```

The UI should answer:

> Who am I simulating, what is their current state, and how does their relationship affect this conversation?

rather than exposing disconnected implementation domains.

## NPC Target

### Overview

At minimum:

- display/name identity useful to the harness;
- gender;
- actual role/capability profile;
- health;
- current activity;
- current semantic/runtime role data that materially affects dialogue.

Do not show every internal authority/debug bit by default.

### Needs

First-class NPC values:

- hunger;
- thirst;
- fatigue;
- stress;
- boredom;
- panic;
- other already-supported bounded need/condition fields only when production owns them.

Write new scenario data to proper NPC fields such as `npc.needs` / appropriate condition projection rather than treating `world.*` as the normal owner. Historical scenario compatibility may still read old `world.*` fallback fields.

### Personality & Traits

Show real registered NPC traits and the production-derived social/personality profile.

Normal mode:

```text
Personality source: Generated
identity seed
archetype
traits
    ↓
production SocialProfileGenerator
    ↓
production trait effects
    ↓
read-only derived personality
```

Derived values include the existing owned fields:

- socialStyle;
- compassion;
- sociability;
- forgiveness;
- bravery;
- materialism;
- aggression;
- loyalty;
- romanceStyle and other semantic categories when relevant.

Provide explicit:

```text
[ ] Override generated personality
```

Only in override mode should the existing numeric controls become directly editable.

The harness must not imply that manual `.50` sliders are how a normal live NPC is created.

## Player

Player must receive the same first-class testing treatment.

### Overview

At minimum:

- identity/display data needed by semantics;
- gender.

### Needs

Add proper first-class player scenario needs rather than reusing NPC/world state:

- hunger;
- thirst;
- fatigue;
- stress;
- boredom;
- panic;
- other already-supported player condition fields where production semantics consume them.

### Personality & Traits

Player traits must come from actual registered PsychopatzCore / Project Hoomans trait catalogs.

Do not copy trait names into Tk.

Use the production player social-trait resolver so selected traits derive:

- orientation;
- romanceStyle;
- jealousyStyle;
- socialStyle;
- food preference;
- other already-owned player social-profile data.

For example:

```text
Gay trait
  -> production SocialTraits.ResolveTraits
  -> orientation = gay

Friendly trait
  -> production resolver
  -> socialStyle = friendly
```

Do not expose a second conflicting manual selector for a value that is already derived from selected traits unless explicit Advanced Override mode is enabled.

---

# 2. Relationship standing versus durable bond

Current directed relationship standing remains:

```text
unknown
neutral
friend
rival
enemy
```

and continues to be derived by the existing `PNC.RelationshipStates.ResolveState` hysteresis rules.

This is a **current standing**, not the durable social-history bond.

Introduce/normalize one durable relationship milestone on the existing directed relationship record, not in a new relationship database.

Conceptual field:

```lua
relationship.bond = {
    class = "none" | "friend" | "lover" | "family",
    kind = nil | "mother" | "father" | "sister" | "brother",
    establishedAt = ...,
    source = ...,
}
```

Exact schema can adapt to current persistence conventions, but it must live with the existing directed relationship record and survive its normal persistence/normalization path.

Do not store a second independent bond database.

## Family

Family is pre-existing/authored.

Current real supported family kinds are those actually produced by Project Hoomans, presently:

- mother;
- father;
- sister;
- brother.

Do not expose hypothetical `cousin`, `grandmother`, `partner`, `spouse`, etc. as normal selectable production kinds unless a real current producer exists.

The registry may remain extensible for future additions, but normal catalogs must distinguish:

```text
supported by current production
vs
future/alias/internal metadata
```

Family is never earned from approval thresholds and is never romance-compatible.

## Friend

Friend bond is earned automatically from relationship progress.

Do not add a separate friendship score.

Use existing approval/respect/familiarity.

Initial recommended tunable entry gate:

```text
approval      >= 80
respect       >= 50
familiarity   >= 60
current standing not rival/enemy
family bond absent
```

The approval threshold is the primary user-requested friendship milestone; the respect/familiarity gates prevent a near-stranger from becoming a durable friend from one score spike.

Keep thresholds in named relationship/social constants so they can be tuned without rewriting policy.

When the gate is crossed server-authoritatively:

- establish durable `friend` bond;
- record a bounded social memory/event such as `friendship_established`;
- update normal relationship/social revisions;
- expose the new bond through normal snapshots/context.

Do **not** demote the durable friend bond merely because approval temporarily falls to 79.

A durable bond records social history.

Current standing may later become rival/enemy while durable bond remains friend:

```text
bond = friend
standing = enemy
```

This allows estranged/former-friend dialogue.

If friendship rupture is ever added, it must be an explicit relationship event/policy, not threshold oscillation.

Starting companions explicitly authored as friend may seed the durable friend bond immediately.

---

# 3. Lover progression through compatibility + proposal

Lover must never be gained automatically from a score threshold alone.

Normal runtime progression:

```text
none
 -> earned friend
 -> romance eligible
 -> player proposal
 -> NPC acceptance evaluation
 -> lover
```

Existing starting companions authored as lover remain valid and seed the lover bond directly.

## Romance compatibility

Do not create a second romance/gender matrix.

Reuse existing production social-profile logic, including:

- player gender;
- NPC gender;
- player orientation derived from actual traits such as Gay / Bisexual / default straight behavior;
- NPC orientation/social profile;
- existing `PNC.SocialProfileMath.IsGenderCompatible`;
- existing `PNC.SocialProfileMath.AreMutuallyOrientationCompatible` or equivalent current production compatibility API.

Same-gender romance should become eligible only when the actual orientation state supports it.

Compatibility means romance **may be considered**. It does not mean the actors are already lovers.

## Proposal eligibility

Recommended initial tunable gate:

```text
durable bond == friend
approval      >= 85
respect       >= 60
familiarity   >= 80
current standing not rival/enemy
family bond absent
mutual orientation/gender compatibility == true
NPC alive/available
proposal cooldown clear
```

Expose a canonical semantic proposal choice only when eligible.

Do not create separate semantic IDs for male/female/gay/straight variants.

Conceptually:

```text
RELATIONSHIP_PROPOSAL
```

with localized realization determined separately.

## Proposal acceptance

Acceptance must be server-authoritative.

Do not use client-only random acceptance.

Use existing relationship/personality/trait data to calculate a bounded deterministic probability or deterministic seeded roll.

Inputs may include:

- approval above minimum;
- respect above minimum;
- familiarity above minimum;
- NPC romanceStyle;
- relevant actual traits such as Flirty / Reserved;
- current social standing;
- other existing authored romance-affecting profile data.

Expected tendencies:

```text
Flirty / romanceStyle=flirty
    -> higher chance

Reserved / romanceStyle=reserved
    -> lower chance and/or stronger familiarity influence
```

Do not invent a new permanent `romanceChance` attribute.

On acceptance:

- promote durable bond `friend -> lover`;
- record `relationship_proposal_accepted` memory/event;
- update revisions;
- apply lover-specific semantic wording/context.

On rejection:

- remain friend;
- record a bounded rejection event;
- add proposal cooldown;
- any approval/respect consequence must be bounded and policy/personality-driven, never automatically catastrophic.

The same proposal cannot be spammed repeatedly without cooldown.

---

# 4. Relationship panel in Semantic Lab

The normal UI must stop presenting bond as an arbitrary dropdown.

Relationship panel should show:

```text
Approval
Respect
Familiarity

Current standing
Reason / threshold explanation

Durable bond
Friend promotion progress

Romance compatibility
Proposal eligibility
Proposal cooldown / result
```

Examples:

```text
Standing: UNKNOWN
Reason: familiarity < 5

Friend bond:
approval       72 / 80
respect        55 / 50
familiarity    63 / 60
Not yet earned
```

or:

```text
Bond: FRIEND

Romance:
gender/orientation compatible  yes
approval threshold             yes
respect threshold              yes
familiarity threshold          yes
proposal available             yes

[ Simulate proposal ]
```

Family:

```text
Bond: FAMILY
Kind: Mother
Romance compatible: no
Reason: family relationship
```

The harness proposal button must call the same production relationship/proposal policy boundary used by the game path, not mutate the scenario directly to lover.

For fixture/debug work, direct bond editing may remain under explicit Advanced/Malformed override only.

---

# 5. Immediate relationship feedback

Approval/respect/familiarity controls currently require Apply before the user can understand the outcome.

P11 normal UI should compute/display a preview using the **production relationship resolver** while the slider changes:

```text
Approval       -100
Respect         -20
Familiarity       0

Preview standing: UNKNOWN
Reason: familiarity < 5
```

This preview is not persisted until Apply.

Controls:

```text
Apply
Apply + Replay
[ ] Auto replay after adjustment
```

Auto replay should be optional and debounced.

Clearly distinguish:

```text
Preview value
Applied worker value
```

if necessary.

---

# 6. Remove primary-toolbar diagnostics clutter

The main Simulation workflow should not expose low-level maintenance/debug actions as ordinary controls.

Move these away from the primary toolbar:

- Preview;
- Snapshot;
- World knowledge refresh;
- Restart worker;
- Capture baseline;
- Persona matrix;
- Sweep.

Recommended ownership:

```text
Send control
  -> optional Preview mode/menu

World Knowledge inspector
  -> Refresh button inside that tab

Diagnostics / Worker
  -> Snapshot
  -> Restart worker

Compare tab
  -> baseline
  -> sweep/comparison dimensions
  -> run comparison
```

Do not remove capabilities that remain useful.

Move them to understandable destinations.

---

# 7. Replace Sweep / Persona Matrix with Compare

Current `Sweep` is an undocumented selector used only by Persona Matrix.

Replace the primary-facing controls with one explicit `Compare` tab/surface.

Example:

```text
Utterance
[ What's up? ]

Compare by
[ Approval ]

Scenario A: current
Scenario B: -80
Scenario C: +80

[ Run comparison ]
```

Supported dimensions may include:

- approval;
- respect;
- familiarity;
- needs;
- health;
- traits;
- generated personality seed/archetype;
- language;
- relationship proposal eligibility;
- other production-backed fields.

Show side-by-side:

- NPC reply;
- hub/semantic choices;
- speech style;
- relationship standing;
- durable bond;
- runtime graph path.

No raw matrix JSON as the primary result.

---

# 8. Unified Runtime Dialogue Graph

Simulation graph must support the actual runtime semantic structure, not only ConversationBlocks.

One shared renderer, multiple adapters:

```text
semantic_flow
conversation_block
semantic_hub
```

## Semantic Flow

Greeting such as `hello` must visualize its real production Flow and current/visited transitions.

## ConversationBlock

Keep existing P9 graph behavior.

## Semantic Hub

What's Up must visualize the actual provider/candidate decision surface rather than remain blank.

The hub graph may show:

```text
WHAT'S UP
  -> Wellbeing
  -> Needs
  -> Medical
  -> Gossip
  -> Activity
  -> Trader
  -> ...
```

using real offered/hidden provider candidates and safe eligibility/rank diagnostics.

Do not fabricate a ConversationBlock.

Highlight at least:

- current;
- visited;
- available;
- locked/hidden where safe;
- future;
- completed.

Preserve completed graph history as P10 already requires.

---

# 9. Trait truthfulness

Normal UI catalogs must contain only traits/kinds actually registered by current production owners.

## Player

Use actual PsychopatzCore/Project Hoomans player trait catalogs.

Trait selection must feed the real player social-profile resolver.

## NPC

Use actual `PNC.NPCTraits` definitions/catalog.

Trait selection must feed the real generated NPC personality path.

Do not introduce hypothetical traits for testing in normal mode.

Malformed/future synthetic fixtures belong only in explicit diagnostics/tests.

---

# 10. Speech realization file structure

Keep the current realization registry API, but prevent `PNC_SpeechRealization.lua` from becoming a new god file.

Target organization:

```text
Semantics/SpeechRealization/

PNC_SpeechRealization.lua
    registry
    resolver
    fallback
    common family helpers

Families/
    PNC_SpeechRealization_Social.lua
    PNC_SpeechRealization_Status.lua
    PNC_SpeechRealization_Knowledge.lua
    PNC_SpeechRealization_Actions.lua
    PNC_SpeechRealization_QuestTrade.lua
```

Exact grouping may adapt to actual current template ownership.

Avoid one file per phrase and avoid dozens of tiny modules.

Translations remain in normal translation catalogs.

Semantic IDs remain language-independent.

---

# Milestones

## P11A — Truthful actor/context model and UI cleanup skeleton

Required:

- inventory current Simulation toolbar/workbench behavior;
- remove hypothetical/future bond kinds from normal catalogs;
- distinguish real production kinds from aliases/future metadata;
- establish actor-centric workbench shell:
  - NPC Target;
  - Player;
  - Relationship;
  - World;
- nested actor tabs:
  - Overview;
  - Needs;
  - Personality & Traits;
- move primary-toolbar diagnostics toward their final owner tabs;
- preserve all existing worker functionality.

**Gate:** normal UI no longer advertises non-current bond kinds and the two actors are first-class visible concepts.

## P11B — First-class Player/NPC needs + production traits/personality

Required:

- add proper player needs/condition scenario state;
- normalize NPC needs onto NPC-owned fields;
- retain historical `world.*` compatibility only for old fixture loading;
- add actual player trait selection from production catalogs;
- add actual NPC trait selection from production catalogs;
- player traits derive player social profile through production resolver;
- NPC identity/archetype/traits derive NPC personality through production generator;
- generated personality is default/read-only;
- manual personality override is explicit.

**Gate:** both actors can be configured symmetrically and normal personality values are production-derived.

## P11C — Durable dynamic friend bond

Required:

- add durable bond milestone to existing directed relationship persistence/normalization;
- seed current authored starting friend relationships;
- implement named tunable friend-promotion constants with initial gate:
  - approval >= 80;
  - respect >= 50;
  - familiarity >= 60;
  - not rival/enemy;
- server-authoritative automatic promotion;
- memory/event + revision update;
- no automatic threshold demotion;
- ActorConversationContext/semantic realization consume durable bond separately from current standing.

**Gate:** a relationship can progress `none -> friend`, later become enemy standing while retaining friend history, and survive persistence round-trip.

## P11D — Romance compatibility + proposal -> lover

Required:

- use existing gender/orientation compatibility APIs;
- derive player orientation from real traits;
- use NPC social profile/orientation;
- prohibit family romance;
- proposal only from eligible friend bond;
- named tunable proposal thresholds with initial gate:
  - approval >= 85;
  - respect >= 60;
  - familiarity >= 80;
- server-authoritative acceptance probability/seeded roll influenced by existing romanceStyle/traits and relationship surplus;
- Flirty/Reserved effects use existing production metadata;
- accepted proposal promotes `friend -> lover`;
- rejection retains friend and adds cooldown;
- starting lover remains valid;
- no gender/orientation-specific duplicate semantic action IDs.

**Gate:** compatible high-standing friends can propose; incompatible/family actors cannot; accepted proposal persists lover bond; rejected proposal cannot be spammed.

## P11E — Relationship UX + Compare cleanup

Required:

- relationship sliders show immediate production-derived preview state/reason;
- friend-promotion progress shown;
- romance compatibility/proposal availability shown;
- optional debounced Auto Replay;
- replace Persona Matrix/Sweep/Baseline controls with one understandable Compare surface;
- move Preview/Snapshot/World Knowledge refresh/Restart worker to contextual Diagnostics/inspector locations.

**Gate:** user can understand relationship progression without knowing internal thresholds or Sweep semantics.

## P11F — Unified Runtime Dialogue Graph

Required:

- semantic Flow adapter;
- ConversationBlock adapter;
- semantic Hub adapter;
- greeting Flow becomes visible;
- What's Up hub becomes visible;
- current/visited/completed state retained;
- one shared graph renderer;
- graph actions continue through normal semantic frames.

**Gate:** `hello`, `What's up?`, and an authored ConversationBlock all produce meaningful runtime graphs in Simulation.

## P11G — Modular realization packs

Required:

- extract built-in realization families into a small number of domain packs;
- preserve registry/fallback behavior;
- no semantic/output regressions;
- no one-file-per-line fragmentation.

**Gate:** new semantic family content can be added to the correct domain pack without growing the core resolver into a god module.

## P11H — Final runtime-parity usability gate

Required:

- real Tk/Xvfb interaction at minimum and normal desktop sizes;
- both actors' needs/traits/profile editing;
- production-generated NPC personality;
- player orientation from real traits;
- dynamic friend promotion;
- proposal eligibility/accept/reject/cooldown;
- family exclusion;
- lover wording/context;
- relationship live preview;
- Compare workflow;
- greeting Flow graph;
- What's Up hub graph;
- ConversationBlock graph;
- structured inventory regression;
- P10 hub regression;
- EN/TL;
- privacy/stale/replay/authority;
- persistence and migration/versioning checks;
- Python/Lua/Kahlua/doctor/catalog/diff checks;
- no duplicate relationship/personality/graph ModData.

Only after P11A-P11H pass may the parent goal return to **READY FOR USER LIVE TEST**.

---

# Hard invariants

- Family is authored/pre-existing.
- Friend is earned automatically.
- Lover requires proposal + acceptance.
- Orientation compatibility comes from existing gender/trait/social-profile logic.
- Compatibility does not itself create lover state.
- Friend/lover durable bond is not the same as current friend/rival/enemy standing.
- Durable bond lives in the existing directed relationship record.
- No second bond database.
- No client-only proposal RNG.
- No hypothetical production kinds in normal UI.
- Both Player and NPC Target are first-class simulation actors.
- Generated NPC personality is normal; manual sliders are override/debug.
- Player traits derive player social profile.
- One semantic parser, one provider registry, one relationship owner, one translation backend, one graph renderer family.
