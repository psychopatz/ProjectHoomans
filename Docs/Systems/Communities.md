# Communities

## Purpose

Phase 5C adds persistent physical population centers without turning factions
into settlement records. A faction remains a political organization; a
community is one fixed settlement, camp, staging site, evacuation site, or
historical location owned by that faction. One faction may own zero, one, or
many communities.

This phase is data foundation and guarded tooling only. Community fields do
not change combat, diplomacy, jobs, presence, recruitment, relationships,
conduct, or companion ownership.

## Authority and persistence

The authoritative registry is separate Global ModData under
`PNC_Communities`:

```lua
{
    schemaVersion = 2,
    revision = 0,
    byID = {},
    byFaction = {},
    sitesByID = {}
}
```

`byID` contains canonical community records. `byFaction` is a deterministic
secondary index. NPC `record.affiliation.communityID` is canonical for current
NPC placement; `community.memberIDs` is a rebuildable secondary index.
Communities never contain full NPC records or live engine objects.

Community IDs are server-generated `community_<opaque>` strings. Generation
uses the existing ID generator, bounded collision retries, and never derives
identity from a display name.

## Record schema

Each schema-V2 record stores:

- `id`, `factionID`, `name`, `mode`, and `status`;
- `createdAt`, `archivedAt`, `destroyedAt`, and optional reasons;
- a primitive `home = { x, y, z, radius }`;
- optional `siteID`, referencing the canonical primitive site registry;
- optional `leaderNPCID`;
- rebuildable `memberIDs`;
- `capacity = { population, beds, storage }`;
- `security` from 0 through 100;
- `morale` from -100 through 100;
- integer summary supplies for food, medicine, ammunition, tools, and
  materials;
- `revision`.

No grid squares, buildings, zones, inventory items, containers, Java objects,
functions, threads, metatables, or NPC record pointers are valid persistent
values.

## Reusable hideout sites

Schema V2 separates a physical site from the community currently occupying it.
A site stores only a stable `community_site_*` ID, `building` or `radius`
classification, primitive home/bounds coordinates, occupancy or stable
player-character claim, world-age timestamps, and revision. Building and
square objects are inspected transiently by
`PNC.CommunitySiteResolver.DescribeAt()` and are never retained.
`FindAvailableNear()` remains available for current or nearby placement.
Faction-debug creation uses `FindRandomHouse()` to scan persistent world
building definitions for residential room combinations, discard occupied or
claimed sites, and randomly choose from the stable sorted candidates. Only the
resulting primitive bounds and coordinates cross into persistence. An unloaded
house is valid: auto generation leaves its residents abstract until normal
presence admission can materialize them.

An active community may reserve one site. Archiving, destroying, or wiping out
the last living member releases that occupancy while preserving both the
historical community and reusable site. Another community can then reserve the
site. A vacant site may instead be claimed with a full
`player:<accountIdentity>:<characterUUID>` key; username-only and online-ID
claims are rejected. Claims are a persistence foundation only and do not yet
create safehouses, construction ownership, or base-building permissions.

## Modes and lifecycle status

Modes are `settled`, `camped`, `staging`, `evacuating`, `abandoned`, and
`destroyed`. Statuses are `active`, `inactive`, `archived`, and `destroyed`.

Only settled and camped communities may currently normalize as active.
Staging and evacuating remain inactive data classifications. Abandoned
communities cannot remain active. Archived communities normalize to abandoned
mode; destroyed status and mode normalize together. Archiving or destroying a
community clears active membership and leadership but preserves its historical
record.

No evacuation movement, mobile parties, territory claims, or proximity-driven
diplomacy exists in this phase.

## Home anchor and pure spatial helpers

Home coordinates are finite world-tile numbers. Z is clamped to -32 through 32,
and radius to 1 through 200. Settled communities default to radius 35; camps
default to 15.

`PNC.Communities.GetDistanceFromHome(community, x, y, z)` and
`PNC.Communities.IsInsideHomeArea(community, x, y, z)` are pure. Containment
requires the same integer floor and distance within radius. Membership does
not teleport, materialize, dematerialize, or constrain an NPC.

## NPC affiliation V2

NPC affiliation now includes:

```lua
communityID = nil
communityRole = "resident"
communityJoinedAt = 0
```

Roles are leader, resident, guard, medic, worker, dependent, and prisoner.
Community role is independent of faction role and does not assign an AI job.

An NPC must already belong to the owning faction, may belong to at most one
community, and may remain faction-affiliated without a community. Transfers
are atomic and normally require the same owning faction. Removing or
transferring faction membership detaches the old community index before the
faction service commits the replacement affiliation. NPC death removes active
community membership and clears community leadership. If that death removes
the final living member of an active community, it becomes destroyed with
reason `population_wiped_out` and its site becomes vacant, unless the owning
faction still has a stable player-character member. Abstract NPCs otherwise
remain members.

The community leader must be a living indexed member. Replacing leadership is
atomic. There is no automatic successor.

## Capacity and population

Configured population, beds, and storage are capacity summaries, not current
population. Their ranges are 0–500, 0–500, and 0–100000. Current population is
derived from living NPC affiliations and the rebuilt member index.
`currentPopulation`, `populationCapacity`, and `overcrowded` are added to
public read copies. Assignment does not enforce population capacity unless a
caller explicitly sets `strictCapacity = true`.

## Security, morale, and supplies

Security and community morale are authored summaries. They do not currently
alter combat, desertion, recruitment, or diplomacy.

Supplies are abstract integer units clamped from 0 through 1,000,000. They are
not item inventories. Removing more than the available amount fails with
`insufficient_supply`; it does not partially remove or clamp the transaction.
No world-container scan, pricing, consumption, production, or trade simulation
is present.

Creation defaults are centralized by mode. A faction archetype applies only a
mild one-time creation adjustment:

- settler: +5 security and +20 storage;
- looter: +10 security and +10 ammunition;
- trader: +30 storage and +5 tools;
- refugee: -5 food (clamped), +2 medicine, and -5 morale.

Defaults are not continuously recalculated from the faction archetype.

## Public server API

Read APIs return copies:

- `Create`, `Get`, `List`, and `GetForFaction`;
- `BuildSiteID`, `GetSite`, `ListSites`, `ReserveSite`, `ReleaseSite`,
  `ClaimSite`, and `UnclaimSite`;
- `GetNPCAffiliation` and `GetNPCCommunity`;
- `AddNPC`, `RemoveNPC`, and `TransferNPC`;
- `SetLeader`, `SetMode`, `SetStatus`, `SetHome`, `SetCapacity`,
  `SetSecurity`, and `SetMorale`;
- `GetSupply`, `AddSupply`, `RemoveSupply`, and `SetSupply`;
- `Archive` and `Destroy`;
- `RebuildIndexes` and `ValidateRegistry`;
- `IsInsideHomeArea` and `GetDistanceFromHome`.

All mutation APIs reject non-authority calls. The Community Inspector uses the
existing guarded admin/debug command route; ordinary clients cannot mutate
community state.

`PNC.CommunityDirector.GenerateForFaction(factionID, spec)` is the reusable
event-driven group-generation entry point. It creates or reuses a community,
reserves a primitive site, generates faction/community-affiliated NPC records,
and assigns leaders. `presenceMode` accepts `auto`, `abstract`, or `live`.
`siteSelection = "random_house"` selects a free residential building
definition, including one in an unloaded chunk.
Records are always created abstract first. Auto requests materialization only
for a loaded site; live also falls back safely to abstract if the site is
unloaded; abstract sets a transient force-abstract policy. There is no
continuous director tick.

## Revisions

A changed community increments `community.revision` and the community registry
revision. NPC placement changes also increment affiliation revision and the
NPC `recordRevision`. A transfer touches each changed community but performs
one registry-level revision transaction and one affiliation commit.

Pure reads, identical setters, and rejected operations change no revision.
Already-correct index rebuilding is revision-neutral. Community edits never
change `presenceRevision`, social, relationship, conduct, faction-relation, or
diplomacy revisions.

## Migration

NPC persistence remains V15 and affiliation remains V2. Community registry and
records advance from V1 to V2. Normalization adds an empty `sitesByID` registry
and nil `siteID` references, so existing communities remain valid but do not
acquire invented buildings. The community migration itself does not mutate
factions; the separate faction registry is now V4 for layered faction emblems.

Loading normalizes partial registry data, clears invalid/missing/dead/currently
retired community references, and deterministically rebuilds both secondary
indexes. Migration preserves the legacy faction class, hostility, ownership,
diplomacy, relationships, conduct, profiles, and presence.

## Validation and debugging

The read-only validator checks faction ownership, ID/key agreement, home and
numeric bounds, supply bounds, unique membership, affiliation/index agreement,
living leadership, retired-state leadership, `byFaction`, missing references,
and serialization safety. The admin repair action rebuilds indexes only.

The PsychopatzCore Debug Hub exposes **PNC Community Inspector**. Its controls
call authoritative services to create settlements/camps, assign/transfer/remove
NPCs, set leaders/roles/home, adjust summaries, validate/repair, archive, and
destroy. A separate optional Community NPC World Overlay requests sanitized
server diagnostics and draws community, role, mode/status, distance,
containment, population/capacity, security, morale, and revision above visible
NPCs. The world map has an independent **BASES: ON/OFF** control beside
**NPC NAMES**. It outlines building bounds, draws the configured hideout radius
and community name, and colors occupied, vacant, and claimed sites. In
admin/debug mode, right-clicking a vacant shape offers a guarded
server-authoritative player-character claim.

Faction debug creation now runs the community director automatically. The
inspector includes a typed 1–24 NPC-population field and presence-mode control
plus a standalone
**Generate NPC Group** action for existing factions. The result reports live
and abstract counts so unloaded-site behavior is visible. New factions and
communities use archetype-aware naming pools rather than debug timestamps.
Generated roles are archetype-aware as well, so trading companies receive a
trader and looter gangs receive raiders and enforcers.

Normal roster and detailed snapshots expose only a bounded faction
presentation summary: faction ID/name/archetype plus the NPC's membership,
role, and rank. Conversation portraits use that summary to show
**Faction Name / Role** below the NPC name. Relationship category and
time-of-day remain separate semantic context values for greeting selection.

The Faction Inspector includes a compact owned-community count, names/modes,
active population, and total abstract supplies. The Relationship Inspector
shows community name, ID, role, and current home containment for NPC
participants only.

## Deferred extensions

Autonomous director scheduling, strategic building scoring,
safehouse/base construction, mobile parties, caravans, patrols, raids,
territory, markets, detailed
inventories, tribute, robbery, construction, farming, recruitment strategy,
proximity diplomacy, and normal-player management UI remain future work.
