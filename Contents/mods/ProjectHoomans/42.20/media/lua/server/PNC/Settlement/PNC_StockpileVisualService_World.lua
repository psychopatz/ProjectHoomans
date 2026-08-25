if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local World = {}
local VISUAL_DATA_KEY = "PNC_StockpileVisual"
local VISUAL_OWNER = "ProjectHoomans"

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

function World.SquareAt(point)
    if not point or type(getCell) ~= "function" then return nil end
    local ok, cell = pcall(getCell)
    if not ok or not cell or type(cell.getGridSquare) ~= "function" then
        return nil
    end
    local squareOk, square = pcall(cell.getGridSquare, cell,
        point.x, point.y, point.z)
    return squareOk and square or nil
end

function World.SquareKey(square)
    if not square then return nil end
    -- LoadGridsquare is raised for every square entering the active cell.
    -- These are guaranteed IsoGridSquare methods, so avoid three protected
    -- calls on that hot event path.
    local x = type(square.getX) == "function" and square:getX() or nil
    local y = type(square.getY) == "function" and square:getY() or nil
    local z = type(square.getZ) == "function" and square:getZ() or nil
    if x == nil or y == nil or z == nil then return nil end
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

function World.SquareMatchesPoint(square, point)
    if not square or not point then return false end
    return tonumber(type(square.getX) == "function"
            and square:getX() or nil) == tonumber(point.x)
        and tonumber(type(square.getY) == "function"
            and square:getY() or nil) == tonumber(point.y)
        and tonumber(type(square.getZ) == "function"
            and square:getZ() or nil) == tonumber(point.z)
end

local function listObjects(square)
    local objects = call(square, "getObjects")
    if not objects or type(objects.size) ~= "function"
        or type(objects.get) ~= "function"
    then return {} end
    local output = {}
    for index = 0, objects:size() - 1 do
        output[#output + 1] = objects:get(index)
    end
    return output
end

local function isPresent(square, target)
    for _, object in ipairs(listObjects(square)) do
        if object == target then return true end
    end
    return false
end

local function markerFor(object)
    local data = call(object, "getModData")
    local marker = data and data[VISUAL_DATA_KEY] or nil
    return type(marker) == "table" and marker or nil
end

local function isOwnedMarker(marker)
    -- Older Project Hoomans visuals predate the owner field.  Keep those
    -- manageable while refusing to touch another mod that uses the same
    -- generic-looking marker key.
    return marker and (marker.owner == nil
        or tostring(marker.owner) == VISUAL_OWNER)
end

function World.EnforceVisualOnly(object, spec)
    if not object then return false end
    call(object, "removeAllContainers")
    call(object, "setOutlineOnMouseover", false)
    if spec and spec.objectType == "thumpable" then
        call(object, "setIsContainer", false)
        call(object, "setIsThumpable", false)
        call(object, "setIsDismantable", false)
        call(object, "setCanBarricade", false)
        call(object, "setIsHoppable", false)
        call(object, "setIsDoor", false)
        call(object, "setCanPassThrough", false)
    end
    return true
end

function World.OwnedFacilityId(object)
    local marker = markerFor(object)
    if not isOwnedMarker(marker) or marker.facilityId == nil then return nil end
    return tostring(marker.facilityId)
end

function World.VisualObjects(square, facilityId)
    local output = {}
    for _, object in ipairs(listObjects(square)) do
        local marker = markerFor(object)
        if isOwnedMarker(marker)
            and tostring(marker.facilityId or "")
            == tostring(facilityId or "")
        then
            output[#output + 1] = object
        end
    end
    return output
end

function World.MatchingVisual(square, facilityId, spec)
    local objects = World.VisualObjects(square, facilityId)
    if #objects ~= 1 then return nil end
    local marker = markerFor(objects[1])
    if isOwnedMarker(marker)
        and tostring(marker.sprite or "") == tostring(spec.sprite)
        and tonumber(marker.tier) == tonumber(spec.tier)
        and tostring(marker.objectType or "isoobject")
            == tostring(spec.objectType or "isoobject")
    then
        World.EnforceVisualOnly(objects[1], spec)
        return objects[1]
    end
    return nil
end

local function removeObject(square, object)
    if not square or not object then return false end
    call(square, "transmitRemoveItemFromSquare", object, true)
    if isPresent(square, object) then
        call(square, "RemoveTileObject", object, true)
    end
    return not isPresent(square, object)
end

function World.RemoveAt(square, facilityId)
    local removed = true
    for _, object in ipairs(World.VisualObjects(square, facilityId)) do
        if not removeObject(square, object) then removed = false end
    end
    return removed
end

function World.AddObject(square, facility, spec, point)
    if not square or not spec or not spec.sprite then
        return false, "STOCKPILE_VISUAL_ENGINE_UNAVAILABLE"
    end
    local object
    local ok
    if spec.objectType == "thumpable"
        and IsoThumpable and type(IsoThumpable.new) == "function"
        and type(getCell) == "function"
    then
        local cellOk, cell = pcall(getCell)
        if cellOk and cell then
            ok, object = pcall(IsoThumpable.new, cell, square,
                spec.sprite, spec.north == true)
            if not ok or not object then
                ok, object = pcall(IsoThumpable.new, IsoThumpable, cell,
                    square, spec.sprite, spec.north == true)
            end
        end
    elseif IsoObject and type(IsoObject.new) == "function" then
        ok, object = pcall(IsoObject.new, square, spec.sprite)
        if not ok or not object then
            ok, object = pcall(IsoObject.new, IsoObject, square, spec.sprite)
        end
    end
    if not ok or not object then
        return false, "STOCKPILE_VISUAL_CREATE_FAILED"
    end

    -- The furniture sprites are only a world-facing representation of the
    -- stockpile.  IsoThumpable defaults to interactive/thumpable, and a
    -- sprite may also carry container metadata in the base tileset.  Clear
    -- every container and interaction flag before the object enters the
    -- square.  Keep pass-through disabled so the sprite still contributes
    -- its normal collision footprint.
    World.EnforceVisualOnly(object, spec)
    local data = call(object, "getModData")
    if not data then return false, "STOCKPILE_VISUAL_MODDATA_UNAVAILABLE" end
    data[VISUAL_DATA_KEY] = {
        facilityId = tostring(facility.id),
        level = tonumber(facility.level) or 1,
        tier = spec.tier,
        mode = spec.mode,
        sprite = tostring(spec.sprite),
        objectType = spec.objectType or "isoobject",
        owner = VISUAL_OWNER,
        visualOnly = true,
        hasContainer = false,
        thumpable = false,
        canPassThrough = false,
        x = point.x, y = point.y, z = point.z,
    }
    local addMethod = spec.objectType == "thumpable"
        and "AddSpecialObject" or "AddTileObject"
    call(square, addMethod, object, -1)
    if not isPresent(square, object) then
        -- Keep a compatibility fallback for runtimes or test doubles that do
        -- not expose the preferred insertion method.
        local fallback = addMethod == "AddTileObject"
            and "AddSpecialObject" or "AddTileObject"
        call(square, fallback, object, -1)
    end
    if not isPresent(square, object) then
        return false, "STOCKPILE_VISUAL_ADD_FAILED"
    end
    -- AddSpecialObject calls IsoObject.addToWorld(), which can recreate a
    -- container from the furniture sprite.  This cleanup must run after the
    -- engine insertion, not only before it.
    World.EnforceVisualOnly(object, spec)
    call(object, "transmitCompleteItemToClients")
    call(object, "transmitModData")
    return true, object
end

return World
