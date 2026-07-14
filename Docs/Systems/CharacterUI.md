# Character UI

## Purpose
- `PNC_Nameplates` owns the overhead-overlay lifecycle and public debug API.
- `PNC_NameplateEntries` and `PNC_NameplateBodies` resolve network snapshots to nearby live bodies.
- `PNC_NameplatePresentation`, `PNC_NameplateDebug`, and `PNC_NameplateRenderer` own visual rules, debug strings, and drawing respectively.
- `PNC_CharacterWindow` owns the NPC profile shell and tabs.
- `PNC_ContextHub` and `PNC_NPCSelection` own reusable cursor selection and NPC context entry, so command, talk, debug, and future interaction flows share one hub.
- nearby NPCs are listed directly on the root world context menu; each entry uses Dynamic Trading's production Talk icon and owns a submenu for its actions
- normal context labels contain only the NPC name. Archetype and distance are developer metadata and appear only while global debug presentation is enabled or that NPC is being recorded.
- the NPC monitor uses the shared list-content hook to layer presence and `REC` badges over its roster renderer without coupling those indicators to the base row layout
- tab helper files own their own content areas so medical, bandage, and body-part systems can be added without replacing the window.
- full character and inventory payloads are requested on demand instead of being replicated every tick.

## Current Tabs
- `Info`
- `Skills`
- `Health`
- `Protection`
- `Temperature`

## Ownership Rules
- only the `PNC_Nameplates` subsystem draws overhead bars and text
- name colors communicate disposition: colonists are green, hostile NPCs are red, and neutral NPCs are white
- only `PNC_CharacterWindow` opens and renders the profile window
- only the context hub stack decides which NPCs are selectable from a right-click
- per-NPC recording state comes from the authoritative record snapshot/diagnostic payload; UI code never maintains a separate recording toggle
- snapshot payloads come from `PNC_Network`, not UI code
- inventory and character details come from `PNC_Network.BuildCharacterPayload`, not from ad-hoc UI caches
