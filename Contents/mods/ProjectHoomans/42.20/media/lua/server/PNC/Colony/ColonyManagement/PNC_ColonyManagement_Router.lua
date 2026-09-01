if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


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
    local snapshot = Management.BuildSnapshot(player)
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
