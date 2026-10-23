# P14 — Production Rehydration & Mod-Code Execution Parity

**Status:** ACTIVE / mandatory architecture-corrective phase  
**Opened:** 2026-10-24  
**Implementation baseline audited:** ProjectHoomans remote main at `d3c6c2018b4a074bdf6178b7f060f18832ed2344`.  
**P13 disposition:** operational workbench foundation retained.  
**Native Project Zomboid requirement:** none for normal Semantic Lab operation.  
**Source save mutation:** FORBIDDEN.

## Product intent

Semantic Lab exists to run the **actual Project Hoomans mod code** in a stripped, safe, headless-compatible environment.

The harness is not a second implementation of Project Hoomans.

The architectural rule is:

> **Fixture the engine, never fixture the mod.**

And:

> **Python may discover, transport, isolate, inspect, orchestrate, and present state. Production Lua interprets Project Hoomans state and owns gameplay behavior.**

The desired execution model is:

```text
real Project Hoomans persisted state
        ↓
Python read-only transport / selection
        ↓
isolated worker payload
        ↓
REAL production Lua persistence + normalization
        ↓
REAL Project Hoomans registries/services
        ↓
REAL conversation / semantics / relationships / factions /
inventory / recruitment / proposal / knowledge / trading providers
        ↓
Semantic Lab GUI / CLI inspection
```

Only genuinely Project-Zomboid-engine-owned boundaries may be replaced by fixtures.

Examples of acceptable fixtures/adapters:

- GameTime / time-of-day;
- climate/weather;
- IsoPlayer / IsoZombie object boundaries;
- live position;
- engine needs when no offline authoritative source is available;
- rendering;
- audio;
- networking transport;
- native UI lifecycle;
- Java-only engine services.

Examples of **unacceptable harness reimplementation** when production Lua already owns the behavior:

- Project Hoomans relationship state;
- bond promotion;
- proposal policy;
- faction diplomacy;
- NPC inventory persistence;
- NPC persistence migrations;
- recruitment;
- community membership;
- semantic provider eligibility;
- conversation routing;
- Project Hoomans item/inventory business policy.

## Why P14 exists

P12/P13 established a strong operational save-backed harness:

- real save discovery;
- real Player/NPC selection;
- immutable source snapshots;
- isolated mutable working world;
- production Talk routing;
- relationship/proposal/recruitment execution;
- world/faction browser;
- Player inventory decoding;
- gift workbench;
- agent-grade CLI;
- operational GUI acceptance.

However, the latest real-save audit exposed a remaining architecture violation.

The Python save importer still interprets parts of the **Project Hoomans persisted gameplay schema** directly instead of passing the saved record through the production Lua persistence/runtime owners.

This causes false `MISSING` / `unknown` states even when the save contains valid production data.

### Verified example: NPC inventory

Project Hoomans persists NPC inventory using compact production modes such as:

```text
SEED_ONLY
BASELINE_DELTA
FULL
```

Production rehydrates those through the Project Hoomans inventory persistence path.

The current Python importer accepts an NPC inventory only if it already looks like an expanded `items` table.

Therefore a valid compact saved inventory can appear as:

```text
source = MISSING
```

in Semantic Lab.

This is not a missing save value. It is a harness rehydration defect.

### Verified example: faction diplomacy

The save-backed provider can project faction identity/membership, but current projection does not preserve enough of the production diplomacy graph, including directed relation maps and the Player diplomacy-faction mapping required to resolve faction standing.

This can produce:

```text
Faction/community standing: MISSING
```

while tactical hostility and hostile Talk choices are still correctly available through other production facts.

P14 corrects this class of problem by moving interpretation back to production Lua.

## Python versus Lua ownership

### Python may own

Python/runtime tooling may:

- discover save directories;
- read/copy source files read-only;
- call Core's binary reader;
- select raw persisted records/tables;
- build immutable source snapshots;
- create isolated worker payloads;
- manage worker process lifecycle;
- supply explicit engine fixtures;
- render GUI;
- expose CLI;
- diff/reset working state;
- track provenance;
- validate source-save immutability.

### Python must not own

Python must not independently implement Project Hoomans gameplay/persistence policy when production Lua already owns it.

Avoid code conceptually like:

```python
if raw_inventory has items:
    use it
else:
    inventory = MISSING

if approval >= 80 and respect >= 50:
    bond = friend

if tactical_class == hostile:
    infer relationship enemy
```

when production Lua has the authoritative persistence/service path.

### Lua owns

Production Lua must own:

- record deserialization/migration;
- inventory baseline generation and delta replay;
- inventory normalization;
- relationship normalization and state;
- durable bond policy;
- faction relation interpretation;
- Player/faction diplomacy mapping where production owns it;
- Talk audience;
- speech context;
- semantic candidate generation;
- proposal/recruitment/gift effects;
- other Project Hoomans business behavior.

## Canonical save import boundary

The normal P14 import should become:

```text
Python
    discover save
    select Player
    select raw PNC_npc<ID>
    select relevant raw registries
    transport raw serialized payloads
            ↓
Lua worker
    production persistence deserialize/migrate
    production inventory deserialize
    production social/faction normalization
    install hydrated record into isolated registries
            ↓
production Project Hoomans runtime
```

Python should not need to understand the internal meaning of every persistence field.

This future-proofs Semantic Lab when persistence schemas evolve.

## NPC rehydration

Use the real Project Hoomans persistence/load path wherever feasible.

The worker should accept the raw persisted NPC record and invoke the same production record deserialization/normalization used by Project Hoomans.

The exact production owner must be audited at implementation time.

Expected responsibilities include:

- schema migration;
- normalized identity;
- traits;
- social profile;
- relationships;
- inventory persistence;
- faction/community links;
- equipment;
- knowledge;
- other persisted runtime state.

Do not manually duplicate those migrations in Python.

### Inventory acceptance

The isolated worker must correctly hydrate:

```text
SEED_ONLY
BASELINE_DELTA
FULL
```

through the production inventory subsystem.

For `BASELINE_DELTA`:

```text
saved seed / baseline identity
        ↓
production deterministic baseline generation
        ↓
production delta replay
        ↓
hydrated inventory
```

The GUI/CLI should then see the resulting runtime inventory projection.

## Relationship and hostility semantics

Do not conflate:

```text
personal NPC → Player relationship
faction diplomacy
tactical hostility
conversation audience
```

These are separate production concepts.

A hostile raider may legitimately have:

```text
personal relationship = unknown / absent
tactical hostility = hostile
conversation audience = hostile
faction relation = hostile/war
```

Do **not** synthesize an `enemy` personal relationship merely because `attackPlayers=true`.

Semantic Lab should display each layer separately.

## Faction/diplomacy rehydration

Pass the relevant raw faction/diplomacy persisted state into production Lua.

Preserve and/or hydrate production-owned data such as:

- faction records;
- faction relation maps;
- Player-key -> diplomacy-faction mapping;
- provisional Player diplomacy faction;
- war;
- alliance;
- truce;
- pacification;
- trust/fear/grievance or other persisted relation dimensions;
- community linkage;
- membership/leadership.

Use production faction services to resolve:

```text
selected NPC faction
        ↓
selected Player's real/provisional diplomacy faction
        ↓
directed faction relationship
        ↓
effective faction standing/context
```

Python should transport the records, not reproduce faction diplomacy policy.

## Canonical social-context projection

Semantic Lab should expose separate source/derived rows for:

```text
Personal relationship
Faction relationship
Tactical hostility
Conversation audience
Speech style
Durable bond
```

Example:

```text
Personal relationship
    unknown
    source = MISSING
    reason = no persisted NPC→Player relationship

Faction relationship
    hostile / at war
    source = SAVE → production FactionService

Tactical hostility
    hostile
    source = SAVE

Conversation audience
    hostile
    source = DERIVED production ConversationAudience
```

This makes a hostile NPC with no personal history understandable instead of looking contradictory.

## Hostile speech parity

Typed semantic greetings should consume the same authoritative social/tactical context as the normal hostile/parley Talk entry.

Do not manufacture a personal `enemy` relationship to make speech harsher.

If the production greeting realization is too polite for an actively hostile audience, fix the production realization/audience policy itself.

Reuse the existing production semantic/speech realization system.

Expected outcome:

```text
hostile audience
→ appropriately hostile/parley wording
```

without changing semantic facts.

## MISSING-state taxonomy

Every important `MISSING` result must be classifiable.

Allowed categories:

```text
LEGITIMATE_ABSENCE
    no value exists in save/runtime

ENGINE_ONLY
    requires engine fixture/live provider

UNSUPPORTED_FORMAT
    persisted format not yet supported

PROVIDER_OMISSION
    save contains value but provider did not transport it

REHYDRATION_FAILURE
    raw production payload exists but production Lua was not invoked correctly
```

The GUI/CLI should expose bounded reason metadata where useful.

Do not silently replace missing data with invented defaults.

## Engine fixtures

Fixtures remain important.

P14 does **not** attempt to recreate all of Project Zomboid.

The harness should strip unrelated engine systems and provide fixtures only at real engine boundaries.

Examples:

```text
time
weather
climate
needs
position
nearby zombie density
engine UI
rendering
audio
network transport
Java-native objects
```

When a Project Hoomans subsystem asks for one of these values, the fixture should satisfy the same expected API/contract as narrowly as practical.

The fixture must not absorb Project Hoomans gameplay policy.

## Future world-object dataset — explicitly out of scope

A future goal may build a dataset/catalog for world objects/items so semantic actions can ground commands such as:

```text
stand near the garbage bin
go to the pole
wait beside the vending machine
```

P14 does **not** implement that dataset.

P14 only ensures the runtime architecture can support it later:

```text
future object dataset
        ↓
engine/world fixture or provider
        ↓
production Project Hoomans semantic/action code
```

Do not add world-object catalog generation, scene indexing, pathing, or spatial-command implementation during P14.

## P14 milestones

### P14A — Production rehydration boundary

Required:

- audit current Python save importer and Lua production persistence owners;
- define raw-record transport contract;
- add worker command/API for production rehydration;
- hydrate raw `PNC_npc<ID>` through production Lua;
- install hydrated records into isolated registry;
- keep immutable source/raw payload for provenance;
- stop Python from interpreting normal NPC runtime persistence fields where Lua owns them.

**Gate:** one real saved NPC is loaded from raw persisted payload through production Lua, and hydrated runtime state is inspectable.

### P14B — Production NPC inventory rehydration

Required:

- route compact saved inventory through production inventory persistence;
- prove `SEED_ONLY`, `BASELINE_DELTA`, and `FULL`;
- baseline generation and delta replay use production Lua;
- GUI/CLI actor inventory uses hydrated runtime result;
- remove false `MISSING` caused by Python expecting expanded `items`.

**Gate:** at least one real BASELINE_DELTA NPC inventory that previously appeared MISSING is correctly hydrated from the save.

### P14C — Production faction/diplomacy rehydration

Required:

- transport raw faction/diplomacy tables;
- preserve relation maps and Player diplomacy-faction mapping;
- invoke production faction owners;
- expose faction relation separately from personal relationship;
- prove hostile/war/allied/neutral cases where real saves contain them.

**Gate:** a real hostile faction target shows production-resolved faction standing without fabricating personal enemy relationship.

### P14D — Canonical social context + hostile speech parity

Required:

- expose personal relationship, faction relationship, tactical hostility, conversation audience, bond, and speech style separately;
- typed `hello` and normal Talk entry consume the same production social/tactical context;
- correct overly friendly hostile realization through production speech policy if still reproduced.

**Gate:** a hostile raider case is internally coherent in GUI/CLI and produces appropriate production wording.

### P14E — MISSING-state audit and provider cleanup

Required:

- inventory important SAVE/FIXTURE/LIVE/MISSING fields;
- classify each MISSING reason;
- remove Python policy duplicates;
- route supported saved state through production rehydration;
- retain legitimate/engine-only absence honestly.

**Gate:** no important save-owned field appears generically MISSING when production-supported raw data exists.

### P14F — Real-save production-runtime regression

Required real-save matrix:

- follower/companion;
- neutral;
- hostile raider;
- trader/provider target;
- saved relationship present;
- saved relationship absent;
- BASELINE_DELTA inventory;
- faction relation available;
- faction relation absent.

For each, exercise:

- save selection;
- production rehydration;
- Talk;
- semantic greeting;
- inventory;
- gift where available;
- relationship/faction context;
- mutation/reset;
- source-save immutability.

CLI and GUI must use the same worker/runtime owners.

**Gate:** the harness is proven to be executing production Project Hoomans state interpretation rather than a Python copy of it.

## Hard invariants

- Fixture the engine, never the mod.
- Python transports/isolates/presents; production Lua interprets Project Hoomans state.
- Source saves remain read-only.
- Working world remains isolated and mutable.
- No second Project Hoomans persistence implementation in Python.
- No Python inventory-delta implementation when production Lua owns it.
- No Python relationship/bond/faction policy duplication.
- Personal relationship, faction diplomacy, tactical hostility and audience remain separate.
- Engine fixtures are narrow and explicit.
- Missing values remain honest.
- P13 GUI/CLI operational work remains retained.
- Native PZ remains user-owned final acceptance.
- Future world-object dataset work is out of scope.

## Completion condition

P14 is complete when Semantic Lab can load real saved Project Hoomans state and prove that:

```text
saved raw mod state
        ↓
production Lua deserialize / normalize / hydrate
        ↓
production services
        ↓
conversation / semantics / mutations
```

is the normal execution path.

At that point, changes to Project Hoomans production Lua should automatically affect Semantic Lab behavior without requiring parallel Python gameplay changes, except where a genuine engine fixture contract itself changes.
