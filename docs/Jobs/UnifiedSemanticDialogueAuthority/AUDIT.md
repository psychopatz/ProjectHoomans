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


## Post-P9 cleanup audit — `fa1d9f9f`

P0–P9 correctly established semantic-first runtime behavior, but a subsequent
source/UI audit found that the repository still carries migration-era
architecture that conflicts with the desired steady state.

### Executable first-party legacy definitions remain

The production mod tree still contains `PNC_SocialFlavorDefinitions.lua` and
its shards, with 13 first-party `Flavor.Register(...)` registrations covering
farewell, combat/medical reactions, abandonment, horde/retreat, incapacitated
speech and leader loss.

Bandits/Necroa/Project ALife first-party compatibility Flavor-definition files
also remain physically present.

These files are no longer needed as semantic authority and must not remain in
production merely as migration history. P10 must prove content parity and
delete them.

### ToolReply literal catalog is still loaded by the worker

`PNC_ConversationToolReplies.lua` correctly selects through ResponseCatalog and
states that it no longer reads the former literal table. However,
`ProductionModules_ConversationSemantic.lua` still explicitly loads
`PNC_ConversationToolReplyCatalog.lua` as `tool_catalog`.

That is an unnecessary split-source residue and makes the old catalog appear
live. P10 deletes the table and the load after parity proof.

### CompanionCommandFlavor is still a live wording registry

`PNC_SharedComposition_Final.lua` still loads `PNC_CompanionCommandFlavor` and
its definition shards. Some player command/emote and NPC presentation helpers
still call `Flavor.Resolve(...)`.

The semantic emote catalog currently treats those groups as a compatibility
content source, which means semantic meaning may be selected first but Dialogue
Content is not yet the sole first-party wording registry.

P10 migrates this content to ResponseCatalog + SpeechRealization + Dialogue
Content and removes the parallel registry.

### Legacy semantic names remain

`PNC_FlavorTextResolver*` now provides semantic threat/audience/need/grief
context but retains `PNC.FlavorText` / `PNC.FlavorTextConst`.

`PNC_FlavorAddress*` remains a useful addressing/identity projection beside the
newer semantic address resolver, but its name and namespace preserve the
obsolete Flavor architecture.

P10 keeps the behavior and removes/merges the legacy naming/namespace.

### Dialogue Content source is migration-heavy

Measured source state:

- about 242 KB;
- 168 phrase families / 179 phrase records;
- 167 family IDs contain `.migrated.`;
- 167 families contain `MIGRATED_*` concepts;
- 167 families contain `legacySource`;
- roughly 1,674 repeated locked metadata fields;
- roughly 126 KB attributable to repeated `canonicalConcept + locked` metadata.

Most repeated semantic ownership/conditions/priority/follow-up metadata does not
belong to the wording owner. It duplicates ResponseCatalog truth for Studio
display.

P10 introduces a compact canonical schema and makes Studio join semantic and
content authorities dynamically.

### Studio has reached flat-list scaling limits

The current production catalog contains 191 response pools and 168 content
families. Both Studio surfaces render flat lists.

The IDs already encode natural hierarchy (`semantic.compat.*`,
`semantic.medical.distress.*`, `semantic.tool_reply.*`,
`semantic.generated.*`, etc.). P10 must derive a tree from those canonical IDs
rather than inventing another grouping database.

### Revised conclusion

P0–P9 remain accepted semantic-runtime foundation, but the previous
`READY FOR USER LIVE TEST` boundary is superseded.

The parent goal is reopened for P10 because the desired steady state is not
"legacy code is no longer authoritative"; it is:

> **legacy first-party dialogue code/content is absent, canonical semantic/content
> ownership is compact, and Studio exposes that ownership hierarchically.**
