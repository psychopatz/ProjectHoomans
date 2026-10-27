# Migration Matrix — Legacy Dialogue Owners to Unified Semantics

This is the active source-truth inventory. A family is complete only when a
semantic pool/flow selects meaning before delivery, wording has one content
owner, and the old first-party prose selector is no longer an authority.

| Legacy family / packet | Actual production owner and callers | Authoritative facts/context | Target semantic pool or flow | Content owner | Follow-up eligibility | Characterization / acceptance evidence | Status and retirement disposition |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `social.conversation_farewell` | `client/PNC/Conversation/PNC_ConversationFarewell.lua`; Group A legacy definitions | Close reason, relationship role/tier, NPC/player identity, active-session cancellation | `semantic.flow.farewell` | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Normally none; preserve lifecycle close semantics | `pnc_conversation_farewell_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; definitions are source material, not a selector |
| `social.conversation_safety_danger` | `client/PNC/Conversation/PNC_SocialFlavorPresentation_Speech.lua`; Group C definition | Safety event, threat/context fields, player/NPC identity | `semantic.conversation.safety` | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Only with disclosed threat facts | `pnc_conversation_safety_smoke`, `pnc_conversation_safety_feedback_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; unsupported offers are filtered |
| `social.player_spoke` | `PNC_SocialFlavorPresentation_Speech.lua`; Group B definition | Player utterance, addressed NPC, relationship/style context | `semantic.social.reaction` / active semantic beat | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Continuation only when the selected plan exposes it | `pnc_social_flavor_presentation_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; retire prose selection after P8 |
| `social.witnessed_player_kill` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Witnesses.lua`; Group A definition | Combat event, victim/actor refs, witness relationship/style, event/fact refs | `semantic.combat.reaction` | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | What happened only when the event fact is disclosed | `pnc_player_kill_witness_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; transport alias only |
| `social.witnessed_teammate_hurt` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_TeammateDelivery.lua`; damage adapters | Wound/damage authority, patient/attacker/need/threat bands, observer role, bounded refs | `semantic.medical.distress.teammate` | Semantic ResponseCatalog in P4; canonical Dialogue Content migration in P7 | What happened / who hurt them / what they need only from disclosed facts | `pnc_social_combat_damage_smoke`, `pnc_unified_authority_p4_medical_smoke` | `SEMANTIC_FIRST_ACCEPTED`; legacy definitions are source material until P8 |
| `treated_wound` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_Treatment.lua`; treatment completion hook | Wound/treatment authority, target health, body part, bounded treatment refs | `semantic.medical.distress.treatment` | Semantic ResponseCatalog in P4; canonical Dialogue Content migration in P7 | What happened / what do you need only from disclosed treatment facts | `pnc_social_events_smoke`, `pnc_unified_authority_p4_medical_smoke` | `SEMANTIC_FIRST_ACCEPTED`; legacy transport alias retained, no prose selector |
| `social.follower_abandoned_zombie` | `server/PNC/Social/PNC_FollowerAbandonmentService.lua`; Group B definition | Follower identity, abandonment phase, zombie threat, relationship, event ref | `semantic.companion.reaction` | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Pursuer only when disclosed; health is hidden without a health fact | `pnc_follower_abandonment_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; retire prose selection after P8 |
| `social.follower_abandoned_hostile_npc` | `server/PNC/Social/PNC_FollowerAbandonmentService.lua`; Group B definition | Follower identity, hostile-NPC identity/kind, abandonment phase, relationship | `semantic.companion.reaction` | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Who was after you only when the hostile ref is disclosed | `pnc_follower_abandonment_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; retire prose selection after P8 |
| `social.zombie_horde_detected` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Awareness.lua`; Group C definition | Bounded count band, source/direction/retreat reason, observer/event refs | `semantic.combat.reaction` / threat variant | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Where / how many / what happened only with location/count/event facts | `pnc_unified_authority_p2_event_followup_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; retire prose selection after P8 |
| `social.zombie_stamina_retreat` | `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`; Group C definition | Retreat reason, threat band, stamina/awareness context, event ref | `semantic.combat.reaction` / retreat variant | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | What happened when the retreat fact is disclosed | `pnc_unified_authority_p3_social_events_smoke`, combat/social-event smoke coverage | `SEMANTIC_FIRST_ACCEPTED`; retire prose selection after P8 |
| `social.incapacitated_call` | `common/.../PNC_SocialEventHooks_DownedDistress_Public_Shared.lua`; `Hooks.OnIncapacitated` | Health/wound authority, downed audience/need/threat, bounded attacker identity, event refs | `semantic.medical.distress.call` | Semantic ResponseCatalog in P4; canonical Dialogue Content migration in P7 | What happened / who hurt you / what do you need when disclosure allows | `pnc_incapacitated_flavor_emit_smoke`, `pnc_unified_authority_p4_medical_smoke` | `SEMANTIC_FIRST_ACCEPTED`; old matrix is source material until P8 |
| `social.incapacitated_update` | `common/.../PNC_SocialEventHooks_DownedDistress_Public_Shared.lua`; `Hooks.OnIncapacitatedStatusChanged` | Bounded downed context plus health/wound update phase and event refs | `semantic.medical.distress.update` | Semantic ResponseCatalog in P4; canonical Dialogue Content migration in P7 | Same medical follow-up policy; expiry/repeat bounded | `pnc_incapacitated_flavor_emit_smoke`, `pnc_unified_authority_p4_medical_smoke` | `SEMANTIC_FIRST_ACCEPTED`; old matrix is source material until P8 |
| `social.incapacitated_repeat` | `common/.../PNC_SocialEventHooks_DownedDistress_Public_Shared.lua`; `Hooks.TickIncapacitatedDistress` | Bounded downed context plus repeat/debounce state and event refs | `semantic.medical.distress.repeat` | Semantic ResponseCatalog in P4; canonical Dialogue Content migration in P7 | Only while the response window remains valid; cadence bounded | `pnc_incapacitated_flavor_emit_smoke`, `pnc_unified_authority_p4_medical_smoke` | `SEMANTIC_FIRST_ACCEPTED`; old matrix is source material until P8 |
| `social.witnessed_leader_death` | `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_LeaderLoss.lua`; LeaderDeath definitions | Leader/faction refs, grief/succession role, event/fact refs, disclosure policy | `semantic.leader_loss.reaction` | Semantic ResponseCatalog; canonical Dialogue Content migration in P7 | Who died / what happened / what next only with authoritative refs | `pnc_leader_loss_flavor_smoke`, `pnc_leader_loss_pipeline_smoke`, `pnc_unified_authority_p3_social_events_smoke` | `SEMANTIC_FIRST_ACCEPTED`; definitions are source material |
| ToolReply social reactions | `shared/PNC/Conversation/PNC_ConversationToolReplies.lua` via `client/PNC/Integrations/PBrainZ/PNC_PBrainZ_ResponseFallback.lua` | Tool result accepted/rejected/queued, subtype/reason, policy gates | `semantic.tool_reply.social.*` | `projecthoomans.dialogue_content.tool_replies`; existing EN/TL keys remain migration source until P7 | Active-beat continuation only when the selected plan exposes it | `pnc_unified_authority_p5_tool_replies_smoke`, `pnc_llm_tool_reply_catalog_smoke`, PBrainZ/translation regressions | `SEMANTIC_FIRST_ACCEPTED`; legacy table is not loaded or consulted |
| ToolReply ask-name | `PNC_ConversationToolReplies.lua`; identity presentation command path | Authoritative identity knowledge/disclosure, accepted/unnamed/rejected result | `semantic.tool_reply.ask_name.*` | `projecthoomans.dialogue_content.tool_replies`; existing EN/TL keys remain migration source until P7 | Identity exchange continuation through the existing flow | `pnc_unified_authority_p5_tool_replies_smoke`, identity/category and PBrainZ fallback tests | `SEMANTIC_FIRST_ACCEPTED`; old localized selector is no longer used |
| ToolReply orders | `PNC_ConversationToolReplies.lua`; companion command result/fallback paths | Command admission/result, command ID/reason, capability/site facts | `semantic.tool_reply.order.*` | `projecthoomans.dialogue_content.tool_replies`; existing EN/TL keys remain migration source until P7 | Command follow-up only when capability/result facts remain valid | `pnc_unified_authority_p5_tool_replies_smoke`, companion command/camp regressions | `SEMANTIC_FIRST_ACCEPTED`; old wording selector is no longer used |
| `projecthoomans:wellbeing` | `shared/PNC/Conversation/Blocks/PNC_ConversationRegistry*`; `PNC_SemanticConversationCategoryOwnership.lua`; Suggestions projection | Conversation block eligibility/gates/effects, health/relationship facts | Semantic wellbeing flow/provider | Dialogue Content wellbeing questions/answers | Existing wellbeing follow-ups | `pnc_semantic_conversation_ownership_smoke`, category eligibility/registry boundary, semantic runtime tests | `SEMANTIC_CATEGORY_AUTHORITY_ACCEPTED`; registry remains data/gates/effects owner |
| `projecthoomans:small_talk` | Conversation registry and Suggestions registry projection | Block gates, relationship/social context, current topic | Semantic social/small-talk provider | Dialogue Content small-talk variants | Contextual continuation when facts support it | category ownership/semantic social tests | `SEMANTIC_CATEGORY_AUTHORITY_ACCEPTED`; registry is a projection source, not meaning authority |
| `projecthoomans:ask_about` | Conversation registry and `PNC_SemanticDialogueSuggestions_Projection_Offers.lua` | Block knowledge/context references and disclosure gates | Semantic context/knowledge question path | Dialogue Content knowledge/context answers | Context-reference follow-ups from existing Resolver | category ownership and semantic fact/knowledge tests | `SEMANTIC_CATEGORY_AUTHORITY_ACCEPTED`; retain blocks/effects, retire legacy response ownership |
| `compat.bandits.hooman_hurt` / `Bandit.Say` | Bandits compatibility damage adapter plus `PNC_Bandits_HoomansFlavorDefinitions.lua`; native `Bandit.Say` remains provider caption delivery | External Bandits damage/actor facts and provider event identity | `semantic.compat.bandits.hooman_hurt` | `projecthoomans.dialogue_content.compatibility`; old definitions are source material | Event/attacker follow-up only for disclosed facts | `pnc_social_combat_damage_smoke`, `pnc_unified_authority_p6_compatibility_smoke`, Bandits bridge tests | `SEMANTIC_FIRST_ACCEPTED`; Hoomans packet carries selected text, legacy ID is transport alias only |
| Necroa mask warnings | Necroa exposure observers/social adapter; native zombie captions remain `PNC_Necroa_ZombieFlavor.lua` | External exposure/mask event, player/NPC identity, event ref | `semantic.compat.necroa.mask_warning`; `semantic.compat.necroa.player_mask_removed` | `projecthoomans.dialogue_content.compatibility`; client definitions are source material | What happened only when provider facts/disclosure allow | `pnc_necroa_player_warning_throttle_smoke`, `pnc_unified_authority_p6_compatibility_smoke`, `pnc_compatibility_necroa_*` | `SEMANTIC_FIRST_ACCEPTED`; semantic failure suppresses delivery rather than selecting Hoomans legacy prose |
| Project ALife meta/encounter/faction speech | `PNC_ProjectALife_EventPresenter.lua`; external adapter normalizer/server transport; old FlavorDefinitions are no longer required | External event category, stance, faction/conflict/damage, bounded refs | `semantic.compat.projectalife.meta`; `.encounter`; `.faction` | `projecthoomans.dialogue_content.compatibility`; old definitions are source material | Grounded event follow-up only with canonical refs/facts | `pnc_unified_authority_p6_compatibility_smoke`, `pnc_projectalife_compat_policy_smoke` and adapter tests | `SEMANTIC_FIRST_ACCEPTED`; presenter enqueues selected semantic text and provenance |
| Companion Dogs greeting/feed | `PNC_CompanionDogs_Interaction.lua` → `PNC_CompanionDogs_Presentation.lua`; old `CompanionCommandFlavor` groups remain compatibility aliases | External dog sex/hunger/feed result, NPC/dog/event identity | `semantic.compat.companion_dogs.greeting`; `.feed` | `projecthoomans.dialogue_content.compatibility`; old dog lines are source material | None; bounded ambient delivery | `pnc_companion_dogs_compatibility_smoke`, `pnc_unified_authority_p6_compatibility_smoke` | `SEMANTIC_FIRST_ACCEPTED`; selected text is sent before social-greeting presentation |
| Generic PsychopatzCore SocialFlavor API | PsychopatzCore `PsychopatzSocialFlavor.lua`, `PsychopatzSocialFlavorClient.lua`; other adopters | Caller-owned generic flavor registrations and presentation policy | Not replaced | Adopter-owned content | n/a | Core SocialFlavor smoke suite and PNC compatibility boundary tests | `COMPATIBILITY_ONLY`; retain generic queue/arbitration/TTS/nameplate infrastructure |

## P7 content-ownership closure

The table's earlier “canonical Dialogue Content migration in P7” notes are
resolved by the generated source and registry at
`tools/semantic_harness/codebuilder/sources/semantic_dialogue_content.json`.
All migrated event/medical/social families use
`projecthoomans.dialogue_content.migrated_events`; ToolReply families use
`projecthoomans.dialogue_content.tool_replies`; compatibility families use
`projecthoomans.dialogue_content.compatibility`. Each family is keyed by the
stable semantic template ID and carries its response-pool, semantic-variant,
follow-up, legacy-source, and semantic-authority metadata for Studio review.

P7 acceptance is covered by the generated-registry/content parity tests,
production Lua content smoke, and live Observatory response-pool detail tests
listed in `PROGRESS.md`. The remaining legacy definition files and old
translation keys are source material only; P8 is responsible for proving and
retiring any residual first-party selector caller.

## P8 retirement audit

The first-party social definition shards are now source-only migration
material: `PNC_SocialFlavorPresentation_Core.lua`, farewell, and the runtime
conversation composition no longer load them. Bandits/Necroa compatibility
definition shards are likewise not loaded by production composition; their
adapters select `semantic.compat.*` first and explicit semantic failure
suppresses delivery. Project ALife definitions remain unrequired source
material. The diary hydrator preserves already-selected text and resolves only
canonical Conversation Content keys; it never reselects a persisted flavor ID.

The command interaction queue no longer lets `CompanionCommandFlavor` replace
a selected `ResponseCatalog` realization. Its remaining `Flavor.Resolve`
calls are explicit compatibility-only UI helpers for callers with no semantic
result; semantic NPC event/greeting/acknowledgement paths fail explicitly when
their realization is missing. This is the remaining compatibility boundary,
not a semantic owner.

P8 retirement evidence is
`pnc_unified_authority_p8_retirement_smoke`, the updated composition and diary
regressions, the semantic category ownership tests, and the production
P3/P4/P6 semantic negative suites.

## P5 ownership boundary

`PNC_ConversationToolReplyCatalog.lua` is retained as migration/source
material only. Production `PNC_ConversationToolReplies` now calls the existing
`ResponseCatalog` and `RealizationAuthority`; it does not require, read, or
select from the legacy literal table. Tool-result realization carries semantic
pool, response-plan, realization, and content-owner provenance.

The three `projecthoomans:*` categories now report
`semantic_response_flow` as conversational meaning authority. The existing
ConversationBlocks registry remains the owner of authored block data,
eligibility gates, branches, effects, and repeat behavior.

## Compatibility boundary

Generic PsychopatzCore SocialFlavor remains available to other adopters and to
presentation/transport infrastructure. Project Hoomans semantic-owned packets
must carry selected text and cannot silently invoke that generic prose
selector.

## P9 routing/content repair audit

ToolReply meaning remains selected once by `ResponseCatalog` and
`RealizationAuthority`; `PNC_ConversationToolReplies.lua` now passes that
selected response through the existing `SpeechRealization` seam so generated
Dialogue Content owns EN/TL wording at runtime. The old
`PNC_ConversationToolReplyCatalog.lua` and legacy ToolReply translation keys
remain migration/source material only. Event context-reference patterns now
declare their lifecycle offer metadata, so ordinary questions cannot be
claimed by an event follow-up parser outside an active disclosed response
window. Evidence: ToolReply EN/TL coverage, translation integration,
response-candidate isolation, and the 42-test event/context regression set.
