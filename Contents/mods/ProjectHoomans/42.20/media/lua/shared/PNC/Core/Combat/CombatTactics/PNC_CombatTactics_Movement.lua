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

local function GetFollowOwnerAnchor(record)
    local orderSpec = record and record.orderSpec
    local Common = PNC.BehaviorCommon
    local owner
    local ownerX
    local ownerY
    local ownerZ
    if type(orderSpec) ~= "table"
        or orderSpec.kind ~= (Const.ORDER_FOLLOW or "follow")
        or not Common
        or not Common.GetOwner
    then
        return nil
    end
    owner = Common.GetOwner(record)
    if not owner or not owner.getX or not owner.getY then
        return nil
    end
    ownerX = tonumber(owner:getX())
    ownerY = tonumber(owner:getY())
    ownerZ = owner.getZ and tonumber(owner:getZ()) or nil
    if not ownerX or not ownerY then
        return nil
    end
    if ownerZ and record.z ~= nil and math.abs(ownerZ - record.z) > 0.5 then
        return nil
    end
    return ownerX, ownerY, ownerZ,
        tonumber(Const.FOLLOW_RETREAT_MAX_DISTANCE)
            or tonumber(Const.FOLLOW_COMBAT_LEASH_DISTANCE) or 5.5
end

local function ClampToFollowOwner(x, y, ownerX, ownerY, maxDistance)
    local dx = x - ownerX
    local dy = y - ownerY
    local distance = math.sqrt((dx * dx) + (dy * dy))
    if distance <= maxDistance or distance <= 0.001 then
        return x, y
    end
    return ownerX + (dx / distance) * maxDistance,
        ownerY + (dy / distance) * maxDistance
end

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
    local ownerX
    local ownerY
    local ownerZ
    local ownerMaxDistance
    local stepX
    local stepY
    if not record then return nil end
    ownerX, ownerY, ownerZ, ownerMaxDistance = GetFollowOwnerAnchor(record)
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
            if ownerX then
                candidateX, candidateY = ClampToFollowOwner(
                    candidateX, candidateY, ownerX, ownerY, ownerMaxDistance
                )
            end
            stepX = record.x + ((candidateX - record.x) * 0.8)
            stepY = record.y + ((candidateY - record.y) * 0.8)
            if TraversalQuery.CanStep(
                record.x, record.y, record.z,
                stepX, stepY, retreatZ
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
    candidateX = record.x + (baseX * distance)
    candidateY = record.y + (baseY * distance)
    if ownerX then
        candidateX, candidateY = ClampToFollowOwner(
            candidateX, candidateY, ownerX, ownerY, ownerMaxDistance
        )
    end
    return {
        x = candidateX,
        y = candidateY,
        z = retreatZ,
    }
end

return Tactics
