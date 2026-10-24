# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** REOPENED — P12/P13 save-backed operational workbench retained; P14 production rehydration parity is mandatory.  
**Current mandatory phase:** P14D — Canonical social context + hostile speech parity.
**Current local baseline audited:** ProjectHoomans `main` at `f887bff8` before the P14C evidence commit.
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

P14B closed this false-negative path: Python transports the compact envelope and production Lua rehydrates `SEED_ONLY`, `BASELINE_DELTA`, and `FULL` through the real persistence/inventory owners.

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

## Completed P14C — production faction/diplomacy rehydration

Evidence recorded on 2026-10-24:

- Python now transports raw `PNC_Factions` and `PNC_Communities` registries in
  `ProjectHoomans.rawRegistries`; it does not derive faction standing,
  diplomacy state, or membership policy.
- The Lua worker installs those bounded raw registries through production-owned
  `PNC.Factions.LoadRaw` and `PNC.Communities.LoadRaw`, which call the real
  `PNC.FactionTypes.NormalizeFactionRegistry` and
  `PNC.CommunityTypes.NormalizeRegistry` paths.
- The detached load seam preserves saved relation maps, war/alliance/truce
  fields, standing, trust, fear, grievance, faction membership, community
  membership, and leader references without running the full-world live-NPC
  reconciliation pass.
- Production `PNC.Factions.GetDiplomacyFactionForPlayerKey` and
  `PNC.Factions.GetRelation` resolve the selected Player key and directed
  NPC-faction relation. The result is exposed as a separate production
  faction context; personal relationship and tactical hostility remain
  separate fields.
- Synthetic raw-save coverage proves production load owners, directed war
  standing, community leader/member preservation, reset isolation, fixture
  mode, and source immutability. A real local save also resolves a non-player
  NPC faction against the selected Player diplomacy faction.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_production_faction_rehydration_p14c
python3 -m unittest tools.semantic_harness.tests.test_production_inventory_rehydration_p14b tools.semantic_harness.tests.test_production_rehydration_p14a tools.semantic_harness.tests.test_protocol tools.semantic_harness.tests.test_cli_parity_p13f
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_actor_inspectors_p13c tools.semantic_harness.tests.test_inventory_gift_workbench_p13e tools.semantic_harness.tests.test_operational_acceptance_p13g
```

All listed checks pass. P14C is accepted; continue with P14D.

## Completed P14D — canonical social context + hostile speech parity

Evidence recorded on 2026-10-24:

- Production `ActorConversationContext` now exposes separate personal relationship,
  faction relationship, tactical hostility, conversation audience, and durable-bond
  layers. The worker derives these projections from the hydrated production record
  and production registries; it does not infer personal enemy state from faction war.
- Saved hostile Talk context calls production `PNC.Conversation.TalkStart.Project`,
  which calls the production audience/relationship path. The typed `hello` semantic
  response and native hostile/parley Talk projection both resolve `audience=hostile`,
  `reason=player_hostile`, and `route=hostile_full_conversation`.
- Canonical GUI/CLI projections include source and reason for each layer, including
  legitimate personal-relationship absence and explicit durable-bond absence.
- Production speech style now carries dimensions/provenance/reason. The production
  guarded greeting localization was corrected from a neutral-sounding
  `Hello. What is it?` to `State your business. Keep your distance.` without creating
  a personal enemy relationship.
- Synthetic saved hostile actor coverage proves faction war, tactical hostility,
  hostile audience, guarded speech, CLI/GUI inspection, reset restoration, source
  snapshot equality, and source-save byte immutability. Developer/Test fixture mode
  remains supported.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_production_social_context_p14d tools.semantic_harness.tests.test_contextual_talk_parity_p11j tools.semantic_harness.tests.test_contextual_speech_style_p3 tools.semantic_harness.tests.test_contextual_speech_behavior_p8b tools.semantic_harness.tests.test_conversation_inspector
python3 -m unittest tools.semantic_harness.tests.test_production_rehydration_p14a tools.semantic_harness.tests.test_production_inventory_rehydration_p14b tools.semantic_harness.tests.test_production_faction_rehydration_p14c tools.semantic_harness.tests.test_production_social_context_p14d tools.semantic_harness.tests.test_protocol tools.semantic_harness.tests.test_cli_parity_p13f tools.semantic_harness.tests.test_conversation_inspector
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_actor_inspectors_p13c tools.semantic_harness.tests.test_inventory_gift_workbench_p13e tools.semantic_harness.tests.test_operational_acceptance_p13g tools.semantic_harness.tests.test_contextual_talk_parity_p11j
```

All listed checks pass. Changed Lua files pass `luac5.3 -p` and `pz-verify`
Kahlua ERROR+ checks. P14D is accepted; continue with P14E.

## Completed P14E — MISSING-state audit and provider classification

Evidence recorded on 2026-10-24:

- Compact persisted NPC inventory envelopes are now provenance `SAVE` with the
  production owner chain `PNC.Persistence.DeserializeRecord ->
  PNC.Inventory.EnsureRecordInventory`; Python still does not decode inventory
  modes. This removes the false `npc.inventory = MISSING` diagnostic while the
  production Lua rehydration boundary remains authoritative.
- Important honest absences now carry an explicit `missingClass`: legitimate
  absent personal relationship/traits/faction/community/bond, engine-only native
  Player tail fields, unsupported-format/provider failure paths where applicable,
  and rehydration failures remain distinct from ordinary absence.
- Real compact-save audit for `npcWilberDowns_R4XY` now reports no unclassified
  important `MISSING` path; the remaining saved `player.traits` absence is marked
  `LEGITIMATE_ABSENCE`, and native `worn`/`equipped` gaps are marked `ENGINE_ONLY`.
- Developer/Test fixture mode remains explicitly labeled `FIXTURE`; it does not
  claim SAVE provenance for social context or production faction registries.
- No source-save mutation or live Project Zomboid mutation was introduced.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_missing_state_audit_p14e tools.semantic_harness.tests.test_production_rehydration_p14a tools.semantic_harness.tests.test_production_inventory_rehydration_p14b tools.semantic_harness.tests.test_production_faction_rehydration_p14c tools.semantic_harness.tests.test_production_social_context_p14d tools.semantic_harness.tests.test_save_import_p12c tools.semantic_harness.tests.test_player_engine_state_p13b tools.semantic_harness.tests.test_cli_parity_p13f
```

All listed checks pass. P14E is accepted; continue with P14F.

## Current Exact Next Chunk — P14F

On the existing local `main`:

1. exercise real saved companion/follower, neutral NPC, hostile raider, and
   trader/provider actors through production rehydration;
2. cover persisted and absent personal relationships, BASELINE_DELTA inventory,
   faction relation present/absent, Talk, semantic hello, inventory, gift where
   supported, relationship/faction context, mutation, and reset;
3. prove GUI result equals CLI result, source save bytes remain unchanged, and
   working-world reset restores the imported production baseline;
4. run focused Python, Lua, Tk/Xvfb, CLI, Kahlua, and diff checks, then update
   this ledger and close P14 only when the real-save production-runtime path is
   evidenced.

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
