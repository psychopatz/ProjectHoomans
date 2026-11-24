-- Server runtime & command handler for world-item scavenge policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Scavenge/PNC_ScavengePolicy"

PNC = PNC or {}
PNC.ScavengeRuntime = PNC.ScavengeRuntime or {}

local Runtime = PNC.ScavengeRuntime
local Policy = PNC.ScavengePolicy

function Runtime.HandleRequest(player, args)
    args = type(args) == "table" and args or {}
    if not player then return false, "player_required" end
    local action = tostring(args.action or "request_policy")

    if action == "request_policy" then
        return true, "policy_snapshot", Policy.Snapshot(player)
    elseif action == "set_enabled" then
        local ok, reason = Policy.SetEnabled(player, args.enabled == true)
        if not ok then return false, reason end
        return true, "scavenge_enabled_updated", Policy.Snapshot(player)
    elseif action == "set_category" then
        local ok, reason = Policy.SetCategory(player, args.categoryId, args.enabled == true)
        if not ok then return false, reason end
        return true, "scavenge_category_updated", Policy.Snapshot(player)
    elseif action == "set_categories" then
        local ok, reason = Policy.SetCategories(player, args.categories)
        if not ok then return false, reason end
        return true, "scavenge_categories_updated", Policy.Snapshot(player)
    elseif action == "set_preferences" then
        local ok, reason = Policy.SetPreferences(player, args.sourcePolicy or args.preferences)
        if not ok then return false, reason end
        return true, "preferences_updated", Policy.Snapshot(player)
    elseif action == "set_auto_grab" or action == "remove_auto_grab" then
        local ok, reason = Policy.SetAutoGrab(player, args.fullType,
            action == "set_auto_grab" and args.enabled == true)
        if not ok then return false, reason end
        return true, "auto_grab_updated", Policy.Snapshot(player)
    end
    return false, "scavenge_action_invalid"
end

return Runtime
