# P13 — Operational Semantic Test Workbench

**Status:** OPERATIONAL FOUNDATION COMPLETE / retained under P14  
**Opened:** 2026-10-24  
**Implementation baseline audited:** ProjectHoomans remote `main` at `dbfd9099a0b687bc2f6505f58e81e32ea6dc5966`.  
**P12 disposition:** save-backed runtime/backend foundation retained; product usability acceptance reopened.  
**Native Project Zomboid requirement:** none for normal Semantic Lab operation.  
**Source save mutation:** FORBIDDEN.

## P14 supersession note

P13's World Browser, Player engine-state provider, symmetric actor inspectors, faction/community workbench, gift verification, CLI parity, and operational acceptance are retained.

P14 is now active because the remaining parity defect is no longer operational usability; it is that some Project Hoomans persisted gameplay state is still interpreted in Python rather than rehydrated by the production Lua owners.

Do not replay P13A-P13G unless a regression is demonstrated.

## Why P13 exists

P12 successfully introduced:

- immutable read-only save/source snapshots;
- detached mutable working worlds;
- real save discovery;
- real saved Player/NPC import;
- real directed relationship import;
- production relationship/proposal/recruitment mutation paths;
- Core/Hoomans/DynamicTrading save-state providers;
- explicit offline engine fixtures;
- optional read-only profiler enrichment;
- source provenance;
- final source-save immutability checks.

However, the current Semantic Lab is not yet usable enough to replace repeated native-game verification.

The current GUI exposes save browsing as a compressed one-row control strip containing:

```text
Save
Discover saves
Player
NPC group
NPC
Inspect
Import target
```

On the normal Simulation left-pane width, the save selector can collapse so severely that discovered saves cannot be practically selected. The P12 GUI acceptance only proved that controls existed; it did not prove that a user could operate the complete save-selection workflow at realistic geometry.

The backend also returns factions and communities separately from NPC category buckets. It does not yet project or render the saved world as a hierarchy where NPCs are browsable under their actual faction/community.

Player-side parity is also incomplete:

- Player and NPC are not symmetrical first-class inspection surfaces;
- the Player tab does not expose a useful visual inventory browser;
- real offline player inventory is often `MISSING` because `PNC_PlayerCharacters` is an identity/social registry rather than the authoritative Project Zomboid player inventory;
- gift testing therefore remains harder to visually verify than native gameplay.

P13 turns the existing P12 backend into an operational testing workbench.

The product goal is:

> A human or coding agent can select a real saved world, select the saved player, browse NPCs by faction/community, inspect both actors and their inventories, execute the real production conversation/gift/relationship/recruitment paths against the isolated working world, inspect exactly what changed, reset safely, and use the same operations from GUI and CLI.

---

# 1. Preserve the P12 architecture

Do not replace:

- `SaveCatalog`;
- `SavedWorldBrowser`;
- `SaveBackedImporter`;
- `SemanticStateCatalog`;
- immutable source snapshot;
- mutable working world;
- Core `GlobalModDataReader`;
- production relationship/proposal/recruitment authorities;
- existing semantic worker;
- existing graph renderer family;
- optional live profiler provider.

P13 is primarily an operational/useability phase over those owners.

Do not add a second save parser, conversation runtime, relationship runtime, gift runtime, inventory mutation path, or graph system.

---

# 2. P12 completion wording is narrowed

P12 backend/runtime acceptance remains valid.

The former statement:

```text
P12 status: COMPLETE
```

must be interpreted as:

```text
P12 save-backed runtime/backend foundation complete
P13 operational usability acceptance required
```

Do not replay P12A-P12K unless a regression is found.

Do not report the full Semantic Lab product as complete merely because the save backend discovers and imports state.

---

# 3. Normal save-backed workflow

The normal Simulation workflow should become:

```text
select saved world
    ↓
select saved player
    ↓
browse saved world hierarchy
    ↓
select NPC target
    ↓
load isolated working world
    ↓
inspect Player / NPC / Relationship / World / Faction
    ↓
run Talk / semantic action / gift / recruit / proposal
    ↓
inspect mutations
    ↓
reset working world
```

Synthetic profiles/scenarios remain Developer/Test-only.

The normal save-backed workflow must not require the user to choose a synthetic `NPC profile` such as `Companion (owned)`.

When save-backed mode is active, role/tactical/ownership/faction/community state comes from the imported save and production derivation.

---

# 4. World Browser UX

Replace the compressed one-row save browser with a dedicated usable browser surface.

Use existing Tk.

Do not introduce another application.

Recommended structure:

```text
Saved World
────────────────────────────────

Save
[ <save> ▼ ] [ Reload saves ]

Player
[ <saved player> ▼ ]

Search
[ __________________________ ]

World
▼ Faction: Patz Fellowship
    ★ Hank Patz       friend
      Dana Patz       neutral
      Pete Patz       friend

▼ Faction: West Point Survivors
      ...

▼ Unaffiliated
      ...

▼ Hostile
      ...

▼ Known Traders
      ...
```

A `ttk.Treeview` or equivalent hierarchical Tk control is appropriate.

## Required hierarchy

Where persisted, group actors by:

- faction;
- community where useful;
- unaffiliated;
- hostile;
- provider/trader overlay where useful.

The backend should project hierarchy data; UI should render it.

Do not make Tk infer faction membership from strings.

## Selection behavior

Selecting/double-clicking an NPC must:

- identify exact persisted NPC ID;
- preserve selected Player;
- import the Player/NPC pair through the existing save-backed importer;
- populate the existing workbench;
- make that NPC the normal Talk target.

The workflow should not require:

```text
Discover
 -> Inspect
 -> choose category
 -> choose NPC
 -> Import target
```

for every target.

---

# 5. Real interaction acceptance, not widget-existence tests

P12 tests currently prove controls exist.

P13 GUI acceptance must operate the controls.

At realistic desktop and minimum supported geometry, Xvfb/Tk tests must:

1. discover saves;
2. open/select a real or realistic save row;
3. select a player;
4. expand a faction/group;
5. select an NPC;
6. import/load the pair;
7. verify the Player/NPC workbench updates;
8. start Talk.

If the browser is visually unusable because controls are clipped/collapsed, the gate fails even if widget objects exist.

---

# 6. Player/NPC symmetric actor workbench

Player and NPC Target should be symmetric first-class actor surfaces.

Each actor should expose, where supported:

```text
Overview
Needs
Personality & Traits
Inventory
```

The exact content may differ because Project Zomboid Player and Hoomans NPC owners differ, but the navigation model should be parallel.

## Player

At minimum expose:

- identity / character UUID / account identity;
- display name;
- gender/orientation/social profile where persisted;
- traits;
- needs fixtures or live enrichment;
- inventory;
- provenance.

## NPC

At minimum expose:

- identity;
- tactical/ownership state;
- faction/community;
- traits;
- generated/saved personality;
- needs;
- inventory;
- provenance.

Do not duplicate inventory widgets.

Use one reusable actor-inventory presentation component.

---

# 7. Offline Player engine-state provider

`PNC_PlayerCharacters` does not own the native Project Zomboid player's complete physical inventory.

P13 must audit the actual Build 42.20 save ownership for offline Player engine state and implement the smallest safe read-only provider needed for Semantic Lab parity.

Priority:

1. Player inventory;
2. worn/equipped items;
3. Player traits if the authoritative saved source is available;
4. needs/condition values where safe and useful;
5. position/runtime-like engine values only if the persisted source is proven.

Potential engine save sources must be verified against current Build 42.20 save format before implementation.

Do not guess formats.

Do not silently synthesize inventory.

The provider must be:

- version-gated;
- read-only;
- bounded;
- fail-closed;
- provenance-aware.

If a field cannot be decoded safely:

```text
source = MISSING
```

is correct.

Do not make the live profiler mandatory.

Optional live profiler may still enrich transient values.

---

# 8. Inventory workbench

Both actors need a readable inventory surface.

Normal inventory UI should show human-readable records such as:

```text
Item
Type/category
Count
Container
Equipped/worn state
Condition/state
Source/provenance
```

Group or filter by useful categories where available.

Preserve Advanced/raw JSON inspection as a secondary diagnostic surface.

Do not use raw JSON as the normal inventory workflow.

---

# 9. Gift verification workbench

Gift testing is a mandatory P13 product flow.

Target layout may be side-by-side:

```text
Player Inventory              NPC Inventory
──────────────                ─────────────
Apple x2                      Sardines x2
Bandage x4                    Hammer
Water x1

Selected: Apple x1
                [ Give → ]
```

The button must not directly modify Python inventory tables.

It must route through the real production gift/semantic/inventory authority path.

Required observable result:

```text
Gift
Player -> NPC
item / amount

Transfer
before -> after

NPC response
<production dialogue>

Relationship
approval/respect/etc before -> after

Source save
UNCHANGED
```

Reset Working World must restore both actor inventories and relationship state to the imported baseline.

---

# 10. Faction/community workbench

Saved faction/community state should be first-class.

For selected faction/community expose where persisted:

- ID/name;
- leader;
- members;
- ownership;
- faction roles;
- community;
- standing/diplomacy if available;
- trader/provider overlays;
- provenance.

Clicking a member should make that actor the current NPC target.

This surface should support later semantic/gossip verification without adding separate faction state in Semantic Lab.

---

# 11. Legacy fixture controls in save-backed mode

Normal save-backed mode must stop visually implying that fixture controls are authoritative.

Examples:

- `NPC profile [Companion (owned)]`;
- `Load scenario`;
- `Save scenario`;
- other synthetic-profile selectors.

These may remain under explicit:

```text
Developer / Test
```

or:

```text
Advanced fixture mode
```

but should not dominate normal save-backed operation.

Do not delete fixture infrastructure required by CI.

---

# 12. GUI/CLI parity for agents

Every important save-backed workflow should have a machine-readable CLI/worker equivalent.

Required operations should include, directly or through existing commands:

- list/discover saves;
- inspect one save;
- list players;
- list factions/communities;
- list/search NPCs;
- select/load Player + NPC;
- inspect actor state;
- inspect inventories;
- inspect relationship;
- Start Talk;
- submit semantic utterance;
- execute supported gift/recruit/proposal actions;
- inspect working-world diff;
- reset working world;
- reload source.

GUI and CLI must share backend owners.

Do not implement a GUI-only state path.

This is mandatory because autonomous agents should be able to use the harness without screenshots for ordinary verification.

---

# 13. P13 milestones

## P13A — Operational World Browser UX

Required:

- replace compressed save-browser row;
- dedicated save/player/world browser;
- hierarchical faction/community/actor tree;
- search/filter;
- double-click or simple selection import;
- selected actor becomes Talk target;
- fixture NPC profile hidden/demoted in save-backed mode;
- realistic Tk geometry acceptance.

**Gate:** user can discover/select one of multiple saves, select a Player, expand faction/group, select/import NPC and Start Talk without using raw JSON or legacy scenario loading.

## P13B — Offline Player Engine-State Provider

Required:

- audit actual Build 42.20 Player save ownership;
- implement bounded read-only engine provider for Player inventory first;
- decode item identities through authoritative saved registries/dictionaries where required;
- provenance/fail-closed behavior;
- no write support.

**Gate:** at least one real compatible save exposes real Player inventory offline, with source-save hash unchanged; unsupported saves report MISSING/reason.

## P13C — Symmetric Player/NPC Actor Inspectors

Required:

- Overview;
- Needs;
- Personality & Traits;
- Inventory;
- parallel navigation;
- source/effective/provenance display;
- one reusable inventory presentation family.

**Gate:** switching selected Player/NPC refreshes both actor inspectors from imported working state.

## P13D — Faction/Community Workbench

Required:

- faction/community hierarchy;
- member/leader views;
- standings/diplomacy where available;
- member click -> current NPC target;
- provider overlays.

**Gate:** real saved faction membership can be navigated and used to select conversation targets.

## P13E — Inventory/Gift Verification Workbench

Required:

- side-by-side Player/NPC inventory;
- item selection;
- production gift route;
- transfer/result/reaction/relationship diff;
- reset restores imported baseline;
- no direct Python gameplay mutation.

**Gate:** one real save-backed gift can be visually and machine-readably verified end-to-end with unchanged source save.

## P13F — Agent-grade CLI parity

Required:

- stable machine-readable world browser;
- actor/inventory/faction inspection;
- Talk and semantic actions;
- gift/recruit/proposal;
- diff/reset/reload;
- same backend as GUI.

**Gate:** agent can reproduce the key P13E verification without interacting with Tk.

## P13G — Operational acceptance

Use real-save-backed evidence plus realistic Tk/Xvfb.

Mandatory end-to-end sequence:

```text
discover save
 -> select Player
 -> browse faction
 -> select NPC
 -> inspect Player inventory
 -> inspect NPC inventory
 -> Start Talk
 -> execute gift
 -> observe conversation + relationship/inventory changes
 -> reset working world
 -> verify imported baseline restored
 -> verify source save unchanged
```

Also validate:

- neutral;
- follower/companion;
- hostile where Talk supports it;
- trader/provider where available;
- save without supported Player engine inventory;
- minimum supported window geometry;
- desktop geometry.

**Gate:** Semantic Lab is operational enough that normal semantic/conversation verification should be performed here first, with native PZ reserved for user-owned final live acceptance.

---

# 14. Hard invariants

- P12 save/runtime architecture remains authoritative.
- Save and live sources remain read-only.
- All mutations remain isolated to working world.
- PZ does not need to run.
- Live profiler remains optional/read-only.
- Synthetic scenario mode remains available for tests but is not normal UX.
- No second binary Global ModData reader.
- Verify engine Player-save format before decoding.
- No guessed Player inventory.
- Production gift/relationship/recruitment authorities remain authoritative.
- Raw JSON remains Advanced/diagnostic, not normal inventory editing.
- GUI and CLI share backend state owners.
- Widget existence is not usability acceptance.
- Real interaction through Tk/Xvfb is required for GUI gates.
- One Semantic Lab application; no parallel browser app.

---

# 15. Completion condition

Do not report the Semantic Lab goal complete merely because P12 backend tests are green.

P13 is complete only when a user or coding agent can practically use the save-backed Semantic Lab as the primary conversation/semantic verification environment.

Native Project Zomboid remains the final user-owned game acceptance surface, not the normal development loop.
