local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local player = {
    access = "",
    getAccessLevel = function(self) return self.access end,
    getUsername = function() return "DebugAdmin" end,
    getOnlineID = function() return 42 end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getPrimaryHandItem = function()
        return { getFullType = function() return "Base.Axe" end }
    end,
}
local warnings = {}
local apiCalls = {}
local networkCalls = {}
local relationshipCalls = {}
local diagnosticCalls = {}
local spawned
local teleported
local audited

local function networkCapture(name)
    return function(...)
        networkCalls[name] = { ... }
    end
end

PNC = {
    Const = {
        CMD_DEBUG = "DebugCommand",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
        ORDER_FOLLOW = "follow",
        ORDER_ROAM = "roam",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 12,
    },
    Core = {
        Now = function() return 321 end,
        LogInfo = function() end,
        LogWarn = function(message)
            warnings[#warnings + 1] = message
        end,
    },
    Types = {
        NormalizeFaction = function(value) return value end,
    },
    Inventory = {
        GetDebugEquipmentSpawnMode = function(variant, requested)
            return requested or "sandbox_chances"
        end,
    },
    Archetypes = {
        Get = function(id) return { id = id } end,
        GetColonistDefaults = function() return { "General" } end,
        GetHostileDefaults = function() return { "Scavenger" } end,
    },
    API = {
        Spawn = function(spec)
            spawned = spec
            return { id = "spawned-1" }
        end,
        DebugCommand = function(id, action, args)
            apiCalls[#apiCalls + 1] = {
                kind = "debug", id = id, action = action, args = args,
            }
        end,
        SetOrder = function(id, orderSpec)
            apiCalls[#apiCalls + 1] = {
                kind = "order", id = id, value = orderSpec,
            }
        end,
        SetHostility = function(id, modeSpec)
            apiCalls[#apiCalls + 1] = {
                kind = "hostility", id = id, value = modeSpec,
            }
        end,
    },
    Registry = {
        Get = function(id)
            if id == "npc-teleport" then
                return { id = id, x = 100, y = 200, z = 0 }
            end
            return nil
        end,
        GetLiveZombie = function() return nil end,
    },
    Network = {
        SendRelationshipDebug = networkCapture("relationship"),
        SendConversationRelationship = networkCapture("conversation"),
        SendKnowledgeDebug = networkCapture("knowledge"),
        SendColonyManagement = networkCapture("colony"),
        SendFactionDebug = networkCapture("faction"),
        SendCommunityDebug = networkCapture("community"),
        SendNeedsDebug = networkCapture("needs"),
        SendDirectorDebug = networkCapture("director"),
        SendDebugRoster = networkCapture("roster"),
    },
    RelationshipDebug = {
        TriggerSocialEvent = function(receivedPlayer, args)
            relationshipCalls.social = args
            return { kind = "social" }, "social_reason"
        end,
        SetConversationStanding = function(receivedPlayer, args)
            relationshipCalls.standing = args
            return { kind = "standing" }, "standing_reason"
        end,
        ApplyDebugBaseline = function(receivedPlayer, args)
            relationshipCalls.baseline = args
            return { kind = "baseline" }, "baseline_reason"
        end,
        SetPlayerPacification = function(receivedPlayer, args)
            relationshipCalls.pacification = args
            return { kind = "pacification" }, "pacification_reason"
        end,
    },
    NPCKnowledge = {
        ExecuteDebugForPlayer = function(receivedPlayer, args)
            diagnosticCalls.knowledge = args
            return { kind = "knowledge" }, "knowledge_reason"
        end,
    },
    DebugCompanionRecruit = {
        Try = function() return true, "recruited" end,
    },
    ColonyManagement = {
        BuildSnapshot = function() return { kind = "colony" } end,
    },
    FactionDebug = {
        PerformAction = function(receivedPlayer, args)
            diagnosticCalls.faction = args
            return { kind = "faction" }
        end,
    },
    CommunityDebug = {
        PerformAction = function(receivedPlayer, args)
            diagnosticCalls.community = args
            return { kind = "community" }
        end,
    },
    NeedsDebug = {
        PerformAction = function(args)
            diagnosticCalls.needs = args
            return { kind = "needs" }
        end,
    },
    AbstractDirectorDebug = {
        PerformAction = function(args)
            diagnosticCalls.director = args
            return { kind = "director" }
        end,
    },
    BodyLifecycle = {
        LastAudit = { marker = "audit" },
        AuditLoadedBodies = function(now, forced)
            audited = { now = now, forced = forced }
        end,
        BuildDebugRoster = function() return { { id = "npc-1" } } end,
    },
}

isServer = function() return true end
getCell = function() return nil end

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerLegacyDebugCommandHandler"
PNC.ServerLegacyDebugCommandHandler.ConfigureTeleport({
    ToCoordinates = function(receivedPlayer, x, y, z)
        teleported = { player = receivedPlayer, x = x, y = y, z = z }
        return true
    end,
})

assertEqual(Router.Handle("DebugCommand", player, { action = "heal" }), true,
    "unauthorized debug command consumed")
assertEqual(#apiCalls, 0, "unauthorized debug command executed")
assert(string.find(warnings[1], "action=heal", 1, true),
    "unauthorized action missing from warning")

player.access = "admin"
Router.Handle("DebugCommand", player, nil)
assertEqual(#apiCalls, 0, "nil debug payload executed")
Router.Handle("DebugCommand", player, { action = "unknown_action" })
assertEqual(#apiCalls, 0, "unknown debug action executed")

Router.Handle("DebugCommand", player, {
    action = "spawn", variant = "hostile_melee", x = 4, y = 5, z = 0,
})
assertEqual(spawned.faction, "hostile", "debug spawn faction")
assertEqual(spawned.archetypeID, "Scavenger", "debug spawn archetype")
assertEqual(spawned.orderSpec.kind, "hostile_hunt", "debug spawn order")
assertEqual(spawned.forceLive, true, "debug spawn force-live")
assertEqual(spawned.debug, true, "debug spawn flag")

Router.Handle("DebugCommand", player, {
    action = "teleport_to_npc", id = "npc-teleport",
})
assertEqual(teleported.player, player, "teleport player")
assertEqual(teleported.x, 101.5, "teleport x")
assertEqual(teleported.y, 201.5, "teleport y")

local relationshipActions = {
    social_trigger_event = "social",
    conversation_relationship_standing = "standing",
    relationship_debug_baseline = "baseline",
    relationship_pacification = "pacification",
}
for action, key in pairs(relationshipActions) do
    local args = { action = action, id = "npc-2" }
    Router.Handle("DebugCommand", player, args)
    assertEqual(relationshipCalls[key], args, action .. " payload")
end

local knowledgeArgs = { action = "knowledge_debug_action", id = "npc-3" }
Router.Handle("DebugCommand", player, knowledgeArgs)
assertEqual(diagnosticCalls.knowledge, knowledgeArgs, "knowledge payload")
assertEqual(networkCalls.knowledge[2].kind, "knowledge",
    "knowledge response")

Router.Handle("DebugCommand", player, {
    action = "conversation_debug_recruit", npcID = "npc-4",
})
assertEqual(networkCalls.colony[2].kind, "colony", "recruit colony refresh")

local diagnosticActions = {
    faction_debug_action = "faction",
    community_debug_action = "community",
    needs_debug_action = "needs",
    director_debug_action = "director",
}
for action, key in pairs(diagnosticActions) do
    local args = { action = action }
    Router.Handle("DebugCommand", player, args)
    assertEqual(diagnosticCalls[key], args, action .. " payload")
    assertEqual(networkCalls[key][2].kind, key, action .. " response")
end

local directActions = {
    "force_live", "force_abstract", "heal", "revive", "damage",
    "damage_part", "infection", "clear_infection",
    "bandage_almost_dirty", "animation_scene_play",
    "animation_scene_pool_step", "animation_scene_pool_start",
    "animation_scene_stop", "set_map_presentation", "set_weapon_mode",
    "set_equipment_slot", "clear_equipment", "toggle_debug",
}
for _, action in ipairs(directActions) do
    local args = { action = action, id = "npc-5" }
    Router.Handle("DebugCommand", player, args)
    local call = apiCalls[#apiCalls]
    assertEqual(call.action, action, action .. " route")
    assertEqual(call.args, args, action .. " payload identity")
end

local mapArgs = { action = "set_map_known", id = "npc-6" }
Router.Handle("DebugCommand", player, mapArgs)
assertEqual(mapArgs.playerKey, "DebugAdmin", "map-known player key")

local weaponArgs = { action = "copy_held_weapon", id = "npc-7" }
Router.Handle("DebugCommand", player, weaponArgs)
assertEqual(weaponArgs.weaponFullType, "Base.Axe", "copied weapon type")
assertEqual(weaponArgs.sourcePlayer, player, "copied weapon source player")

local loadoutArgs = { action = "copy_player_loadout", id = "npc-8" }
Router.Handle("DebugCommand", player, loadoutArgs)
assertEqual(loadoutArgs.sourcePlayer, player, "copied loadout source player")

local orderSpec = { kind = "guard" }
Router.Handle("DebugCommand", player, {
    action = "set_order", id = "npc-9", orderSpec = orderSpec,
})
assertEqual(apiCalls[#apiCalls].kind, "order", "set-order route")
assertEqual(apiCalls[#apiCalls].value, orderSpec, "set-order payload")
local modeSpec = { mode = "hostile" }
Router.Handle("DebugCommand", player, {
    action = "set_hostility", id = "npc-9", modeSpec = modeSpec,
})
assertEqual(apiCalls[#apiCalls].kind, "hostility", "set-hostility route")
assertEqual(apiCalls[#apiCalls].value, modeSpec, "set-hostility payload")

Router.Handle("DebugCommand", player, { action = "audit_bodies" })
assertEqual(audited.now, 321, "body audit time")
assertEqual(audited.forced, true, "body audit force")
assertEqual(networkCalls.roster[2][1].id, "npc-1", "body audit roster")
assertEqual(networkCalls.roster[3], true, "body audit authorization")
assertEqual(networkCalls.roster[4], PNC.BodyLifecycle.LastAudit,
    "body audit metadata")

print("pnc_server_legacy_debug_command_handler_smoke: ok")
