-- Formation slot allocation and owner personal-space correction.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local FollowFormationCache = {}

local function isSameFollowGroup(record, other)
    local otherOrder
    local otherOwnerID
    local recordOwnerID
    if not record or not other or other.alive == false then
        return false
    end
    otherOrder = other.orderSpec or {}
    if tostring(otherOrder.kind or "") ~= Const.ORDER_FOLLOW then
        return false
    end
    otherOwnerID = tonumber(other.ownerOnlineID)
    recordOwnerID = tonumber(record.ownerOnlineID)
    if otherOwnerID ~= nil and recordOwnerID ~= nil then
        return otherOwnerID == recordOwnerID
    end
    return tostring(other.ownerUsername or "")
        == tostring(record.ownerUsername or "")
end

local function sortFollowerRecords(a, b)
    return tostring(a and a.id or "") < tostring(b and b.id or "")
end

local function resolveFollowOwnerKey(record, owner)
    local onlineID = owner and owner.getOnlineID
        and tonumber(owner:getOnlineID())
        or tonumber(record and record.ownerOnlineID)
    if onlineID ~= nil then
        return "id:" .. tostring(onlineID)
    end
    return "user:" .. tostring(
        owner and owner.getUsername and owner:getUsername()
            or record and record.ownerUsername
            or ""
    )
end

local function buildFollowFormation(record, owner, now, ownerMoving)
    local followers = {}
    local slots = {}
    local fx
    local fy
    local i
    if Registry and Registry.ForEach then
        Registry.ForEach(function(other)
            if isSameFollowGroup(record, other) then
                followers[#followers + 1] = other
            end
        end)
    end
    table.sort(followers, sortFollowerRecords)
    for i = 1, #followers do
        slots[tostring(followers[i].id)] = i - 1
    end
    fx, fy = Internal.ResolveOwnerForward(owner)
    return {
        expiresAt = now + (
            ownerMoving
                and (
                    tonumber(Const.FOLLOW_FORMATION_MOVING_CACHE_MS) or 200
                )
                or (
                    tonumber(Const.FOLLOW_FORMATION_IDLE_CACHE_MS) or 1000
                )
        ),
        count = #followers,
        slots = slots,
        forwardX = fx,
        forwardY = fy,
        ownerMoving = ownerMoving == true,
    }
end

function Internal.ResolveFollowSlot(record, owner, ownerMoving)
    local ownerKey
    local cache
    local now
    local slotIndex
    local followerCount
    local fx
    local fy
    local rightX
    local rightY
    local backX
    local backY
    local pairIndex
    local side
    local lateral
    local trailing
    local target
    if not owner then
        return nil
    end
    now = Core.Now()
    ownerKey = resolveFollowOwnerKey(record, owner)
    cache = FollowFormationCache[ownerKey]
    if not cache
        or now >= (tonumber(cache.expiresAt) or 0)
        or cache.slots[tostring(record.id)] == nil
        or ownerMoving == true and cache.ownerMoving ~= true
    then
        cache = buildFollowFormation(record, owner, now, ownerMoving)
        FollowFormationCache[ownerKey] = cache
    end
    slotIndex = tonumber(cache.slots[tostring(record.id)]) or 0
    followerCount = tonumber(cache.count) or 1
    fx = tonumber(cache.forwardX) or 0
    fy = tonumber(cache.forwardY) or 1
    rightX = -fy
    rightY = fx
    backX = -fx
    backY = -fy
    if followerCount <= 1 then
        lateral = 0
        trailing = tonumber(Const.FOLLOW_SLOT_DISTANCE) or 2.25
    else
        pairIndex = math.floor(slotIndex / 2)
        side = (slotIndex % 2 == 0) and -1 or 1
        lateral = side * (
            (tonumber(Const.FOLLOW_SLOT_LATERAL) or 1.15)
            + (pairIndex * (
                tonumber(Const.FOLLOW_SLOT_ROW_LATERAL) or 0.25
            ))
        )
        trailing = (tonumber(Const.FOLLOW_SLOT_DISTANCE) or 2.25)
            + (pairIndex * (
                tonumber(Const.FOLLOW_SLOT_ROW_DISTANCE) or 0.85
            ))
    end
    record.runtime = record.runtime or {}
    target = record.runtime.followSlotTarget or {}
    record.runtime.followSlotTarget = target
    target.x = owner:getX() + (backX * trailing) + (rightX * lateral)
    target.y = owner:getY() + (backY * trailing) + (rightY * lateral)
    target.z = owner:getZ()
    target.stopDistance = tonumber(Const.FOLLOW_SLOT_STOP_DISTANCE) or 0.35
    target.personalSpaceCorrection = nil
    -- Formation offsets are useful outdoors but can place the synthetic goal
    -- through an exterior/interior wall in a small room. Keep the slot only
    -- when it resolves to the owner's loaded building and room; otherwise
    -- route to the owner square so the native path exposes the real doorway.
    local cell = getCell and getCell() or nil
    local ownerSquare = owner.getSquare and owner:getSquare() or nil
    local slotSquare = cell and cell.getGridSquare and cell:getGridSquare(
        math.floor(target.x),
        math.floor(target.y),
        math.floor(target.z)
    ) or nil
    if ownerSquare and slotSquare then
        local ownerBuilding = ownerSquare.getBuilding
            and ownerSquare:getBuilding() or nil
        local slotBuilding = slotSquare.getBuilding
            and slotSquare:getBuilding() or nil
        local ownerRoom = ownerSquare.getRoom and ownerSquare:getRoom() or nil
        local slotRoom = slotSquare.getRoom and slotSquare:getRoom() or nil
        if ownerBuilding ~= slotBuilding
            or (ownerBuilding ~= nil and ownerRoom ~= slotRoom)
        then
            target.x = owner:getX()
            target.y = owner:getY()
            target.stopDistance = tonumber(
                Const.FOLLOW_INDOOR_APPROACH_DISTANCE
            ) or 1.6
            target.indoorApproach = true
        else
            target.indoorApproach = nil
        end
    else
        target.indoorApproach = nil
    end
    return target
end
