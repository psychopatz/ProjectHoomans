# NPC Knowledge

NPC knowledge is a server-authoritative, sparse notes system. It separates:

- Truth: data owned by an NPC record or another truth provider.
- Knowledge: what one player-character UUID has discovered about that NPC.
- Evidence: the normalized observations that support that knowledge.

Persistent data is `PNC_NPCKnowledge`, indexed as `byCharacter[uuid].byNPC[npcID]`. Absence means unknown. The store never creates an all-player/all-NPC descriptor matrix.

The shared registry exposes descriptor, category, provider, evidence-source, and resolver registries. The server service owns persistence, validation, evidence pruning, resolution, disclosure, and server snapshots.

Normal dossier snapshots include only discovered descriptor values and safe presentation data. They never contain provider truth. Authorized Knowledge Laboratory snapshots are a separate command and can include truth for comparison.

Built-in descriptors currently expose the existing NPC social profile through `pnc_social_profile`: personality dimensions, orientation, food preference, and social/romance preference values. Private orientation is disclosure-only; it cannot be inferred from familiarity or behavioral evidence.

Social-event mappings are isolated in `PNC_KnowledgeSocialEventAdapter.lua`. Adding a new game event mapping does not modify the knowledge persistence or resolver service.

Limits are deterministic: 64 evidence entries per NPC, 16 per descriptor, 64 journal entries, 16 manual notes, and 512 characters per manual note. Direct disclosures have pruning priority.
