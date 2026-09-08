local T = require "tests/support/test"

T.addPackagePaths()

local player = {
    getUsername = function() return "DebugAdmin" end,
    getOnlineID = function() return 42 end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local spawned
local baseline
local disclosure
local knowledgeSnapshot
local knowledgeSend
local spawnCount = 0
local baselineCount = 0

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_DEBUG = "DebugCommand",
        ORDER_FOLLOW = "follow",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
        ORDER_ROAM = "roam",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 12,
    },
    Core = {
        IsClientOnly = function() return false end,
        Now = function() return 500 end,
        LogWarn = function() end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    Network = {
        ClientState = {},
        SendNPCKnowledge = function(receivedPlayer, snapshot, reason)
            knowledgeSend = {
                player = receivedPlayer,
                snapshot = snapshot,
                reason = reason,
            }
        end,
    },
    Client = {
        CanUseDebug = function() return true end,
    },
    Registry = {},
    Inventory = {
        GetDebugEquipmentSpawnMode = function(_, requested)
            return requested or "sandbox_chances"
        end,
    },
    Factions = {
        EnsurePlayerFaction = function()
            return true, nil, { id = "faction_debug" }
        end,
    },
    PlayerCharacters = {
        GetEntityKey = function(receivedPlayer, context)
            T.equal(receivedPlayer, player,
                "local debug spawn resolves the player identity")
            T.equal(context.callback, "debug_companion_spawn",
                "local debug spawn uses the companion identity context")
            return "player:DebugAdmin:character-debug", "resolved"
        end,
    },
    Relationships = {
        SetInitialBaseline = function(npcID, targetKey, standing, at)
            baselineCount = baselineCount + 1
            baseline = {
                npcID = npcID,
                targetKey = targetKey,
                standing = standing,
                at = at,
            }
            return standing
        end,
    },
    NPCKnowledge = {
        DiscoverAllForPlayer = function(receivedPlayer, npcID, at, source, deferCommit)
            disclosure = {
                player = receivedPlayer,
                npcID = npcID,
                at = at,
                source = source,
                deferCommit = deferCommit,
            }
            return { revealed = { "identity.name" } }
        end,
        BuildPlayerSnapshotForPlayer = function(receivedPlayer, npcID)
            knowledgeSnapshot = {
                player = receivedPlayer,
                npcID = npcID,
            }
            return { npcID = npcID, revision = 1 }
        end,
    },
    API = {
        Spawn = function(spec)
            spawnCount = spawnCount + 1
            spawned = spec
            return { id = "local-debug-" .. tostring(spawnCount) }
        end,
    },
}

getSpecificPlayer = function() return player end
getGameTime = function()
    return { getWorldAgeHours = function() return 123 end }
end
package.preload["PsychopatzCore/World/PsychopatzTeleport"] = function()
    return {}
end

T.load("ProjectHoomans", "client", "PNC/Networking/PNC_ClientActions.lua")

T.equal(PNC.Client.SendDebug("spawn", {
    variant = "companion",
    tacticalClass = "colonist",
    equipmentSpawnMode = "melee",
}), true, "local companion debug spawn succeeds")
T.equal(spawned.recruited, true, "local debug companion is recruited")
T.equal(spawned.orderSpec.kind, "follow",
    "local debug companion receives the follow order")
T.equal(baseline.npcID, "local-debug-1",
    "local debug companion baseline targets the spawned NPC")
T.equal(baseline.standing.approval, 75,
    "local debug companion uses Has-a-friend approval")
T.equal(baseline.standing.respect, 65,
    "local debug companion uses Has-a-friend respect")
T.equal(baseline.standing.familiarity, 90,
    "local debug companion uses Has-a-friend familiarity")
T.equal(disclosure.source, "lifelong_relationship",
    "local debug companion uses the lifelong disclosure source")
T.equal(disclosure.deferCommit, true,
    "local debug companion defers disclosure commit")
T.equal(knowledgeSnapshot.npcID, "local-debug-1",
    "local debug companion builds its knowledge snapshot")
T.equal(knowledgeSend.snapshot.npcID, "local-debug-1",
    "local debug companion sends its knowledge snapshot")

PNC.Client.SendDebug("spawn", {
    variant = "neutral",
    tacticalClass = "neutral",
})
T.equal(baselineCount, 1,
    "neutral debug spawn does not receive companion relationship state")
T.finish("pnc_client_debug_spawn_initialization_smoke")
