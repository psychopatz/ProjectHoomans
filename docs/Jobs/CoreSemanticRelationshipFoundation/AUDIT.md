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
---

## Post-P7 independent verification — acceptance reopened

A second source/test audit on 2026-11-02 checked the agent's completion claim against current production code and adversarial probes.

### Verified repository/test state

- Core `03fd546`: clean, ahead 4.
- DynamicTrading `30e745f6`: ahead 3; the pre-existing tracked `DTHoomans_Conversation.lua` edit remains preserved.
- ProjectHoomans `aa9895ca`: clean, ahead 5.
- Dynamic Trading full suite: `43/43`.
- Hoomans focused new tests: `2/2` under the intended runner.
- Hoomans broad suite: `978/984`; `pnc_composition_bootstrap_smoke` is directly stale because of this job's new composition import, while the other five failures predate this job's touched files and require baseline classification.
- Changed runtime Lua parses with `luac5.3 -p`; changed committed diffs pass `git diff --check`.

### Acceptance-invalidating evidence

1. **Player identity fork:** DT uses `player:online:<id>` / `player:user:<name>`; Hoomans uses persistent `player:<account>:<characterUUID>` / SP-slot + UUID. The same player can therefore receive separate Core relationships.
2. **Destructive stale Hoomans sync:** a direct reproduction showed `SyncToCore` can report success while deleting a newer DT memory and `DynamicTrading` extension from Core.
3. **Hoomans pack schema mismatch:** its concepts/dialogue blocks/multi-word patterns do not conform to Core's actual registry/matcher contract. A wellbeing-good block registered with no gates/nodes/text and could win at approval -100.
4. **Semantic pack residue:** pack-level capabilities are not enforced for dialogue/parser content; unregistering the DT pack still leaves `trade` parsing as DT `TRADE`.
5. **Incomplete standalone DT semantic coverage:** greeting/trade/rumor work, but representative identity/whereabouts utterances such as `who are you`, `where are you heading`, and `where did you come from` have no intended semantic result.
6. **P6 test scope mismatch:** the existing hot-plug smoke manipulates Core payloads directly and does not exercise real DT/Hoomans production lifecycle/adapters.

These findings supersede the earlier P7 developer-complete claim. See PROGRESS P8 and ROADMAP P8-P12.


---

## Second post-closeout production-path audit — P13-P15 required

A second independent audit after commits through Core `bc1f7a8`, DynamicTrading `03318881`, and ProjectHoomans `e78f4fb6` re-ran focused/full suites and adversarial production paths.

### Positive evidence

- Core focused identity/semantic lifecycle/dialogue-flow/pack tests pass.
- Dynamic Trading full runner passes `43/43`.
- Hoomans focused P8B/P10/P12 tests pass.
- Hoomans broad runner is `981/986`; the same five older failures remain and the goal-caused composition failure is fixed.
- P8B preserves DT memories/extensions across stale and subsequent Hoomans writes.
- P10 Hoomans patterns and wellbeing gates behave correctly when invoked with the intended Hoomans capabilities.
- Changed corrective Lua parses; `git diff --check` is clean.

### New acceptance-invalidating evidence

1. **Real DT-first identity handoff still forks.** Core/DT can issue and mirror a canonical UUID, but later Hoomans `ValidateClaim` rejects it as `unknown_uuid` because its registry has no record, then `EnsureIdentity` creates a different UUID. The prior P8A/P12 tests bypassed the actual Hoomans identity service.
2. **Production conversation capability leak.** `ActorConversationService:Submit` does not pass `effectiveContext.capabilities` into `ParseTurn`. With both packs registered, a DT-only-capability conversation parses `follow me` as Hoomans `COMMAND`.
3. **P11 factual coverage incomplete.** Several required utterance families still do not parse, and current whereabouts output is a hardcoded "southern outpost / central market" sentence selected before real DT world-knowledge evidence.
4. **P12 final matrix misses all three boundaries above.** It is useful for interleaved social-state preservation but is not sufficient final hot-plug acceptance.

These findings supersede the P8-P12 READY FOR USER LIVE TEST closeout. See ROADMAP P13-P15 and current PROGRESS.

---

## Third independent audit — P16-P17 required

A third independent audit on 2026-11-03 checked the P13-P15 developer-complete claim against actual production paths.

### Verified positive evidence

- P14 is genuinely fixed in production orchestration. With real DT and Hoomans packs registered together:
  - DT-only capabilities + `follow me` -> no Hoomans intent;
  - Hoomans-only capabilities + `trade` -> no DT intent;
  - Hoomans capabilities + `follow me` -> Hoomans COMMAND.
- Required DT utterance families now parse with fuzzy matching disabled.
- The old fabricated southern-outpost/central-market factual line is gone.
- No-evidence destination/news responses are bounded uncertainty/no-news.
- A real published/acquired `market.route` WorldKnowledge fact grounds a generic route answer and returns the real fact ID.
- Dynamic Trading full runner passes `43/43`.
- Project Hoomans broad runner is `982/987`, with the same five older baseline failures.
- Focused Core/Hoomans corrective suites pass; changed Lua and diff checks are clean.

### Remaining acceptance-invalidating evidence

1. **Forgeable P13 provenance:** Core's public deterministic `SignProvenance` can be computed for an arbitrary unknown UUID. When the corresponding fields are placed in player modData, the real Core verifier reports `valid_provenance` and the real Hoomans service accepts the forged UUID as `core_adopted`. The current mechanism is not authoritative proof of Core issuance.
2. **P15 production grounding gap:** destination/origin/settlement success tests inject those values directly into `TalkService.Submit`. No production caller was found providing those answer fields. A real acquired route fact grounds `what route`, but `where are you heading` remains uncertain because canonical destination/next-settlement state is not populated.

These findings supersede the P13-P15 READY FOR USER LIVE TEST closeout. See ROADMAP P16-P17 and current PROGRESS.

---

## Fourth independent audit — P18-P19 required

A fourth independent audit on 2026-11-03 checked the P16-P17 developer-complete claim against production call order and live owner wiring.

### Verified positive evidence

- Core's P16 issuance registry, account binding and save/load API exist.
- Normal legitimate DT-first -> Hoomans identity adoption works.
- P14 capability isolation remains fixed.
- P17 policy fields/setters and TalkService policy consumption work at API level.
- Real WorldKnowledge road-news/route facts return fact-backed responses.
- Dynamic Trading full runner passes `43/43`.
- Hoomans focused P16/P17 tests pass.
- Hoomans broad runner is `982/987`, with the same five older baseline failures.
- changed Lua syntax and `git diff --check` pass.

### New acceptance-invalidating evidence

1. **Mirror-to-authority bootstrap bypass:** an unknown `PNC_CharacterUUID` is not issued initially, but if Core/DT `GetTargetKey` runs first, `GetCharacterUUID` registers that mirror as `source=hoom_adopted`. Real Hoomans then accepts the forged UUID as `core_adopted`. P16 tests use the safer opposite call order.
2. **Live destination/origin wiring missing:** no production runtime caller invokes the new destination/origin setters. The resident-excursion lifecycle already owns destination information but only updates current settlement.
3. **Machine-ID presentation leak:** real Hoomans communities have separate machine `id` and human `name`; DT stores the ID and TalkService concatenates the raw value. Tests use friendly strings as IDs and therefore miss the live presentation problem.
4. **Factual reload unproven:** destination/origin/current policy is queried immediately after seeding; no P17 final test persists/reloads that factual state before dialogue.

### Independent bypass reproduction

- before Core resolution: forged UUID -> `false / not_issued`;
- Core `GetTargetKey` -> canonical key containing forged UUID;
- after Core resolution: `true / source=hoom_adopted`;
- Hoomans `EnsureIdentity` -> forged UUID / `core_adopted`.

These findings supersede the P16-P17 READY FOR USER LIVE TEST closeout. See ROADMAP P18-P19 and current PROGRESS.

---

## Fifth independent audit — P20 required

A fifth independent production-path audit on 2026-11-03 checked the P18-P19 completion claim.

### Accepted evidence

- P18 is genuinely fixed. An unknown `PNC_CharacterUUID` remains `not_issued` after Core `GetTargetKey` runs first; Core generates a fresh authoritative UUID and Hoomans adopts that UUID rather than the forged mirror.
- Production resident excursion now updates canonical DT origin/destination/current state for PREPARING, OUTBOUND, VISITING, RETURNING_HOME and AT_HOME.
- DTHoomans place presentation resolves Hoomans community machine IDs to `community.name`; unresolvable machine IDs are suppressed rather than exposed.
- P14 capability isolation remains green.
- Dynamic Trading full runner passes `43/43`.
- Hoomans focused P18/P19 tests pass.
- Hoomans broad runner remains `982/987` with the same five known baseline failures.
- changed Lua syntax and repository diff checks pass.

### Remaining acceptance-invalidating evidence

1. **FAILED-after-departure bug.** Hoomans normalizes `completedAt` to numeric `0`, but DTHoomans checks `not payload.completedAt`. In Lua `0` is truthy. A real production-handler probe with `departedAt=12, completedAt=0` incorrectly restored current settlement to home and cleared destination.
2. **Persistence proof is same-object continuity.** The trader-record tests retain the same backing simulated storage table/object across the alleged reload. Clearing a local variable does not demonstrate reconstruction from persisted state. WorldKnowledge `Save/Load` is real, but trader-record reload acceptance is still synthetic.
3. **Documentation history was stale.** Dynamic Trading is clean at `89c349ce`; the previously preserved `DTHoomans_Conversation.lua` semantic-hub edit was incorporated into commit `be9e8e10`.

These findings supersede the P18-P19 READY FOR USER LIVE TEST closeout. See ROADMAP P20 and current PROGRESS.

---

## Post-audit P20 resolution — Ready for user live test

The P20 phase addressed and resolved both audit findings:

1. **FAILED excursion lifecycle semantics fixed:**
   - In `DTHoomans_ResidentExcursion.lua`, truthiness checks were replaced with numeric lifecycle comparisons (`departedAt > 0`, `completedAt > 0`, `visitedAt > 0`, `returnStartedAt > 0`).
   - In `PNC_CommunityExcursionService.lua`, lifecycle timestamps are cleanly reset to 0 upon transitioning to `PREPARING`.
   - Regressions in `dt_m10d_resident_excursion_smoke.lua` cover all 6 mandatory failure states, including explicit reproduction of `departedAt = 12, completedAt = 0` (which keeps current settlement `nil` and away, rather than fabricating home).
2. **Reconstructed persistence verified:**
   - In both `dt_standalone_semantic_story_smoke.lua` and `pnc_real_cross_adopter_hotplug_matrix_smoke.lua`, storage is snapshotted (deep-copied), runtime references and sessions are wiped, and storage is reloaded into a fresh table.
   - Distinct Lua object identity is asserted (`reloadedTrader ~= originalTrader`), while canonical policy fields (`home`, `current`, `origin`, `destination`) and loaded WorldKnowledge facts/evidence survive.
   - Failure state (`current = nil, destination = nil, s = AWAY`) and completion state (`current = home, destination = nil, s = READY`) persistence and reload are verified.
3. **Repository status:**
   - Dynamic Trading: `43/43` PASS.
   - Project Hoomans: `982/987` PASS (5 baseline failures unchanged).
   - PsychopatzCore focused suites: ALL PASS.
   - All changed Lua passes syntax and diff checks.

The job is returned to **READY FOR USER LIVE TEST**.
