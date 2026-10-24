# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** P14 ACCEPTED — P12/P13 save-backed operational workbench retained; production rehydration parity and runtime-only controls are verified.
**Current mandatory phase:** P14 complete — production rehydration parity and runtime-only workbench controls accepted.
**Current exact Next Chunk:** None — P14 is complete; the next phase requires a new roadmap decision.
**Current local baseline audited:** ProjectHoomans `main` at `4f8592c4` before this regression-repair commit.
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

## 2026-10-24 runtime-control regression repair

The saved-pair GUI audit found two regressions after the production parity work:

- importing a saved NPC projected the canonical social context only after a
  conversation response, so the Relationship workbench showed midpoint slider
  values or stale `unknown` state;
- save-backed `CONFIG` rehydrated from the immutable source and discarded a
  user’s runtime-only relationship slider draft, while production social action
  results were not visible as `TOOL/ACTION` transcript entries.

The repair preserves the production ownership boundary:

- the raw `PNC_PlayerCharacters` registry is transported to Lua and loaded by
  `PNC.PlayerCharacters.Load` / `PNC.PlayerCharacters.NormalizeRegistry`;
- the headless player fixture exposes only the engine identity/mod-data
  boundary needed for production identity binding, including canonical
  `sp_slot_N` save identities;
- relationship slider edits use the new worker command
  `APPLY_RUNTIME_RELATIONSHIP_BASELINE`, which invokes production
  `PNC.Relationships.SetDebugBaseline` in the isolated working world;
- Reset clears the runtime override and reprojects the imported baseline;
- GUI social context now shows personal relationship, faction relationship,
  tactical hostility, conversation audience, durable bond, speech style, and
  runtime-override provenance separately;
- diagnostics/advanced visibility continues from the user’s persisted UI
  state, while a fresh UI keeps useful tools visible;
- production social actions are rendered in the transcript from the returned
  production `actionResult`, without inventing a Python gameplay action.

Focused regression evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_production_rehydration_p14a tools.semantic_harness.tests.test_save_import_p12c tools.semantic_harness.tests.test_production_inventory_rehydration_p14b tools.semantic_harness.tests.test_production_faction_rehydration_p14c tools.semantic_harness.tests.test_production_social_context_p14d tools.semantic_harness.tests.test_real_save_production_runtime_p14f tools.semantic_harness.tests.test_missing_state_audit_p14e
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_gui_saved_pair_entrypoint tools.semantic_harness.tests.test_ui_state_persistence tools.semantic_harness.tests.test_operational_acceptance_p13g
python3 -m py_compile tools/semantic_harness/runtime/save_import.py tools/semantic_harness/runtime/worker.py tools/semantic_harness/ui/dialogs/catalog_control.py tools/semantic_harness/ui/shell.py
luac5.3 -p tools/semantic_harness/lua/worker.lua tools/semantic_harness/lua/worker/CommandRouter.lua tools/semantic_harness/lua/worker/ProductionModules.lua tools/semantic_harness/lua/worker/ProductionRehydration.lua tools/semantic_harness/lua/worker/RuntimeEnvironment.lua tools/semantic_harness/lua/worker/RuntimeState.lua tools/semantic_harness/lua/worker/ScenarioSession.lua tools/semantic_harness/lua/worker/SemanticAdapters_Core.lua
git diff --check
```

All focused checks pass. The full unwrapped discovery suite was started but
interrupted after it stalled in an existing Tk subprocess smoke test; no
failure was emitted by that run. The focused Xvfb GUI/CLI acceptance suites
remain the authoritative evidence for this repair. P14 remains accepted.

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

All listed checks pass. P14E is accepted.

## Completed P14F — real-save production-runtime regression

Evidence recorded on 2026-10-24:

- The real save
  `Saves/Apocalypse/2026-10-14_13-57-03/global_mod_data.bin` was exercised
  through the normal importer, Lua worker, production rehydration, Talk,
  semantic hello, inspection, mutation, and reset path without a native
  Project Zomboid process.
- The actor matrix covered `npcKentLangley_OWOJ` as a saved
  companion/follower with a persisted personal friendship and gift transfer,
  `npcAdrianMedina_8J7W` as a neutral actor with absent personal and directed
  faction standing, `npcBarneyYamamoto_2OXA` as a hostile raider with absent
  personal relationship, and `npcBrendonOakes_2ZOW` as a trader/provider.
  It also selected `npcNicolasHarris_5V0Z` from the saved directed faction
  relation and verified the production faction relation path.
- Every selected NPC used a saved `BASELINE_DELTA` inventory envelope and
  hydrated production inventory items through
  `PNC.Persistence.DeserializeRecord -> PNC.Inventory.EnsureRecordInventory`.
- Production social context remained layered: personal relationship,
  production faction relationship, tactical hostility, conversation audience,
  durable bond, and speech style were inspected independently. Hostile Talk
  and semantic hello consumed the same production audience context without
  fabricating a personal enemy relationship.
- The GUI inspector, CLI `--inspect-social-context`, and worker context agree
  for the real hostile actor. Reset restored the imported bounded NPC/player
  baseline after Talk, semantic input, and gifting. The source snapshot and
  source-save SHA-256 remained unchanged for each exercised actor.
- Developer/Test fixture mode remains available and explicitly labeled
  `FIXTURE`; it is not used as real-save evidence.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_real_save_production_runtime_p14f
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_actor_inspectors_p13c tools.semantic_harness.tests.test_inventory_gift_workbench_p13e tools.semantic_harness.tests.test_operational_acceptance_p13g tools.semantic_harness.tests.test_contextual_talk_parity_p11j
python3 -m py_compile tools/semantic_harness/runtime/save_import.py tools/semantic_harness/runtime/player_engine_state.py tools/semantic_harness/tests/test_missing_state_audit_p14e.py tools/semantic_harness/tests/test_real_save_production_runtime_p14f.py
luac5.3 -p tools/semantic_harness/lua/worker/Conversation.lua
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py --file tools/semantic_harness/lua/worker/Conversation.lua --kahlua --severity ERROR --no-snippets
git diff --check
```

All listed checks pass. P14F is accepted; P14 is complete.

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

## P14 completion

P14A through P14F are complete on the existing local `main`. The normal
Semantic Lab path is now:

```text
real saved Project Hoomans state
        ↓
production Lua deserialize / migrate / normalize / hydrate
        ↓
isolated production registries and working world
        ↓
production Project Hoomans services
        ↓
conversation / semantics / gameplay mutations
```

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

P14 acceptance is complete. Future work must preserve the production Lua
ownership boundary and must not reintroduce parallel Python Hoomans
persistence or gameplay policy.

Native Project Zomboid remains user-owned final acceptance.

## Completed P15 — Semantic Lab authoritative interaction projection and saved-world lens

Evidence recorded on 2026-10-24:

- Mutating worker calls (`INPUT`, semantic suggestion clicks, and relationship
  proposals) now merge the authoritative post-action production snapshot into
  the bounded action response. GUI and CLI therefore render the same
  production-owned relationship/inventory/context state while retaining the
  existing transcript, tool, and action evidence.
- The worker `SNAPSHOT` route now uses the established Lua compact transport
  boundary. Large real-save inventory envelopes no longer exceed the JSON-line
  message limit; Python preserves the already-imported immutable diagnostic
  source/provider copy and working baseline when compact snapshots omit those
  duplicated fields.
- Real saved `npcJordanMcLane_0LBN` proves a typed insult updates production
  approval, respect, and familiarity in the GUI sliders (`-3.62`, `-2.71`,
  `1.0`), retains `TOOL/ACTION` evidence, resets to the imported baseline, and
  leaves the source save SHA-256 unchanged.
- The Saved World Browser defaults to a player-relative, mutually exclusive
  lens with roots for Player faction/companions, settlers/communities,
  hostile/looters, traders/providers, neutral/unaffiliated, other faction
  members, and unknown/unsupported actors. `Saved affiliations` remains
  available for persisted faction/community inspection.
- Actor affiliation is now a dedicated tree column instead of a duplicate name
  suffix. Color tags and textual badges are derived from bounded SAVE/provider
  facts; the browser explicitly documents that this presentation lens does not
  fabricate personal enemy relationships or replace production diplomacy.
- UI state persists the saved-world view, search, selected save/player/NPC, open
  roots, tabs, sashes, diagnostics/advanced visibility, geometry, and existing
  conversation choices. Developer/Test fixture mode remains available.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_real_save_production_runtime_p14f tools.semantic_harness.tests.test_save_backed_snapshot_p12a tools.semantic_harness.tests.test_production_rehydration_p14a tools.semantic_harness.tests.test_production_faction_rehydration_p14c
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_gui_saved_pair_entrypoint tools.semantic_harness.tests.test_saved_world_relationship_lens_p15b tools.semantic_harness.tests.test_faction_community_workbench_p13d tools.semantic_harness.tests.test_operational_acceptance_p13g tools.semantic_harness.tests.test_ui_organization tools.semantic_harness.tests.test_ui_state_persistence tools.semantic_harness.tests.test_inventory_gift_workbench_p13e
python3 -m unittest tools.semantic_harness.tests.test_contextual_runtime_parity_p11c tools.semantic_harness.tests.test_contextual_runtime_parity_p11d tools.semantic_harness.tests.test_cli_parity_p13f tools.semantic_harness.tests.test_save_backed_conversation_p12j
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-kahlua-lint/scripts/pz_kahlua_lint.py lint tools/semantic_harness/lua/worker/CommandRouter.lua --severity=ERROR --stats
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py --file tools/semantic_harness/lua/worker/CommandRouter.lua --kahlua --severity ERROR --no-snippets
git diff --check
```

All listed checks pass. P15 interaction projection and saved-world browser
slice accepted. Next Chunk: none for this requested slice.

## Completed P15 follow-up — production NPC dossier and interaction history inspector

Evidence recorded on 2026-10-24:

- Save import now transports the raw `PNC_NPCKnowledge` registry separately from the bounded faction/community request. Python retains selection, source provenance, and immutable snapshot ownership; it does not interpret knowledge, journal, gift preference, or relationship policy.
- The isolated Lua worker installs the raw registry into worker-local `PNC_NPCKnowledge` ModData and invokes the production `PNC.NPCKnowledge.Load` owner. The dossier is projected through production `BuildPlayerSnapshotForPlayer`; relationship history is projected through production `PNC.RelationshipDebug.BuildSnapshotForRequest` with a bounded interaction journal.
- Normal Talk and snapshot responses remain compact. The large dossier/history projection is available through the explicit worker/CLI inspector path and is requested by the NPC Target `Dossier` and `Interactions` tabs. When Interactions is already selected, a production action refreshes the same projection so recorded event type, applied state, before/after values, and delta are visible.
- Relationship sliders now preserve and display production decimal values to two places, so a real social action such as `-3.62`, `-2.71`, and `1.00` is visible as the authoritative runtime result rather than being rounded to integer text.
- CLI supports `--inspect-dossier` and `--inspect-interaction-history`. Developer/Test fixture mode remains explicit and marks these production projections `NOT_APPLICABLE` rather than importing saved knowledge.
- Synthetic raw-save coverage proves descriptors, knowledge journal, manual note, gift preference, production rehydration owner, reset equality, and source-byte immutability. Real-save coverage proves Kent's production dossier/history, a typed insult appending `player_dialogue_insult`, reset restoration, and unchanged source-save bytes.

Focused evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_production_rehydration_p14a
python3 -m unittest tools.semantic_harness.tests.test_real_save_production_runtime_p14f
python3 -m unittest tools.semantic_harness.tests.test_production_inventory_rehydration_p14b tools.semantic_harness.tests.test_production_faction_rehydration_p14c tools.semantic_harness.tests.test_production_social_context_p14d tools.semantic_harness.tests.test_missing_state_audit_p14e
timeout 90s python3 -m unittest tools.semantic_harness.tests.test_gui_saved_pair_entrypoint.GuiSavedPairEntrypointTests.test_saved_production_dossier_and_interactions_are_visible_on_demand
python3 -m compileall -q tools/semantic_harness
luac -p tools/semantic_harness/lua/worker/CommandRouter.lua tools/semantic_harness/lua/worker/ProductionModules.lua tools/semantic_harness/lua/worker/ProductionRehydration.lua tools/semantic_harness/lua/worker/ScenarioSession.lua
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py --file tools/semantic_harness/lua/worker/CommandRouter.lua --kahlua --severity ERROR --no-snippets
git diff --check
```

This follow-up is accepted on the existing local `main`. Current exact Next
Chunk: none for this requested inspector slice.
