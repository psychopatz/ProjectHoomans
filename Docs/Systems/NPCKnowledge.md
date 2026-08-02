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
