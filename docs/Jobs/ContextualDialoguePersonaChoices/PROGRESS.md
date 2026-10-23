# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** REOPENED — P12/P13 save-backed operational workbench retained; P14 production rehydration parity is mandatory.  
**Current mandatory phase:** P14A — Production rehydration boundary.  
**Current remote baseline audited:** ProjectHoomans `main` at `d3c6c2018b4a074bdf6178b7f060f18832ed2344`.  
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

## Current Exact Next Chunk — P14A

On the user's existing local `main`:

1. read root `AGENTS.md` and this job's docs in documented order, including `PRODUCTION_REHYDRATION_AND_MOD_CODE_PARITY.md`;
2. inspect local ProjectHoomans/Core/DynamicTrading branch/HEAD/upstream/divergence and preserve concurrent work;
3. trace one real imported `PNC_npc<ID>` from:
   - Core GlobalModDataReader;
   - Python save provider/importer;
   - worker configure/install;
   - isolated registry;
   - conversation/semantic context;
4. audit the actual production Lua persistence/load owners for NPC records, inventory, social state and migrations;
5. define the smallest raw-record transport contract from Python to Lua;
6. add/reuse a worker operation that accepts raw persisted NPC data and invokes the real production deserialization/normalization path;
7. install the hydrated production record into the isolated worker registry;
8. preserve immutable raw source/provenance alongside the hydrated working state;
9. stop Python from interpreting normal NPC runtime fields that the production Lua path now owns;
10. keep genuine engine fixtures unchanged;
11. do not implement world-object datasets, scene indexing, pathing or spatial commands in this chunk;
12. add focused tests proving:
    - raw saved record enters production Lua;
    - production rehydration output is used by the worker;
    - source snapshot is unchanged;
    - reset restores the imported baseline;
    - legacy Developer/Test fixtures still work through their explicit path;
13. run focused Python/Lua/Tk checks and `git diff --check`;
14. update this ledger with exact evidence and continue automatically to P14B when green.

## P14A acceptance

Evidence must structurally prove:

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
