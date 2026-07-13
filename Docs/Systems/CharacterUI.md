# Character UI

## Purpose
- `PNC_Nameplates` owns the overhead-overlay lifecycle and public debug API.
- `PNC_NameplateEntries` and `PNC_NameplateBodies` resolve network snapshots to nearby live bodies.
- `PNC_NameplatePresentation`, `PNC_NameplateDebug`, and `PNC_NameplateRenderer` own visual rules, debug strings, and drawing respectively.
- `PNC_CharacterWindow` owns the NPC profile shell and tabs.
- `PNC_ContextHub` and `PNC_NPCSelection` own reusable cursor selection and NPC context entry, so command, talk, debug, and future interaction flows share one hub.
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
- name colors communicate disposition: recruited/companion NPCs are green, hostile NPCs are red, and other friendly or unrecruited NPCs are white
- only `PNC_CharacterWindow` opens and renders the profile window
- only the context hub stack decides which NPCs are selectable from a right-click
- snapshot payloads come from `PNC_Network`, not UI code
- inventory and character details come from `PNC_Network.BuildCharacterPayload`, not from ad-hoc UI caches
