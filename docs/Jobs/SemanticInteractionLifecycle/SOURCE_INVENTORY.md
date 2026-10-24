# P0A — Production flavor and state-ownership inventory

**Evidence checkout:** existing `main`, baseline commit `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

**Scope:** Build 42.20 production Lua and the existing Semantic Lab worker. This inventory does not claim legacy retirement.

## Authority map

| Concern | Trigger / resolver owner | Durable state and authority | Presentation path |
| --- | --- | --- | --- |
| Freeform typed/headless Talk | `PNC/Semantics/PNC_SemanticDialogueInput.lua`, existing parser/router/policy | ConversationBlocks and existing authoritative domains; input itself is not gameplay authority | Response plan, suggestions, TTS/nameplate |
| Semantic buttons | `PNC_SemanticDialogueSuggestions.lua` -> `Input.SubmitSemanticFrame` | Existing input/ConversationBlocks authority; frame receipts are bounded runtime state | Same response-plan path as typed input |
| Conversation open/close | `PNC_ConversationLifecycle.lua`, conversation definition lifecycle | Conversation lease and block effects are authoritative; ordinary farewell remains client-presentation owned | Conversation UI plus `PNC_ConversationFarewell.lua` |
| Farewell | `PNC_ConversationFarewell.lua`, `PNC_ConversationFarewellContext.lua`, GroupA definitions | Client pending queue, `farewellEvaluated`, chance/cooldown/TTL; no old path ModData write | SocialFlavor client enqueue, delayed NPC line, player speech, TTS/nameplate |
| Vanilla emotes | `PNC_VanillaEmoteInteractions.lua`, `PNC_ServerPlayerEmoteInteractionCommandHandler.lua` | Server social definitions and relationship/memory mutation | Companion command/emote animation and result presentation |
| Companion/social replies | Companion flavor definitions and command presentation | Command/action registry and existing gameplay domains | Flavor realization, nameplate, TTS |
| Combat/health/social events | Social event hooks, social event service, health/treatment adapters | Server SocialEvents, Relationships, Knowledge, Faction, Health and Task owners | Compact network projection and existing flavor presentation |
| World/gossip | Project A-Life compatibility presenter and World Knowledge | Addon/fact owner plus existing knowledge/event domains | Client category/speaker/cooldown/TTS presentation |

## Registered legacy family and ID inventory

- Greeting/emote overlap: `social_greeting_npc_*`, `vanilla_emote_wavehi_npc_*`, and semantic greeting flow/response-catalog variants.
- Farewell: `social.conversation_farewell`.
- Social speech/events: `social.player_spoke`, `social.conversation_safety_danger`, `social.witnessed_player_kill`, `social.witnessed_teammate_hurt`, `social.follower_abandoned_zombie`, `social.follower_abandoned_hostile_npc`, `social.zombie_horde_detected`, `social.zombie_stamina_retreat`, `social.incapacitated_call`, `social.incapacitated_update`, `social.incapacitated_repeat`, and `social.witnessed_leader_death`.
- Project A-Life: `projectalife.meta_gunfire`, `projectalife.meta_aircraft`, `projectalife.meta_crash`, `projectalife.meta_ambience`, `projectalife.encounter_friendly`, `projectalife.encounter_hostile`, `projectalife.encounter_unknown`, `projectalife.faction_hostile`, `projectalife.faction_conflict_incoming`, and `projectalife.faction_conflict_outgoing`.
- Compatibility: `compat.bandits.hooman_hurt`, `compat.necroa.mask_warning`, and `compat.necroa.player_mask_removed`.
- Vanilla/player emote IDs: `insult`, `thumbsdown`, `wavehi`, `wavebye`, `thankyou`, `thumbsup`, `clap`, and `salute`, with aliases defined by the interaction registry.

## Trigger, selection, presentation and authority evidence

### Farewell

`PNC_ConversationFarewell.Schedule` filters close reasons, guards `farewellEvaluated`, checks a 12-second per-NPC client cooldown, rolls a 55% chance, resolves social role/context, resolves the player realization, and queues the NPC realization for a 1.9-second delay with a 7-second TTL. `Pump` scans only the bounded pending queue on tick and skips active conversations. It is client-only and presentation-only in the legacy route.

### Emotes and greetings

`PNC_VanillaEmoteInteractions` maps emote IDs to event definitions, typed replies, daily greeting state and relationship tiers. The server emote handler validates authority, identity, live targets, radius, cooldown and relationship effects before sending a bounded result. `PNC_SocialGreetingService` uses spatial/registry candidates, meeting/LOS checks, per-player presence edges, a one-hour pump interval and a four-greeting-per-pump budget. Relationship and social event services own effects; animation and flavor queues do not.

### Combat, medical and world reactions

Witness hooks and health/treatment adapters emit grounded events only after their source-domain checks. Awareness keeps threshold, clear-interval, cooldown, speaker and per-player budget logic. Project A-Life normalizes addon events and applies seen/category/speaker/family/ambient cooldowns. These paths must retain canonical event/fact identity rather than parse generated prose.

## Persistence and network findings

- Ordinary farewell, player-speech reaction, safety feedback, emote rendering and Project A-Life TTS are legacy presentation/runtime state; inspected paths do not create a new durable pair record.
- Server social events enter `PNC.SocialEvents.Emit` only after authority/source validation. Relationship memories, cooldowns, knowledge evidence and faction incidents remain owned by existing server services.
- Existing directed relationship persistence is keyed by player/NPC entity identity and is bounded by its relationship memory/bond services.
- The new lifecycle owner is separate and sparse: NPC-global truth remains in existing registries, pair capsules are created only after meaningful deltas, shared event payloads are canonicalized once, and unrelated clients receive no private thread projection.
- The worker’s lifecycle metrics provide the initial pair-count, recent-turn, capsule-size, shared-event and dormant-work baseline without adding Python gameplay semantics.

## Characterization baselines

Existing focused tests cover farewell eligibility, vanilla emote definitions and presentation, social greeting, social-event transport, combat/damage flavor, incapacitated IDs/emission, leader loss, and typed/headless production-worker routes. The new lifecycle baselines are:

- `tests/pnc_semantic_interaction_lifecycle_smoke.lua`;
- `tests/pnc_semantic_interaction_persistence_smoke.lua`;
- `tools/semantic_harness/tests/test_semantic_interaction_lifecycle_p1.py`.

P0A establishes the source migration inventory and characterization baseline. It does not claim that legacy flavor authority has been deleted or that P0–P9 is complete.
