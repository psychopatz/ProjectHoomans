local CLIENT_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PNC_Client.lua"
local SERVER_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/server/PNC/PNC_Server.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local nativeTeleports = {}
local clientCommands = {}
local coreTeleportCalls = {}
local clientOnly = false
local player = {
    getAccessLevel = function() return "admin" end,
    teleportTo = function(_, x, y, z)
        nativeTeleports[#nativeTeleports + 1] = { x = x, y = y, z = z }
    end,
}

getSpecificPlayer = function() return player end
isClient = function() return false end
sendClientCommand = function(_, module, command, payload)
    clientCommands[#clientCommands + 1] = { module = module, command = command, payload = payload }
end
package.preload["PsychopatzCore/World/PsychopatzTeleport"] = function()
    return {
        ToCoordinates = function(target, x, y, z)
            coreTeleportCalls[#coreTeleportCalls + 1] = { target = target, x = x, y = y, z = z }
            if not (isServer and isServer()) and target and target.teleportTo then
                target:teleportTo(x, y, math.floor(z))
            end
            return true
        end,
    }
end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_DEBUG = "DebugCommand",
    },
    Core = {
        Now = function() return 1000 end,
        IsClientOnly = function() return clientOnly end,
    },
    Registry = {
        Get = function(id)
            if id == "far_npc" then return { id = id, x = 12000, y = 13500, z = 0 } end
            return nil
        end,
        GetLiveZombie = function() return nil end,
    },
    Network = { ClientState = { snapshots = {}, characterPayloads = {} } },
    ClientInterpolation = {},
}

dofile(CLIENT_FILE)

assertEqual(PNC.Client.SendDebug("teleport_to_npc", { id = "far_npc" }), true,
    "single-player teleport accepted")
assertEqual(#nativeTeleports, 1, "single-player used native teleportTo")
assertEqual(nativeTeleports[1].x, 12001.5, "single-player destination x")
assertEqual(nativeTeleports[1].y, 13501.5, "single-player destination y")
assertEqual(coreTeleportCalls[1].x, 12001.5, "client delegated destination to Core")

clientOnly = true
assertEqual(PNC.Client.SendDebug("teleport_to_npc", { id = "far_npc" }), true,
    "multiplayer request accepted")
assertEqual(clientCommands[1].command, "DebugCommand", "multiplayer request reached PNC server")
assertEqual(clientCommands[1].payload.id, "far_npc", "multiplayer request kept NPC id")

local onClientCommand
isClient = function() return false end
isServer = function() return true end
getCell = function() return nil end
Events = {
    OnTick = { Add = function() end },
    OnClientCommand = { Add = function(callback) onClientCommand = callback end },
    OnServerStarted = { Add = function() end },
}

local serverPlayer = {
    getAccessLevel = function() return "admin" end,
    getUsername = function() return "teleport_admin" end,
}
PNC = {
    Const = {
        MODULE = "PNC",
        CMD_DEBUG = "DebugCommand",
    },
    Core = {
        Now = function() return 1000 end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    Registry = {
        Get = function(id)
            if id == "far_npc" then return { id = id, x = 12000, y = 13500, z = 0 } end
            return nil
        end,
        GetLiveZombie = function() return nil end,
    },
    Network = {},
}

dofile(SERVER_FILE)
onClientCommand("PNC", "DebugCommand", serverPlayer, { action = "teleport_to_npc", id = "far_npc" })
local serverCall = coreTeleportCalls[#coreTeleportCalls]
assertEqual(serverCall.target, serverPlayer, "server approved requesting player")
assertEqual(serverCall.x, 12001.5, "server delegated destination x")
assertEqual(serverCall.y, 13501.5, "server delegated destination y")

print("pnc_teleport_smoke: ok")
