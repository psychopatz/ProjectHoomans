-- Combat movement requests and retreat destination selection.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Const = PNC.Const
local PathService = PNC.PathService
local TraversalQuery = PNC.TraversalQuery
local COMBAT_NAVIGATION = {
    navigationPolicy = "combat",
    navigationProvider = "engine_path",
}

function Internal.RequestMove(record, zombie, x, y, z, mode, stopDistance, reason)
    local MoveIntent = PNC.BehaviorMoveIntent
    if MoveIntent and MoveIntent.RequestMove and record and record.presenceState == Const.PRESENCE_LIVE then
        MoveIntent.RequestMove(
            record, x, y, z, mode, stopDistance, reason, COMBAT_NAVIGATION
        )
        return true
    end
    if PathService and PathService.MoveToward then
        return PathService.MoveToward(
            record, zombie, x, y, z, mode, stopDistance, reason,
            COMBAT_NAVIGATION
        )
    end
    return false
end

function Internal.RequestHold(record, zombie, reason)
    local MoveIntent = PNC.BehaviorMoveIntent
    if MoveIntent and MoveIntent.Hold
        and record and record.presenceState == Const.PRESENCE_LIVE
    then
        return MoveIntent.Hold(record, reason)
    end
    if PathService and PathService.Reset then
        if PathService.Commands and PathService.Commands.Reset then
            PathService.Commands.Reset(record, zombie, reason)
        else
            PathService.Reset(zombie, record, reason)
        end
        return true
    end
    return false
end

function Internal.BuildRetreatFromSource(record, target, distance, sourceX, sourceY, sourceZ, state)
    local dx
    local dy
    local len
    local baseX
    local baseY
    local angles
    local angle
    local cosAngle
    local sinAngle
    local candidateX
    local candidateY
    local retreatZ
    local i
    if not record then return nil end
    if sourceX ~= nil and sourceY ~= nil then
        dx = record.x - tonumber(sourceX)
        dy = record.y - tonumber(sourceY)
    elseif state and state.vectorX ~= nil and state.vectorY ~= nil then
        dx = tonumber(state.vectorX)
        dy = tonumber(state.vectorY)
    elseif target then
        dx = record.x - target.x
        dy = record.y - target.y
    else
        dx = 1
        dy = 0
    end
    len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.001 then
        dx = 1
        dy = 0
        len = 1
    end
    baseX = dx / len
    baseY = dy / len
    retreatZ = tonumber(sourceZ) or target and target.z or record.z
    angles = { 0, 0.55, -0.55, 1.05, -1.05 }
    if TraversalQuery and TraversalQuery.CanStep and TraversalQuery.CanOccupy then
        for i = 1, #angles do
            angle = angles[i]
            cosAngle = math.cos(angle)
            sinAngle = math.sin(angle)
            dx = (baseX * cosAngle) - (baseY * sinAngle)
            dy = (baseX * sinAngle) + (baseY * cosAngle)
            candidateX = record.x + (dx * distance)
            candidateY = record.y + (dy * distance)
            if TraversalQuery.CanStep(
                record.x, record.y, record.z,
                record.x + (dx * 0.8), record.y + (dy * 0.8), retreatZ
            ) and TraversalQuery.CanOccupy(candidateX, candidateY, retreatZ) then
                baseX = dx
                baseY = dy
                break
            end
        end
    end
    if state then
        state.vectorX = baseX
        state.vectorY = baseY
    end
    return {
        x = record.x + (baseX * distance),
        y = record.y + (baseY * distance),
        z = retreatZ,
    }
end

return Tactics
