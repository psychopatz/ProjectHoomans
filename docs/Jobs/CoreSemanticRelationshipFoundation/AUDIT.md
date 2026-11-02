# Audit — Current Semantic, Social and Adopter Boundaries (P0A)

**Audit Date:** 2026-11-02. Verified against current working trees and test baselines.

## 1. Exact Repository Truth

| Repository | Branch | Commit HEAD | Upstream | Worktree Status |
|---|---|---|---|---|
| **psychopatzCore** | `main` | `0100bf4ba5f552498199e4fd987aee7ba5f1b12c` | `origin/main` (0 ahead, 0 behind) | Clean |
| **DynamicTrading** | `main` | `c97ee13225dccb15ef36b2a6aca186d66304c1ad` | `origin/main` (0 ahead, 0 behind) | 1 tracked modification in `Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua` (preserves trade choice provider hook into `whats_up` semantic hub). |
| **ProjectHoomans** | `main` | `02ab2b41921a0c27f16c787eca79c341857a0707` | `origin/main` (0 ahead, 0 behind) | Clean |

---

## 2. Inventory of Current Core Public APIs

### A. Actors & Registry (`PsychopatzCore.Actors`)
Location: `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/`
- `Actors.NewRegistry()`: Instantiates fresh isolated registry table.
- `Actors.Create(spec)`: Generates and registers canonical actor from spec (`Factory.Generate`, deterministic inventory starter, `providerLease`).
- `Actors.Get(actorId)`: Returns deep clone of canonical actor record.
- `Actors.Save()`: Returns JSON serialized string of default registry.
- `Actors.Load(serialized)`: Decodes and replaces records in default registry.
- `Actors.DefaultRegistry`: Global singleton registry instance.
- `Registry:Commit(actorId, patch, expectedRevision)`: Atomic patch for identity, appearance, persona, knowledge, extensions, social, world, providerLease, personalInventory.
- `Registry:AcquireProvider`, `MaterializeProvider`, `DematerializeProvider`, `ReleaseProvider`, `SwitchProvider`: Provider lease lifecycle.

### B. Social Authority (`PsychopatzCore.Actors.Social` / `PsychopatzSocial.lua`)
Location: `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzSocial.lua`
- `Social.SCHEMA_VERSION = 1`
- `Social.NormalizeTargetKey(value)`: Validates prefixes `npc:`, `actor:`, `player:`, `steam:`.
- `Social.NewState(source)`: Normalizes and bounds state (`personality`, `personalityOverrides`, `recentEventIDs` [limit 128], `relationships`).
- `Social.Validate(state)`: Checks schema version, structure, score bounds (`approval` [-100..100], `respect` [-100..100], `familiarity` [0..100]), and memory format.
- `Social.Get(state, targetKey)`: Returns deep clone of relationship or nil.
- `Social.GetOrCreate(state, targetKey)`: Retrieves or initializes zeroed relationship.
- `Social.SetPersonality(state, personality, authority, expectedRevision)`: Requires `authority == "server"`.
- `Social.RecordAuthorizedEvent(state, event)`: Server-authoritative event application (`event.authority == "server"` and `event.authorized == true`). Rejects duplicates via `recentEventIDs`. Bounds deltas and appends memory (limit 64). Increments revisions.
- `Social.ToPayload(state)`: Validated serialization export.
- **Critical Gap Found in P0A:** `Social.NewState` / `normalizeRelationship` currently drops unknown fields and does not support an `extensions` dictionary on relationship entries.

### C. Semantics Foundation (`PsychopatzCore.Semantics`)
Location: `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/`
- `Semantics.RegisterConcept(definition)`: Registers concept ID, parent, and surface aliases in `PsychopatzSemanticRegistry`.
- `Semantics.RegisterSpeechAct(definition, metadata)`: Registers speech act ID, intent, and examples.
- `Semantics.RegisterPattern(definition)`: Registers ordered regex/token pattern matchers.
- `Semantics.Parse(text, options)`: Returns semantic IR candidate set via fuzzy, concept, and pattern matchers.
- `Semantics.DialogueRouter.New(spec)`: Stateful router handling IR decisions, context resolution, and candidate arbitration.
- `Semantics.DialogueTurn.Parse(text, parseCandidates, options)`: Compound sentence splitting and turn segmentation.
- `Semantics.DialogueState.New(spec)`: Tracks `pendingQuestion`, `pendingRequest`, recent speech acts, topics, and references.
- `Semantics.Context.RegisterResolver(id, resolver, priority)`: Priority-ordered context resolution pipeline.

### D. Conversation Service (`PsychopatzCore.Conversation`)
Location: `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Conversation/`
- `PsychopatzActorConversationService.New(spec)`: Offline/client actor conversation service orchestrating `DialogueRouter`, `DialogueTurn`, and `DialogueState`. Automatically projects actor identity, persona, personality, and relationships into context. Supports injected `router`, `responsePlanner`, `localize`, and capability invocation.
- `PsychopatzSocialFlavor.Register(flavorID, definition)`: Deterministic flavor variant resolver using seed, context, and speaker rules.
- `PsychopatzConversationMessage.New(spec)`: Cross-mod message envelope with delivery receipts.

### E. Capability Catalog (`PsychopatzCore.Kernel.PC_CapabilityCatalog`)
Built-in capabilities: `core.runtime`, `core.collections`, `core.events`, `core.semantics`, `core.translation`, `core.conversation`, `core.voice`, `core.journal`, `core.spatial`, `core.world_region`, `core.deterministic_content`, `core.actors`, `core.inventory`, `core.currency`, etc.
Adopter convenience packs:
- `pack.trading_common` (`core.runtime`, `core.inventory`, `core.currency`, `core.actors`, `core.conversation`, `core.debug`)
- `pack.trading_abstract` (adds `core.radio_device_state`, `core.radio_os`)
- `pack.trading_hoomans` (adds `core.debug_hub`, `core.teleport`)

---

## 3. Field-by-Field Relationship Ownership Matrix

Comparison between Core Social (`PsychopatzSocial.lua`) and Project Hoomans (`record.social` via `PNC_RelationshipTypes*.lua` and `PNC_RelationshipService*.lua`):

### Top-Level Social State (`actor.social` / `record.social`)

| Field | Core Social | Hoomans `record.social` | Semantics & Scale | Ownership Disposition |
|---|---|---|---|---|
| `schemaVersion` | 1 | 4 | Numeric version | **SHARED-CORE** (Core version 1; Hoomans tracks internal migration version) |
| `revision` | Integer >= 0 | Integer >= 0 | Monotonic mutation revision | **SHARED-CORE** |
| `personality` | Table | Table | Big Five / behavioral traits (normalized by ProfileTypes) | **SHARED-CORE** |
| `personalityOverrides` | Table | Table | Trait/archetype overrides | **SHARED-CORE** |
| `relationships` | Map `[targetKey]` | Map `[targetKey]` | Map of directed relationships | **SHARED-CORE** |
| `recentEventIDs` | Array (limit 128) | Array (limit 64) | Deduplication log for applied event IDs | **SHARED-CORE** |
| `lastEvaluatedAt` | _(in rel)_ | Number (hours) | World age timestamp of last decay/evaluation | **SHARED-CORE** (promoted to shared or kept per rel) |
| `morale` | _(none)_ | Number [-100..100] | Current NPC emotional morale state | **HOOMANS-EXTENSION** (`social.extensions.ProjectHoomans.morale`) |
| `moraleBaseline` | _(none)_ | Number [-100..100] | Target resting morale | **HOOMANS-EXTENSION** (`social.extensions.ProjectHoomans.moraleBaseline`) |
| `conduct` | _(none)_ | Table | Observed crimes, trespass, violations | **HOOMANS-EXTENSION** (`social.extensions.ProjectHoomans.conduct`) |

### Per-Target Relationship Entry (`relationships[targetKey]`)

| Field | Core Social | Hoomans `relationships[targetKey]` | Semantics & Scale | Ownership Disposition |
|---|---|---|---|---|
| `targetKey` | string (`npc:`, `actor:`, `player:`, `steam:`) | key in map (`npc:<id>`, `player:<acc>:<uuid>`) | Target entity identifier | **SHARED-CORE** |
| `targetKind` | _(derived from key)_ | "player" \| "npc" | Derived from `EntityRef.Parse` | **SHARED-CORE** (derived/stored) |
| `targetID` | _(derived from key)_ | string | Derived from `EntityRef.Parse` | **SHARED-CORE** (derived/stored) |
| `approval` | Number [-100..100] | Number [-100..100] | Direct alignment/sentiment | **SHARED-CORE** |
| `respect` | Number [-100..100] | Number [-100..100] | Competence/status valuation | **SHARED-CORE** |
| `familiarity` | Number [0..100] | Number [0..100] | Degree of acquaintance/knowledge | **SHARED-CORE** |
| `revision` | Integer >= 0 | Integer >= 0 | Relationship mutation counter | **SHARED-CORE** |
| `lastEventAt` | Number | _(same as `lastInteractionAt`)_ | Timestamp of last event | **SHARED-CORE** |
| `baselineApproval` | _(none)_ | Number [-100..100] | Archetype/default resting approval | **HOOMANS-EXTENSION** |
| `baselineRespect` | _(none)_ | Number [-100..100] | Archetype/default resting respect | **HOOMANS-EXTENSION** |
| `state` | _(none)_ | Enum (`unknown`, `neutral`, `friend`, `rival`, `enemy`) | Discrete attitude state derived from scores | **HOOMANS-EXTENSION** / Derived helper |
| `previousState` | _(none)_ | Enum | Previous discrete attitude state | **HOOMANS-EXTENSION** |
| `memories` | Array (limit 64) | Array (limit 20) | Bounded memorable events | **SHARED-CORE** (see memory matrix below) |
| `saturation` | _(none)_ | Map `[eventType]` | Diminishing returns tracker | **HOOMANS-EXTENSION** |
| `cooldowns` | _(none)_ | Map `[cooldownID]` -> hour | Action cooldown timestamps | **HOOMANS-EXTENSION** |
| `interactionJournal`| _(none)_ | Array (limit 80) | Presentation history for UI interaction diary | **HOOMANS-EXTENSION** |
| `interactionRevision`| _(none)_ | Integer >= 0 | Journal sequence counter | **HOOMANS-EXTENSION** |
| `lastInteractionAt` | _(none)_ | Number | Timestamp of last interaction | **SHARED-CORE** (aliased to `lastEventAt`) |
| `lastEvaluatedAt` | _(none)_ | Number | Timestamp of last decay evaluation | **HOOMANS-EXTENSION** |
| `bond` | _(none)_ | Table (`schemaVersion`, `class`, `kind`, `establishedAt`, `source`) | Durable family/friend/romance bond | **HOOMANS-EXTENSION** (`extensions.ProjectHoomans.bond`) |
| `extensions` | _(MISSING)_ | _(none)_ | Adopter namespaced extension dictionary | **SHARED-CORE CONTRACT REQUIRED (P0B/P1A)** |

### Memory Entry (`memories[]`)

| Field | Core Social Memory | Hoomans Memory | Ownership Disposition |
|---|---|---|---|
| `id` | String required | String required | **SHARED-CORE** |
| `type` | String | String | **SHARED-CORE** |
| `aboutKey` | Target key | Target key (`aboutKey`) | **SHARED-CORE** |
| `createdAt` | Number | Number | **SHARED-CORE** |
| `approvalEffect` | Number | Number [-100..100] | **SHARED-CORE** |
| `respectEffect` | Number | Number [-100..100] | **SHARED-CORE** |
| `familiarityEffect`| Number | _(none)_ | **SHARED-CORE** |
| `tags` | Map `[string] -> true` | Map `[string] -> true` | **SHARED-CORE** |
| `moraleEffect` | _(none)_ | Number [-100..100] | **HOOMANS-EXTENSION** / Opaque in memory |
| `strength` | _(none)_ | Number [0..1] | **HOOMANS-EXTENSION** / Optional shared |
| `decayPerDay` | _(none)_ | Number [0..1] | **HOOMANS-EXTENSION** / Optional shared |
| `permanent` | _(none)_ | Boolean | **HOOMANS-EXTENSION** / Optional shared |
| `shareable` | _(none)_ | Boolean | **HOOMANS-EXTENSION** / Optional shared |
| `knowledgeSource` | _(none)_ | Enum (`experienced`, `witnessed`, `told_...`) | **HOOMANS-EXTENSION** |
| `sourceKey` | _(none)_ | String entity key | **HOOMANS-EXTENSION** |
| `lastEvaluatedAt` | _(none)_ | Number | **HOOMANS-EXTENSION** |
| `eventSequence` | _(none)_ | Number | **HOOMANS-EXTENSION** |

---

## 4. Dynamic Trading Call and Dependency Map

### A. Mod Dependency Graph (`mod.info`)
```text
PsychopatzCore (Independent foundation)
      ^
      | require
DTCommon (require: PsychopatzCore, MarketSense)
      ^                     ^
      | require             | require
DTAbstract              DTHoomans (require: DTCommon, ProjectHoomans)
(Standalone radio/remote)   (Optional physical Hoomans bridge)
```

### B. Standalone Conversation Entry Points in DT
- `DTCommon_TalkService.lua`: Server-authorized bridge to Core's `PsychopatzActorConversationService`.
  - Requires `PsychopatzCore/Conversation/PsychopatzActorConversationService`.
  - Resolves actor through `DTCommon.CoreActorPolicy.ResolveActor(record)`.
  - Builds conversation context using `DTCommon.WorldKnowledge.BuildConversationContext(traderID, ...)`.
  - Does NOT require or call any `PNC.*` or `ProjectHoomans` module.
- `DTCommon_TradeWindow.lua`: Standalone client trade window fallback (`DTCommon.TradeWindow.Open`) used when `PNC.InventoryWindow` is absent.
- `DTCommon_CoreActorPolicy.lua`:
  - `Policy.PriceContext(record, player)`: Reads `PsychopatzCore.Actors.Social.Get(social, playerKey)` directly! Calculates price discounts based on `approval`, `respect`, and `familiarity`.
  - `Policy.ResolveActor(record)`: Calls `PsychopatzCore.Actors.Get(actorID)`.

### C. DTHoomans Integration Entry Points (The Bridge)
File: `Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua`
- Calls into Project Hoomans:
  1. `PNC.Factions.GetNPCAffiliation(npcID)`: Queries affiliation role (`trader` or `guard`).
  2. `PNC.Semantics.DialogueChoiceRegistry.RegisterProvider`: Registers trade choice provider (`dynamictrading.trader`) with `whats_up` semantic hub hook.
  3. `PNC.API.Conversations`:
     - `RegisterCategory("dthoomans:caravan_referral", ...)`
     - `RegisterBlock("dthoomans:caravan_referral_basic", ...)`
     - `GetCategory("projecthoomans:trade")`
     - `RegisterBlock("dthoomans:trade_basic", ...)`
     - `RegisterCategoryEligibilityProvider("dthoomans:caravan_roles", ...)`
- **Current Limitation:** In the current codebase, trader story / small-talk / rumor dialogue is only packaged in `DTHoomans` under `media/conversation/caravan/shared/{language}/basic.json` via Hoomans block registry. When Hoomans is absent, DT has only `DTCommon_TalkService` (a minimal shell over Core ActorConversationService) and `DTCommonTradeWindow`, but no standalone DT semantic pack registered in Core!
- **Target Resolution (P3):** Create a rich Dynamic Trading semantic pack registered directly in PsychopatzCore (`pack.trading_story` / `DT_SemanticPack`) providing greetings, role queries, stories, rumors, and trade choices without Hoomans.

---

## 5. Classification of Hoomans Semantic & Dialogue Modules

Inventory of Hoomans semantic and conversation subsystems grouped by role:

### Category G: Generic Mechanism Candidates for Core
*(Domain-agnostic, reusable conversation and semantic mechanisms that have no Hoomans gameplay policy or PNC record coupling)*
1. `shared/PNC/Conversation/Blocks/PNC_ConversationRules/`: Rule evaluation primitives (`Internal.Compare`, numeric gates, time matches, weather matches).
2. `shared/PNC/Conversation/Blocks/PNC_ConversationTextLoader*.lua`: Modular JSON text translation catalog loader.
3. `shared/PNC/Conversation/Blocks/PNC_ConversationRegistry/`: Category, weighted block, and choice registry logic (can be promoted into a generic Core Dialogue Pack Registry or semantic pack mechanism).
4. `shared/PNC/Semantics/PNC_ActorConversationContext*.lua`: Context projection logic translating actor records and relationships into normalized conversation scope.

### Category H: Hoomans Content & Policy (MUST REMAIN IN PROJECT HOOMANS)
*(Gameplay, NPC behavior, AI, physical interaction, and Hoomans-specific content)*
1. `shared/PNC/Conversation/Memory/Events/`: Hoomans-specific gossip, backstories, and topic memory catalogs (`Events_Gossip.lua`, `Backstories.lua`).
2. `shared/PNC/Conversation/PNC_ConversationGifts.lua`: Gift offering, acceptance, item taking, and social consequence.
3. `shared/PNC/Conversation/PNC_ConversationScene*.lua`: Scene lease, combat ceasefire, threat negotiation.
4. `server/PNC/Conversation/ConversationAuthority/`: Server-side recruit, settlement admission, companion orders, departure.
5. `server/PNC/Conversation/LLMSocialReaction/`: LLM prompt construction, tool schemas, and social admission leases.
6. `server/PNC/Semantics/ActionPlanProviders/`: Hoomans NPC action plans (Camp, Item consumption/give/refill, Path, Wait, Follow, Attack).
7. `server/PNC/Semantics/CampSiteResolver/`: Camp site geometry, room enumeration, shelter queries.
8. `server/PNC/Semantics/Inventory/`: NPC inventory query service, item selection, weapon/ammo matching.
9. `server/PNC/Networking/Handlers/PNC_ServerSemantic*CommandHandler.lua`: Multi-player packet handlers for cognition, tasks, and social interactions.
10. `client/PNC/Conversation/Blocks/ConversationComposer/*`: Hoomans UI dialogue composer for recruit, departure, gifts, and companion menus.

### Category A: Compatibility & Adapters over Core
1. `shared/PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua`: Projects Hoomans records to Core Social and forwards authorized events.
2. `shared/PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua`: Adapts Core provider leases to Hoomans body lifecycle.
3. `shared/PNC/Core/Persistence/PNC_Persistence_CoreMigration.lua`: Handoff adapter to `PsychopatzCore.Actors.Migration`.
4. `shared/PNC/Core/Persistence/PNC_Persistence_CoreKnowledge.lua`: Adapts Hoomans facts to Core knowledge.
5. `client/PNC/Integrations/PNC_PsychopatzCoreRadio*.lua`: UI integration with Core Radio OS.

### Category O: Obsolete / Duplicate Modules
1. Private duplicate relationship normalizers outside `PNC_RelationshipTypes_Public.lua`.
2. Hardcoded relationship delta calculations in UI panels that bypass `RelationshipService` / `RecordAuthorizedEvent`.

---

## 6. Migration Hazards and Focused Test Baselines

### Migration Hazards
1. **Field Loss on Core Social Normalization:**
   `PsychopatzSocial.lua` (`normalizeRelationship`) currently strips all unlisted properties. If Hoomans extensions (`bond`, `saturation`, `cooldowns`, `interactionJournal`) are passed to Core without a namespaced extension envelope, they are deleted.
   *Mitigation:* Introduce `extensions` map in Core Social relationship and top-level schema; preserve opaque adopter extensions during normalize, validate, serialize, and deserialize.
2. **Actor & Target Key Desynchronization:**
   Hoomans uses `npc:<id>` and `player:<account>:<uuid>`. Core supports `npc:`, `actor:`, `player:`, `steam:`. When an NPC is migrated to Core, its canonical `actorId` must remain stable and map 1:1 with `targetKey`.
3. **Repeated Legacy Import Forking:**
   `Migration.Import` must record provenance in `Migration.Store` (`sourceHash`, `mappingKey`, status `already_imported`). Loading an existing save must never duplicate actors or overwrite newer canonical relationship deltas.
4. **Adopter Removal/Re-addition (Hot-Plug):**
   If Hoomans is removed from a save: Core actor identity and base relationship (`approval`, `respect`, `familiarity`, memories) must remain intact. Dynamic Trading must continue functioning. When Hoomans is re-added, Hoomans extension data must be restored without data loss.
5. **DynamicTrading Local Worktree Preservation:**
   `Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua` has a tracked edit hooking the trade choice provider into `whats_up` semantic hub. This work must be preserved.

### Focused Test Baselines (Verified Passing)
- **PsychopatzCore:**
  - `lua tests/psychopatz_npc_social_smoke.lua` -> PASS
  - `lua tests/psychopatz_npc_actor_smoke.lua` -> PASS
  - `lua tests/psychopatz_npc_acceptance_matrix_smoke.lua` -> PASS
  - `lua tests/psychopatz_actor_conversation_service_smoke.lua` -> PASS
  - `lua tests/psychopatz_actor_conversation_restore_smoke.lua` -> PASS
  - `lua tests/psychopatz_semantic_dialogue_turn_smoke.lua` -> PASS
  - `lua tests/psychopatz_capability_contract_smoke.lua` -> PASS
- **DynamicTrading:**
  - `lua tests/dt_npc_foundation_policy_smoke.lua` -> PASS
  - `lua tests/dt_npc_foundation_service_smoke.lua` -> PASS
  - `lua tests/dt_npc_provider_adapter_smoke.lua` -> PASS
  - `lua tests/dt_provider_hotswap_persistence_smoke.lua` -> PASS
  - `lua tests/dt_guard_referral_client_smoke.lua` -> PASS
  - `lua tests/dt_guard_referral_server_smoke.lua` -> PASS
- **ProjectHoomans:**
  - `python3 tests/run_tests.py pnc_relationship_foundation_smoke --jobs 1` -> PASS
  - `python3 tests/run_tests.py pnc_conversation_semantic_runtime_smoke --jobs 1` -> PASS
  - `python3 tests/run_tests.py pnc_npc_foundation_social_adapter_smoke --jobs 1` -> PASS
  - `python3 tests/run_tests.py pnc_conversation_smoke --jobs 1` -> PASS
  - `python3 tests/run_tests.py pnc_conversation_authority_smoke --jobs 1` -> PASS
  - `python3 tests/run_tests.py pnc_conversation_category_eligibility_smoke --jobs 1` -> PASS
