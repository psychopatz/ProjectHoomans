local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
            assertEqual(receivedPlayer, player, "snapshot player")
            return buildSnapshot()
        end,
        HandleAction = function(receivedPlayer, args)
            assertEqual(receivedPlayer, player, "action player")
            actionArgs = args
            return buildSnapshot(), { ok = true, action = args and args.action }
        end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerColonyManagementCommandHandler"

assertEqual(Router.Handle("ColonyManagementRequest", player, nil), true,
    "colony snapshot request handled")
assertEqual(colonyCall.player, player, "colony snapshot response player")
assertEqual(colonyCall.snapshot.marker, "snapshot-1",
    "colony snapshot response")

colonyCall = nil
local ordinaryArgs = { action = "assign_work", npcID = "npc-1" }
Router.Handle("ColonyManagementAction", player, ordinaryArgs)
assertEqual(actionArgs, ordinaryArgs, "colony action payload identity")
assertEqual(colonyCall.snapshot.actionResult.ok, true,
    "colony action result not attached")
assertEqual(deltaCall, nil, "ordinary colony action sent settlement delta")

Router.Handle("ColonyManagementAction", player, nil)
assertEqual(actionArgs, nil, "nil colony action payload normalized")
assertEqual(colonyCall.snapshot.actionResult.ok, true,
    "nil colony action result not attached")

local settlementActions = {
    "base_create", "base_expand", "base_shrink", "barricade_build",
    "hq_upgrade", "facility_create", "facility_upgrade",
    "facility_component_set", "facility_component_remove",
    "facility_destroy", "stockpile_node_create", "stockpile_node_remove",
}
for _, action in ipairs(settlementActions) do
    colonyCall = nil
    deltaCall = nil
    Router.Handle("ColonyManagementAction", player, { action = action })
    assertEqual(deltaCall.player, player, action .. " delta player")
    assertEqual(deltaCall.settlement.id, "settlement-1",
        action .. " settlement")
    assertEqual(deltaCall.result.action, action, action .. " result")
    assertEqual(type(deltaCall.storage.revision), "number",
        action .. " storage")
    assertEqual(colonyCall, nil, action .. " sent full snapshot")
end

local sendDelta = PNC.Network.SendSettlementDelta
PNC.Network.SendSettlementDelta = nil
Router.Handle("ColonyManagementAction", player, { action = "base_create" })
assertEqual(colonyCall.snapshot.actionResult.action, "base_create",
    "missing delta transport did not send full snapshot")
PNC.Network.SendSettlementDelta = sendDelta

PNC.ColonyManagement.HandleAction = nil
Router.Handle("ColonyManagementAction", player, { action = "unknown" })
assertEqual(colonyCall.snapshot.actionResult.ok, false,
    "unavailable action handler fallback succeeded")
assertEqual(colonyCall.snapshot.actionResult.reason, "unknown_colony_action",
    "unavailable action handler fallback reason")

print("pnc_server_colony_management_command_handler_smoke: ok")
