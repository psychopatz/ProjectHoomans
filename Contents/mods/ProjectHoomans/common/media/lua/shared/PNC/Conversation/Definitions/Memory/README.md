# Conversation memory definitions

These are definitions, not schematics: they describe reusable NPC facts,
gossip lines, and current-day conversation topics. Runtime registration lives
under the versioned 42.20 Lua tree; content modules and their text bundles
live under common.

## Backstories

Each Lua module registers one fact with Memory.RegisterBackstory. Keep IDs and
values stable, use a class of colonist, neutral, hostile, or shared, and add
every text key to both common/media/conversation/backstory/shared/EN/facts.json
and common/media/conversation/backstory/shared/TL/facts.json.

The profile is selected from record.identity.seed with a separate salt for
each fact kind. The selected job, hometown, education, hobby, family
background, value, tragedy, survival origin, and fear are computed in memory
and are not copied into the NPC ModData record. The date-of-birth resolver is
special: identity.birth
stores one packed integer (year * 384 + month * 32 + day) so age remains
stable as the world date advances. The game API uses zero-based month and day
values; the resolver returns one-based month and day values for dialogue.

Add new modules to Backstories/00_PNC_ConversationBackstories.lua.

When a conversation needs an LLM, Lua renders a bounded set of these facts
into request-local dialogue context. The context is used to build that prompt
and is not synchronized into or stored as PBrainZ memory.

## Gossip templates

Each Lua module registers one template with Memory.RegisterGossipTemplate.
Every code is a stable 16-bit wire ID: do not reuse or renumber a published
code. The arguments field defines the positional order used by
Memory.BuildGossipPacket, whose payload contains the numeric code and only
the argument array. Keep placeholders identical in both language bundles.

Add new modules to GossipTemplates/00_PNC_ConversationGossipTemplates.lua.
Text keys live in common/media/conversation/gossip/shared/EN/templates.json
and common/media/conversation/gossip/shared/TL/templates.json.

## Event memory

Each event type registers with `Memory.Events.RegisterType` from a module under
`EventTypes/`. Keep event IDs and explicit event codes stable. Only salient or
permanent events enter the durable selection; shareable events may name a
registered gossip event when the template accurately describes them.

Event ModData is optional. When present, the m payload holds at most 8
current-day references, 6 durable references, and 4 current-day conversation
participants. Event references contain numeric event codes, identity-derived
target seeds, a packed day for durable entries, and small flags. Conversation
topics are stored as flat player-seed/mask pairs in m.t; the masks use stable
topic bit positions registered below ConversationTopics. Append topic bits,
never reuse or renumber them. The packed player seed is mixed from the NPC
identity seed and the player's character UUID. No transcript text, topic
strings, or player UUIDs are copied into this store. Current-day references
and topic masks expire when the packed world date changes. Gossip transport
sends at most 4 template codes plus one shared subject name; clients render
those codes through their local language bundle.

The prompt projection is also bounded to 14 dialogue facts total, including
backstory facts and any rendered gossip statements.

Add new modules to `EventTypes/00_PNC_ConversationMemoryEventTypes.lua`.

## Current-day conversation topics

Each topic module self-registers one stable bit and its small matching alias
set. Keep the bit assignments append-only, use short canonical labels, and
add new modules to `ConversationTopics/00_PNC_ConversationMemoryTopics.lua`.
Accepted semantic turns accumulate a session-local mask. On close, Lua also
classifies at most the latest 64 visible messages, merges those topics, then
sends the server one numeric mask. ModData stores no transcript: it keeps a
flat list of at most four player-seed/mask pairs for that NPC and day. Prompt
context projects at most eight registered topic labels from that daily mask;
it does not replay original messages. The open session keeps its bounded
working context until close, then clears the transcript and semantic state.
An ambient request may borrow at most four recent messages, each truncated to
160 characters, only while the same NPC/player conversation is still active.
