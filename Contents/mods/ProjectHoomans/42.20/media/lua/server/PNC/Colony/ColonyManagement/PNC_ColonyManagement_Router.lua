if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
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


function Management.HandleAction(player, args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.action or "")
    if action == "rename" then
        return Management.RenameForPlayer(player, args)
    end
    if action == "faction_rename" then
        return Management.RenameFactionForPlayer(player, args)
    end
    if action == "faction_emblem" then
        return Management.SetFactionEmblemForPlayer(player, args)
    end
    local outcome = Internal.handleSettlementAction(player, args, action)
        or Internal.handleStorageColonistAction(player, args, action)
        or Internal.handleTaskingAction(player, args, action)
        or Internal.handleProductionAction(player, args, action)
        or Internal.handleWorkDebugAction(player, args, action)
        or { ok = false, reason = "unknown_colony_action" }
    local snapshotBuilder = (args.snapshotScope == "base"
        or BASE_SNAPSHOT_ACTIONS[action])
        and Management.BuildBaseSnapshot or Management.BuildSnapshot
    if type(snapshotBuilder) ~= "function" then
        snapshotBuilder = Management.BuildSnapshot
    end
    local snapshot = snapshotBuilder(player, {
        taskBrainNpcID = args.taskBrainNpcID,
    })
    return snapshot, {
        ok = outcome.ok == true,
        reason = outcome.reason,
        details = outcome.details,
        storageId = outcome.storage and outcome.storage.id or nil,
        requestId = args.requestId,
        action = action,
    }
end

return Management
