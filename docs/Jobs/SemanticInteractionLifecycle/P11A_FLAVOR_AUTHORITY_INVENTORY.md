# P11A — Legacy Flavor Authority Inventory

**Status:** audit complete; migration work follows this inventory.

This is the bounded production-Lua inventory for the P11 authority
consolidation. `Flavor` is not globally forbidden: authored text,
translation, formatting, queueing, delivery, and compatibility are valid
uses below the semantic authority line. The classification here is about the
current behavior of each site, not only its module name.

## Classification rules

| Classification | Meaning |
| --- | --- |
| `CONTENT_ONLY` | Stores authored localized/fallback lines or content aliases. It may not choose a semantic branch. |
| `PRESENTATION_ONLY` | Translates, formats, queues, nameplates, diary, TTS, or UI-delivers an already selected realization. |
| `TRANSPORT_ONLY` | Carries bounded semantic/realization fields between authority and presentation. |
| `COMPATIBILITY_ONLY` | Preserves an external-mod or legacy API boundary without selecting Hoomans meaning. |
| `GAMEPLAY_DOMAIN_AUTHORITY` | Owns a gameplay fact/effect/permission. It must provide facts to semantic planning, not choose dialogue meaning. |
| `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` | Currently chooses a conversational act, topic, stance, response family, variant, or realization before/without a canonical semantic plan. |
| `DEAD_OBSOLETE` | No production caller should retain this decision API after dependency migration. |

## Direct semantic-decision sites

| Path / symbol | Current classification | Required disposition |
| --- | --- | --- |
| `42.20/media/lua/server/PNC/Social/PNC_SocialGreetingService_TryGreet.lua:101` `Interactions.GreetingReplyFlavorID` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` | Resolve a semantic GREET plan and realization first. Keep NPC type/tier/day only as authoritative eligibility/effect context or compatibility metadata. |
| `42.20/media/lua/shared/PNC/Core/Commands/PNC_VanillaEmoteInteractions.lua:325-378` `GreetingReplyFlavorID`, `ReplyFlavorID` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` | Emote is the input act. Active beat/context and the semantic response catalog choose the reply plan/family/ID. |
| `42.20/media/lua/server/PNC/Networking/Handlers/PNC_ServerPlayerEmoteInteractionCommandHandler.lua:317,377` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` plus gameplay-domain authority for applying the effect | Preserve command validation/effect/cooldown authority; remove role/tier Flavor ID selection from the reply path. |
| `42.20/media/lua/client/PNC/Conversation/PNC_ConversationFarewell.lua:109,187` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` | Close eligibility, chance, delay, and cooldown remain local lifecycle policy; FAREWELL response planning selects the realization before queueing. |
| `42.20/media/lua/shared/PNC/Core/Social/PNC_FlavorTextResolver.lua:56-330` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` in its current Flavor namespace | Split pure threat/audience/need/grief derivation into neutral semantic context providers. The providers may classify authoritative facts; they may not select Flavor variants or response text. |
| `common/media/lua/shared/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DownedDistress_Core_Shared.lua:43` and callers | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` | Retain bounded threat/audience/need facts; semantic medical/distress planning chooses the reaction family. |
| `42.20/media/lua/server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_LeaderLoss.lua:46-50` and `:59` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` | Succession/effect remains domain-owned; grief stance and realization must come from semantic LEADER_LOSS planning. |
| `42.20/media/lua/client/PNC/Conversation/PNC_SocialFlavorDefinitions_*.lua` `variants.when` tables | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` until migrated; their line payloads remain `CONTENT_ONLY` | Move branch/variant selection into the existing ResponseCatalog/ResponsePlan boundary. Keep the authored lines as registered content or translation fallbacks. |
| `42.20/media/lua/client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_*` `cell(...)` matrices | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` for the matrix choice; line arrays are `CONTENT_ONLY` | Use neutral medical/distress providers plus semantic response pools. SocialFlavor may only deliver the selected realization. |
| `42.20/media/lua/client/PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath*` `when(...)` matrices | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` for grief/succession selection; lines are `CONTENT_ONLY` | Use authoritative succession and neutral grief context providers, then a semantic plan. |

## Companion and social presentation paths

| Path / symbol | Current classification | Required disposition |
| --- | --- | --- |
| `42.20/media/lua/shared/PNC/Core/Commands/PNC_CompanionCommandFlavor.lua:114` `Flavor.Resolve` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` at present; intended end state is `CONTENT_ONLY`/compatibility adapter | A command result is gameplay-domain-owned. Semantic acknowledgement/reaction planning must select the realization, then this module may resolve authored content for that ID or receive resolved text. |
| `42.20/media/lua/client/PNC/Commands/PNC_CompanionCommandPresentation.lua:167,201,323,415` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` at present; intended end state is `PRESENTATION_ONLY` | Replace direct variant resolution with the selected semantic realization payload. Keep `Say`, message publication, nameplate, and TTS sinks. |
| `42.20/media/lua/client/PNC/Commands/PNC_CompanionCommandPresentation_PlayerEmoteResult.lua:75,247` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` at present; intended end state is `PRESENTATION_ONLY` | Player/emote outcome meaning is planned semantically before this adapter presents it. |
| `42.20/media/lua/client/PNC/Commands/PNC_CompanionCommandInteractionQueue.lua:124` | `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` at present; intended end state is `PRESENTATION_ONLY`/`TRANSPORT_ONLY` | Queue admission, priority, TTL, dedupe, and delivery remain. It must not call a context-sensitive resolver to choose the reply family. |
| `42.20/media/lua/client/PNC/Conversation/PNC_SocialFlavorPresentation_Core.lua` and `...Receive_*`, `...Delivery.lua` | `PRESENTATION_ONLY` / `TRANSPORT_ONLY` | Preserve context enrichment only as input projection and queue metadata. Remove response-family selection from `Flavor.Resolve` calls once callers provide semantic realization/text. |
| `42.20/media/lua/client/PNC/Conversation/PNC_ConversationDiary.lua:72` | `PRESENTATION_ONLY` | Diary formatting/replay lookup may remain; it must not be the source of conversational meaning. |
| `42.20/media/lua/client/PNC/Conversation/PNC_ConversationFarewell.lua` SocialFlavor client calls | `PRESENTATION_ONLY` after FAREWELL migration | Queue/render the semantic result; the legacy `social.conversation_farewell` ID may remain as a content alias only. |

## Domain, transport, and compatibility boundaries

| Path / family | Classification | Boundary rule |
| --- | --- | --- |
| Companion command success/failure, `PNC_CompanionCommandInteraction.lua` | `GAMEPLAY_DOMAIN_AUTHORITY` | It decides whether a command succeeded and its world effects. It must hand the outcome to semantic acknowledgement/reaction planning. |
| `PNC_FactionService_PlayerSuccession.lua` and leader-loss effects | `GAMEPLAY_DOMAIN_AUTHORITY` | It decides succession and faction state. It must not select grief wording. |
| Combat, medical executor, corpse-awareness, follower abandonment, and SocialEventHooks event IDs | `GAMEPLAY_DOMAIN_AUTHORITY` for event facts/effects; `SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE` for response-family selection | Preserve source validation, cooldown, effects, and canonical event refs; call semantic planning for speech. |
| `PNC_Network_Server_Social.lua`, client command routers, greeting/emote result payloads | `TRANSPORT_ONLY` | Carry `semanticAct`, `topic`, `responsePlanID`, `realizationFamily`, `realizationID`, fact refs, and optional resolved text. Do not derive them in the transport layer. |
| `Compatibility/Mods/Bandits/*`, `Necroa/*`, `ProjectALife/*`, and CompanionDogs adapters | `COMPATIBILITY_ONLY` for integration; registered lines are `CONTENT_ONLY` | External event authority remains external. Hoomans semantic planning owns any Hoomans conversational reaction; compatibility code may provide facts/content aliases only. |
| `PNC_Necroa_ZombieFlavor.lua` direct zombie captions | `COMPATIBILITY_ONLY` / `PRESENTATION_ONLY` | Deliberately outside Hoomans SocialFlavor; no Hoomans conversational branch may be selected there. |

## Legacy APIs to retire

| API | Classification | End state |
| --- | --- | --- |
| `Interactions.GreetingReplyFlavorID` | `DEAD_OBSOLETE` after greeting/emote migration | Keep only a short-lived content-alias shim if an external compatibility caller is proven; it must not be called by production conversational paths. |
| `Interactions.ReplyFlavorID` | `DEAD_OBSOLETE` after emote migration | Same rule; static guard prevents new production callers. |
| `PNC.FlavorText.Resolve` / Flavor-namespaced response key resolver | `DEAD_OBSOLETE` as a response selector; neutral classifier functions may be relocated/reused | Replace callers with semantic context providers and ResponseCatalog plans. |
| Context-sensitive `PsychopatzCore.SocialFlavor.Resolve` in production conversational callers | `DEAD_OBSOLETE` as an authority path | Keep Core renderer/content lookup below the authority line, accepting `realizationID`/resolved text and no longer inspecting relationship/need/grief to choose meaning. |

## Evidence and coverage

The inventory was produced from the current `main` checkout using the codebase
graph for `ReplyFlavorID`, `Flavor.Resolve`, and the classifier symbols, then
literal call-site scans for the exact legacy APIs and SocialFlavor definitions.
The current graph generation is ready for `project-hoomans`; candidate paths
must be coverage-checked again after the migration edits. This document is an
audit baseline, not a claim that P11 is complete.

## Current re-audit after the P11 migration slices

The preliminary rows above describe the work that was required. This section is
the current classification after the greeting, farewell, emote, event-family,
and presentation-boundary changes in this checkout; it supersedes any earlier
`MUST_MIGRATE` label for a site listed below.

| Site/family | Current classification | Evidence/boundary |
| --- | --- | --- |
| `PNC_SocialGreetingService_TryGreet.lua` | `GAMEPLAY_DOMAIN_AUTHORITY` + semantic realization | Eligibility/effect policy remains in the service; GREET selection uses `RealizationAuthority` and `semantic.flow.greeting.opening`. The old ID is a compatibility/content alias. |
| `PNC_ConversationFarewell.lua` | `GAMEPLAY_DOMAIN_AUTHORITY` + semantic realization + `PRESENTATION_ONLY` | Close/delay/cooldown remain lifecycle policy; FAREWELL plan is selected before queueing. |
| `PNC_ServerPlayerEmoteInteractionCommandHandler.lua` | `GAMEPLAY_DOMAIN_AUTHORITY` + semantic realization | Active beat and emote act enter `semantic.emote.reply`; no legacy reply helper is called. |
| Medical, combat, leader-loss, follower-abandonment, corpse-awareness, and medical-supply event producers | `GAMEPLAY_DOMAIN_AUTHORITY` + semantic realization | Authoritative facts/effects stay in their domains; each produces `responsePlanID`, `realizationFamily`, `realizationID`, fact refs, and resolved text before network/presentation. |
| `PNC_FlavorTextResolver.lua` | `SEMANTIC_CONTEXT_PROVIDER` | Threat, audience, need, grief, NPC-role, and relationship-tier functions return bounded derived facts only. They do not select prose or a Flavor ID. |
| `PNC_CompanionCommandFlavor.lua` and direct `Flavor.Resolve` call sites | `CONTENT_ONLY`/`PRESENTATION_ONLY` | Command outcome meaning is selected by semantic command planning; remaining calls are fallback authored-line rendering, diary hydration, or delivery. Ambient presentation refuses to synthesize lifecycle provenance for flavor-only packets. |
| `PNC_SocialFlavorPresentation_*` and queue/diary modules | `PRESENTATION_ONLY`/`TRANSPORT_ONLY` | They deliver selected text and bounded provenance; they cannot create a response plan from a legacy Flavor ID. |
| `Compatibility/Mods/*` | `COMPATIBILITY_ONLY` | External facts are normalized and passed through semantic reaction planning where Hoomans produces dialogue; external/legacy IDs remain transport/content aliases only. |
| `PNC_VanillaEmoteInteractions.lua` legacy reply helpers | `DEAD_OBSOLETE` for production authority; `CONTENT_ONLY` compatibility API for tests/older callers | A static guard verifies no production caller uses `ReplyFlavorID`, `GreetingReplyFlavorID`, `GreetingState`, `ResolveNPCType`, or `ResolveRelationshipTier`. |

Guard evidence: `tools/semantic_harness/tests/test_legacy_semantic_authority_p11.py`
passes 11/11; focused production-Lua event/interaction regressions pass 17/17.
The production-Lua authority smoke also covers renderer substitution across
greeting, farewell, emote, companion acknowledgement, combat, medical/distress,
and leader-loss/grief families without invoking the renderer for semantic
selection.
