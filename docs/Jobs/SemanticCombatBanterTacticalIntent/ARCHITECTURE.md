# Architecture — Semantic Combat Banter & Tactical Intent

## Design target

Combat dialogue is gameplay presentation over authoritative combat facts.

```text
Perception / ZombieObservation
CombatResolution / AttackExecution
Companion behavior / owner combat state
Equipment / Firearms / Skills
                 |
                 v
        Combat Moment Context
                 |
                 v
        Combat Banter Arbiter
          /             \
         v               v
       BARK       TACTICAL_PROMPT
         |               |
         v               v
Semantic response    Semantic offers
/ UtterancePlan     + encounter intent
         |               |
         +-------+-------+
                 v
       existing presentation
      conversation or combat strip
                 |
                 v
 existing gameplay authorities only
```

The semantic layer describes and presents combat. It does not become the combat authority.

## 1. Combat Moment Context

Introduce one bounded runtime semantic projection for notable combat moments. This may be a new focused service or an extension of the existing SemanticCombatReaction service, but there must be one canonical projection contract.

Suggested fields:

```text
kind
eventRef
actorKind / actorID
targetKind / targetID
outcome
attackType / attackKind
weaponFullType
weaponDisplayName?        optional sanitized flavor
weaponFamily
weaponSkill
weaponSkillLevel
bodyPart / woundType
pressureBand / nearbyCount
actorHealth / panic / stress
reactionStyle
relationshipTier
traits/personality projection
encounterID / encounterIntent
burstCount / streakContext
source / occurredAt
```

Facts are populated at the owner that actually knows them. Do not reconstruct them later from rendered text.

Routine context is live-only and bounded.

## 2. Horde encounter episode

`PNC_ZombieObservation` remains the threat-pressure sensor and must remain free of new global zombie-list scans.

Add one episode state owner above the sensor, for example `SemanticCombatEncounterService`, that consumes observation transitions and owns:
- episode ID;
- start time;
- latest pressure band/count summary;
- material escalation/de-escalation;
- clear/end transition;
- current tactical intent;
- spokesperson/prompt state;
- prompt expiry.

Episode state is runtime-only.

A stable horde does not create repeated "new encounter" events.

## 3. Team encounter intent

Encounter intent is separate from `record.attackType`.

States:
- `undecided`;
- `engage`;
- `avoid`;
- `hold`.

Resolution inputs:
- explicit semantic choice;
- owner begins attacking -> engage;
- owner/team clearly withdraws -> avoid;
- explicit hold choice -> hold;
- immediate threat -> self-defense may act regardless of undecided/avoid/hold.

Intent expires when the episode clears.

The intent informs companion behavior through existing target/avoid/retreat authorities. It does not directly apply damage or pathing.

## 4. Presentation classes

### BARK

A bark is autonomous presentation.

Properties:
- does not pause/block gameplay;
- no response required;
- may have optional conversational continuation only if context supports it, but absence of buttons is normal;
- transient;
- `llmEligible=false` for routine combat;
- `memoryEligible=false` unless an existing meaningful social event independently qualifies;
- banter-arbiter controlled.

### TACTICAL_PROMPT

A tactical prompt represents unresolved gameplay intent.

Properties:
- has semantic `offerIDs`;
- offer frames are authoritative semantic choices, not text reparsing;
- must support typed equivalent input;
- full conversation UI can render it when open;
- a lightweight non-modal combat-choice surface renders the same offers when closed;
- selecting an offer dispatches through the existing semantic/action path into existing companion/gameplay authority;
- implicit player action may resolve it without a click;
- expiry must not leave stale buttons/actions.

## 5. Combat Banter Arbiter

One bounded arbiter ranks candidate speech moments.

Inputs:
- moment kind/urgency;
- current pressure;
- speaker personality/style;
- semantic-family recency;
- speaker recency;
- current active tactical prompt;
- team chatter budget;
- event novelty;
- listener visibility/range;
- whether another higher-priority line is presenting.

Priority example:
1. immediate warning / tactical prompt;
2. injury/downed/reload-critical callout;
3. meaningful encounter escalation;
4. unusual/impressive kill;
5. ordinary kill flavor;
6. low-value repetition -> silence.

The arbiter must cap simultaneous speakers and prevent one kill from producing a chorus.

## 6. Horde dialogue

Horde semantic content is not generic combat acknowledgement.

Follower behavior:
- if a dangerous encounter begins and team intent is unresolved, an eligible follower may ask the team whether to engage;
- choose one spokesperson by bounded relevance/priority;
- do not ask again while the same prompt/episode is active;
- if the player starts fighting first, resolve to engage and allow an immediate personality reaction rather than waiting for the prompt answer;
- if the team avoids, permit avoidance/relief/caution reaction where appropriate.

Example semantic strategies:
- `ASK_ENGAGE_HORDE`;
- `ACK_ENGAGE_EAGER`;
- `ACK_ENGAGE_HESITANT`;
- `ACK_AVOID_RELIEVED`;
- `ACK_HOLD_READY`;
- `WARN_HORDE_ESCALATION`.

Wording varies through existing style/personality/trait realization.

## 7. Kill commentary

Generalize kill moments by target and weapon context.

Target families:
- zombie;
- hostile human NPC;
- foreign/mod NPC where authoritative kill evidence is available.

Weapon families should derive from actual Equipment/Skills descriptors:
- firearm;
- short blade;
- long blade;
- axe;
- spear;
- short blunt;
- long blunt;
- unarmed/other.

Content predicates may also use:
- head/neck vs other body location;
- high/low skill;
- pressure band;
- actor panic/stress;
- burst/streak context.

Examples are flavor targets:
- blade + head/neck + aggressive/dark humor -> teeth/molars/gore line;
- firearm + high Aiming + confident -> sharpshooting boast;
- firearm + low skill/nervous -> surprised/relieved line;
- veteran under pressure -> terse tactical confirmation;
- compassionate human kill -> discomfort or gravity.

Never claim facts not present in the moment context.

## 8. Weapon-name flavor

Weapon display names are optional lexical slots.

Rules:
- use sanitized human-readable names only;
- never expose internal full-type IDs;
- low selection probability;
- avoid repeating the weapon name in consecutive barks;
- generic family line must always be available;
- modded/unknown weapon must degrade gracefully.

## 9. Interaction and UI

The existing conversation Response Channel remains the full-dialogue renderer.

Add a small non-modal combat-choice renderer only for active `TACTICAL_PROMPT` offers when the full conversation UI is closed.

It must consume the same:
- lifecycle event/beat;
- semantic offer IDs;
- candidate eligibility;
- click frame/dispatch path.

No duplicate semantic decision code lives in the renderer.

When the full conversation UI opens, the same prompt should project there without duplicate action authority.

## 10. Persistence

Runtime-only:
- horde episode;
- encounter intent;
- prompt state;
- moment context;
- banter cooldowns/budgets;
- routine bark selection;
- weapon-commentary context.

Existing durable owners remain the only persistent owners for:
- relationship memories;
- conduct;
- meaningful social encounter outcomes;
- explicitly meaningful conversation state.

No combat transcript, routine kill ledger, or new ModData root.

## 11. Performance

Mandatory constraints:
- no new recurring `getZombieList()`/world scan;
- no all-NPC scan per kill;
- use existing spatial/perception indexes;
- one bounded candidate set per moment;
- cooldown/coalescing before expensive presentation work;
- no per-kill LLM;
- no per-frame dialogue generation;
- no unbounded event queue.

## 12. Extensibility

The combat-moment contract must be event-agnostic enough to later support:
- reload/out-of-ammo comments;
- weapon breaking;
- friendly-fire warnings;
- rescue/protection acknowledgements;
- downed ally callouts;
- exceptional shots/melee moments.

Those are future consumers unless explicitly added by the roadmap. Do not implement them merely because the architecture permits them.
