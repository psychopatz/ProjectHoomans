-- Colony action admission and base/facility action request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local BASE_SNAPSHOT_ACTIONS = {
    base_create = true, base_expand = true, base_shrink = true,
    barricade_build = true, hq_upgrade = true,
    facility_create = true, facility_upgrade = true,
    facility_capacity_set = true, facility_component_set = true,
    facility_component_remove = true, facility_destroy = true,
    stockpile_node_create = true, stockpile_node_remove = true,
    farm_plot_crop = true, farm_plot_policy = true, farm_plot_debug = true,
    facility_anchor_role_replace = true,
    building_queue = true, building_debug_get_items = true,
    work_cancel = true, work_resume = true,
}

function Client.RequestColonyAction(action, options)
    local player = Internal.GetPlayer()
    local args = type(options) == "table" and Core.DeepCopy(options) or {}
    args.action = tostring(action or "")
    args.requestId = args.requestId or Internal.RequestID("colony")
    if BASE_SNAPSHOT_ACTIONS[args.action] then
        args.snapshotScope = "base"
    end
    if PNC.Nameplates and PNC.Nameplates.Settings
        and PNC.Nameplates.Settings.storageTransactionLogging == true
    then
        args.transactionLogging = true
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player, Const.MODULE, Const.CMD_COLONY_MANAGEMENT_ACTION, args
        )
        return true, "sent", args.requestId
    end
    if not PNC.ColonyManagement or not PNC.ColonyManagement.HandleAction then
        return false, "colony_management_unavailable", args.requestId
    end
    local snapshot, result = PNC.ColonyManagement.HandleAction(player, args)
    snapshot = snapshot or {}
    snapshot.actionResult = result
    if args.snapshotScope == "base" or BASE_SNAPSHOT_ACTIONS[args.action] then
        ClientState.colonyBase = snapshot
        ClientState.colonyBaseRevision =
            (tonumber(ClientState.colonyBaseRevision) or 0) + 1
        ClientState.lastColonyBaseReceiveAt = Core.Now()
    else
        ClientState.colonyManagement = snapshot
        ClientState.colonyManagementRevision =
            (tonumber(ClientState.colonyManagementRevision) or 0) + 1
        ClientState.lastColonyManagementReceiveAt = Core.Now()
    end
    if (result.action == "storage_player_deposit"
            or result.action == "storage_player_withdraw"
            or result.action == "storage_npc_deposit"
            or result.action == "storage_npc_deposit_all")
        and PNC.InventoryWindow
        and PNC.InventoryWindow.OnColonyStorageResult
    then
        PNC.InventoryWindow.OnColonyStorageResult(result)
    end
    return result and result.ok == true, result and result.reason, args.requestId
end

function Client.RequestCreateBase(options)
    local request = type(options) == "table" and Core.DeepCopy(options) or {}
    request.snapshotScope = "base"
    return Client.RequestColonyAction("base_create", request)
end

function Client.RequestExpandBase(options)
    local request = type(options) == "table" and Core.DeepCopy(options) or {}
    request.snapshotScope = "base"
    return Client.RequestColonyAction("base_expand", request)
end

function Client.RequestShrinkBase(options)
    local request = type(options) == "table" and Core.DeepCopy(options) or {}
    request.snapshotScope = "base"
    return Client.RequestColonyAction("base_shrink", request)
end

function Client.RequestBuildBarricade(options)
    return Client.RequestColonyAction("barricade_build", options)
end

function Client.RequestQueueBuilding(options)
    return Client.RequestColonyAction("building_queue", options)
end

function Client.RequestUpgradeHQ(options)
    return Client.RequestColonyAction("hq_upgrade", options)
end

function Client.RequestCreateFacility(options)
    return Client.RequestColonyAction("facility_create", options)
end

function Client.RequestUpgradeFacility(options)
    return Client.RequestColonyAction("facility_upgrade", options)
end

function Client.RequestSetFacilityCapacity(options)
    return Client.RequestColonyAction("facility_capacity_set", options)
end

function Client.RequestDebugFacilityMaterials(options)
    return Client.RequestColonyAction("facility_debug_get_materials", options)
end

function Client.RequestSetFacilityComponent(options)
    return Client.RequestColonyAction("facility_component_set", options)
end

function Client.RequestSetFarmPlotCrop(options)
    return Client.RequestColonyAction("farm_plot_crop", options)
end

function Client.RequestSetFarmPlotPolicy(options)
    return Client.RequestColonyAction("farm_plot_policy", options)
end

function Client.RequestFarmPlotDebug(options)
    return Client.RequestColonyAction("farm_plot_debug", options)
end

function Client.RequestReplaceFacilityAnchors(options)
    return Client.RequestColonyAction("facility_anchor_role_replace", options)
end

function Client.RequestRemoveFacilityComponent(options)
    return Client.RequestColonyAction("facility_component_remove", options)
end

function Client.RequestDestroyFacility(options)
    return Client.RequestColonyAction("facility_destroy", options)
end

function Client.RequestCreateStockpileAccessNode(options)
    return Client.RequestColonyAction("stockpile_node_create", options)
end

return Client
