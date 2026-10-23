# P12 — Save-Backed Offline Semantic Runtime

**Status:** BACKEND FOUNDATION COMPLETE / operational usability acceptance continues in P13  
**Opened:** 2026-10-24  
**Current implementation baseline audited:** ProjectHoomans remote main at `73e1ac5d0e49045a4660f447296a4b99544b4f0f`.  
**Source-save mutation:** FORBIDDEN.  
**Native Project Zomboid requirement:** none for normal Semantic Lab operation.  
**Optional live profiler:** read-only enrichment only; disabled by default and enabled through external settings text + game restart.

## P13 operational supersession note

P12's save-backed runtime/backend architecture is retained and should not be replayed.

The former P12 completion claim did not prove that the GUI was practically usable at realistic geometry. P13 reopens product acceptance around the operational workbench: usable save selection, faction/community actor browsing, symmetric Player/NPC inspection, offline Player inventory where supported, gift verification, and GUI/CLI parity.

Read `OPERATIONAL_SEMANTIC_TEST_WORKBENCH.md` for the active phase.

## Why P12 exists

P10/P11/P11J brought the Semantic Lab close to conversation/semantic runtime parity:

- real production semantic Lua;
- real Talk-start projection;
- contextual hub;
- Flow/Hub/ConversationBlock graph projection;
- generated NPC personality;
- player/NPC trait projection;
- relationship standing/bond logic;
- recruitment authority;
- structured inventory;
- world/actor controls;
- production authority and provider paths.

The remaining architectural problem is **state origin**.

The normal harness still begins from synthetic scenario fixtures for substantial parts of the world:

- actor identity/profile fixtures;
- relationship fixtures;
- engine needs;
- time;
- weather;
- world age;
- inventory/runtime conditions;
- integration availability;
- faction/community state when not explicitly projected.

Adapters then reconstruct production-like state around those fixtures.

That model is now the main source of parity drift.

P12 changes the normal product architecture from:

```text
synthetic scenario
 -> adapter reconstruction
 -> production Lua
```

to:

```text
real saved mod state
+ offline engine fixtures
+ optional read-only live profiler snapshot
        ↓
isolated mutable harness world
        ↓
production Lua
```

Fixtures remain for automated tests, malformed-state tests, and engine values that are intentionally unavailable offline. They are no longer the normal user-facing source of mod-owned actor/world state.

---

# 1. Read-only source, mutable harness world

The most important P12 invariant is separation between source state and harness working state.

## Source world

The source world is immutable and read-only.

Sources may include:

- Project Zomboid save files;
- Project Hoomans Global ModData;
- PsychopatzCore Global ModData;
- Dynamic Trading Global ModData;
- future registered mod state providers;
- optional profiler/live snapshot.

Semantic Lab must never write to:

- the original save;
- `global_mod_data.bin`;
- any live Project Zomboid object;
- any live mod registry;
- any live relationship;
- live factions/communities/inventory;
- the profiler bridge.

## Harness world

Loading a save creates a detached deep-copy / normalized harness snapshot.

All testing mutations occur only here.

Examples:

```text
relationship changes
friend promotion
lover proposal
recruitment
faction standing changes
community membership
inventory changes
knowledge changes
quest changes
conversation state
semantic tool effects
```

must execute through production Lua services against the isolated harness world.

The source save remains unchanged.

Required mental model:

```text
REAL SAVE
   │ read-only
   ▼
IMPORTED SOURCE SNAPSHOT
   │ copy/normalize
   ▼
HARNESS WORKING WORLD
   │ mutable
   ▼
PRODUCTION LUA
```

---

# 2. Save import is the normal product workflow

Normal Semantic Lab startup should no longer default to a hand-authored synthetic NPC profile.

Target flow:

```text
World source
[ Saved World ]

Save
[ <save name> ▼ ]

Player
[ <saved player character> ▼ ]

NPC Target
[ <saved Project Hoomans NPC> ▼ ]

[ Load Snapshot ]
```

After load, the main workbench operates on the imported working world.

Synthetic scenarios remain available only as explicit Developer/Test mode for:

- automated regression fixtures;
- malformed/corruption tests;
- precise compiler/parser tests;
- states that cannot exist in a real save;
- no-save CI environments.

Do not let new user-facing Semantic Lab features depend on synthetic defaults.

---

# 3. Reuse the existing Core save reader

PsychopatzCore already owns a read-only Build 42.20 Global ModData parser:

```text
psychopatzCore/tools/profiler/moddata_reader.py
    GlobalModDataReader
```

P12 must reuse this reader.

Do not create another `global_mod_data.bin` decoder in Project Hoomans or Semantic Lab.

Core remains responsible for low-level serialization decoding.

Project Hoomans owns projection of Hoomans-specific persisted schemas into the harness world.

---

# 4. Initial persisted sources

## NPC directory

Use:

```text
PNC_Core_Global
```

to enumerate canonical NPC pointers/records.

Individual NPC records live in isolated roots such as:

```text
PNC_npc<ID>
```

Import the actual persisted record rather than reconstructing an NPC from UI fields.

## Player characters

Use:

```text
PNC_PlayerCharacters
```

and the current player-character schema.

Enumerate saved player characters and obtain the real stable player identity/entity key.

## Directed relationship

For selected Player A and NPC B, load the actual directed NPC -> player relationship from:

```text
npcRecord.social.relationships[playerEntityKey]
```

This record is the source for:

- baselines;
- approval;
- respect;
- familiarity;
- state;
- previousState;
- durable bond;
- memories;
- saturation;
- cooldowns;
- interaction journal;
- revisions/timestamps.

Do not reconstruct these fields from three sliders when the save already owns them.

## Other mod-owned state

Where available, import actual persisted:

- NPC identity and seed;
- traits;
- social profile/personality;
- faction/community state;
- persistent inventory;
- knowledge/world-knowledge links;
- quest state;
- companion/recruitment state;
- Dynamic Trading/provider state;
- other registered module-owned data required by semantics.

Unknown fields should be preserved in the imported snapshot when safely possible.

---

# 5. Production relationship authority inside the harness

The current harness contains relationship reconstruction logic in adapters.

P12 removes that architecture.

Adapters may provide engine/service seams such as:

- Registry.Get;
- PlayerCharacters.GetEntityKey;
- time;
- network/server stubs;
- actor lookup.

Adapters must NOT own production policy such as:

- relationship-state derivation;
- durable bond normalization;
- automatic friend promotion;
- proposal eligibility;
- proposal cooldown;
- memory effects;
- relationship revisions.

Instead:

```text
import real relationship
 -> normalize with production RelationshipTypes
 -> install in isolated NPC record
 -> mutate through real RelationshipService
```

The Semantic Lab Relationship panel should use production projections such as `PNC.RelationshipGraph` where available.

This must allow:

```text
save relationship
 -> harness mutation
 -> production standing/bond/event change
 -> inspect result
 -> Reset Snapshot
 -> original imported relationship restored
```

without touching the source save.

---

# 6. Offline engine fixtures remain normal

Project Zomboid does NOT need to run for normal Semantic Lab work.

Some engine/transient values are intentionally represented by offline fixtures unless a proven offline save reader exists.

Examples may include:

- player/NPC hunger;
- thirst;
- fatigue;
- stress;
- boredom;
- panic;
- current time of day;
- weather;
- temperature;
- season;
- transient activity;
- position;
- nearby zombie density;
- other engine-only facts.

These values must be explicitly identified as:

```text
OFFLINE ENGINE FIXTURE
```

rather than pretending they came from the save.

Fixtures remain editable inside the harness.

They never write back to Project Zomboid.

---

# 7. Optional live profiler adapter

P12 also supports an optional one-way live snapshot path.

This is NOT required for normal Semantic Lab use.

## Enablement

The Project Zomboid side must be disabled by default.

Enable it only through an external settings/config text value that requires restarting Project Zomboid before it takes effect.

Do not add a normal in-game UI toggle.

Before choosing the final setting/key name, audit the existing Project Hoomans/Core debug/settings infrastructure and use the existing owner/convention.

## Direction

The bridge is strictly:

```text
PROJECT ZOMBOID
       │
       │ READ ONLY
       ▼
profiler/runtime snapshot
       │
       ▼
Semantic Lab
```

Do not expose mutation commands from Semantic Lab back into the running game.

Allowed conceptually:

- GET_SNAPSHOT;
- GET_PLAYER;
- GET_NPC;
- GET_WORLD;
- GET_FACTIONS;
- GET_RUNTIME_STATE.

Forbidden:

- SET_RELATIONSHIP;
- RECRUIT_NPC;
- SET_BOND;
- SET_WEATHER;
- MUTATE_INVENTORY;
- any gameplay command.

## Purpose

When enabled, the profiler may replace/enrich offline engine fixtures with actual transient state such as:

- current GameTime;
- weather/climate;
- live player needs;
- live NPC needs;
- current position;
- current activity;
- runtime inventory;
- runtime tactical state;
- nearby zombie density;
- integration availability.

The imported/live snapshot is still copied into the harness before testing.

All later mutations stay harness-only.

---

# 8. Provenance is mandatory

Every important state value must carry provenance.

Canonical source classes:

```text
SAVE
FIXTURE
LIVE
DERIVED
HARNESS_MUTATION
MISSING
```

Examples:

```text
npc.identity.name
    value = Hank Patz
    source = SAVE

relationship.approval
    imported = 73
    effective = 90
    source = HARNESS_MUTATION
    baseSource = SAVE

world.weather
    value = clear
    source = FIXTURE
```

Derived values remain derived through production Lua:

- relationship standing;
- relationship graph quadrant;
- proposal eligibility;
- Talk target type;
- SpeechStyleContext;
- semantic candidates;
- graph paths.

Do not import a stale derived label when production can recompute it from authoritative fields.

---

# 9. Override patches

Harness edits are patches over the imported source snapshot.

Do not destroy imported values.

Reset actions should include:

```text
Reset turn
Reset conversation
Reset selected actor mutations
Reset working world to imported snapshot
Reload save from disk
```

`Reset working world` must not reread disk.

`Reload save` explicitly rereads the source save.

---

# 10. Dynamic mod-state providers

Do not hard-code every future mod variable into Semantic Lab Python.

Introduce a provider/projection contract.

Conceptually:

```text
SaveStateProvider
    id
    discover_tables(...)
    list_players(...)
    list_npcs(...)
    list_factions(...)
    project_world(...)
    project_actor(...)
    project_relationship(...)
    install_into_harness(...)
```

Expected initial providers:

- PsychopatzCore;
- ProjectHoomans;
- DynamicTrading.

Core owns binary decoding.

Each adopter/provider owns interpretation of its own schema.

A future mod should be able to expose semantic-relevant state without modifying the central save reader.

---

# 11. Raw state inspector versus semantic state catalog

Dynamic discovery must not blindly turn every persisted field into a normal UI control.

Provide two views.

## Raw Save Inspector

May display almost all decoded persisted tables/fields for debugging.

## Semantic State Catalog

Contains only fields officially relevant to conversation/semantic simulation.

Each catalog entry should identify:

- semantic state ID;
- owner;
- scope;
- type;
- source availability;
- mutability in harness;
- production derivation;
- provenance.

---

# 12. World Browser

A save-backed Semantic Lab should expose a world browser.

Target categories include, where persisted:

```text
Players
Companions
Colonists
Followers
Neutral NPCs
Hostile NPCs
Factions
Communities
Known traders
Other registered actor/provider groups
```

Selecting an NPC makes it the current conversation target.

Do not require manual profile construction for normal save-backed testing.

---

# 13. Production mutations in the isolated runtime

Once the imported working world is loaded, real production Lua should handle semantic/gameplay mutations.

Examples include:

- relationship changes through RelationshipService;
- durable friend promotion;
- normal semantic proposal action through the production proposal service;
- recruitment through production recruitment/community ownership;
- faction/knowledge/inventory/quest mutations through their real owners.

The existing P11M normal production proposal-route gap is folded into P12's production-mutation acceptance. A harness-only direct proposal command is not sufficient.

Do not mutate imported tables directly if a production authority/service exists.

---

# 14. Save safety

Save import is read-only.

Required protections:

- open/read only;
- no writing to save directory;
- no ModData commit;
- no GlobalModData.save;
- no runtime bridge mutation.

If Project Zomboid may currently be writing the save, use a stable-snapshot read strategy:

```text
stat source
 -> copy/read safely outside save
 -> stat source again
 -> changed?
      retry/fail with save_changed_during_read
```

Do not modify or lock the game save.

---

# 15. P12 milestones

## P12A — Snapshot/provenance architecture

- immutable imported source snapshot;
- mutable harness working world;
- provenance classes;
- override patch semantics;
- reset/reload semantics;
- fixtures retained only as explicit engine/test sources;
- save-backed normal product path.

**Gate:** source snapshot cannot be mutated by worker actions; working snapshot can.

## P12B — Core reader reuse + save catalog

- reuse Core `GlobalModDataReader`;
- discover PZ saves;
- inspect compatibility/world version;
- index Global ModData roots;
- enumerate `PNC_PlayerCharacters`;
- enumerate `PNC_Core_Global` NPC pointers and `PNC_npc<ID>` records;
- fail closed on unsupported/corrupt saves.

**Gate:** list real saved players/NPCs without starting PZ.

## P12C — Real actor/relationship import

- select saved player + NPC;
- import canonical NPC record;
- derive stable player entity key;
- load exact directed relationship;
- install normalized actor/player/relationship state in isolated worker registries;
- remove relationship/bond/friend reconstruction policy from SemanticAdapters.

**Gate:** imported relationship data matches save and production relationship services mutate only working state.

## P12D — Save-backed world browser

- Players;
- companions/colonists/followers;
- neutral/hostile NPCs;
- factions;
- communities;
- known trader/provider data;
- target selection;
- provenance.

**Gate:** select real saved actor pair and open Talk without constructing a synthetic NPC profile.

## P12E — Dynamic mod-state providers

- provider contract;
- Core provider;
- Project Hoomans provider;
- Dynamic Trading provider;
- raw-state inspector separated from semantic-state catalog.

**Gate:** adopter can project its own state without central binary-decoder or per-field Python duplication.

## P12F — Offline engine fixture provider

- normal Semantic Lab remains independent of running PZ;
- current engine-world fixture fields become explicit fixture provider state;
- source=FIXTURE;
- editable offline engine stand-ins;
- no saved mod-owned value silently falls back to fixture.

**Gate:** Semantic Lab runs fully offline from save + explicit engine fixtures.

## P12G — Optional read-only live profiler provider

- audit existing settings/debug owner;
- settings-text-only, disabled-by-default toggle;
- restart required to enable game-side export;
- no normal in-game toggle;
- one-way read-only snapshot interface;
- no mutation commands;
- copy live transient state into harness snapshot;
- source=LIVE.

**Gate:** Lab works with game closed; optional live state can enrich fixtures without write-back.

## P12H — Production mutation runtime

- imported world runs production relationship mutations;
- durable friend promotion;
- normal semantic proposal route -> proposal service;
- recruitment -> production community/faction ownership;
- faction/knowledge/inventory/quest mutations where supported;
- all changes isolated to working world;
- Reset World restores import baseline.

**Gate:** source save remains byte/content unchanged after destructive harness simulations.

## P12I — Source-aware UI and relationship parity

- SAVE/FIXTURE/LIVE/DERIVED/HARNESS_MUTATION/MISSING indicators;
- imported vs effective values;
- production RelationshipGraph;
- baseline/standing/bond/memories/cooldowns/revisions;
- World Browser integration.

**Gate:** imported relationship view reflects actual saved record rather than reconstructed fixture.

## P12J — Save-backed conversation/replay parity

- Talk from real selected saved actors;
- What's Up;
- identity;
- recruitment;
- proposal;
- relationship changes;
- factions;
- knowledge;
- inventory/trading;
- Flow/Hub/ConversationBlock graphs;
- replay/Compare from imported world.

**Gate:** normal end-to-end Lab testing no longer requires a hand-authored synthetic NPC scenario.

## P12K — Final parity/safety matrix

- multiple real saves;
- multiple players;
- multiple NPC types;
- relationship matrices;
- factions/communities;
- corrupt/unsupported save handling;
- save-changing-during-read;
- Core/Hoomans/DT presence/absence;
- offline fixture mode;
- optional live enrichment;
- source save unchanged;
- Python/Lua/Kahlua/doctor/catalog/diff checks.

**Gate:** Semantic Lab is a read-only save-seeded, isolated, production-Lua semantic runtime.

---

# 16. Hard invariants

- Normal product workflow is save-backed.
- Synthetic scenarios are test/developer-only.
- Project Zomboid does not need to run.
- Engine-only state may remain explicit offline fixtures.
- Live profiler is optional, disabled by default, settings-text controlled, and read-only.
- Source saves are never modified.
- Live Project Zomboid is never mutated by Semantic Lab.
- All harness mutations occur only in the detached working world.
- Reuse Core GlobalModDataReader; no second binary parser.
- Mod owners interpret their own persisted schemas through providers.
- Production Lua owns behavior and mutations.
- SemanticAdapters provide seams, not duplicate relationship/business policy.
- Every important value exposes provenance.
- Missing values are explicit; do not invent hidden defaults.
- One semantic parser, one relationship authority, one Talk authority, one provider system, one graph renderer family.
