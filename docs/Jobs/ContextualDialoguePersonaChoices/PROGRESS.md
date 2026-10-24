# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** REOPENED — P12/P13 save-backed operational workbench retained; P14 production rehydration parity is mandatory.  
**Current mandatory phase:** P14C — Production faction/diplomacy rehydration.
**Current local baseline audited:** ProjectHoomans `main` at `2308e5a8` before the P14B evidence commit.
**Normal Semantic Lab runtime requirement:** Project Zomboid may remain CLOSED/OFFLINE.  
**Source save mutation:** FORBIDDEN.

## Accepted foundation to preserve

P12/P13 materially provide:

- real save discovery and World Browser;
- real saved Player/NPC selection;
- immutable source snapshot + isolated mutable working world;
- Player engine inventory decoding;
- Player/NPC actor inspectors;
- faction/community workbench;
- production gift verification;
- Talk/semantic graphs;
- production relationship/proposal/recruitment paths;
- agent-grade CLI parity;
- source provenance;
- optional read-only profiler enrichment;
- operational Tk/Xvfb acceptance.

Do not replay P12/P13 unless a regression is demonstrated.

## 2026-10-24 real-save parity audit

The latest real-save screenshots expose a deeper architecture problem.

### Hostile raider relationship

A hostile raider does **not** automatically require a personal `enemy` relationship record.

Production separates:

```text
personal NPC→Player relationship
faction diplomacy
tactical hostility
conversation audience
```

A raider may therefore truthfully have:

```text
personal relationship = absent/unknown
tactical hostility = hostile
conversation audience = hostile
```

Do not fabricate an enemy personal relationship.

### False NPC inventory MISSING

Project Hoomans persists NPC inventory through compact modes including:

```text
SEED_ONLY
BASELINE_DELTA
FULL
```

Production Lua owns rehydration.

Current Python save import still expects an already-expanded `inventory.items` shape. Therefore a valid compact persisted inventory can be reported as MISSING.

This is a confirmed harness rehydration defect.

### Incomplete faction diplomacy import

The save browser can import faction identity/membership, but current state projection does not preserve enough production diplomacy state, including directed relation maps and Player diplomacy-faction mapping.

This can make faction standing appear MISSING while hostile Talk choices remain correct from tactical hostility.

### Architecture verdict

The harness must stop reimplementing Project Hoomans persistence/business interpretation in Python.

Rule:

> **Fixture the engine, never fixture the mod.**

Python owns discovery/transport/isolation/presentation.

Production Lua owns Hoomans deserialization, normalization, derivation and gameplay mutation.

## Completed P14A — production rehydration boundary

Evidence recorded on 2026-10-24:

- Python `SaveBackedImporter` transports selected raw records through
  `ProjectHoomans.rawRecords` without making Lua runtime decisions.
- Lua worker invokes `PNC.Persistence.DeserializeRecord` and
  `PNC.Inventory.EnsureRecordInventory`, then installs the result in an
  isolated `PNC.Registry`.
- SAVE relationship, recruitment, trader overlay, inventory transfer, and
  conversation paths use the hydrated production record; the worker only
  supplies engine/scene fixtures such as the conversation lease.
- Large real-save records remain within the bounded worker transport by
  removing duplicate legacy provider copies from the worker request.
- UI/Talk responses remain bounded by compacting public relationship and
  conversation projections while retaining the full record privately in the
  production registry.
- Source-save SHA and immutable source snapshots remain unchanged across
  import, configure, mutation, and reset.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_production_rehydration_p14a
python3 -m unittest tools.semantic_harness.tests.test_save_import_p12c tools.semantic_harness.tests.test_save_backed_conversation_p12j tools.semantic_harness.tests.test_save_backed_snapshot_p12a tools.semantic_harness.tests.test_cli_parity_p13f
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_actor_inspectors_p13c tools.semantic_harness.tests.test_inventory_gift_workbench_p13e tools.semantic_harness.tests.test_operational_acceptance_p13g
```

All listed checks pass. P14A is accepted.

## Completed P14B — production NPC inventory rehydration

Evidence recorded on 2026-10-24:

- Production Lua generated and reserialized `SEED_ONLY`, `BASELINE_DELTA`, and
  `FULL` records through `PNC.Persistence.SerializeRecord`; Python only
  transported the raw record.
- Lua rehydrated every mode through `PNC.Persistence.DeserializeRecord` and
  `PNC.Inventory.EnsureRecordInventory`, with the hydrated record installed in
  the isolated registry and consumed by the semantic inventory query.
- Core sparse numeric inventory keys survive JSON-lines transport; Core reader
  `_entries` shapes are restored as generic transport data, not interpreted as
  Project Hoomans gameplay state.
- Real saved `npcWilberDowns_R4XY` previously reported
  `npc.inventory = MISSING` in the Python projection. Its persisted
  `BASELINE_DELTA` now rehydrates as `BASELINE_DELTA` with eight production
  inventory items, using a read-only Project Zomboid item-type engine fixture.
- GUI/CLI operational parity, semantic inventory display, source-save SHA,
  immutable source snapshots, reset isolation, and Developer/Test fixture mode
  remain passing.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_production_inventory_rehydration_p14b
python3 -m unittest tools.semantic_harness.tests.test_production_rehydration_p14a
python3 -m unittest tools.semantic_harness.tests.test_save_import_p12c tools.semantic_harness.tests.test_save_backed_conversation_p12j tools.semantic_harness.tests.test_save_backed_snapshot_p12a tools.semantic_harness.tests.test_cli_parity_p13f
python3 -m unittest tools.semantic_harness.tests.test_protocol
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_actor_inspectors_p13c tools.semantic_harness.tests.test_inventory_gift_workbench_p13e
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_operational_acceptance_p13g
```

All listed checks pass. P14B is accepted; continue with P14C.

## Current Exact Next Chunk — P14C

On the existing local `main`:

1. trace and transport the raw saved faction/diplomacy state needed by the
   production faction owners;
2. invoke production faction/community load and relationship services to
   resolve NPC faction → selected Player real/provisional diplomacy faction;
3. preserve war, alliance, truce, pacification, trust/fear/grievance, and
   membership/leader state without adding Python diplomacy policy;
4. keep personal relationship, faction relationship, tactical hostility, and
   conversation audience as separate production-owned layers;
5. run focused Python, Lua, Tk/Xvfb, CLI, Kahlua, and diff checks, then update
   this ledger and continue automatically to P14D.

## P14A acceptance

Evidence structurally proved:

```text
Python
    raw saved PNC_npc record
        ↓
Lua worker
    production deserialize/migrate/normalize
        ↓
isolated PNC Registry
        ↓
production conversation/semantic systems
```

A Python-generated runtime approximation is not acceptance.

## Ordered remaining P14 milestones

- **P14B:** production NPC inventory rehydration, including BASELINE_DELTA;
- **P14C:** production faction/diplomacy rehydration;
- **P14D:** canonical social context + hostile speech parity;
- **P14E:** MISSING-state audit/provider cleanup;
- **P14F:** real-save production-runtime regression.

See `PRODUCTION_REHYDRATION_AND_MOD_CODE_PARITY.md`.

## Explicit future non-goal

A future project may build a world-object/item dataset for grounded commands such as:

```text
stand near the garbage bin
go to the pole
```

That is out of scope for P14.

P14 only ensures the harness architecture will later allow such engine/world data to feed the real production semantic/action code.

## Handoff rule

Do not report the Semantic Lab parity goal complete until P14F proves that real saved Hoomans state is interpreted by production Lua rather than parallel Python policy.

Native Project Zomboid remains user-owned final acceptance.
