# Settlement, base, and facility foundation

This is Project Hoomans successor architecture. Dynamic Trading and
ZedColonies are neither runtime dependencies nor authoritative data sources.
PsychopatzCore supplies only generic grid-region and zone infrastructure;
Project Hoomans owns every concept described below.

## Settlement progression and territory

A settlement has one persistent Base record associated with a Project Hoomans
community/faction. The Settlement Headquarters is virtual. HQ level determines
the hard territory ceiling and facility-tier gate. The current defaults are
400 tiles at HQ level 1, 500 at level 2, and 650 at level 3.

Territory starts at 270 tiles. Each abstract perimeter reinforcement adds 10
tiles and is rejected when its unclamped result would exceed the current HQ
limit. An HQ upgrade raises the ceiling but grants no territory; reinforcements
must still be built. Claimed area, territory capacity, HQ limit, free expansion
capacity, and facility allocated floor area remain distinct values.

The Base Zone is a connected two-dimensional XY footprint stored at logical
Z=0. It owns the corresponding vertical world columns, so multiple building
floors do not consume territory repeatedly. Creation, union-based expansion,
and subtraction-based shrinking validate the complete resulting footprint for
one cardinal component. Remote islands, diagonal-only contact, corridor cuts,
and capacity overruns are rejected atomically.

## Facilities and components

Facilities are logical simulation entities, not spawned buildings. A record
stores a stable ID, Base ID, definition ID, level, stable component-ID set,
revision, and cached derived state. Definitions are registered in
`PNC.FacilityDefinitions`; instances do not copy definition data.

Two component kinds are available:

- `anchor`: exact X/Y/Z with a semantic role and optional object resolver/tag.
- `region`: a normalized irregular GridRegion on exactly one explicit Z level.

Anchors preserve Z identity (`100,100,1` differs from `100,100,0`). Region
components must normally be cardinally connected. Both validate their XY
footprint against Base territory without charging upper floors again.
Components use semantic roles such as `sleep.bed`, `sleep.area`, and
`growing.plot`; NPC callers request capabilities such as `sleep` or `farm.work`
instead of naming a concrete facility.

Operational state is derived and cached after relevant mutations. Current
states include `PLANNED`, `NEEDS_ASSIGNMENT`, `OPERATIONAL`, `UNDERSIZED`,
`INVALID_COMPONENT`, and `DISABLED`. Capability, definition, and role indexes
are rebuilt on load or facility mutation, never every tick.

### Initial definitions

Barracks levels expose `sleep` and `rest`, require at least one sleeping area
and one sleep spot, and permit 4/8/14 sleep anchors at levels 1/2/3. Higher
levels require matching HQ levels. Separate connected sleeping regions may be
assigned on different floors. The legacy role name `sleep.bed` is retained for
save compatibility, but its square does not require furniture.

Farm levels expose `farm.work`, provide 2/4 exclusive `growing.plot` slots,
and cap total plot area at 32/64 tiles at levels 1/2. Each plot is a vanilla
farming rectangle no larger than 4 x 4 tiles. Worker capacity is separate
activity-limit data (2/4 concurrent workers). A plot must contain at least one
existing vanilla farming furrow; Hoomans never digs or creates farmland.

Facility definitions also own presentation metadata and declarative build
costs. Barracks and Farm currently each consume one `Base.Money`; this is an
explicit placeholder until construction resources are finalized. The server
measures the player's recursive inventory and the authoritative Base stockpile,
then consumes from the player first and the stockpile second immediately before
committing the new record. The chooser displays both source counts.

The allocation and payment algorithm lives in PsychopatzCore as
`PsychopatzMaterialTransaction`. It accepts arbitrary recipes and prioritized
stores that implement `count`, `remove`, and `restoreRemoved`. It aggregates
duplicate recipe rows, quotes per-source allocations, preflights the complete
recipe, and rolls back earlier removals if a later source fails. Facility
construction supplies physical-player and virtual-stockpile adapters; crafting
and future systems can reuse the transaction without depending on settlements.

## Reservations and NPC interaction

`PNC.FacilityReservations` is runtime-only. It supports reserve, start,
complete, release, expiration, component removal cleanup, and NPC cleanup.
`PNC.FacilityService.AcquireActivity(baseId, npcId, capability, options)` uses
capability and role indexes, claims an available component, and returns a
reservation plus an anchor target when applicable. Active NPCs can resolve and
path to that target; abstract NPCs pass `abstract=true` and perform only the
logical availability/capacity step. Interaction-target resolution remains a
service boundary and no live IsoObject is persisted.

Reusable square predicates live in PsychopatzCore's
`PsychopatzSquareRules`. The region selector can require any registered rule,
colors the hovered tile green/red, and validates every selected square. Project
Hoomans maps component-definition `worldRule` values onto the same authority
checks. Farmland remains assignment policy; bed detection is a reusable runtime
query because furniture at a sleep spot can change after assignment.

## Facility jobs and animation scenes

Facility work is a data-defined activity pipeline. Definitions map a capability
to its component role, active job, animation scene, need effect, arrival range,
and completion threshold. The server acquires and renews a reservation, while
the shared behavior owns travel, interaction positioning, scene playback, and
order restoration.

Barracks sleep reserves one `sleep.bed` spot and examines its loaded square at
job acquisition time. With no real bed, the NPC paths directly to the spot and
loops `facility.sleep.floor` through `BumpType=PNC_Sleep`
(`Bob_SitGround_SleepIdle`). With a real bed, the NPC instead paths to a free
cardinal neighbor, then is authoritatively positioned at the center of the
possibly multi-tile bed, aligned to its long axis, and loops
`facility.sleep.bed` through `BumpType=PNC_SleepBed` (`Bob_Asleep`). Furniture
changes are detected without rebuilding the component. Both scenes reduce
fatigue using elapsed game hours, complete at the rested threshold, and restore
the preceding order. Idle guards above the fatigue threshold automatically seek
an operational sleep spot.

Animation scenes now expose guarded tick/stop lifecycle callbacks. Combat,
movement, damage, abstraction, and external bumps still interrupt through the
central scene arbiter. A sleep interruption immediately restores the actor to
the safe approach tile; the facility order remains queued and resumes after the
threat. The owner's NPC context menu exposes `Stop Current Activity`, which
releases the reservation, stops the scene, and restores the prior order.

## Stockpile access

The authoritative inventory remains the existing logical Colony Storage/
PsychopatzCore inventory. `PNC.StockpileAccessService` persists small waypoint
records and attaches only `{type, nodeId, baseId}` beneath an object's `PNC`
ModData. Multiple nodes can reference the same logical storage. Removing a node
does not remove inventory. The client context action opens the existing storage
window when its storage ID is known, otherwise Colony Management. Active NPCs
use nearest-node/radius arrival APIs; abstract transfers bypass pathing and call
the logical transfer callback directly.

The foundation intentionally does not yet supply a player construction recipe
or choose a final art sprite. Placement code should create the selected
non-authoritative world object through the normal Build 42 construction flow,
then call `AttachModData`; it must not copy Colony Storage into an IsoObject
container.

## Authority, networking, and persistence

Clients submit bounded intents through the existing Colony Management command:
base create/expand/shrink, perimeter reinforcement, HQ upgrade, facility
create/upgrade/component set/remove/destroy, and stockpile node create/remove.
Explicit client request helpers wrap those action names. The server checks
ownership, expected entity revision, final geometry connectivity/capacity,
facility HQ gates, component counts/tile totals, XY containment, and exclusive
overlap. Structured reason codes are returned for translation. Stable request
IDs are cached at the Colony Management boundary, and Base commands also guard
duplicates directly.

The initial Colony Management response contains the settlement snapshot.
Subsequent settlement mutations return a requester-only `SettlementDelta`
payload containing the bounded settlement domain rather than retransmitting
people, needs, inventory, research, and provision state. Domain event names are
included in results and structured Core events are emitted after commits. The
Base-tab editor previews locally and sends only the confirmed `regionDelta`;
mouse movement is never networked. Settlement snapshots include the canonical
Base footprint so edits can render the current territory and validate the
candidate locally before the server repeats authoritative validation.

`PNC_Settlements_V1` stores schema version 1 maps for Bases, Facilities,
Components, Stockpile Nodes, and Project Hoomans-owned Core Zones. Cached
interaction targets, reservations, capability/role indexes, and spatial buckets
are not serialized. Loading normalizes/re-registers zones and rebuilds indexes.

No Base or Facility service owns an update callback. Geometry counting,
connectivity, spatial membership, component validation, and operational-state
calculation run only on load, explicit query, or mutation.

## Management and authoring flow

Open Colony Management and select `BASE`. Before a Base exists, use `CLAIM
TERRITORY`; drag in the world and use Replace/Add/Erase to form one connected
footprint, then confirm. Once established, the tab exposes Expand, Shrink,
Reinforce, Upgrade HQ, Build a Building, Assign Area, Assign Sleep Spot, Upgrade
Facility, and Place Stockpile. `BUILD A BUILDING` opens a card chooser with the
definition image, material cost, availability state, and description. The
Base tab now uses a building browser instead of a flat selector/control pile.
The left pane lists building instances and operational state; the inspector
nests required component slots and their assigned areas/anchors. Contextual
zone/bed/upgrade controls act on the selected building. Facility components are
shown with their role, exact floor, coordinates or area, and tile count.

`SHOW BASE LAYOUT` is a persistent toggle for the world overlay. It draws the
exact saved Base spans, facility regions, anchor tiles, and stockpile access
nodes in separate colors. Facility assignment selectors also receive these
layers as guides, so already allocated tiles remain visible while editing.

In debug mode, select a colonist and a facility, then use `SEND TO WORK
FACILITY`. This starts the same reserved `facility_activity` used by production
jobs, routes it through the normal navigation and animation stacks, and reports
`QUEUED`, `TRAVELLING`, `STARTING`, `SLEEPING`, or `INTERRUPTED` in the Debug
details. Debug hold keeps the scene running after fatigue is cured so animation
testing is convenient. `STOP FACILITY TEST` restores the preceding order.

`PLACE STOCKPILE` currently creates the authoritative logical access waypoint
at the selected tile, which is sufficient to test containment, persistence,
networking, and NPC arrival. It does not yet spawn the final physical access
box; the construction recipe/sprite and the `AttachModData` call remain the
next physical-object slice.

Action results are displayed at the top of the Base details. The preview's
connectivity/capacity feedback is advisory; confirmation always goes through
the existing requester/server command and optimistic revision checks.

## Validation

Run:

```bash
lua tests/pnc_settlement_foundation_smoke.lua
lua tests/pnc_settlement_layout_overlay_smoke.lua
lua tests/pnc_facility_debug_work_smoke.lua
lua ../psychopatzCore/tests/psychopatz_square_rules_smoke.lua
```

The smoke suite covers normalization, connected expansion, island and diagonal
rejection, HQ/barricade progression, revision conflicts and atomic rejection,
multi-floor Barracks assignments, bed limits/upgrades, Farm tile limits,
reservations, and stockpile radius arrival. Core geometry has its own
`psychopatz_grid_region_smoke.lua` suite.

Manual in-game check:

1. Open Colony Management, choose Base, claim an L-shaped territory with two
   drag operations (`REPLACE`, then `ADD`), and confirm.
2. Reopen Base and verify claimed/capacity values and the green existing-zone
   guide. Try a disconnected expansion and confirm that it cannot be submitted.
3. Toggle `SHOW BASE LAYOUT`, verify the territory footprint, then reinforce
   once and expand by up to ten effective tiles.
4. Put at least two `Base.Money` items in the player inventory. Open `BUILD A
   BUILDING`, inspect the two placeholder cards, then create a Barracks and
   confirm one money item is consumed.
5. Select the Barracks in the building browser, assign a connected sleeping
   area, assign one empty-ground sleep spot, and verify its nested component and
   operational state. Repeat on a real bed to exercise furniture detection.
6. Create a Farm and verify ordinary ground is rejected, cultivated farmland is
   accepted, and an area above 100 tiles is rejected at level 1.
7. Place a stockpile waypoint inside the Base and verify its node count rises.
8. In Debug, select a colonist and the Barracks, send the colonist to work, and
   verify the empty spot loops `PNC_Sleep`, while the bed spot approaches from a
   neighboring tile, centers the NPC on the bed, and loops `PNC_SleepBed`.
   Trigger a nearby
   enemy and verify the scene interrupts/restores position, then resumes after
   danger. Right-click the NPC, choose `Stop Current Activity`, and confirm the
   previous order resumes.
