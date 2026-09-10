local T = require "tests/support/test"
T.addPackagePaths()

local handlers = {}
local now = 42
local state = {}

PNC = {
    Const = { MODULE = "PNC",
        CMD_COLONY_MANAGEMENT_REQUEST = "RequestColonyManagement",
        CMD_COLONY_MANAGEMENT = "ColonyManagement",
        CMD_SETTLEMENT_DELTA = "SettlementDelta",
        CMD_COLONY_JOURNAL = "ColonyJournal",
        CMD_COLONY_KNOWLEDGE_DELTA = "ColonyKnowledgeDelta" },
    Core = {
        Now = function() return now end,
        IsClientOnly = function() return true end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    Network = { ClientState = state },
    Client = { Internal = {
        RegisterServerCommand = function(command, handler)
            handlers[command] = handler
        end,
    } },
}

PNC.KnowledgeInterest = {}
PNC.Client.Internal.IsWorldReady = function() return true end
local sent
getSpecificPlayer = function() return {} end
sendClientCommand = function(_, module, command, args)
    sent = { module = module, command = command, args = args }
end

T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Colony.lua")

handlers.ColonyManagement({
    scope = "base",
    snapshot = { colony = { id = "colony-1" } },
})
T.equal(state.colonyBase.colony.id, "colony-1",
    "base response did not reach the base client state")
T.equal(state.colonyManagement, nil,
    "base response overwrote the full colony state")
T.equal(state.colonyBaseRevision, 1, "base revision did not advance")
T.equal(state.lastColonyBaseReceiveAt, now,
    "base receive timestamp was not recorded")

handlers.SettlementDelta({
    settlement = { id = "base-1", revision = 3 },
    actionResult = { action = "base_create", ok = true },
})
T.equal(state.colonyBase.settlement.id, "base-1",
    "settlement delta did not refresh the base state")
T.equal(state.colonyBase.actionResult.action, "base_create",
    "settlement action result did not reach the base state")
T.equal(state.colonyBaseRevision, 2,
    "settlement delta did not advance the base revision")

T.load("ProjectHoomans", "client", "PNC/Networking/PNC_ClientRequests.lua")
T.truthy(PNC.Client.RequestBaseBootstrap(),
    "multiplayer base bootstrap request was not accepted")
T.equal(sent.command, "RequestColonyManagement",
    "base bootstrap used the wrong server command")
T.equal(sent.args.snapshotScope, "base",
    "base bootstrap did not request the compact scope")

PNC.Core.IsClientOnly = function() return false end
PNC.ColonyManagement = {
    BuildBaseSnapshot = function()
        return { colony = { id = "local-colony" } }
    end,
    BuildSnapshot = function()
        error("base bootstrap called the full snapshot builder")
    end,
}
T.truthy(PNC.Client.RequestBaseBootstrap(),
    "single-player base bootstrap request was not accepted")
T.equal(state.colonyBase.colony.id, "local-colony",
    "single-player base bootstrap did not use the compact builder")

T.finish("pnc_client_colony_base_scope_smoke")
