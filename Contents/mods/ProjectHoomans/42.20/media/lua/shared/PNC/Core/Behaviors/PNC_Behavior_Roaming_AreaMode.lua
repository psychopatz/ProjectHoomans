-- Area roaming mode provider.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.AreaMode
if type(H) ~= "table" then
    return Roaming
end

local Core = H.Core
local Const = H.Const
local Common = H.Common
local BehaviorCombat = H.BehaviorCombat
local chooseAreaGoal = H.ChooseAreaGoal
local syncAreaBounds = H.SyncAreaBounds
local areaStateChanged = H.AreaStateChanged
local hasActivePassage = H.HasActivePassage
local beginAreaPause = H.BeginAreaPause
local resolveRoamingThreat = H.ResolveRoamingThreat
local AreaMovement = H.AreaMovement

function H.Run(record, zombie, order)
    record.runtime = record.runtime or {}
    local state = record.runtime.roaming or {}
    local targetRadius = math.max(1, tonumber(order.targetRadius) or Const.ROAM_TARGET_RADIUS)
    local now = Core.Now()
    local target
    local pathing
    record.runtime.roaming = state
    pathing = record.runtime.pathing
    if state.goalX ~= nil
        and pathing
        and pathing.phase == "blocked"
        and (
            pathing.blockReason == "native_path_unreachable"
            or pathing.blockReason == "native_goal_cooldown"
        )
    then
        local paused, deferred = beginAreaPause(
            record,
            zombie,
            order,
            state,
            now
        )
        if deferred then return true end
        state.goalX = nil
        state.goalY = nil
        state.goalZ = nil
        if paused then
            return true
        end
    end
    target = resolveRoamingThreat(
        record,
        state,
        targetRadius,
        now
    )
    if target then
        state.phase = "combat"
        Common.SetCombatTarget(record, target, "roaming_threat")
        BehaviorCombat.TickEngage(record, zombie, target)
        return true
    end
    if record.runtime.target ~= nil then
        -- Target reassessment may invalidate the previous world object while
        -- this roamer still has an active dwell timer. Clear it before the
        -- early idle return; otherwise LOD sees permanent combat and keeps
        -- this NPC on the 75 ms tier despite having nothing to fight.
        Common.ClearCombatTarget(
            record,
            "roam_target_lost",
            zombie
        )
    end

    if AreaMovement and AreaMovement.Run then
        return AreaMovement.Run(record, zombie, order, state, now)
    end
    return false
end

return Roaming
