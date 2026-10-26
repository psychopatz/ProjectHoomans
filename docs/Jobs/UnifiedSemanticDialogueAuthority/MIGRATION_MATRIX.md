# Migration Matrix — Legacy Dialogue Owners to Unified Semantics

This is the active source-truth inventory. A family is not complete until the
semantic pool/flow selects meaning before delivery, the wording is owned by
Dialogue Content, and the old first-party prose selector is no longer an
authority. `CHARACTERIZED` means P0 has recorded the current owner and tests;
it does not mean the family has been migrated.

| Legacy family / packet | Actual production owner and callers | Authoritative facts/context | Target semantic pool or flow | Content owner | Follow-up eligibility | Characterization / acceptance evidence | Status and retirement disposition |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `social.conversation_farewell` | `client/PNC/Conversation/PNC_ConversationFarewell.lua`; legacy definitions in `PNC_SocialFlavorDefinitions_GroupA.lua` | Conversation close reason, relationship role/tier, NPC/player identity, active-session cancellation | `semantic.flow.farewell` | Dialogue Content farewell variants | Normally none; preserve lifecycle close semantics | `pnc_conversation_farewell_smoke` | `SEMANTIC_FIRST_PARTIAL`; keep queue/presentation alias during migration, retire registered prose selection |
| `social.conversation_safety_danger` | `client/PNC/Conversation/PNC_SocialFlavorPresentation_Speech.lua`; Group C definition | Conversation safety event, threat/context fields, player/NPC identity | `semantic.conversation.safety` | Dialogue Content safety warning variants | `ASK_SAFETY_WHAT`, `ASK_SAFETY_WHERE` only with threat facts | `pnc_conversation_safety_smoke`, `pnc_conversation_safety_feedback_smoke` | `SEMANTIC_FIRST_PARTIAL`; no first-party fallback after boundary migration |
| `social.player_spoke` | `PNC_SocialFlavorPresentation_Speech.lua` and Group B definition | Player utterance, addressed NPC, relationship/style context | `semantic.social.reaction` / active semantic beat | Dialogue Content social reaction | Continuation when the selected plan exposes it | `pnc_social_flavor_presentation_smoke`, `pnc_social_events_smoke` | `SEMANTIC_FIRST_PARTIAL`; retire prose selection |
| `social.witnessed_player_kill` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Witnesses.lua`; Group A definition | Combat event, victim/actor refs, witness relationship/style, event/fact refs | `semantic.combat.reaction` | Dialogue Content combat witness variants | What happened / are you okay / threat only when facts support it | `pnc_social_events_smoke`, `pnc_social_combat_damage_smoke`, presentation smoke | `SEMANTIC_FIRST_PARTIAL`; retain transport alias only |
| `social.witnessed_teammate_hurt` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Treatment.lua`; Group A definition | Wound/treatment event, patient/attacker/need/threat bands, relationship | `semantic.medical.distress` | Dialogue Content medical distress variants | What happened / who hurt them / what do you need when exposed | `pnc_social_combat_damage_smoke`, incapacitated emit/definition smoke | `SEMANTIC_FIRST_PARTIAL`; retire legacy line selection |
| `social.follower_abandoned_zombie` | `server/PNC/Social/PNC_FollowerAbandonmentService.lua`; Group B definition | Follower identity, abandonment phase, zombie threat, relationship, event ref | `semantic.companion.reaction` | Dialogue Content companion relationship variants | What happened / are you hurt / threat when abandonment facts are valid | `pnc_social_events_smoke`, compatibility/social event coverage | `SEMANTIC_FIRST_PARTIAL`; retire prose selector |
| `social.follower_abandoned_hostile_npc` | `server/PNC/Social/PNC_FollowerAbandonmentService.lua`; Group B definition | Follower identity, hostile-NPC identity/kind, abandonment phase, relationship | `semantic.companion.reaction` | Dialogue Content companion relationship variants | Who was after you / what happened when hostile ref is disclosed | `pnc_social_events_smoke` | `SEMANTIC_FIRST_PARTIAL`; retire prose selector |
| `social.zombie_horde_detected` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Awareness.lua`; Group C definition | Bounded zombie count band, source/direction/retreat reason, observer/event refs | `semantic.combat.reaction.horde` (explicit pool/variant) | Dialogue Content horde warning variants | Where / how many / what happened only with location/count/event facts | social event and combat adapter smoke tests | `SEMANTIC_FIRST_PARTIAL`; retire prose selector |
| `social.zombie_stamina_retreat` | `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`; Group C definition | Retreat reason, threat band, stamina/awareness context, event ref | `semantic.combat.reaction.retreat` | Dialogue Content retreat variants | What now / where is danger when current facts permit | combat adapter and social-event smoke coverage | `CHARACTERIZED`; migrate with horde/combat event flow |
| `social.incapacitated_call` | `shared/PNC/Core/Presence/PNC_BodyLifecycle/...DownedDistress...`; `PNC_SocialFlavorDefinitions_Incapacitated_Call.lua` | Downed audience, need, threat, attacker identity, bounded event/context | `semantic.medical.distress.call` | Dialogue Content medical distress call matrix | What happened / who hurt you / what do you need when disclosure allows | `pnc_incapacitated_flavor_definitions_smoke`, `pnc_incapacitated_flavor_emit_smoke` | `CHARACTERIZED`; keep matrix as migration source material, retire selector |
| `social.incapacitated_update` | Downed distress update path; `PNC_SocialFlavorDefinitions_Incapacitated_Update.lua` | Same bounded downed context plus update/recovery phase | `semantic.medical.distress.update` | Dialogue Content update variants | Same medical follow-up policy, expiry/repeat bounded | incapacitated definition/emit smoke | `CHARACTERIZED`; retire selector |
| `social.incapacitated_repeat` | Downed distress repeat path; `PNC_SocialFlavorDefinitions_Incapacitated_Repeat.lua` | Same bounded downed context plus repeat/debounce state | `semantic.medical.distress.repeat` | Dialogue Content anti-repeat variants | Only while the response window remains valid | incapacitated definition/emit smoke including non-overlap | `CHARACTERIZED`; retire selector |
| `social.witnessed_leader_death` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_LeaderLoss.lua`; LeaderDeath close/wider definitions | Leader/faction refs, grief/succession role, event/fact refs, disclosure policy | `semantic.leader_loss.reaction` | Dialogue Content grief/succession variants | Who died / what happened / what next only with authoritative refs | `pnc_leader_loss_flavor_smoke`, `pnc_leader_loss_pipeline_smoke` | `SEMANTIC_FIRST_PARTIAL`; retire leader prose selector |
| ToolReply social reactions | `shared/PNC/Conversation/PNC_ConversationToolReplies.lua` via `client/PNC/Integrations/PBrainZ/PNC_PBrainZ_ResponseFallback.lua` | Tool result accepted/rejected/queued, subtype/reason, relationship/policy gates | Semantic social/emote result pools | Dialogue Content tool-result response variants | Active-beat continuation only when result plan exposes it | PBrainZ, companion command, and semantic social smoke tests | `CHARACTERIZED`; remove ToolReply wording authority after parity |
| ToolReply ask-name | `PNC_ConversationToolReplies.lua`; identity presentation command path | Authoritative identity knowledge and disclosure policy, accepted/unnamed/rejected result | Semantic identity/name response path | Dialogue Content identity responses | Identity exchange continuation via existing flow | conversation identity/category and PBrainZ fallback tests | `CHARACTERIZED`; remove localized ToolReply selection |
| ToolReply orders | `PNC_ConversationToolReplies.lua`; companion command result/fallback paths | Command admission/result, command ID, reason, capability/site facts | `semantic.companion.reaction` / command-result pools | Dialogue Content companion acknowledgement/rejection | Command follow-up only when capability/result facts remain valid | companion command/camp/semantic task tests | `CHARACTERIZED`; remove ToolReply wording authority |
| `projecthoomans:wellbeing` | `shared/PNC/Conversation/Blocks/PNC_ConversationRegistry*`; `PNC_SemanticConversationCategoryOwnership.lua`; Suggestions registry projection | Conversation block eligibility/gates/effects, health/relationship facts | Semantic wellbeing flow/provider | Dialogue Content wellbeing questions/answers | Existing wellbeing follow-ups | category eligibility, registry boundary, semantic runtime tests | `CHARACTERIZED`; registry may remain data/effects owner, not meaning owner |
| `projecthoomans:small_talk` | Conversation registry and `projecthoomans.conversation_registry` Suggestions provider | Block gates, relationship/social context, current topic | Semantic social/small-talk provider | Dialogue Content small-talk variants | Contextual continuation when facts support it | conversation category and semantic social tests | `CHARACTERIZED`; retire registry projection as meaning authority |
| `projecthoomans:ask_about` | Conversation registry and `PNC_SemanticDialogueSuggestions_Projection_Offers.lua` | Block knowledge/context references and disclosure gates | Semantic context/knowledge question path | Dialogue Content knowledge/context answers | Context-reference follow-ups from existing Resolver | conversation registry and semantic fact/knowledge tests | `CHARACTERIZED`; retain blocks/effects, retire legacy response ownership |
| `compat.bandits.hooman_hurt` / `Bandit.Say` | `client/PNC/Compatibility/Mods/Bandits/PNC_Bandits_HoomansFlavorDefinitions.lua`; `shared/Core/Compatibility/Mods/Bandits/PNC_Bandits_Flavor.lua`; Bandits adapter | External Bandits damage/actor facts and provider event identity | Semantic compatibility medical/combat reaction | Dialogue Content compatibility variants | Medical/combat follow-up only for exposed facts | `pnc_bandits_damage_command_smoke`, incoming bridge/compatibility tests | `CHARACTERIZED`; adapter facts only, no PNC legacy prose fallback |
| Necroa mask warnings | `server/PNC/Compatibility/Mods/Necroa/PNC_Necroa_ExposureServer_Observers.lua` and `_Social.lua`; client definitions | External exposure/mask event, player/NPC identity, event ref | Semantic compatibility safety/medical reaction | Dialogue Content compatibility variants | Why/what happened only when provider facts/disclosure allow | `pnc_compatibility_necroa_*`, `pnc_necroa_*` | `CHARACTERIZED`; remove silent semantic-to-legacy fallback |
| Project ALife meta/encounter/faction speech | `client/PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_EventPresenter.lua`; `PNC_ProjectALife_FlavorDefinitions.lua` | External event category, stance, faction/conflict/damage, bounded event refs | Semantic world/encounter/faction pools | Dialogue Content compatibility/world-event variants | Grounded event follow-up only with canonical refs/facts | `pnc_projectalife_compat_policy_smoke` and adapter tests | `CHARACTERIZED`; definitions become migration source/compat alias only |
| Generic PsychopatzCore SocialFlavor API | PsychopatzCore `PsychopatzSocialFlavor.lua`, `PsychopatzSocialFlavorClient.lua`; other adopters | Caller-owned generic flavor registrations and presentation policy | Not replaced | Adopter-owned content | n/a | Core social-flavor smoke suite and PNC compatibility boundary tests | `COMPATIBILITY_ONLY`; retain generic API, but PNC semantic-owned packets must include selected text |

## P0 baseline facts

- Project Hoomans `HEAD`, `main`, and `origin/main` all began at
  `f2390998d30dcab7ee1110a850c97b38f8fb1ee9`.
- The first-party inventory contains thirteen `social.*` registrations across
  Group A/B/C, incapacitated call/update/repeat, and leader-death files.
- `PNC_ConversationToolReplies.lua` is the only caller of the ToolReply
  catalog's wording tables; its entry point is the PBrainZ response fallback.
- The three `projecthoomans:*` categories still advertise
  `conversation_registry` as authority even though semantic ownership metadata
  already exists beside them.
- Existing semantic event producers already call `SocialReactions.Resolve` or
  `RealizationAuthority.Resolve`, but some presentation callers pass
  `resolvedText` while `BuildReceivePayload` only projected `text`. That gap
  allowed Core `ResolveDetailed` to choose a legacy line.
- Baseline focused harness runs: semantic `87/87` in `1.81s` wall clock;
  social/compatibility regression selection `24/24` in `0.63s` wall clock.

P0 records these facts and adds characterization coverage. It does not delete
or disable a selector.

## P2 follow-up ownership update

The reopened follow-up bridge is now accepted. The horde row's semantic
selection remains owned by `SocialReactions` and
`semantic.combat.reaction`; the selected plan's bounded offer IDs are recorded
by `SemanticInteractionLifecycle.RecordNPCSpeech`, projected by
`DialogueSuggestions`, and answered by the existing context-reference local
response path. The same lifecycle contract is available to the medical,
abandonment, leader-loss, safety and corpse families once their event adapters
provide authoritative fact refs.

P2 production-worker evidence is
`tools/semantic_harness/tests/test_unified_authority_p2_event_followup.py` plus
`tests/pnc_unified_authority_p2_event_followup_smoke.lua`. No family is marked
fully retired by this bridge: legacy first-party selectors remain migration
source material until the family-specific P3/P4/P6 parity gates pass.
