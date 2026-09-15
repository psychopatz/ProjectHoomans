# Radio discovery flavour packs

Project Hoomans registers one native channel at `69.0 MHz`. Discovery messages
are ordinary PsychopatzCore custom-radio message packs, so future events can
register their own high-priority pack without changing the scanner.

The discovery context supports these replacement tokens:

- `{playerFirstName}`, `{playerLastName}`, `{playerFullName}`
- `{npcFirstName}`, `{npcLastName}`, `{npcFullName}`
- `{npc2FirstName}`, `{npc2LastName}`, `{npc2FullName}`
- `{argumentPrimaryName}`, `{argumentSecondaryName}`
- `{conflictPrimaryName}`, `{conflictSecondaryName}`
- `{factionName}`, `{settlementName}`, `{location}`
- `{entityID}`, `{kind}`, `{groupType}`, `{archetypeID}`, `{phase}`

The radio text may use real NPC and faction values when the server rolls a
radio introduction. Argument variants are the intentional flavor exception:
they use the first names of both selected members so they can address each
other, without creating player knowledge. Other messages resolve to anonymous
caller/group text when there is no introduction.
The selected NPC is always a living member of the broadcasting entity. A
successful introduction may speak the NPC's real name as immersive flavor, but
it does not create `identity.name` knowledge. The disclosed faction is still
persisted as a strategic contact and as `faction.identity` knowledge. The
in-person “What's your name?” interaction remains the authoritative route for
learning the NPC's name.

About 25% of discovery broadcasts with at least two living members use an
argument variant. These exchanges alternate between the selected living
primary and secondary speakers, preserve their internal voice bindings, and
remain flavor-only. The existing introduction line is retained when its
separate roll succeeds, so faction disclosure behavior stays unchanged.

About 15% of broadcasts with an eligible second faction use a conflict
variant. The scanned entity remains the primary speaker, while the secondary
speaker is a living member from another radio-eligible faction. Looter versus
neutral exchanges are preferred, followed by looter versus a player-faction
colonist. Both speakers may address each other by first name for flavor, but
neither name becomes `identity.name` knowledge. The conflict does not add a
second faction discovery claim; only the scanned faction follows the existing
radio introduction persistence rule.

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
