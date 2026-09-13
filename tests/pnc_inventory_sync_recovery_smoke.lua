local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")
local SERVER_ROOT = T.path("ProjectHoomans", "server", "")

T.addPackagePaths()

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = copy(entry) end
    return result
end

local sentRequests = {}
local registered = {}
local fullPayloads = 0
local deltaPayloads = 0

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_FULL_SYNC_REQUEST = "FullSyncRequest",
        CMD_REQUEST_CHARACTER = "RequestCharacter",
        CMD_CHARACTER_PAYLOAD = "CharacterPayload",
        CMD_INVENTORY_DELTA = "InventoryDelta",
        CMD_INVENTORY_RESULT = "InventoryResult",
    },
    Core = {
        DeepCopy = copy,
        Now = function() return 1 end,
        IsClientOnly = function() return true end,
        LogWarn = function() end,
    },
    Network = {
        ClientState = {
            characterPayloads = {},
            snapshots = {},
        },
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                registered[command] = handler
            end,
        },
    },
}

package.preload["PNC/Knowledge/PNC_KnowledgeInterest"] = function()
    return {}
end

getSpecificPlayer = function() return {} end
sendClientCommand = function(_, module, command, args)
    sentRequests[#sentRequests + 1] = {
        module = module,
        command = command,
        args = args,
    }
end

T.load(CLIENT_ROOT .. "PNC/Networking/PNC_ClientRequests.lua")
T.truthy(PNC.Client.RequestCharacterPayload("npc-1", true),
    "full inventory request was not sent")
T.equal(sentRequests[1].args.forceFull, true,
    "full inventory request did not set forceFull")
T.equal(sentRequests[1].args.inventoryRevision, nil,
    "full inventory request still used a stale revision")

PNC.Client.RequestCharacterPayload = function(npcID, forceFull)
    sentRequests[#sentRequests + 1] = {
        npcID = npcID,
        forceFull = forceFull,
    }
    return true
end

PNC.Network.ClientState.characterPayloads["npc-1"] = {
    inventory = {
        revision = 4,
        summary = { revision = 4 },
        items = {},
        containers = {},
    },
}

T.load(CLIENT_ROOT .. "PNC/Networking/PNC_ClientInventoryCommands.lua")
registered[PNC.Const.CMD_INVENTORY_DELTA]({
    npcId = "npc-1",
    fromRevision = 4,
    inventoryRevision = 5,
    ops = {{ op = "update", itemID = "missing", itemState = {} }},
})
local recoveryRequest = sentRequests[#sentRequests]
T.equal(recoveryRequest.npcID, "npc-1",
    "rejected delta did not request the correct NPC")
T.equal(recoveryRequest.forceFull, true,
    "rejected delta did not request an authoritative snapshot")

PNC.ServerCommandRouter = {
    Register = function(command, handler)
        registered["server:" .. command] = handler
    end,
}
PNC.Registry = {
    Get = function(id) return id == "npc-1" and { id = id } or nil end,
}
PNC.Network.CanViewCharacter = function() return true end
PNC.Network.SendCharacterPayload = function() fullPayloads = fullPayloads + 1 end
PNC.Network.SendInventoryDelta = function() deltaPayloads = deltaPayloads + 1 end

T.load(SERVER_ROOT .. "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler.lua")
local handler = registered["server:" .. PNC.Const.CMD_REQUEST_CHARACTER]
T.truthy(handler, "character request handler was not registered")
handler({}, { id = "npc-1", forceFull = true })
T.equal(fullPayloads, 1, "forceFull request did not send full payload")
T.equal(deltaPayloads, 0, "forceFull request incorrectly sent a delta")
handler({}, { id = "npc-1", inventoryRevision = 4 })
T.equal(deltaPayloads, 1, "normal revision request stopped using deltas")

T.finish("pnc_inventory_sync_recovery_smoke")
