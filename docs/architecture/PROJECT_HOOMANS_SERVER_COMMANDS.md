# Project Hoomans Server Command Inventory

This is the Chunk 3 migration index for the authoritative
`Events.OnClientCommand` boundary. `PNC` remains the required module namespace.
Unknown module names and unknown command names continue to be ignored.

The inventory records routing ownership only. Command strings, payload fields,
validation, responses, side effects, and authority remain defined by existing
constants and handlers.

## Routed Families

| Family | Inbound command | Current target | Migration |
|---|---|---|---|
| Inventory | `CMD_INVENTORY_TRANSFER` | `PNC.ServerInventory.Transfer(player, args or {})` | 3A routed |
| Inventory | `CMD_INVENTORY_ACTION` | `PNC.ServerInventory.Action(player, args or {})` | 3A routed |

The router consumes a registered command even when its optional service method
is unavailable, matching the prior branch behavior. It does not wrap handlers
in `pcall` or reinterpret handler results.

## Remaining Direct Families

| Family | Inbound commands / guards | Current responsibility |
|---|---|---|
| Player bootstrap | `CMD_PLAYER_BOOTSTRAP_REQUEST` | knowledge bootstrap handler |
| World discovery | `CMD_WORLD_DISCOVERY_REQUEST`, `CMD_WORLD_DISCOVERY_ACTION` | action plus discovery response |
| NPC presentation | `CMD_NPC_PRESENTATION_REQUEST` | presentation handler |
| Knowledge disclosure | `CMD_KNOWLEDGE_DISCLOSURE_REQUEST` | disclosure handler |
| Full synchronization | `CMD_FULL_SYNC_REQUEST` | build roster list and broadcast |
| Conversation scene | `ConversationScene.CMD_BEGIN`, `.CMD_END`, `.CMD_CEASEFIRE` | scene command handler |
| Conversation | `CMD_CONVERSATION_CATEGORY_REQUEST`, `CMD_CONVERSATION_CHOICE_REQUEST`, `CMD_CONVERSATION_RECRUIT_REQUEST` | authoritative conversation handlers when available |
| Character detail | `CMD_REQUEST_CHARACTER` with `args.id` | access validation and full payload/inventory delta |
| Health | `CMD_REVIVE` with `args.id`; `CMD_BANDAGE` with `args.id` and `args.partId` | revive/treatment services |
| Companion orders | `CMD_COMPANION_COMMAND` with `args.commandID` | companion command service |
| Map command | `CMD_MAP_COMMAND` | execute with debug authorization and send `CMD_MAP_COMMAND_RESULT` |
| Faction toll | `CMD_FACTION_TOLL_RESPONSE` | toll response handler |
| Player combat | `CMD_PLAYER_WEAPON_HIT` | authoritative damage report handler |
| Debug roster | `CMD_DEBUG_ROSTER_REQUEST` | authorization, optional body audit, roster response |
| Relationships | `CMD_RELATIONSHIP_DEBUG_REQUEST`, `CMD_CONVERSATION_RELATIONSHIP_REQUEST` | authorized debug or conversation-safe snapshots |
| NPC knowledge | `CMD_NPC_KNOWLEDGE_REQUEST`, `CMD_KNOWLEDGE_DEBUG_REQUEST` | authorized knowledge snapshots/actions |
| Factions | `CMD_FACTION_DEBUG_REQUEST`, `CMD_FACTION_MEMBERS_REQUEST`, `CMD_FACTION_MEMBER_ACTION` | debug/member snapshots and actions |
| Communities | `CMD_COMMUNITY_DEBUG_REQUEST` | authorized community diagnostics |
| Needs | `CMD_NEEDS_DEBUG_REQUEST` | authorized Needs diagnostics |
| Director | `CMD_DIRECTOR_DEBUG_REQUEST` | authorized Director diagnostics |
| Colony management | `CMD_COLONY_MANAGEMENT_REQUEST`, `CMD_COLONY_MANAGEMENT_ACTION` | presentation snapshot and allowlisted actions |
| Legacy debug envelope | `CMD_DEBUG` | one authorization gate followed by the actions below |

## Legacy `CMD_DEBUG` Actions

The following action strings remain one protocol envelope and must retain the
single `canUseDebug(player)` gate before any action executes:

- `spawn`, `teleport_to_npc`;
- `social_trigger_event`, `conversation_relationship_standing`,
  `relationship_debug_baseline`, `relationship_pacification`,
  `conversation_debug_recruit`;
- `knowledge_debug_action`, `faction_debug_action`,
  `community_debug_action`, `needs_debug_action`, `director_debug_action`;
- `force_live`, `force_abstract`;
- `heal`, `revive`, `damage`, `damage_part`, `infection`,
  `clear_infection`, `bandage_almost_dirty`;
- `animation_scene_play`, `animation_scene_pool_step`,
  `animation_scene_pool_start`, `animation_scene_stop`;
- `set_map_presentation`, `set_map_known`;
- `set_weapon_mode`, `copy_held_weapon`, `copy_player_loadout`,
  `set_equipment_slot`, `clear_equipment`;
- `toggle_debug`, `set_order`, `set_hostility`, `audit_bodies`.

## Extraction Rules

- Keep the module namespace gate ahead of router dispatch.
- Register the PZ `Events.OnClientCommand` callback once, at the existing
  `PNC_Server` registration point.
- A registered handler returns control to PZ exactly as the old branch did.
- Preserve each branch's current malformed-payload behavior. Do not broaden or
  tighten guards during structural extraction.
- Resolve domain services at call time where optional/load-order behavior
  currently permits absence.
- Extract by cohesive family and run its affected protocol/authority tests
  before registering the next family.
