# NPC Knowledge

NPC knowledge is a server-authoritative, sparse notes system. It separates:

- Truth: data owned by an NPC record or another truth provider.
- Knowledge: what one player-character UUID has discovered about that NPC.
- Evidence: the normalized observations that support that knowledge.

Persistent data is `PNC_NPCKnowledge`, indexed as `byCharacter[uuid].byNPC[npcID]`. Absence means unknown. The store never creates an all-player/all-NPC descriptor matrix.

The shared registry exposes descriptor, category, provider, evidence-source, and resolver registries. The server service owns persistence, validation, evidence pruning, resolution, disclosure, and server snapshots.

Normal dossier snapshots include only discovered descriptor values and safe presentation data. They never contain provider truth. Authorized Knowledge Laboratory snapshots are a separate command and can include truth for comparison.

## UI

**NPC Dossier** is opened from the NPC context menu or conversation. It uses the shared portrait panel, safe identity header, registry-derived category tabs, a compact overview, and a Notes tab when journal/manual notes exist. Rows are produced by `PNC_KnowledgePresentation` and `PNC.KnowledgeUIRenderers`, not by descriptor-specific controls.

**NPC Knowledge Lab** is admin-only, available from the PsychopatzCore Debug Hub, NPC debug context menu, and Relationship Laboratory. Its initial snapshot is a descriptor summary table; raw evidence is requested only for the selected descriptor. The truth toggle causes a new server request and does not retain truth when off.

Built-in descriptors currently expose the existing NPC social profile through `pnc_social_profile`: personality dimensions, orientation, food preference, and social/romance preference values. Private orientation is disclosure-only; it cannot be inferred from familiarity or behavioral evidence.

Social-event mappings are isolated in `PNC_KnowledgeSocialEventAdapter.lua`. Adding a new game event mapping does not modify the knowledge persistence or resolver service.

Limits are deterministic: 64 evidence entries per NPC, 16 per descriptor, 64 journal entries, 16 manual notes, and 512 characters per manual note. Direct disclosures have pruning priority.

## Unified Cross-Mod Core Integration

Shared cross-mod actor knowledge and identity exchange live in `PsychopatzCore` (`PsychopatzActorKnowledge`, `PsychopatzActorIdentityExchange`, `PsychopatzActorKnowledgeServer`, `PsychopatzActorKnowledgeClient`) and are shared across `ProjectHoomans`, `DTAbstract`, and `DTHoomans`:

- **Bidirectional sync**: Core snapshots mirror into `ProjectHoomans` (`PNC_MapCoreActorKnowledge`), and committed `ProjectHoomans` disclosures write back into Core via `PsychopatzCore.ActorKnowledgeServer.SyncDisclosedFacts`.
- **Unified familiarity thresholds** (`PsychopatzActorIdentityExchange.FAMILIARITY_THRESHOLDS`):
  - Available from the start (`0`): `identity_name` (after mutual name exchange), `identity_nickname`, `faction` (`faction.identity`).
  - Relationship-gated: `identity_surname` (`20`), `identity_full_name` (`25`), and backstory tiers (`25 / 50 / 75`).
- **Identity exchange rules**: No persisted fake aliases and no `"Lie about your name"` suggestion button (lie detection remains active for free-text input). Below familiarity `25`, initial name disclosure reveals nickname if present, else first name.
- **WorldKnowledge persistence & NPC-to-NPC sharing**: `PsychopatzCore.WorldKnowledge` owns single-copy ModData persistence (`PsychopatzCore.WorldKnowledge`, pruning expired facts on save) so neither `ProjectHoomans` nor `DynamicTrading` duplicates WorldKnowledge payloads. Cooperative NPC-to-NPC social events trigger lightweight mutual `PropagateConversation` exchanges (`max = 2` facts, 24h in-memory pair cooldown, skipping `enemy`/`rival` pairs).
