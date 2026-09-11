# Radio discovery flavour packs

Project Hoomans registers one native channel at `69.0 MHz`. Discovery messages
are ordinary PsychopatzCore custom-radio message packs, so future events can
register their own high-priority pack without changing the scanner.

The discovery context supports these replacement tokens:

- `{playerFirstName}`, `{playerLastName}`, `{playerFullName}`
- `{npcFirstName}`, `{npcLastName}`, `{npcFullName}`
- `{npc2FirstName}`, `{npc2LastName}`, `{npc2FullName}`
- `{factionName}`, `{settlementName}`, `{location}`
- `{entityID}`, `{kind}`, `{groupType}`, `{archetypeID}`, `{phase}`

NPC and faction identity tokens reveal real values only when the server rolls
a radio introduction. Otherwise they resolve to anonymous caller/group text.
The selected NPC is always a living member of the broadcasting entity. A
successful introduction records the same `identity_name` knowledge topic used
by an in-person introduction, so the learned name persists in SP and MP.

Add variety by appending message definitions to
`WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_MessagePacks.lua`,
or register a separate pack against
channel `projecthoomans.frequency_scan` and event type `discovery`. Pack
`matches(context)` and `priority` select specialized siege, treasure, distress,
or faction-event traffic while the generic packs remain fallbacks.

When a scan successfully airs a pack, its speakable lines are also returned to
the client as a bounded radio presentation. If PBrainZ TTS is enabled and the
radio is still powered, audible, and unmuted, those lines enter the Core voice
channel with the `radio` DSP profile. Static marker lines such as `<wzzt>` are
kept for the native radio broadcast but are not sent to TTS.
