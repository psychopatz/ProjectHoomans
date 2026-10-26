# Audit — Unified Semantic Dialogue Authority

**Audit baseline:** ProjectHoomans `181b58bcc30dc65dc61d19a49d6238abca50ece9`; PsychopatzCore `cf28189c57f7810f31d25c46c11eb88080f47baa`.

This audit establishes why a new follow-on goal is required even though the older Semantic Interaction Lifecycle P11 declared the audited migration families complete.

## What is already correct

### Semantic realization authority exists

`PNC_SemanticDialogueRealizationAuthority.lua` requires semantic selection before Flavor/SocialFlavor rendering for modern paths.

Current semantic response pools already include representative event speech such as:

- `semantic.flow.farewell`;
- `semantic.medical.distress`;
- `semantic.leader_loss.reaction`;
- `semantic.combat.reaction`;
- `semantic.companion.reaction`;
- `semantic.social.reaction`;
- `semantic.conversation.safety`;
- `semantic.corpse.reaction`.

Modern social-event producers commonly call semantic social reaction/realization first and pass selected text plus response-plan/realization/fact provenance into presentation.

### Semantic lifecycle already has the follow-up foundation

`PNC_SemanticInteractionLifecycle` already supports:

- `npc_speech` envelopes;
- `eventRef`;
- `beatID`;
- bounded thread event refs/memories;
- `RecordNPCSpeech`;
- `ResponseWindow`;
- sparse thread state and compaction.

`PNC_SemanticDialogueContextState` already owns:

- one bounded pending follow-up;
- bounded agenda;
- recent semantic turns/topics.

`PNC_SemanticContextResolver.ResolvePendingFollowUp` already resolves matched/interrupted follow-ups.

`ResponsePlan` already supports bounded turns, fact refs and per-turn offers.

The Suggestions system already supports contextual/branch-continuation candidates and a bounded `MAX_CANDIDATES = 24`.

**Conclusion:** do not add a second recent-event/follow-up subsystem. Extend the existing lifecycle response window/beat so NPC-initiated event speech exposes grounded follow-up offers through the existing semantic Suggestions route.

### Presentation infrastructure is useful

PsychopatzCore SocialFlavor / Project Hoomans SocialFlavor presentation still provides useful:

- queueing/arbitration;
- TTL/cooldown/priority;
- merge/dedupe;
- nameplate/world delivery;
- Conversation delivery;
- TTS;
- compatibility transport.

That infrastructure should remain below the semantic authority line.

## Residual split authority

### Core SocialFlavor can still choose prose

PsychopatzCore `PsychopatzSocialFlavorClient.lua` accepts already-selected text, but when text is absent it can still call `SocialFlavor.ResolveDetailed(flavorID, ...)` and choose prose from registered definitions.

That fallback is appropriate for generic external compatibility, but **Project Hoomans semantic-owned events must no longer depend on it**.

### Project Hoomans SocialFlavor definitions still own prose

The current native Project Hoomans registry includes at least these first-party families:

1. `social.conversation_farewell`
2. `social.conversation_safety_danger`
3. `social.player_spoke`
4. `social.witnessed_player_kill`
5. `social.witnessed_teammate_hurt`
6. `social.follower_abandoned_zombie`
7. `social.follower_abandoned_hostile_npc`
8. `social.zombie_horde_detected`
9. `social.zombie_stamina_retreat`
10. `social.incapacitated_call`
11. `social.incapacitated_update`
12. `social.incapacitated_repeat`
13. `social.witnessed_leader_death`

These tables still contain relationship/role/medical/context-conditioned authored prose. For migrated first-party semantics they should become source material for canonical semantic/content variants, then lose production decision authority.

### ToolReplies is another text authority

`PNC_ConversationToolReplyCatalog.lua` still owns literal reply pools for areas including:

- social react compliment/flirt/insult/apologize/comfort and relationship-gate rejection;
- ask-name named/unnamed/rejected;
- companion/order follow/stay/camp and rejection;
- other command acknowledgements/rejections.

Even when the action/gameplay owner is correct, this remains a parallel conversational content owner.

### Legacy conversation-registry authority remains explicit

`PNC_SemanticConversationCategoryOwnership.lua` still reports `MIGRATION_PHASE = "legacy_registry_projection"` / `AUTHORITY = "conversation_registry"` for at least:

- `projecthoomans:wellbeing`;
- `projecthoomans:small_talk`;
- `projecthoomans:ask_about`.

Those categories need final semantic ownership without duplicating ConversationBlocks/gameplay authority.

### Compatibility flavor families remain

First-party adapters still register flavor families for examples such as:

- Bandits: `compat.bandits.hooman_hurt`;
- Necroa: `compat.necroa.mask_warning`, `compat.necroa.player_mask_removed`;
- Project ALife meta/encounter/faction events.

Modern paths already carry semantic provenance in many cases, but the migration must prove Project Hoomans-owned compatibility speech no longer needs fallback prose selection.

## Misleading legacy names that are no longer authorities

`PNC_FlavorTextResolver.lua` is already a compatibility alias to semantic context providers rather than a prose resolver. Do not treat the filename alone as evidence of split authority.

Likewise, `PNC_SocialFlavorPresentation_*` may remain after migration if it only delivers already-selected semantic speech.

## Content coverage gap

The accepted Dialogue Content Registry proves the architecture but currently covers only a small migrated subset. Existing Flavor/ToolReply/translation wording must be migrated incrementally into canonical semantic/content ownership; do not dump all strings into one new monolith.

## Follow-up gap

Event-driven NPC speech currently carries semantic provenance, but the product does not yet standardize:

```text
ambient semantic event response
→ existing lifecycle beat/response window
→ contextual follow-up offers
→ player typed/click answer
→ grounded resolution against the same event/fact refs
```

This goal closes that gap using existing lifecycle/context machinery.

## Superseded historical claim

Older Semantic Interaction Lifecycle P11 evidence remains valid for the semantic-first paths it tested, but the statement that all first-party legacy prose authority was fully retired is superseded by this audit.

The old job remains foundation/history; this job is the active migration authority.
