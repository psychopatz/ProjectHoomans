-- Colony-management network adapter. ColonyManagement retains action policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Network = PNC.Network
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

Router.Register(Const.CMD_COLONY_MANAGEMENT_REQUEST, function(player, args)
    args = type(args) == "table" and args or {}
    local builder = args.snapshotScope == "base"
        and PNC.ColonyManagement.BuildBaseSnapshot
        or PNC.ColonyManagement.BuildSnapshot
    if type(builder) ~= "function" then
        builder = PNC.ColonyManagement.BuildSnapshot
    end
    Network.SendColonyManagement(
        player,
        builder(player, args),
        args.snapshotScope == "base" and "base" or nil
    )
end)

Router.Register(Const.CMD_COLONY_MANAGEMENT_ACTION,
    function(player, args, rawArgs)
        local snapshot
        local result
        local actionID = tostring(rawArgs and rawArgs.action or "")
        local baseResponse = BASE_SNAPSHOT_ACTIONS[actionID]
            or rawArgs and rawArgs.snapshotScope == "base"
        if PNC.ColonyManagement and PNC.ColonyManagement.HandleAction then
            snapshot, result = PNC.ColonyManagement.HandleAction(
                player,
                rawArgs
            )
        else
            snapshot = PNC.ColonyManagement.BuildSnapshot(player)
            result = { ok = false, reason = "unknown_colony_action" }
        end
        snapshot = snapshot or {}
        snapshot.actionResult = result
        local settlementAction = {
            base_expand = true, base_shrink = true,
            barricade_build = true, hq_upgrade = true,
            facility_create = true, facility_upgrade = true,
            facility_capacity_set = true,
            facility_component_set = true, facility_component_remove = true,
            farm_plot_crop = true, farm_plot_policy = true, farm_plot_debug = true,
            facility_anchor_role_replace = true,
            facility_destroy = true, stockpile_node_create = true,
            stockpile_node_remove = true,
        }
        if settlementAction[tostring(rawArgs and rawArgs.action or "")]
            and Network.SendSettlementDelta
        then
            Network.SendSettlementDelta(
                player,
                snapshot.settlement,
                result,
                snapshot.storage
            )
        else
            Network.SendColonyManagement(player, snapshot,
                baseResponse and "base" or nil)
        end
    end
)
