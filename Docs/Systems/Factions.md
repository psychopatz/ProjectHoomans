# Persistent Factions

## Purpose and Boundaries

The faction system gives organizations stable server-owned identities,
directed opinions, deterministic policies, and symmetric official treaties.
It deliberately separates four concepts:

- a faction archetype describes what kind of organization it is;
- a faction record identifies one persistent organization;
- `record.affiliation` stores an NPC's organization, role, rank, and status;
- legacy `record.faction` is derived tactical compatibility state.

`record.affiliation.factionID` is canonical membership. Assigning an NPC to a
looter organization removes player ownership and applies the looter
archetype's default outsider hostility. Tactical intent combines faction
policy, the directed relation, official treaties, player-scoped exceptions,
and immediate self-defense.

This phase does not implement territory, economy, raids, autonomous strategy,
dialogue, diplomacy UI for ordinary players, or faction simulation.

## Persistence Schema V5

The authority owns the separate `PNC_Factions` Global ModData table:

```lua
{
    schemaVersion = 5,
    revision = 0,
    byID = {
        faction_123 = {
            id = "faction_123",
            name = "Riverside Cooperative",
            archetypeID = "settler",
            status = "active",
            createdAt = 182.5,
            archivedAt = 0,
            leaderNPCID = "npc_123",
            ownerPlayerKey = "player:Patrick:char_f8d31a",
            memberIDs = { npc_123 = true },
            playerMemberKeys = {
                ["player:Patrick:char_f8d31a"] = true,
            },
            policy = {
                schemaVersion = 1,
                aggression = 0.28,
                retaliation = 0.57,
                caution = 0.51,
                hospitality = 0.49,
                opportunism = 0.27,
                outsiderPolicy = "neutral",
                warThreshold = 70,
                peaceThreshold = 25,
                generatedFromArchetype = true,
                generationVersion = 1,
            },
            emblem = {
                schemaVersion = 1,
                backgroundColorID = "green",
                layers = {
                    {
                        symbolID = "House",
                        colorID = "white",
                        scale = 0.76,
                        offsetX = 0,
                        offsetY = 0,
                    },
                    {
                        symbolID = "Star",
                        colorID = "gold",
                        scale = 0.34,
                        offsetX = -0.08,
                        offsetY = -0.08,
                    },
                },
                revision = 0,
            },
            playerPacifications = {
                ["player:Patrick:char_f8d31a"] = {
                    schemaVersion = 1,
                    playerKey = "player:Patrick:char_f8d31a",
                    createdAt = 182.5,
                    untilWorldAgeHours = 206.5,
                    reason = "extortion_bribe",
                    sourceNPCID = "npc_123",
                    revision = 1,
                },
            },
            relations = {
                faction_456 = {
                    schemaVersion = 1,
                    targetFactionID = "faction_456",
                    standing = -18,
                    trust = -20,
                    fear = 5,
                    grievance = 25,
                    state = "wary",
                    previousState = "neutral",
                    atWar = false,
                    allied = false,
                    truceUntil = 0,
                    warStartedAt = 0,
                    warEndedAt = 0,
                    warReason = nil,
                    initiatingFactionID = nil,
                    triggeringIncidentID = nil,
                    incidents = {},
                    recentIncidentIDs = {},
                    lastEvaluatedAt = 183,
                    revision = 1,
                },
            },
            tags = {},
            revision = 1,
        },
    },
    byArchetype = {
        settler = { faction_123 = true },
    },
    byPlayerKey = {
        ["player:Patrick:char_f8d31a"] = "faction_123",
    },
}
```

`byID` is canonical. The other top-level maps are deterministic secondary
indexes. Persistent data contains only serialization-safe primitives and
tables—never NPC records, players, zombies, inventory items, Java objects,
functions, coroutines, or metatables.

## Layered Emblems

Every faction owns a bounded emblem made from one background color and up to
three overlapping vanilla Build 42 map-symbol layers. Persistence stores only
stable symbol IDs, palette IDs, scales, offsets, and revisions. Texture
objects are resolved and cached on the client and never enter ModData.

AI-owned factions receive an archetype-aware deterministic emblem generated
from faction identity. V3 records without an emblem receive the same emblem on
every normalization, making the V4 migration idempotent. A missing or
malformed authored emblem also falls back to that deterministic result.

The player-faction creation control opens the emblem creator before sending
the guarded create request. A player faction owner may reopen it with **Edit
Emblem**. Server APIs normalize the submitted primitives and reject edits by
non-owners. The reusable client editor supports background color plus three
symbol/color/size layers.

## Archetypes and Policy

The four data-only archetypes are:

- `settler` — balanced, neutral outsiders;
- `looter` — aggressive, retaliatory, opportunistic, predatory outsiders;
- `trader` — cautious, hospitable, commercial outsiders;
- `refugee` — highly cautious, low aggression, cautious outsiders.

Each new faction receives deterministic small variation around its archetype
defaults. Existing V2 factions receive the same result every normalization,
using only faction ID, archetype, field name, and generation version. Authored
policy fields are preserved and clamped.

Policy dimensions range from `0` through `1`. War and peace thresholds range
from `0` through `100`. Policy is consulted by escalation and tactical intent;
it is not autonomous faction AI.

## Directed Relations

`factionA.relations[factionB.id]` is A's opinion of B. B's opinion of A is a
separate record and may have different:

- standing, from `-100` through `100`;
- trust, from `-100` through `100`;
- fear, from `0` through `100`;
- grievance, from `0` through `100`;
- state, history, incident list, and revision.

Official war, alliance, and truce fields are symmetric invariants. Treaty
operations synchronously update both directed records, both faction
revisions, and the registry once. Directional opinion metrics remain
independent.

States are `unknown`, `neutral`, `friendly`, `wary`, `hostile`, `war`,
`truce`, and `allied`. Treaty states take priority.

Opinion entry thresholds are:

- friendly: standing at least `30`, trust at least `10`, grievance at most
  `20`;
- hostile: standing at most `-45` or grievance at least `65`;
- wary: standing at most `-15`, trust at most `-25`, fear at least `50`, or
  grievance at least `30`;
- neutral: meaningful contact that meets none of those;
- unknown: no meaningful contact.

Hysteresis retains friendly until standing falls below `20` or grievance
exceeds `30`; hostile remains while standing is at most `-30` or grievance is
at least `50`. Wary remains until standing is above `-5`, trust above `-15`,
fear below `40`, and grievance below `20`.

Explicit recalculation applies deterministic elapsed-world-age decay. Standing
and trust drift toward zero; fear and non-war grievance decline. Reads do not
decay or mutate data. Expired truces clear during explicit recalculation.

## Incidents and Escalation

Faction effects are selected from server-owned definitions. Callers provide a
named incident and evidence context, never arbitrary scores. Supported
incidents are minor/severe member attack, member killed, rescued, protected,
fought together, abandoned, and authoritative personal grievance report.
Treaty audit records cover war, peace, truce, alliance formed, and alliance
broken.

For an attack by A against B, B's relation toward A receives the negative
effect. A's reverse opinion does not change. Rescue/protection similarly
improves the beneficiary faction's opinion of the actor faction.

Attack callbacks are aggregated by faction pair and stable actor/subject keys:

1. the first credible hit creates one minor incident;
2. a repeated hit in the short aggregation window upgrades it to severe;
3. death upgrades that same incident to member killed;
4. duplicate callback/event IDs are rejected;
5. attack ticks do not create an unbounded incident stream.

A minor attack does not automatically declare war. Severe assault is evaluated
against the victim faction's aggression, retaliation, grievance, and war
threshold. Killing a member commonly escalates; killing a leader adds fear and
grievance and uses the `leader_killed` reason. Violence during an active truce
immediately uses `truce_broken`.

Valid persisted war reasons are a bounded enum:
`member_killed`, `severe_assault`, `repeated_aggression`, `leader_killed`,
`truce_broken`, `manual_debug`, `scripted`, and `unknown`.

An individual NPC reaching personal `enemy` does not start faction war by
default. Only leaders/officers/seconds can submit a grievance report.
`PNC.Config.Factions.EnemyRelationshipCanImmediatelyDeclareWar` defaults to
`false`; enabling it is an explicit compatibility override.

The incident history is deterministically limited to 64 entries. Ordinary
weak/old incidents are removed before preserved treaty audits. A separate
bounded recent-ID list retains dedupe evidence.

## Treaties

Server mutation APIs are:

- `DeclareWar(sourceFactionID, targetFactionID, options)`
- `EndWar(sourceFactionID, targetFactionID, options)`
- `StartTruce(sourceFactionID, targetFactionID, options)`
- `MakePeace(sourceFactionID, targetFactionID, options)`
- `FormAlliance(sourceFactionID, targetFactionID, options)`
- `BreakAlliance(sourceFactionID, targetFactionID, options)`

War clears alliance/truce. Truce ends war for a bounded world-age duration.
Peace clears war/alliance/truce, adds `15` standing and `10` trust on each
direction, and halves each direction's grievance. Alliance normally requires
both directions to meet friendly thresholds; guarded debug/script operations
may explicitly override this check. Breaking alliance applies trust and
grievance penalties.

Already-current treaty requests are revision-neutral.

## Tactical Intent and Compatibility Behavior

`PNC.FactionBehavior.ResolveIntent(observerRecord, target, context)` returns:

```lua
{
    intent = "observe",
    attackAllowed = false,
    pursueAllowed = false,
    commandable = false,
    reason = "neutral_outsider_policy",
}
```

Intent priority is immediate self-defense, player-owned membership, same
faction, war, truce, alliance, directed hostility, directed caution/friendship,
archetype policy, then personal disposition.

- player-owned members remain commandable companions for the exact stable
  player-character UUID;
- war allows attack/pursuit against the opposing faction;
- truce prevents attack;
- looters attack outside players and NPC factions by default, even when no
  official war record exists;
- `playerPacifications[playerKey]` can suppress proactive attacks against one
  stable player character until a deterministic world-age-hour timestamp;
- immediate self-defense overrides a player pacification;
- traders tolerate, refugees avoid, and settlers observe neutral outsiders.

Player pacification is a narrow future extortion/bribery hook, not an
alliance, truce, friendship score, or account-wide exemption. The public
server APIs are `PacifyForPlayer`, `PacifyForRuntimePlayer`,
`GetPlayerPacification`, `IsPacifiedForPlayer`,
`ClearPlayerPacification`, and `PrunePlayerPacifications`. The default
duration is 24 world-age hours. Expiry is checked on reads and targeting;
physical removal is an explicit prune operation.

V4 faction records migrate to V5 by receiving an empty
`playerPacifications` map. Normalization is deterministic, bounded to 64
entries, serialization-safe, and idempotent.

The legacy tactical bridge sets external peaceful members to neutral roaming.
It uses hostile-hunt compatibility state only while the faction has an active
war. Final target filtering still resolves the exact opposing faction, so a
war with one player faction does not authorize attacks against unrelated
players or organizations. Social changes never advance `presenceRevision`.

## Membership, Leadership, and Player Factions

Affiliation is now NPC schema V2 and contains faction ID, membership status,
role, rank, joined/left world-age hours, origin archetype, bounded former
factions, optional community ID/role/joined time, and revision.

Player factions store stable
`player:<accountIdentity>:<characterUUID>` membership. A new survivor UUID on
the same account is a different social/faction person and cannot inherit
command authority.

Add rejects unintended dual membership. Transfer changes source/destination
indexes and history atomically. Leadership requires a living member. Removing
or killing a leader clears leadership without inventing a successor.
Archiving preserves faction identity, removes current membership, and clears
all symmetric treaty flags involving the archived faction.

## Public API and Revisions

Copied reads include:

- `Get`, `GetPresentation`, `List`, `GetByArchetype`, `GetMembers`,
  `GetLeader`;
- `GetNPCFaction`, `GetNPCAffiliation`, `IsMember`;
- `GetPlayerFaction`, `GetFactionForPlayerKey`;
- `SetEmblem`, `SetPlayerFactionEmblem`;
- `GetRelation` (`GetDiplomacy` is a directed compatibility alias);
- `AreAtWar`, `AreAllied`, `GetTruceUntil`, `IsFactionAtWar`;
- `GetOrganizationalFactionID`, `GetLegacyFactionClass`.

Authority mutation also includes membership, leadership, archival/destruction,
`CommitDirectedRelation`, `RecalculateRelation`, and
`PNC.FactionIncidentService.AddIncident/RecordAttack/RecordPositiveEvent`.

A directed relation mutation increments that relation, its source faction,
and the registry. An official treaty increments both relation records, both
factions, and the registry exactly once. Rejected, duplicate, unchanged, and
copied read operations increment nothing. NPC affiliation/derived behavior
uses existing record dirty tracking and never changes `presenceRevision`.

## Migration

Faction registry V2 stored one symmetric `diplomacy[pairKey]` peace/war record.
V3 deterministically creates both directed relations and preserves active war,
timestamps, initiator, and revision. It invents no opinion score or incident.
V2 peace becomes neutral meaningful contact. V3 normalization is idempotent
and safely repairs one-sided treaty flags to their strongest symmetric
invariant.

Faction registry V4 adds the serialization-safe layered `emblem` record.
Existing V3 factions receive deterministic archetype-aware emblems without
changing memberships, policy, diplomacy, hostility, or NPC presence.

NPC persistence is V15, affiliation V2, social V3, conduct V1, and player
identity registry V3.

## Debugging and Live Validation

The admin/debug-only **PNC Faction Inspector** is available from the
PsychopatzCore Debug Hub. It has separate source and target faction lists, an
NPC affiliation list, and four focused views: Overview, Diplomacy, Members,
and Diagnostics. Each view shows only its relevant guarded controls and
details, including:

- both directed relation records and revisions;
- standing, trust, fear, grievance, state, and previous state;
- symmetric war/alliance/truce fields;
- policy dimensions;
- incident history;
- resolved intent and reason.

Its incident/treaty buttons invoke production server APIs. They never send or
edit score values. Available triggers are minor attack, severe attack, member
killed, rescue, recalculation, war, 24-hour truce, peace, alliance, and
alliance break.

Creating a faction in the Overview accepts a typed NPC population and invokes
the community director immediately. It assigns a free random residential
building, generates archetype-aware faction/community names and roles, and
keeps residents abstract when that building is unloaded.

Creating the player's faction first opens the layered emblem editor. AI
factions use the deterministic generator. The emblem appears in the NPC map
hover badge and at its community base marker.

The **BASES** map layer uses the same relation palette as NPC map markers:
player-owned is dark green, allied/friendly is bright green, neutral is
yellow, war/hostile is red, and collapsed or vacant is gray. Persistent map
labels use a darker shade for legibility. Hovering within six pixels of a
base radius or building boundary displays a compact name, population, and
player-faction status card. NPC marker hit-testing takes priority and the base
layer renders underneath NPC dots, so base inspection does not block NPC
portrait hover.

Phase 5B.1 also adds disabled-by-default, runtime-only telemetry for callback
delivery, exact faction attribution, aggregation episodes, incident creation,
escalation decisions, intent resolution, and treaty reconciliation. The
buffer is primitive-only, FIFO-bounded to 512 entries, does not enter ModData,
and does not increment revisions. The inspector can clear telemetry, run an
isolated deterministic scenario, toggle the master runtime telemetry flag,
check registry or selected-relation
invariants, enqueue selected-pair reconciliation, and export a text-safe log
summary. `Repair Indexes` rebuilds only `byArchetype`, `byPlayerKey`, and
faction `memberIDs` from canonical records; it never rewrites diplomacy
metrics or NPC affiliations. These controls remain behind the existing
admin/debug authorization.

The former read-only diplomacy dashboard is embedded in the inspector's
**Overview** view. It visualizes the directed treaty state,
standing/trust/fear/grievance bars, resolved intent and rule, selected NPC
affiliation and revisions, aggregation and reconciliation activity,
invariant status, and latest telemetry.

**Toggle NPC World Overlay** enables an actual per-NPC world/nameplate
overlay. For every visible NPC it shows the organizational faction,
archetype, role/rank, relation and war state toward the current player's
faction, authoritative resolved intent, cached tactical hostility flags,
order, active job, current target, and the NPC's directed relationship toward
the exact current player character. The relationship section shows approval,
respect, familiarity, state, revision, and morale. A transient `CHANGE` line
identifies the committed memory/event type and its score/state deltas. Red
means attack is currently
authorized, yellow means a war exists but attack is not currently authorized,
green means the player can command the NPC, and cyan is neutral/observing.
The same toggle is available from the Debug Hub and Options > Mods. The
overlay refreshes from guarded server-produced diagnostics and exposes no
mutation command.

Attack episodes use authoritative NPC/player entity keys plus the faction
pair and a 36-second server-runtime window. A first minor incident is
persisted and later severity upgrades replace that same incident ID; the
episode never stores separate minor and severe incidents. Expiry only removes
runtime diagnostic/deduplication state.

Treaty reconciliation is runtime-only and member-indexed. It processes at
most 16 members per pump, preserves zombie combat, and clears a human target
when current treaty intent no longer authorizes attack. It does not make
former enemies into companions.

See [Faction Diplomacy Balance](FactionDiplomacyBalance.md) for current
defaults and [Faction Diplomacy Live Validation](../Testing/FactionDiplomacyLiveValidation.md) for the manual
single-player, hosted, and dedicated-server matrix. No live rows are
automatically marked passed.

For a basic in-game check:

1. Create/select a player faction and a looter faction.
2. Assign an NPC to the player faction; confirm it is a companion.
3. Transfer it to the looter faction; confirm command ownership clears and it
   roams without automatically attacking.
4. Select looter as source and player faction as target; confirm the intent is
   `threaten` or `avoid`, with `attack=false`.
5. Trigger minor attack; inspect the reverse (victim-to-actor) relation and
   confirm no automatic war.
6. Trigger member killed; confirm war becomes symmetric and both sides'
   members become enemies.
7. While war remains active, transfer a former player companion into the
   enemy faction. Confirm the world overlay reports `war=true`,
   `intent=attack`, `attack=true`, `order=hostile_hunt`, and that the NPC
   immediately loses companion ownership and can acquire the player.
8. Start truce or make peace; confirm attacks stop.
9. Save/reload and confirm directed metrics, incidents, treaty, policy, and
   revisions persist.

Run `lua tests/pnc_faction_diplomacy_smoke.lua` for deterministic non-engine
coverage.

## Future Extension Points

Current data can later support authored policy changes, faction reputation,
negotiation, tribute, leadership succession, autonomous strategy, incident
consolidation, communities, settlements, and normal-player diplomacy UI.
Those systems must consume the existing authority API rather than mutate
relations or treaty flags directly.
