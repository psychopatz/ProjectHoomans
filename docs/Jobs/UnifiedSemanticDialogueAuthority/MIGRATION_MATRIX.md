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

## P9 developer acceptance closure

P9 added no new conversational authority or persistence owner. The final
production checks preserve the matrix boundaries: Project Hoomans semantic
packets are selected before presentation, Dialogue Content owns wording, and
generic PsychopatzCore SocialFlavor remains compatibility-only. Native
semantic smoke tests now supply selected semantic realizations directly, so
the acceptance path itself cannot validate a migrated family by accidentally
consulting first-party legacy prose. The complete Python/Lua/Kahlua,
source-save safety, and deterministic CodeBuilder evidence is recorded in
`PROGRESS.md`.


## P10A source purge audit

P10A closed the dead first-party prose registries after an exact caller/loader
audit and semantic/content parity proof. The executable production surfaces
deleted in this slice are:

- all 20 `PNC_SocialFlavorDefinitions*` files, including the incapacitated
  and LeaderDeath shards;
- `PNC_Bandits_HoomansFlavorDefinitions.lua`,
  `PNC_Necroa_HoomansFlavorDefinitions.lua`, and
  `PNC_ProjectALife_FlavorDefinitions.lua`;
- `PNC_ConversationToolReplyCatalog.lua` and its worker `tool_catalog` load.

The current owners are the semantic event adapters and the existing
ResponseCatalog/ResponsePlan/Dialogue Content path. The production tree and
worker/runtime composition contain no load or require reference to those
deleted paths. The zombie abandonment cause is explicitly routed to
`semantic.companion.reaction` before the generic combat-cause matcher.
Leader-loss close, colonist, and distant variants were added to the existing
semantic pool and generated content source so the queue parity test retains
distinct semantic realizations.

Evidence: `pnc_unified_authority_p10a_legacy_absence_smoke` plus the P3/P4/P5/
P6/P8/presentation/medical/leader-loss native set passes `10/10`; the focused
Python content/Observatory/compiler set passes `27/27`; targeted Kahlua scans
cover 25 Lua files with zero errors/warnings. The next live wording owner is
`PNC_CompanionCommandFlavor*`, tracked as P10B below.

## P10 cleanup closure matrix

The P0–P9 rows above remain behavioral migration evidence. P10 tracks removal
of the migration scaffolding itself.

| Residual surface | P10 target | Required disposition |
| --- | --- | --- |
| `PNC_SocialFlavorDefinitions*` | canonical semantic/content only | delete files and loads; replace old definition tests |
| Bandits/Necroa/Project ALife PNC Flavor definitions | compatibility facts → semantic pools → Dialogue Content | delete first-party wording definitions after parity |
| `PNC_ConversationToolReplyCatalog.lua` | semantic ToolReply pools + Dialogue Content | delete file and worker `tool_catalog` load |
| `PNC_CompanionCommandFlavor*` | semantic command/emote/greeting pools + Dialogue Content | migrate remaining callers, then delete registry/definitions |
| `PNC.FlavorText*` / `PNC_FlavorTextResolver*` | semantic social-context provider | rename/merge; remove legacy namespace/aliases |
| `PNC.FlavorAddress*` | canonical semantic addressing | reconcile/rename; remove legacy namespace |
| `PNC_SocialFlavorPresentation*` and `flavorID` terminology | semantic/speech presentation | rename/consolidate where no external compatibility contract requires the legacy name |
| `.migrated.` / `MIGRATED_*` / `legacySource` content metadata | compact steady-state Dialogue Content | remove from canonical source; retain history only in Git/job docs |
| flat Studio Responses/Dialogue Content lists | derived semantic tree | shared branch projection, counts, search, full IDs in detail pane |
| generic PsychopatzCore SocialFlavor API | external compatibility only | Project Hoomans has zero wording-selection dependency; do not fork another PNC compatibility layer |

### P10B ownership closure

| Migrated family | Actual production callers | Semantic/content owner | Follow-up / compatibility disposition | Proof |
| --- | --- | --- | --- | --- |
| Player commands and NPC acknowledgements/rejections | `PNC_CompanionCommandInteraction`, `PNC_CompanionCommandInteractionQueue`, server emote interaction handler | `semantic.command.player` / `semantic.command.reply` → `PNC_SemanticCompanionSpeech` → `commands_emotes` Dialogue Content | Command outcome remains an authority fact; no first-party Flavor fallback | `pnc_unified_authority_p10b_companion_command_absence_smoke`, command interaction/presentation smokes |
| Player and NPC emotes | `PNC_CompanionCommandEmotes`, `PNC_CompanionCommandPresentation*`, vanilla emote handler | `semantic.emote.player.*` / `semantic.emote.reply.*` → `commands_emotes` Dialogue Content | Emote transport retains event identity only; selected realization is delivered unchanged | player-emote, vanilla-emote, delivery and presentation smokes |
| Greetings | `PNC_SocialGreetingService_TryGreet`, client greeting presentation | `semantic.flow.greeting.*` → `commands_emotes` Dialogue Content | Greeting state/tier remains context; no registry wording owner | social-greeting and P7 content tests |
| Companion Dogs | `PNC_CompanionDogs_Interaction` / `Presentation` | `semantic.compat.companion_dogs.*` → `compatibility` Dialogue Content | Dog provider supplies sex/hunger/feed facts; no Project Hoomans flavor registry | `pnc_companion_dogs_compatibility_smoke`, P10B absence smoke |

P10B source facts: the six `PNC_CompanionCommandFlavor*` files, literal Companion
Dogs flavor table, and composition loads are absent. `Flavor.Resolve` and
`Flavor.Register` are absent from Project Hoomans production Lua; generic
PsychopatzCore SocialFlavor remains an external compatibility boundary.

P10 is accepted only when every row is closed with source-level and runtime
evidence.

## P10 current closure (authoritative over historical migration notes above)

The P7/P8 paragraphs above preserve the migration audit trail. Their wording
about “source material”, `migrated_events`, legacy source metadata, or residual
`Flavor.Resolve` compatibility is historical and is superseded by this
current closure section.

| Cleanup surface | Current owner/callers | Current source of truth | Current evidence | Disposition |
| --- | --- | --- | --- | --- |
| Social context classification | `PNC_Semantics.SocialContext`; social event hooks and medical context providers | bounded threat/audience/need/grief semantic context | `pnc_semantic_social_context_smoke`, P10C namespace smoke, incapacitated lifecycle smoke | `P10C_ACCEPTED`; no `PNC.FlavorText*` namespace or resolver file |
| Conversational addressing | `PNC.Semantics.AddressResolver`; identity and relationship presentation callers | identity/knowledge authority plus semantic relationship-term projection | `pnc_semantic_address_projection_smoke`, identity/presentation regressions | `P10C_ACCEPTED`; no `PNC.FlavorAddress*` namespace or files |
| Speech presentation | `PNC.SemanticSpeechPresentation`; semantic delivery and receive modules | already-selected realization/content text; generic Core queue only at transport boundary | speech presentation/transport/delivery smokes, P10C namespace smoke | `P10C_ACCEPTED`; no PNC `SocialFlavorPresentation` files |
| Event/medical semantic packets | event adapters, `DownedDistress`, leader-loss and compatibility presenters | `ResponseCatalog` → `ResponsePlan`/realization → Dialogue Content; `speechEventID` packet identity | event, medical, compatibility, leader-loss, and P10F negative smokes | `P10C/P10D_ACCEPTED`; no first-party legacy prose selector |
| Dialogue Content canonical source | CodeBuilder v2 source and generated Registry/EN/TL artifacts | semantic template/realization identity plus grouped content metadata | compact-content, parity, idempotence and P10F marker scans | `P10D_ACCEPTED`; `105007` source bytes, `216` families, `395` phrases, `1` player choice; zero migration markers |
| Responses and Dialogue Content Studio organization | `studio/semantic_tree.py` projected by both panes | derived hierarchy from canonical `semantic.*` IDs | `test_semantic_tree_projection_p10e`, focused Xvfb Studio lane | `P10E_ACCEPTED`; bounded paging, search expansion, lazy details |
| First-party legacy registries | no production callers or loaders | Git history only | `pnc_unified_authority_p10f_zero_legacy_smoke`, file/load scans | `P10F_PENDING_FINAL_GATE`; deleted from production tree, final full acceptance outstanding |
| Generic PsychopatzCore SocialFlavor | external Core queue/arbitration/TTS/nameplate API and non-Hoomans adopters | adopter-owned compatibility contract | Core compatibility smoke and PNC transport boundary tests | `COMPATIBILITY_ONLY`; not a Project Hoomans wording authority |
| External compatibility adapters | Bandits bridge and Necroa native zombie caption adapter | external provider facts/events; Hoomans semantic compatibility pools where applicable | Bandits/Necroa/Project ALife/Companion Dogs compatibility tests | `COMPATIBILITY_ONLY`; retain only where external transport/provider behavior requires it |

P10F zero-legacy criteria are accepted by source audit: no first-party
`PNC_SocialFlavorDefinitions*`, `PNC_ConversationToolReplyCatalog.lua`, or
`PNC_CompanionCommandFlavor*`; no `PNC_FlavorText*`, `PNC_FlavorAddress*`, or
PNC `SocialFlavorPresentation` files; no worker/composition loads of deleted
files; no canonical `.migrated.`, `MIGRATED_*`, `legacySource`,
`semanticAuthority`, duplicated response-pool/variant IDs, or migration-era
locked metadata. The retained `SocialFlavorClient`, `flavorID`, ambient-flavor,
PBrainZ, Necroa, and Companion Dogs names are bounded external
compatibility/provider transport surfaces, not Project Hoomans wording
registries.

## P10F final acceptance closure

The final semantic/content/presentation ownership is:

| Layer | Authoritative responsibility | Final implementation evidence |
| --- | --- | --- |
| Semantic meaning | pool/variant selection, facts, gates, response plans and follow-up offers | `PNC.Semantics.ResponseCatalog`, `ResponsePlan`, lifecycle/context providers, event/follow-up native smokes |
| Wording | EN/TL phrase realization and style | Dialogue Content schema v2, CodeBuilder, generated Registry and translation artifacts; `216` families / `395` phrases |
| Continuation | beats, event references, fact references, disclosure windows and typed follow-up routing | existing `SemanticInteractionLifecycle` / `DialogueContextState` path |
| Delivery | already-selected text plus semantic provenance to the existing queue/presentation | `PNC.SemanticSpeechPresentation` and `SemanticSpeechDelivery`; generic Core queue retained only as transport |
| Studio organization | derived bounded hierarchy, not a new store | `studio.semantic_tree` projected by Responses and Dialogue Content |

The canonical source is schema v2 at `105,007` bytes with `216` phrase
families, `395` phrases, and `1` player-choice artifact. Generated Registry,
EN, and TL artifacts are `205,402`, `39,671`, and `39,924` bytes. CodeBuilder
was run twice with identical outputs. Final developer acceptance is recorded
in `PROGRESS.md`: resource-aware Python `159/159` module PASS in `393.81s`
with four isolated processes; focused Xvfb `49/49` PASS in `47.89s`; native
Lua `901/901` PASS in `6.85s`; installed-PZ Kahlua `0` errors / `0` warnings;
real-save source hash unchanged; and `git diff --check` PASS. P10A–P10F are
closed and the matrix is ready for the user-owned native SP/MP validation
boundary.

## P11A current closure

P11A removed migration-only runtime vocabulary and consolidated historical
absence tests without changing semantic/runtime authority.

| Surface | Verified current owner/callers | P11A disposition | Evidence |
| --- | --- | --- | --- |
| Category/composer/suggestion migration metadata | semantic category ownership, ConversationComposer semantic output, and Suggestions offer projection | `legacyRegistry` and `migrationPhase` removed from runtime packets; authority/meaning-owner fields retained | `pnc_semantic_conversation_ownership_smoke`, `pnc_conversation_architecture_contract_smoke` |
| Trace naming | semantic input/world-target/inventory/action-plan callers | `legacyTrace` locals renamed to neutral `coreTrace`; Core DebugTrace behavior unchanged | focused production-Lua suite and source audit |
| LocalResponse legacy fallback registration | `PNC_SemanticDialogueLocalResponse_Core` and input composition | `LEGACY_TEXT_FALLBACKS` table/registration removed; remaining authored LocalResponse wording is the P11B migration surface | `test_legacy_semantic_authority_p11`, architecture contract |
| Compatibility speech bridge names | Bandits incoming damage/adapter; Necroa client composition; Companion Dogs interaction/presentation | first-party filenames/API locals now describe speech/caption transport; external behavior and transport contracts preserved | Bandits, Necroa, compatibility-shape, Companion Dogs smokes; PZ verifier |
| Historical P8/P10 absence tests | deleted first-party legacy registry/namespace surfaces | consolidated into durable architecture-contract absence plus positive parity assertions; domain/runtime tests retained | `tests/pnc_conversation_architecture_contract_smoke.lua` |

## P11B current closure

| Surface | Verified current owner/callers | P11B disposition | Evidence |
| --- | --- | --- | --- |
| First-party semantic response wording | ResponseCatalog selection plus Dialogue Content registry | direct catalog/LocalResponse prose removed; semantic template IDs and bounded args/facts are selected before realization | focused local-response, route, response-catalog, event-follow-up and P7 content smokes |
| Static semantic translation-key maps | client response translation resolver | deleted; resolver derives canonical Dialogue Content keys and resolves bounded runtime aliases | local-route/identity presentation smokes; Kahlua scan |
| SpeechRealization family packs/builders | generated Dialogue Content Registry | deleted; SpeechRealization only applies canonical phrase families and exposes compatibility read-only coverage | realization authority, command/emote and P7 content smokes |
| `Responses.json`, `Realizations.json`, identity response catalogs | Dialogue Content EN/TL artifacts | deleted from production tree and translation manifest after EN/TL key/provenance parity checks | `test_legacy_semantic_authority_p11` negative absence plus positive artifact assertions |
| Grounded event follow-up wording | event semantic pools plus Dialogue Content | known answers use canonical `%s` templates with authoritative fact args; unknown answers use explicit canonical unknown templates | P2 event-follow-up smoke; typed/clicked selection parity retained |
| Command/emote/greeting wording | command/emote/greeting ResponseCatalog pools plus Dialogue Content | canonical phrase variants retain deterministic anti-repeat and target argument formatting | companion command, emote, greeting and P7 content smokes |

## P11C current closure

| Surface | Verified current owner/callers | P11C disposition | Evidence |
| --- | --- | --- | --- |
| Canonical Conversation source entrypoint | Dialogue Content CodeBuilder and shared authoring service | `conversation/manifest.json` is the sole content entrypoint; domain shards are declared there and the deleted monolith is not loaded | `test_p11_conversation_shards`, CodeBuilder output |
| Domain content ownership | Dialogue Content shard loader | wording is grouped into cohesive Conversation-domain shards; shard order is deterministic and does not change stable semantic IDs | shard compiler test, generated Registry/content smokes |
| NLU/pattern authoring boundary | `semantic_definitions.json` and semantic compiler inputs | patterns remain outside response/content shards; response pools and phrase wording are no longer embedded in generic pattern data | shard schema/absence assertions |
| Global identity and generated join | Dialogue Content compiler | merged shards validate globally unique phrase, semantic-template, and player-choice IDs and retain the canonical semantic/content join | `test_p11_conversation_shards`, CodeBuilder twice |
| Authoring writes and stale guards | `SemanticLabAuthoringService` | aggregate fingerprints, owning-shard writes, effect-free previews, and explicit writes are exposed through the service; callers do not patch shard files | service shard write test |

## P11D current closure

| Surface | Verified current owner/callers | P11D disposition | Evidence |
| --- | --- | --- | --- |
| Conversation UI source | manifest-declared conversation UI registry and CodeBuilder | one bounded conversation/ui_registry.json owns landing, hub, child, order, content references, semantic destinations, and provider references | test_p11_conversation_ui_registry, generated ConversationUI Registry |
| What's Up structure | landing projection and static-question provider | generated registry supplies the root shortcut and nine static hub children; candidate IDs and ordering remain production-parity stable | contextual What's Up/hub/talk parity, production Lua smokes |
| Wording references | Dialogue Content player-choice records | UI nodes carry content IDs and generated label/utterance keys; EN/TL wording is not duplicated in the UI registry or semantic provider | Dialogue Content registry parity |
| Provider and semantic authority | static provider, relationship/gossip/gameplay authorities | provider references and semantic destinations are locked references; eligibility, facts, permissions, response meaning, and effects remain outside UI source | UI schema negative assertions, contextual provider tests |
| Agent/human UI edits | SemanticLabAuthoringService | bounded inspect/validate/preview/write plus add/remove/move/reorder operations use one source fingerprint and reject stale/locked edits | test_p11_conversation_ui_registry |

P11E is now the active semantic-taxonomy slice. Its audit must preserve domain
meaning and move generator provenance into metadata rather than canonical IDs.
