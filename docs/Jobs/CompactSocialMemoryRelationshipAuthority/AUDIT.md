# Initial Audit — Compact Social Memory & Relationship Authority

**Scope:** P0 / H0 source-verified participant audit. No production schema changes applied.

## Existing systems observed

Current repository inspection verified exact source paths under `Contents/mods/ProjectHoomans/42.20/media/lua/`:

- `server/PNC/Social/PNC_RelationshipService.lua` + 11 submodules (`Context`, `Commit`, `EventMutation`, `EventMutation_Apply`, `MemoryCommands`, `Maintenance`, `Queries`, `Bond`, `Romance`, `InteractionJournal`, `Consequences`, `PersonalBoundary`) and `shared/PNC/Core/Relationships/*` (`MEMORY_LIMIT = 20`, `RECENT_EVENT_ID_LIMIT = 64`, `INTERACTION_JOURNAL_LIMIT = 80`, `eventSequence`, `relationship.revision`).
- `server/PNC/Social/PNC_SocialEventService.lua` + submodules (`Context`, `Validation`, `Observers`, `Process`, `Process_Transaction`, `Process_Bridges`, `Emit`) and `shared/PNC/Core/Relationships/PNC_SocialEventDefinitions.lua` (25 event types with two-phase `Conduct` + `RelationshipService` commit and faction/knowledge bridges).
- `server/PNC/Social/PNC_ConductService.lua` + `shared/PNC/Core/Conduct/*` (7-dimension objective conduct ledger stored in `social.extensions.ProjectHoomans.conduct` and `PlayerCharacters.Registry`).
- `server/PNC/Knowledge/PNC_KnowledgeSocialEventAdapter.lua` & `PNC_NPCKnowledgeService.lua` (`GlobalModData["PNC_NPCKnowledge"]`, projected via `PNC_Persistence_CoreKnowledge.lua`).
- `shared/PNC/Conversation/Memory/PNC_ConversationMemory*.lua` (`record.memory` / `raw.m`: `s` TODAY max 8, `t` topic bitmasks max 4 players, `l` durable max 6).
- `shared/PNC/ConvoEngine/Interaction/Evidence.lua` & `EvidenceAdapters.lua` (`SESSION`, `TODAY`, `DURABLE`, max 16 rows) and `shared/PNC/ConvoEngine/Social/*` (`Director`, `Conversation`, `ChoicePolicy`, `TurnPolicy`, `ConsequenceService`).
- `shared/PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua` (`ToCoreSocial`, `FromCoreSocial`, `SyncToCore`).

## Critical H0 overlap & convergence findings

1. **`PNC_EntityRef.lua` key mismatch (L43-87)**: accepts only `^npc:([^:]+)$` and 3-segment `^player:([^:]+):([^:]+)$`, rejecting `actor:*`, colon-containing `npc:*` IDs, and 2-segment `player:*` keys. In `FromCoreSocial` (`PNC_Persistence_CoreSocial.lua:L169-171`), `Types.NormalizeRelationship` / `Types.NormalizeMemory` silently drops foreign (e.g. `DynamicTrading`) edges/memories whose keys do not match Hoomans-only patterns.
2. **`PNC_RelationshipMath.RecalculateRelationship` overwrite hazard (L61-114)**: recomputes `approval = baselineApproval + sum(Hoomans memories)` and `respect = baselineRespect + sum(Hoomans memories)`, which overwrites direct Core deltas from other adopters unless unified with Core portable math.
3. **Generic fields tucked in extension bag (`PNC_Persistence_CoreSocial.lua:L53-65`)**: `baselineApproval`, `baselineRespect`, `state`, `previousState`, `cooldowns`, `saturation`, `lastInteractionAt`, `lastEvaluatedAt` belong on first-class Core relationship edges rather than `extensions.ProjectHoomans`.
4. **Numeric dimensions audited**: Personal relationships persist 3 numeric scores (`approval`, `respect`, `familiarity`); `fear` and `affinity`/`affiliation` on personal edges are derived quadrants/NLU features (numeric `trust`/`fear` exist only on inter-faction diplomacy in `PNC_FactionTypes/Relations.lua`).

## Field & system classification

- **Core-generic / duplicate-to-migrate**: `schemaVersion`, `revision`, `lastEvaluatedAt`, `recentEventIDs`, `personality`, `personalityOverrides`, directed `relationships[targetKey]` (`approval`, `respect`, `familiarity`, `baselineApproval`, `baselineRespect`, `state`, `previousState`, `cooldowns`, `saturation`, `lastEventAt`, `memories`), portable event metadata from `PNC_SocialEventDefinitions.lua` (via CodeBuilder `PNC/SocialPolicy`), and broadened `PNC_EntityRef.lua` parsing.
- **Hoomans-specific authority**: `ConductService`, `NPCKnowledgeService`, `bond` (`none`/`friend`/`lover`/`family`), `morale`/`moraleBaseline`, `interactionJournal`/`interactionRevision`, Faction diplomacy/intent (`PNC_FactionTypes/Relations`, `PNC_FactionIntent`), `ConversationMemory` ring buffers (`raw.m`), and physical NPC social hooks (`PNC_SocialEventHooks*`).
- **Derived projection/cache**: `PNC_RelationshipPresentation.BuildForConversation`, `Evidence` (`SESSION`/`TODAY`/`DURABLE`), `SocialDirector`, `PNC_CoreActorRuntimeView`, `runtime.relationshipDebugChanges`, `conduct.scores`.

## Cross-repo ownership conclusion

Generic portable relationship/memory state evolves in `PsychopatzCore` `PsychopatzSocial`. Hoomans reconciles `PNC_EntityRef`, `PNC_RelationshipTypes_Public`, `PNC_Persistence_CoreSocial`, `PNC_RelationshipMath`, and `PNC_SocialEventDefinitions` in parent P4 (`H1-H4`) so there is one generic writable relationship history without breaking Hoomans conduct/knowledge/evidence/director contracts.
