-- Owner-space validation and separation correction for close followers.

local Internal = PNC.BehaviorCompanion.Internal
local Const = PNC.Const
local TraversalQuery = PNC.TraversalQuery

local function isOwnerSpaceCandidate(owner, x, y, z)
    local cell
    local ownerSquare
    local candidateSquare
    local ownerBuilding
    local candidateBuilding
    local ownerRoom
    local candidateRoom
    local sameInteriorContext
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(x, y, z)
    then
        return false
    end
    cell = getCell and getCell() or nil
    ownerSquare = owner and owner.getSquare and owner:getSquare() or nil
    candidateSquare = cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
        or nil
    if not ownerSquare or not candidateSquare then
        return true
    end
    ownerBuilding = ownerSquare.getBuilding
        and ownerSquare:getBuilding() or nil
    candidateBuilding = candidateSquare.getBuilding
        and candidateSquare:getBuilding() or nil
    ownerRoom = ownerSquare.getRoom and ownerSquare:getRoom() or nil
    candidateRoom = candidateSquare.getRoom
        and candidateSquare:getRoom() or nil
    sameInteriorContext = TraversalQuery
        and TraversalQuery.AreSameInteriorContext
        and TraversalQuery.AreSameInteriorContext(
            ownerSquare,
            candidateSquare
        )
    if sameInteriorContext ~= nil then
        return sameInteriorContext
    end
    return ownerBuilding == candidateBuilding
        and (ownerBuilding == nil or ownerRoom == candidateRoom)
end

function Internal.EnforceOwnerPersonalSpace(record, owner, target, ownerDist)
    local minimum = tonumber(Const.FOLLOW_PERSONAL_SPACE_MIN) or 1.25
    local radius = tonumber(Const.FOLLOW_SLOT_DISTANCE) or 2.25
    local dx
    local dy
    local fx
    local fy
    local directions
    local direction
    local x
    local y
    local i
    if not record or not owner or not target or ownerDist >= minimum then
        return target
    end
    dx, dy = Internal.NormalizeDirection(
        (tonumber(record.x) or owner:getX()) - owner:getX(),
        (tonumber(record.y) or owner:getY()) - owner:getY()
    )
    fx, fy = Internal.ResolveOwnerForward(owner)
    if not dx or not dy then
        dx = -fx
        dy = -fy
    end
    directions = {
        { x = dx, y = dy },
        { x = -fx, y = -fy },
        { x = -fy, y = fx },
        { x = fy, y = -fx },
        { x = fx, y = fy },
    }
    for i = 1, #directions do
        direction = directions[i]
        x = owner:getX() + direction.x * radius
        y = owner:getY() + direction.y * radius
        if isOwnerSpaceCandidate(owner, x, y, owner:getZ()) then
            target.x = x
            target.y = y
            target.z = owner:getZ()
            target.stopDistance = tonumber(
                Const.FOLLOW_SLOT_STOP_DISTANCE
            ) or 0.35
            target.indoorApproach = nil
            target.personalSpaceCorrection = true
            return target
        end
    end
    return target
end
