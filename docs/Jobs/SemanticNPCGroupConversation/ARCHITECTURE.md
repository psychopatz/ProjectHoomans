# Architecture — Semantic NPC Group Conversation

## Parent invariant

**NPC->NPC, NPC->player, companion, neutral and hostile speech use one semantic interaction architecture.**

Role, cohort and recipient are context. They are not separate dialogue engines.

## Canonical flow

```text
authoritative gameplay/perception event
        ↓
Combat Moment / other semantic event
        ↓
local candidate set
        ↓
Combat Cohort Resolver
        ↓
Encounter Intent / authoritative gameplay decision
        ↓
Combat Exchange Director
        ↓
Combat Banter Arbiter
        ↓
semantic NPCSpeech envelope
(actorID -> targetID / cohort)
        ↓
Response Catalog / UtterancePlan / SpeechRealization
        ↓
existing NPC in-world presentation
        ↓
nearby players may observe
```

For player-addressed speech, the same flow targets the player and may expose semantic response offers through the existing interaction lifecycle.

## 1. Combat Cohort Resolver

The new generic cohort resolver is a **runtime read model**, not a faction database.

It answers:

```lua
{
    cohortKey = "...",
    kind = "owner_team" | "faction" | "explicit_group" | "solo",
    leaderID = "...",          -- optional authoritative leader
    relationToPlayer = "...", -- if relevant
    encounterID = "...",
}
```

Identity precedence:

1. existing player-owned follower team;
2. existing authoritative explicit squad/group identity, if production exposes one;
3. authoritative faction ID;
4. solo NPC identity.

Do not infer a team merely because unrelated NPCs are nearby.

Do not persist cohort copies. Resolve from existing owner/faction/group authority.

## 2. Local participation

Cohort identity and local participation are separate.

Faction membership may contain many remote/abstract NPCs. An encounter exchange uses only locally relevant participants supplied by existing event/perception/spatial facts.

Preferred rule:
- reuse an already-produced local candidate set from the triggering combat/perception path;
- only if no appropriate local set exists, perform one bounded `Spatial.QueryNPCs` at exchange admission;
- filter to live/relevant cohort members;
- cap candidates before semantic ranking.

Never iterate all faction members to discover who can talk.

## 3. Generic Encounter Intent

Migrate/generalize the accepted `CombatEncounterIntent`.

The final authority must support:
- player-owned follower cohort;
- autonomous neutral/friendly faction cohort;
- hostile faction/squad cohort;
- solo NPC fallback.

Keep:
- `undecided / engage / avoid / hold`;
- runtime-only state;
- encounter binding;
- stale-event guards;
- self-defense precedence;
- explicit resolution provenance.

Change:
- owner identity must no longer be the only team key;
- spokesperson/leader selection must be cohort-aware;
- autonomous cohorts use existing AI/faction/combat authority to resolve gameplay decisions.

Dialogue must never directly invent or secretly override tactical behavior.

## 4. Combat Exchange Director

The Exchange Director is a bounded semantic state machine, not a chatbot.

Example runtime contract:

```lua
{
    exchangeID = "...",
    encounterID = "...",
    cohortKey = "...",
    topic = "horde",
    factRefs = { ... },

    lastSpeakerID = "...",
    lastTargetID = "...",
    lastAct = "PROPOSE_AVOID",
    expectedResponse = "ACCEPT_OR_DISAGREE",

    turnIndex = 2,
    maxTurns = 4,
    expiresAt = ...,

    usedStrategies = { ... }, -- bounded anti-repeat keys
}
```

It must not store rendered text.

The next NPC responds to the known semantic act/frame from the previous turn.

Forbidden:

```text
NPC A renders English
    ↓
parse NPC A English
    ↓
NPC B guesses meaning
```

Required:

```text
NPC A semantic act = PROPOSE_AVOID
    ↓
NPC B receives semantic act + event/fact refs
    ↓
NPC B resolves ACCEPT / DISAGREE / CHALLENGE
    ↓
SpeechRealization renders B
```

## 5. Recipient vs observer

Every NPC speech turn must distinguish:
- **speaker** — actor of the semantic speech;
- **recipient** — NPC/player/cohort being addressed;
- **observers** — nearby players/NPCs who may hear/present the line but are not the semantic target.

Player response offers are allowed only when the player is actually an eligible semantic recipient/participant.

Overheard NPC-to-NPC speech must not manufacture player buttons.

## 6. Group decision vs expression

Gameplay intent and dialogue expression are separate.

```text
AI/faction/combat preference
        ↓
bounded group decision authority
        ↓
resolved encounter intent
        ↓
semantic dialogue expresses/proposes/reacts
```

Personality may affect:
- who proposes;
- willingness to agree/disagree;
- tone/intensity/profanity;
- reassurance/panic;
- whether an optional bark is worth saying.

Personality must not silently mutate authoritative combat state outside the accepted policy seam.

If personality should influence an autonomous group decision, that influence must be an explicit, testable input to the group decision policy.

## 7. Arbiter ownership

All combat exchanges reuse the existing Combat Banter Arbiter.

The arbiter decides whether:
- a tactical warning preempts a joke;
- an exchange turn is admitted;
- a second speaker may respond;
- repeated semantic families are suppressed;
- team/global chatter budget is exhausted;
- silence wins.

Conversation/exchange state does not bypass arbiter budgets.

## 8. Presentation

NPC-to-NPC turns use the existing semantic realization and NPC speech presentation.

Server semantic state should be transported only to clients that can legitimately observe the exchange using existing network-interest/local-player relevance where available.

Do not send a semantic payload once per possible listener if one bounded local presentation event can be fanned out safely.

Presentation transport is not semantic authority.

## 9. Persistence

Routine group combat conversation is transient.

Default:
- no ModData;
- no transcript;
- no durable turn history;
- no LLM;
- no relationship mutation just because two NPCs spoke.

Meaningful gameplay/social outcomes may still enter existing social/faction/relationship authorities through their normal event paths. Dialogue does not duplicate those writes.

## 10. Initial semantic relations

The first implementation should stay narrow enough to prove architecture while being reusable:

- `WARN_THREAT`;
- `PROPOSE_ENGAGE`;
- `PROPOSE_AVOID`;
- `PROPOSE_HOLD`;
- `ACCEPT`;
- `DISAGREE`;
- `CHALLENGE`;
- `ACK`;
- `REASSURE`;
- `PANIC`;
- `COMMAND_RETREAT` / `COMMAND_ENGAGE` only when actual authority resolved that result.

Later mechanics can register additional semantic acts without redesigning the exchange engine.

## 11. Bounded defaults

Exact constants should be measured, but the architecture requires hard caps.

Initial acceptance targets:
- local participant candidates: <= 4 per exchange admission;
- active speaker at a moment: <= 1;
- optional respondent: <= 1;
- exchange turns: <= 4;
- fact refs: existing lifecycle cap;
- active exchanges: bounded global/team map;
- short TTL measured in seconds;
- no per-frame semantic regeneration.

These are ceilings, not targets for how much NPCs should talk.
