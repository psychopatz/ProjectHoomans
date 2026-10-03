if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local Internal = Resources.Internal or {}
local eachObject = Internal.EachObject
local descriptorKey = Internal.DescriptorKey

-- Seating geometry, live-object rehydration, and the seat detector.

local function objectSpriteName(object)
    if not object or not object.getSprite then return nil end
    local sprite = object:getSprite()
    if not sprite or not sprite.getName then return nil end
    return sprite:getName()
end

local function pointInSquare(x, y, square)
    local squareX = square and square.getX and square:getX() or nil
    local squareY = square and square.getY and square:getY() or nil
    if squareX == nil or squareY == nil then return false end
    return x >= squareX and x < squareX + 1
        and y >= squareY and y < squareY + 1
end

local function squareIsSolid(square)
    return square and square.isSolid and square:isSolid() == true
end

local function squareIsSolidTrans(square)
    return square and square.isSolidTrans
        and square:isSolidTrans() == true
end

local function lineBlocked(x1, y1, z1, x2, y2, z2)
    local cell
    local result
    local results
    if type(getCell) ~= "function" or not LosUtil
        or type(LosUtil.lineClear) ~= "function"
    then
        return false, nil
    end
    cell = getCell()
    if not cell or not cell.getGridSquare then return false, nil end
    result = LosUtil.lineClear(
        cell,
        math.floor(x1), math.floor(y1), math.floor(z1),
        math.floor(x2), math.floor(y2), math.floor(z2),
        false
    )
    results = LosUtil.TestResults
    if not results then return false, nil end
    if result == results.Blocked then return true, "line_blocked" end
    if result == results.ClearThroughClosedDoor then
        return true, "closed_door"
    end
    if result == results.ClearThroughWindow then
        return true, "window"
    end
    return false, nil
end

local function seatApproachPoint(square, direction, side, x, y)
    local squareX = square and square.getX and square:getX() or nil
    local squareY = square and square.getY and square:getY() or nil
    if squareX == nil or squareY == nil
        or not (squareIsSolid(square) or squareIsSolidTrans(square))
        or not pointInSquare(x, y, square)
    then
        return x, y
    end
    if direction == "N" then
        if side == "Front" then return x, squareY - 0.3 end
        if side == "Left" then return squareX - 0.3, y end
        if side == "Right" then return squareX + 1.3, y end
    elseif direction == "S" then
        if side == "Front" then return x, squareY + 1.3 end
        if side == "Left" then return squareX + 1.3, y end
        if side == "Right" then return squareX - 0.3, y end
    elseif direction == "W" then
        if side == "Front" then return squareX - 0.3, y end
        if side == "Left" then return x, squareY + 1.3 end
        if side == "Right" then return x, squareY - 0.3 end
    elseif direction == "E" then
        if side == "Front" then return squareX + 1.3, y end
        if side == "Left" then return x, squareY - 0.3 end
        if side == "Right" then return x, squareY + 1.3 end
    end
    return x, y
end

local function approachSquare(x, y, z)
    if type(getCell) ~= "function" then return nil end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(math.floor(x), math.floor(y), z)
end

local function validateSeatApproach(character, object, direction, side,
    seatX, seatY, seatZ, approachX, approachY)
    local furnitureSquare = object and object.getSquare
        and object:getSquare() or nil
    local solid = squareIsSolid(furnitureSquare)
        or squareIsSolidTrans(furnitureSquare)
    local blocked
    local reason
    local targetSquare

    if furnitureSquare then
        if solid and pointInSquare(seatX, seatY, furnitureSquare) then
            blocked, reason = lineBlocked(
                approachX, approachY, seatZ,
                seatX, seatY, seatZ
            )
            if blocked then return false, reason end
        elseif not pointInSquare(seatX, seatY, furnitureSquare) then
            blocked, reason = lineBlocked(
                approachX, approachY, seatZ,
                furnitureSquare:getX(), furnitureSquare:getY(),
                furnitureSquare:getZ()
            )
            if blocked then return false, reason end
        end
        if not solid and not squareIsSolidTrans(furnitureSquare)
            and character and character.canStandAt
            and character:canStandAt(approachX, approachY, seatZ) ~= true
        then
            return false, "cannot_stand"
        end
    end

    targetSquare = approachSquare(approachX, approachY, seatZ)
    if targetSquare then
        if squareIsSolid(targetSquare) then return false, "solid" end
        if squareIsSolidTrans(targetSquare) then
            return false, "solid_trans"
        end
        if targetSquare.isFree
            and targetSquare:isFree(false) ~= true
        then
            return false, "occupied"
        end
    end
    return true, "valid"
end

-- SeatingManager is the vanilla source of truth for furniture seating data.
-- AdvancedAnimator is opaque Java userdata in this PZ build, so do not index
-- it from Lua. The requested PNC node is loaded through the normal animation
-- set and SeatingManager validates the actual live model at this boundary.
function Resources.BuildSeatSpots(character, object)
    local manager
    local worldPos
    local spots = {}
    local directions = { "N", "S", "W", "E" }
    local sides = { "Front", "Left", "Right" }
    local directionIndex
    local sideIndex
    if not character or not object or not SeatingManager
        or not SeatingManager.getInstance or not Vector3f
        or not Vector3f.new
    then
        return spots
    end
    manager = SeatingManager.getInstance()
    if not manager or type(manager.getAdjacentPosition) ~= "function" then
        return spots
    end
    worldPos = Vector3f.new()

    for directionIndex = 1, #directions do
        for sideIndex = 1, #sides do
            local direction = directions[directionIndex]
            local side = sides[sideIndex]
            -- Use the PNC zombie bump node rather than the player-only
            -- sitonfurniture node. SeatingManager needs the requested node
            -- to calculate deferred movement from the active model.
            local valid = manager:getAdjacentPosition(
                character,
                object,
                direction,
                side,
                "bumped",
                "PNC_Anim_SitChair",
                worldPos
            )
            if valid == true
            then
                local seatX = worldPos:x()
                local seatY = worldPos:y()
                local seatZ = worldPos:z()
                local approachX
                local approachY
                local approachValid
                local rejectionReason
                local objectSquare = object.getSquare
                    and object:getSquare() or nil
                approachX, approachY = seatApproachPoint(
                    objectSquare, direction, side, seatX, seatY)
                approachValid, rejectionReason = validateSeatApproach(
                    character,
                    object,
                    direction,
                    side,
                    seatX,
                    seatY,
                    seatZ,
                    approachX,
                    approachY
                )
                if tonumber(seatX) and tonumber(seatY)
                    and tonumber(seatZ)
                then
                    spots[#spots + 1] = {
                        -- x/y are the movement approach point. The exact
                        -- SeatingManager pose is retained separately because
                        -- solid furniture may require walking outside its
                        -- square before entering the animation.
                        x = tonumber(approachX), y = tonumber(approachY),
                        z = tonumber(seatZ),
                        seatAnchorX = tonumber(seatX),
                        seatAnchorY = tonumber(seatY),
                        seatAnchorZ = tonumber(seatZ),
                        direction = direction, side = side,
                        approachKey = direction .. ":" .. side,
                        valid = approachValid == true,
                        approachValid = approachValid == true,
                        validationState = approachValid == true
                            and "VALID" or "BLOCKED",
                        rejectionReason = approachValid == true
                            and nil or rejectionReason,
                        routeStatus = "UNTESTED",
                    }
                end
            end
        end
    end
    return spots
end

function Resources.ResolveLiveObject(resource)
    if type(resource) ~= "table" then return nil end
    if resource.object then return resource.object end
    local square = resource.originX and resource.originY
        and SquareRules.GetSquare(resource.originX, resource.originY,
            resource.originZ or resource.z)
        or nil
    local objects = square and square.getObjects and square:getObjects() or nil
    local detector = Resources.GetDetector(resource.detectorId or "seat")
    if not objects or not detector then return nil end
    local expectedIndex = tonumber(resource.objectIndex)
    local found
    eachObject(square, function(object, index)
        if found or (expectedIndex ~= nil and index ~= expectedIndex) then
            return
        end
        local matched = detector.matches(square, object)
        if matched == true then
            local described = detector.describe(
                square, object, { objectIndex = index })
            if type(described) == "table" then
                local key = descriptorKey(detector, described)
                if tostring(key) == tostring(resource.resourceKey or "") then
                    found = object
                end
            end
        end
    end)
    return found
end

local function describeSeat(square, object, context)
    if not square or not object or not SeatingManager
        or not SeatingManager.getInstance
    then
        return nil
    end
    local manager = SeatingManager.getInstance()
    if not manager
        or type(manager.getTilePositionCount) ~= "function"
    then
        return nil
    end
    local count = tonumber(manager:getTilePositionCount(object)) or 0
    if count <= 0 then return nil end
    local x = square.getX and square:getX() or 0
    local y = square.getY and square:getY() or 0
    local z = square.getZ and square:getZ() or 0
    local objectIndex = context and context.objectIndex or nil
    local resource = {
        detectorId = "seat", targetResolver = "seat",
        resourceKind = "seating_surface", role = "living.chair",
        capability = "living", resourceKey = "seat:" .. tostring(x)
            .. ":" .. tostring(y) .. ":" .. tostring(z) .. ":"
            .. tostring(objectIndex or 0),
        key = "seat:" .. tostring(x) .. ":" .. tostring(y) .. ":"
            .. tostring(z) .. ":" .. tostring(objectIndex or 0),
        x = x + 0.5, y = y + 0.5, z = z,
        originX = x, originY = y, originZ = z,
        objectIndex = objectIndex, seatCount = count,
        sprite = objectSpriteName(object), object = object,
        exclusive = true, available = true,
    }
    local spots = Resources.BuildSeatSpots(
        context and context.character or nil,
        object
    )
    if #spots > 0 then resource.seatSpots = spots end
    return resource
end

Resources.Register("seat", {
    resourceKind = "seating_surface",
    role = "living.chair",
    matches = function(_, object)
        if not object or not SeatingManager
            or not SeatingManager.getInstance
        then return false end
        local manager = SeatingManager.getInstance()
        if not manager
            or type(manager.getTilePositionCount) ~= "function"
        then return false end
        local count = tonumber(manager:getTilePositionCount(object))
        return count ~= nil and count > 0
    end,
    describe = describeSeat,
    key = function(resource)
        return "seat:" .. tostring(resource.originX or 0) .. ":"
            .. tostring(resource.originY or 0) .. ":"
            .. tostring(resource.originZ or 0) .. ":"
            .. tostring(resource.objectIndex or 0)
    end,
})

return Resources
