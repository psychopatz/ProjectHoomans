# Compatibility Path Classification — P8A Gate

Scope: All retained compatibility paths, aliases, adapters, and forwarders across the Project Hoomans codebase.

## Requirements

Under P8A, every retained compatibility path must be classified as:
1. **Permanent public API**: Retained for backward-compatible Lua module resolution across PZ mod require paths without duplicate state or logic.
2. **External integration requirement**: Required by external workshop mods (DynamicTrading, Bandit, Necroa, ProjectALife, Companion Dogs).
3. **Legacy-save migration**: Required to deserialize and upgrade historical character/world save data.
4. **Temporary**: Must be removed before completion.

Zero temporary compatibility shims remain in the repository.

---

## 1. Permanent Public Require Compatibility

These paths provide stable backward compatibility for callers and scripts requiring legacy module locations. Each is a stateless forwarder that returns the identical canonical domain table.

| Legacy Path | Canonical Target | Reason & Invariants |
| --- | --- | --- |
| `client/PNC/UI/PNC_NPCTypePalette.lua` | `client/PNC/Presentation/PNC_NPCTypePalette.lua` | Palette query moved to Presentation. Pure forwarder returns the exact same palette/color table; zero duplicate state; function bytes identical. Maintained callers use canonical Presentation entry. |
| `shared/PNC/Activities/PNC_WorkItems.lua` | `shared/PNC/Production/PNC_WorkItems.lua` | Work item capability and requirements moved to Production owner. Pure forwarder; exact startup order and table identity preserved. |
| `shared/PNC/Activities/PNC_ServerLogistics.lua` | `shared/PNC/Production/PNC_ServerLogistics.lua` | Logistics coordination moved to Production. Pure forwarder; retains canonical table identity. |
| `server/PNC/Networking/PNC_LLMSocialReactionService.lua` | `shared/PNC/Conversation/PNC_LLMSocialReactionService.lua` | LLM social-reaction service moved behind Conversation authority. Networking command routing forwards to canonical Conversation entry. |
| `server/PNC/Networking/PNC_LLMSocialReactionPolicy.lua` | `shared/PNC/Conversation/PNC_LLMSocialReactionPolicy.lua` | LLM social-reaction policy moved behind Conversation authority. Pure forwarder; zero duplicated policy state. |
| `client/PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel.lua` | `client/PNC/Identity/PNC_UniqueNPCDraft.lua` & `PNC_UniqueNPCDefinitionStore.lua` | Identity authoring moved outside UI. Pure forwarder to canonical draft/store tables. |

---

## 2. External Integration Requirements

These modules and adapters interface with external mods and base Project Zomboid engine hooks:

| Path | Integration Target | Reason |
| --- | --- | --- |
| `shared/PNC/Compatibility/PNC_DynamicTrading_Compat.lua` | DynamicTrading mod | Exposes trade item value, stock queries, and merchant dialog bindings. |
| `client/PNC/Compatibility/Mods/Necroa/` | Necroa mod | Zombie caption adapters, mask status checks, and viral infection dialogue. |
| `client/PNC/Compatibility/Mods/ProjectALife/` | ProjectALife mod | Event client handling, ALife faction notifications, and territorial warnings. |
| `client/PNC/Compatibility/Mods/Bandits/` | Bandit mod | Hostility checks, faction warnings, and raider encounter dialogue integration. |
| `client/PNC/Compatibility/Mods/CompanionDogs/` | Companion Dogs mod | Canine companion interaction, feeding, and greeting speech realization integration. |
| `shared/PNC/Core/Persistence/PNC_Persistence_Core*.lua` | PsychopatzCore / Engine save hooks | Retained public optional persistence adapters for historical mod event dispatch. |

---

## 3. Legacy-Save Migration Paths

These codecs and repair routines operate during deserialization to safely upgrade legacy saved games:

| Path | Schema Scope | Migration Capability |
| --- | --- | --- |
| `shared/PNC/Core/Persistence/PNC_Persistence_Repairs.lua` | NPC Save Envelope | Normalizes schema versions across B41/B42 save revisions (`NormalizeVersions`). |
| `shared/PNC/Core/Persistence/PNC_Persistence_HealthCodec.lua` | NPC Health & Wounds | Sanitizes legacy health structures, bandaged state, and wound indices. |
| `shared/PNC/Core/Persistence/PNC_Persistence_Primitives.lua` | Voice & Appearance | Validates appearance tables and restores legacy voice profile identifiers. |
| `shared/PNC/Core/Persistence/PNC_Persistence_RecordState.lua` | Relationship & Progression | Sanitizes legacy follower abandonment, hostility flags, and colonist departure status. |
| `shared/PNC/Core/Persistence/PNC_Persistence_Reset.lua` | Save Integrity | Detects corrupted or unrecoverable NPC records and executes bounded reset. |

---

## 4. Temporary Paths

**None.** All temporary shims (including the historical mixed-owner `PNC_JobsRuntime` registrar) have been removed from the repository. No temporary facades remain.
