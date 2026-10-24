# P0A — Production Flavor and State-Ownership Inventory

**Evidence checkout:** existing `main` checkout

**Baseline:** `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

**Scope:** Build 42.20 production Lua, existing Semantic Lab worker, and the real source/test files in this repository. P0A did not delete legacy content or replace P14 save rehydration.

## Authority map

| Concern | Trigger/context/resolver owner | Durable state and authority | Presentation/TTS path |
| --- | --- | --- | --- |
| Typed/headless Talk | `PNC/Semantics/PNC_SemanticDialogueInput.lua`, existing parser/router/policy | ConversationBlocks and existing authoritative domains; input itself has no gameplay authority | Response plans, suggestions, TTS/nameplate |
| Semantic buttons | `PNC_SemanticDialogueSuggestions.lua` -> `Input.SubmitSemanticFrame` | Existing semantic-frame and ConversationBlocks authority | Same response-plan path as typed input |
| Conversation open/close | `PNC_ConversationLifecycle.lua`, scene lease and ConversationAuthority | Server lease, lifecycle persistence and authored branch effects | Conversation UI and farewell presentation |
| Greetings | `PNC_SocialGreetingService_TryGreet.lua`, greeting flow/catalog and vanilla emote registry | Relationship/social event services; greeting cadence, LOS, presence and budget remain owners | SocialFlavor presentation, TTS/nameplate |
| Farewell | `PNC_ConversationFarewell.lua` and `PNC_ConversationFarewellContext.lua` | Existing close eligibility/chance/cooldown/TTL policy; meaningful lifecycle close is server-owned | Bounded pending queue, SocialFlavor, player speech, TTS |
| Emotes | `PNC_VanillaEmoteInteractions.lua`, server emote handler and result presentation | Server identity/radius/cooldown/relationship/gameplay authority | Engine animation, companion result and SocialFlavor |
| Companion/social replies | Companion command flavor definitions and presentation queue | Command/action registry and authoritative domains | Flavor realization, nameplate and TTS |
| Combat/medical/social events | Social event hooks, transaction service, health/treatment/awareness/faction services | SocialEvents, Relationships, Knowledge, Faction, Health and Task owners | Bounded network projection and existing flavor sinks |
| Corpse awareness | Corpse lifecycle reaction module and body/identity services | Corpse/relationship/knowledge owners; one canonical event, sparse player projections | Nearby-player social flavor |
| Project A-Life | Shared adapter, server event observers/reputation hooks, client normalizer/presenter | Project A-Life event/reputation owner; shared lifecycle reference only | Nearby companion flavor, cooldown and TTS presentation |
| Bandits/Necroa | Compatibility adapters and social bridges | External provider plus existing social/medical owners | Compatibility flavor definitions and network presentation |

## Registered legacy family and ID inventory

- Greeting/emote overlap: `social_greeting_npc_*`, `vanilla_emote_wavehi_npc_*`, semantic greeting flow and response-catalog variants.
- Farewell: `social.conversation_farewell`.
- Social events: `social.player_spoke`, `social.conversation_safety_danger`, `social.witnessed_player_kill`, `social.witnessed_teammate_hurt`, `social.follower_abandoned_zombie`, `social.follower_abandoned_hostile_npc`, `social.zombie_horde_detected`, `social.zombie_stamina_retreat`, `social.incapacitated_call`, `social.incapacitated_update`, `social.incapacitated_repeat`, and `social.witnessed_leader_death`.
- Medical/relationship event definitions: `treated_wound`, `saved_from_incapacitation`, `faction_member_attacked`, `survived_horde_attack`, `necroa_player_mask_removed` and the registered social-event definition set.
- Project A-Life: `projectalife.meta_gunfire`, `projectalife.meta_aircraft`, `projectalife.meta_crash`, `projectalife.meta_ambience`, `projectalife.encounter_friendly`, `projectalife.encounter_hostile`, `projectalife.encounter_unknown`, `projectalife.faction_hostile`, `projectalife.faction_conflict_incoming`, and `projectalife.faction_conflict_outgoing`.
- Compatibility: `compat.bandits.hooman_hurt`, `compat.necroa.mask_warning`, and `compat.necroa.player_mask_removed`.
- Registered player gestures: `insult`, `thumbsdown`, `wavehi`, `wavebye`, `thankyou`, `thumbsup`, `clap`, and `salute`.

## Trigger and selection evidence

### Greeting and farewell

Greeting uses candidate discovery, spatial/LOS and presence checks, a one-hour pump interval and a four-greeting-per-pump budget. Relationship and social-event services own effects; the flavor queue does not. Farewell preserves the existing close-reason filter, `farewellEvaluated` guard, 12-second per-NPC cooldown, 55% roll, role/context resolver, 1.9-second NPC delay, 7-second pending TTL and active-conversation guard. The semantic lifecycle envelope is carried through presentation, while server scene/authority close owns durable suspension.

### Emotes and companion responses

The vanilla interaction registry maps gestures to canonical acts and typed replies. The server handler validates identity, target, radius, cooldown and relationship effects before sending the result. The result presentation and companion queue preserve the semantic envelope through a bounded registry because the existing Core transport intentionally strips nested payloads. A cooldown/no-op emote may show a reply realization but does not create a new pair capsule.

### Grounded events and compatibility

Combat, treatment, incapacitation, abandonment, awareness, leader-loss, faction and compatibility adapters enter `PNC.SocialEvents.Emit` only after their source-domain checks. The social transaction owns memory/relationship/conduct mutation. The lifecycle bridge then records the canonical event reference and NPC reaction provenance. NPC-to-NPC events retain only shared canonical references unless a player-specific durable delta exists.

### Project A-Life

Server encounter/reputation hooks publish validated external events. The server lifecycle persistence registers the source event once when it is published. Client normalization chooses the existing realization and keeps the speaker-specific transport event separate from the canonical `eventRef`; no client-only ambient presentation creates gameplay ModData.

## Persistence and network findings

- Ordinary visible text, TTS, nameplates, farewell pending items, emote animations and client ambient queues are presentation/runtime state, not durable transcripts.
- Server social events and the lifecycle persistence module are authority-checked. Existing Relationship, Knowledge, Faction, Health, Task, ConversationBlocks and Project A-Life stores remain their own state owners.
- Pair state is keyed by the actual player/NPC identity and is absent until meaningful lifecycle state exists. Resolved trivial capsules are removed.
- Shared event payloads are stored once by canonical reference. Private pair/thread projections are not broadcast to unrelated clients.
- Expiry, residue cleanup and anti-repeat eviction are lazy or bounded; lifecycle `Advance` reports zero dormant per-tick work and performs no global scan.

## Characterization baseline

The representative production-Lua baselines are:

- `tests/pnc_semantic_interaction_lifecycle_smoke.lua`;
- `tests/pnc_semantic_interaction_persistence_smoke.lua`;
- `tests/pnc_social_greeting_smoke.lua`;
- `tests/pnc_conversation_farewell_smoke.lua`;
- `tests/pnc_vanilla_emote_interactions_smoke.lua`;
- `tests/pnc_social_events_smoke.lua`;
- `tools/semantic_harness/tests/test_semantic_interaction_lifecycle_p1.py`;
- `tools/semantic_harness/tests/test_semantic_interaction_lifecycle_acceptance.py`;
- `tools/semantic_harness/tests/test_production_faction_rehydration_p14c.py`.

These cover equivalent input meaning, NPC provenance, interruption/resume, UI-independent compact state, multi-day rehydration, trivial-pair removal, significant promotion, 200-turn bounds, sparse multiplayer pairs, shared refs, dormant work, registry/source immutability, greeting/farewell/emote/social-event transport and compatibility regression paths.
