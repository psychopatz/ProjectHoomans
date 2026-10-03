-- Player roaming mode provider.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.PlayerMode
if type(H) ~= "table" then
    return Roaming
end

local Core = H.Core
local Const = H.Const
local Common = H.Common
local Perception = H.Perception

local function playerIsAlive(player)
    return not player
        or not player.isAlive
        or player:isAlive() ~= false
end

local function playerPosition(target)
    local player = target and target.player or nil
    if player and player.getX and player.getY and player.getZ then
        return player:getX(), player:getY(), player:getZ()
    end
    return target and target.x, target and target.y, target and target.z
end

local function refreshPlayerTarget(record, state, now)
    local target = state.playerTarget
    local refreshAt = tonumber(state.playerTargetRefreshAt) or 0
    if target and target.player and playerIsAlive(target.player)
        and now < refreshAt
    then
        return target
    end
    if not Core.GetNearestPlayerPosition then return nil end
    local nearest = Core.GetNearestPlayerPosition(record.x, record.y)
    if not nearest or not nearest.player then
        state.playerTarget = nil
        state.playerTargetRefreshAt = now + math.max(
            250,
            tonumber(Const.ROAM_PLAYER_TARGET_REFRESH_MS) or 1000
        )
        return nil
    end
    state.playerTarget = {
        player = nearest.player,
        x = nearest.x,
        y = nearest.y,
        z = nearest.z,
    }
    state.playerTargetRefreshAt = now + math.max(
        250,
        tonumber(Const.ROAM_PLAYER_TARGET_REFRESH_MS) or 1000
    )
    return state.playerTarget
end

local function playerIsVisible(record, player)
    if not player or not Perception
        or not Perception.CanSeeWorldObject
    then
        return false
    end
    local visible = Perception.CanSeeWorldObject(record, player)
    return visible == true
end

local function currentWorldAgeHours(director, now)
    if director and director.WorldAge then
        return director.WorldAge()
    end
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return tonumber(getGameTime():getWorldAgeHours()) or 0
    end
    return (tonumber(now) or 0) / 3600000
end

-- A non-hostile mobile group trails a player only during its approach phase.
-- The target query is deliberately throttled: the engine path planner already
-- handles target drift, while a fresh exact coordinate every behavior tick
-- creates avoidable movement-intent churn.
function H.Run(record, zombie, order)
    record.runtime = record.runtime or {}
    local state = record.runtime.roaming or {}
    local now = Core.Now()
    local target
    local targetX
    local targetY
    local targetZ
    local arrivalDistance = math.max(
        tonumber(Const.ROAM_PLAYER_ARRIVAL_DISTANCE) or 3,
        tonumber(order.reachedDistance) or 0
    )
    record.runtime.roaming = state
    record.activeBehavior = "Roam:player"
    target = refreshPlayerTarget(record, state, now)
    if not target then
        if not state.combatCleared or record.runtime.target ~= nil then
            Common.ClearCombatTarget(
                record,
                "mobile_player_roam_no_player",
                zombie
            )
            state.combatCleared = true
        end
        if not state.noPlayerHeld then
            Common.HaltMovement(
                record,
                zombie,
                "mobile_player_roam_no_player"
            )
            state.noPlayerHeld = true
        end
        record.activeBehavior = "Roam:player:idle"
        return true
    end
    state.noPlayerHeld = nil
    targetX, targetY, targetZ = playerPosition(target)
    if targetX and targetY
        and Core.Distance(record.x, record.y, targetX, targetY)
            <= arrivalDistance
        and math.abs((tonumber(record.z) or 0) - (tonumber(targetZ) or 0)) < 1
        and playerIsVisible(record, target.player)
    then
        local director = PNC.MobileGroupDirectorInternal
        if director and director.EnterPlayerRoamArea then
            local transitioned = director.EnterPlayerRoamArea(
                record,
                target,
                currentWorldAgeHours(director, now)
            )
            if transitioned then return true end
        end
    end
    if not state.combatCleared or record.runtime.target ~= nil then
        Common.ClearCombatTarget(record, "mobile_player_roam", zombie)
        state.combatCleared = true
    end
    Common.MoveRecord(
        record,
        zombie,
        target.x,
        target.y,
        target.z,
        tostring(order.moveMode or "walk"),
        arrivalDistance,
        "mobile_roam_to_player"
    )
    return true
end

return Roaming

