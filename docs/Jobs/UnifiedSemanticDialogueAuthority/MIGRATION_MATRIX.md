# Migration Matrix — Legacy Dialogue Owners to Unified Semantics

This is the active migration inventory. Update status/evidence as each family moves to single semantic authority.

| Legacy/content family | Current/known role | Target semantic owner | Follow-up opportunity | Target legacy disposition |
| --- | --- | --- | --- | --- |
| `social.conversation_farewell` | authored relationship-conditioned farewell prose + presentation alias | `semantic.flow.farewell` + Dialogue Content | normally none | remove first-party prose selection; keep presentation alias only if needed |
| `social.conversation_safety_danger` | safety warning prose | `semantic.conversation.safety` | what/where threat if grounded | semantic-selected text only |
| `social.player_spoke` | generic reaction/ack content | `semantic.social.reaction` / active beat continuation | continuation when relevant | migrate wording; retire prose selection |
| `social.witnessed_player_kill` | combat witness reaction | `semantic.combat.reaction` | what happened / are you okay / threat context | semantic-selected text only |
| `social.witnessed_teammate_hurt` | injury witness reaction | `semantic.medical.distress` or dedicated grounded reaction pool | who/what happened / medical need | semantic-selected text only |
| `social.follower_abandoned_zombie` | companion abandonment complaint | `semantic.companion.reaction` | what happened / hurt / threat | semantic-selected text only |
| `social.follower_abandoned_hostile_npc` | hostile-NPC abandonment complaint | `semantic.companion.reaction` | who attacked / what happened | semantic-selected text only |
| `social.zombie_horde_detected` | horde warning | `semantic.combat.reaction` with explicit horde context/variant | where / scale / what now | semantic-selected text only |
| `social.zombie_stamina_retreat` | stamina/retreat warning | semantic combat/needs/medical context as audit proves | need rest / hurt / retreat reason | semantic-selected text only |
| `social.incapacitated_call` | initial downed/medical plea | `semantic.medical.distress` | need / attacker / injury | migrate last after context matrix parity |
| `social.incapacitated_update` | changing downed state | `semantic.medical.distress` | same active medical beat | migrate last after parity |
| `social.incapacitated_repeat` | repeated downed plea | `semantic.medical.distress` + anti-repeat/content policy | same beat; no duplicate spam | retire duplicate prose selector |
| `social.witnessed_leader_death` | grief/succession reaction | `semantic.leader_loss.reaction` | who / what happened / what now | semantic-selected text only |
| ToolReplies: social react | literal accepted/rejected social wording | semantic social/emote response pools + Dialogue Content | active-beat continuation | remove ToolReply prose authority |
| ToolReplies: ask name | named/unnamed/rejected wording | semantic identity/name response path | identity/context follow-ups | remove ToolReply prose authority |
| ToolReplies: orders | follow/stay/camp ack/reject wording | `semantic.companion.reaction` / capability result response pools | command-result follow-up when meaningful | remove ToolReply prose authority |
| `projecthoomans:wellbeing` | explicit legacy conversation-registry authority | semantic wellbeing flow/provider | existing wellbeing follow-ups | set semantic authority; retire registry projection authority |
| `projecthoomans:small_talk` | explicit legacy conversation-registry authority | semantic social/small-talk provider | contextual continuation | set semantic authority |
| `projecthoomans:ask_about` | explicit legacy conversation-registry authority | semantic context/knowledge question path | context-reference follow-ups | set semantic authority |
| Bandits `compat.bandits.hooman_hurt` | compatibility event speech | semantic compatibility event context | medical/combat follow-up when facts exposed | adapter provides facts; no first-party prose fallback |
| Necroa mask warnings | compatibility event speech | semantic compatibility response pools | why/what happened if provider facts allow | adapter provides facts; no first-party prose fallback |
| Project ALife meta/encounter/faction speech | compatibility ambient event speech | semantic world/encounter/faction response pools | grounded event follow-ups | adapter provides canonical refs/facts; no first-party prose fallback |
| Core SocialFlavor generic API | generic cross-mod content/queue API | **not replaced** | n/a | retain generic compatibility, but Project Hoomans semantic-owned packets must carry selected realization |

## Status vocabulary

Use:

- `AUDIT_REQUIRED`
- `CHARACTERIZED`
- `SEMANTIC_FIRST_PARTIAL`
- `MIGRATED_SEMANTIC_AUTHORITY`
- `CONTENT_MIGRATED`
- `LEGACY_SELECTOR_RETIRED`
- `ACCEPTED`

A family is not `ACCEPTED` until production tests prove no semantic-owned fallback to legacy prose selection.
