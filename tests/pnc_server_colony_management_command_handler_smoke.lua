local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {}
local buildCount = 0
local actionArgs
local colonyCall
local deltaCall

local function buildSnapshot()
    buildCount = buildCount + 1
    return {
        marker = "snapshot-" .. tostring(buildCount),
        settlement = { id = "settlement-1" },
        storage = { revision = buildCount },
    }
end

PNC = {
    Const = {
        CMD_COLONY_MANAGEMENT_REQUEST = "ColonyManagementRequest",
        CMD_COLONY_MANAGEMENT_ACTION = "ColonyManagementAction",
    },
    Network = {
        SendColonyManagement = function(receivedPlayer, snapshot)
            colonyCall = { player = receivedPlayer, snapshot = snapshot }
        end,
        SendSettlementDelta = function(receivedPlayer, settlement, result,
                storage)
            deltaCall = {
                player = receivedPlayer,
                settlement = settlement,
                result = result,
                storage = storage,
            }
        end,
    },
    ColonyManagement = {
        BuildSnapshot = function(receivedPlayer)
            T.equal(receivedPlayer, player, "snapshot player")
            return buildSnapshot()
        end,
        HandleAction = function(receivedPlayer, args)
            T.equal(receivedPlayer, player, "action player")
            actionArgs = args
            return buildSnapshot(), { ok = true, action = args and args.action }
        end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerColonyManagementCommandHandler"

T.equal(Router.Handle("ColonyManagementRequest", player, nil), true,
    "colony snapshot request handled")
T.equal(colonyCall.player, player, "colony snapshot response player")
T.equal(colonyCall.snapshot.marker, "snapshot-1",
    "colony snapshot response")

colonyCall = nil
local ordinaryArgs = { action = "assign_work", npcID = "npc-1" }
Router.Handle("ColonyManagementAction", player, ordinaryArgs)
T.equal(actionArgs, ordinaryArgs, "colony action payload identity")
T.equal(colonyCall.snapshot.actionResult.ok, true,
    "colony action result not attached")
T.equal(deltaCall, nil, "ordinary colony action sent settlement delta")

Router.Handle("ColonyManagementAction", player, nil)
T.equal(actionArgs, nil, "nil colony action payload normalized")
T.equal(colonyCall.snapshot.actionResult.ok, true,
    "nil colony action result not attached")

local settlementActions = {
    "base_create", "base_expand", "base_shrink", "barricade_build",
    "hq_upgrade", "facility_create", "facility_upgrade",
    "facility_capacity_set",
    "facility_component_set", "facility_component_remove",
    "facility_destroy", "stockpile_node_create", "stockpile_node_remove",
}
for _, action in ipairs(settlementActions) do
    colonyCall = nil
    deltaCall = nil
    Router.Handle("ColonyManagementAction", player, { action = action })
    T.equal(deltaCall.player, player, action .. " delta player")
    T.equal(deltaCall.settlement.id, "settlement-1",
        action .. " settlement")
    T.equal(deltaCall.result.action, action, action .. " result")
    T.equal(type(deltaCall.storage.revision), "number",
        action .. " storage")
    T.equal(colonyCall, nil, action .. " sent full snapshot")
end

local sendDelta = PNC.Network.SendSettlementDelta
PNC.Network.SendSettlementDelta = nil
Router.Handle("ColonyManagementAction", player, { action = "base_create" })
T.equal(colonyCall.snapshot.actionResult.action, "base_create",
    "missing delta transport did not send full snapshot")
PNC.Network.SendSettlementDelta = sendDelta

PNC.ColonyManagement.HandleAction = nil
Router.Handle("ColonyManagementAction", player, { action = "unknown" })
T.equal(colonyCall.snapshot.actionResult.ok, false,
    "unavailable action handler fallback succeeded")
T.equal(colonyCall.snapshot.actionResult.reason, "unknown_colony_action",
    "unavailable action handler fallback reason")
T.finish("pnc_server_colony_management_command_handler_smoke")

T.finish("pnc_server_colony_management_command_handler_smoke")
