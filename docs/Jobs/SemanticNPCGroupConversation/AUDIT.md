# Audit — Semantic NPC Group Conversation

**Audit base:** ProjectHoomans `6c11d218`, existing `main`.

## Verdict

The accepted combat semantic foundation is reusable, but true NPC-to-NPC squad conversation does not yet exist.

Do not solve this by adding neutral/hostile-specific chatter services. The correct seam is to generalize the existing encounter/team/audience assumptions into a bounded, domain-agnostic local cohort and semantic exchange layer.

## Verified reusable foundation

### Combat speech is already partly NPC-agnostic

`PNC_SemanticCombatReactionService.OnPlayerKill` queries nearby managed NPCs and does not require every witness to be a companion before building a combat reaction profile.

`OnNPCKill` and `OnNPCHumanKill` already build authoritative NPC-killer Combat Moments with weapon/action context.

The remaining limitation is audience/presentation: those NPC self-kill reactions currently iterate nearby players and deliver player-facing semantic speech.

### Combat Encounter Intent is follower-specific

`PNC_SemanticCombatEncounterIntent.lua` currently:
- derives its team key from `ownerOnlineID / ownerUsername`;
- requires a live follower/follow-order shape;
- stores one runtime `undecided / engage / avoid / hold` state per owner team;
- correctly remains runtime-only and separate from permanent `attackType`.

This is good behavior with the wrong abstraction boundary for autonomous NPC groups.

### NPC threat sharing is also owner-team specific

`PNC_Perception/NPCThreatAlert.lua` already performs bounded, authority-owned group threat propagation with:
- one spatial query;
- republish throttling;
- TTL;
- recipient-side cached alert state;
- no per-behavior rescan.

However, its group-membership filter is based on common player ownership. It is not a generic faction/squad cohort resolver.

This implementation is a strong performance pattern to reuse.

### Faction/group identity already exists

The faction service exposes authoritative NPC affiliation:
- `Factions.GetFactionID(record)`;
- faction registry `memberIDs`;
- faction relationships/diplomacy;
- leader identity where present.

Do not create another faction-membership database for conversation.

Faction `memberIDs` are identity/index data, not a reason to iterate the whole faction for local speech. Local participation must still come from the spatially relevant active set.

### Social audience semantics already exist

`PNC_SemanticSocialContext` already distinguishes:
- self;
- ally;
- friendly;
- neutral;
- stranger;
- hostile;

using faction standing, personal relationship and companion/follower state.

This should feed participant/audience context rather than be duplicated.

### Semantic speech already has actor/target identity

`PNC_SemanticInteractionLifecycle_Envelope.NPCSpeech` supports:
- `actorID`;
- `targetID`;
- semantic act/topic;
- event/eventRef;
- response plan / realization provenance;
- bounded fact refs.

This is the correct semantic carrier for NPC-to-NPC turns.

The missing part is a generic NPC-recipient exchange/presentation path and short-lived exchange state.

### NPC visual speech presentation already exists

Client presentation already has canonical NPC speech surfaces using actor `:Say()` / halo/nameplate-compatible presentation.

Do not invent a second visual dialogue renderer for NPC-to-NPC combat speech.

### Existing Combat Banter Arbiter is the chatter budget owner

The accepted arbiter already owns:
- stream coalescing;
- urgency/priority;
- speaker/family/team budgets;
- cooldowns;
- explainable silence;
- bounded decision history.

NPC group conversation must compete inside this same arbiter. It must not establish a second independent chatter budget.

## Actual product gaps

1. **No generic Combat Cohort identity.**
   Owner team is currently conflated with encounter team.

2. **No autonomous group encounter intent.**
   Neutral/hostile faction members cannot use the accepted `engage / avoid / hold` contract as a local group decision.

3. **Player is still structurally central to NPC self-banter presentation.**
   An NPC can speak because it killed something, but the transport normally selects nearby players as listeners.

4. **No NPC-to-NPC semantic turn owner.**
   There is no bounded state saying NPC A addressed NPC B with a known semantic act and an expected response.

5. **No coherent multi-turn combat exchange.**
   Independent barks may occur, but there is no semantic sequence such as `WARN -> PROPOSE -> DISAGREE -> COMMAND/ACK`.

6. **No observer/recipient distinction for NPC speech.**
   A nearby player hearing two NPCs talk should not automatically become the semantic recipient or receive buttons.

7. **Owner-specific group-threat propagation cannot represent arbitrary factions/squads.**

8. **Observatory cannot yet explain cohort membership or NPC-to-NPC turn selection.**

## Performance risks to explicitly avoid

Never implement:

```text
every tick
  for every NPC
    find nearby NPCs
      decide whether to talk
```

Also avoid:
- scanning all `faction.memberIDs` for each speech event;
- reparsing rendered dialogue;
- storing transcripts;
- per-turn ModData;
- one semantic generator per listener;
- one response chain per nearby NPC;
- separate neutral/hostile/follower arbiters.

## Preferred runtime shape

```text
authoritative event
    ↓
existing Combat Moment / Perception fact
    ↓
local participant candidates
(reuse existing spatial/event query where possible)
    ↓
Combat Cohort Resolver
    ↓
bounded Encounter/Exchange state
    ↓
one speaker + optional one respondent
    ↓
existing Combat Banter Arbiter
    ↓
semantic NPCSpeech(actorID,targetID)
    ↓
existing realization/presentation
    ↓
nearby players observe only if relevant
```

The exchange must normally use at most a few semantic turns and then terminate or yield to gameplay.
