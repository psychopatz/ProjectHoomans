-- Interaction provider: Project Zomboid door/window mutation adapters.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local methodReturnsTrue = Internal.passageMethodReturnsTrue

-- Engine members may resolve to nil or raise when a class does not expose them
-- in a given point release, so every lookup goes through here.
local function methodOf(object, name)
    local ok
    local method
    if not object then return nil end
    ok, method = pcall(function() return object[name] end)
    if not ok then return nil end
    return method
end

-- Doors that just refused to open (locked from the wrong side, barricaded,
-- obstructed) back off per door, so a body that keeps pressing against one
-- cannot spam the engine toggle and its refusal sounds/halo notes.
local DOOR_REFUSE_BACKOFF_MS = 5000
local DOOR_REFUSED_UNTIL = setmetatable({}, { __mode = "k" })

-- The engine owns "may this character open this door": IsoDoor.couldBeOpen()
-- folds in animals, barricades, the open-from-inside side rule, obstruction and
-- the key rules. Ask it instead of re-deriving the rules in Lua, which is what
-- made a locked door fail for NPCs until a player had opened it once (the
-- engine permanently clears the lock when a character opens it from inside).
local function characterCannotOpen(object, zombie)
    local method = methodOf(object, "couldBeOpen")
    local ok
    local allowed
    if type(method) ~= "function" then return false end
    ok, allowed = pcall(method, object, zombie)
    if not ok then return false end
    return allowed ~= true
end

-- IsoDoor.toggleDoubleDoor/toggleGarageDoor branches inside ToggleDoorActual
-- dereference an IsoPlayer that is null for a zombie body
-- (NullPointerException at IsoDoor.ToggleDoorActual:1620), so multi-tile doors
-- must use the character-independent silent toggle. The silent toggle is still
-- barricade-aware and the engine predicate above has already allowed the open.
local function spriteHasProperty(object, name)
    local method = methodOf(object, "getProperties")
    local ok
    local properties
    local value
    if not method then return false end
    ok, properties = pcall(method, object)
    if not ok or not properties then return false end
    ok, value = pcall(function() return properties:has(name) end)
    return ok and value == true
end

local function doorIsLocked(object)
    return methodReturnsTrue(object, { "isLocked", "IsLocked" })
        or methodReturnsTrue(object, { "isLockedByKey" })
end

local function clearDoorLock(object)
    local method = methodOf(object, "setLocked")
    if method then pcall(method, object, false) end
    method = methodOf(object, "setLockedByKey")
    if method then pcall(method, object, false) end
end

local function holdsDoorKey(object, zombie)
    local getKeyId = methodOf(object, "getKeyId")
    local getInventory = methodOf(zombie, "getInventory")
    local keyId
    local inventory
    local haveThisKeyId
    local ok
    local item
    if not getKeyId or not getInventory then return false end
    ok, keyId = pcall(getKeyId, object)
    keyId = tonumber(keyId)
    if not ok or not keyId or keyId < 0 then return false end
    ok, inventory = pcall(getInventory, zombie)
    if not ok or not inventory then return false end
    haveThisKeyId = methodOf(inventory, "haveThisKeyId")
    if not haveThisKeyId then return false end
    ok, item = pcall(haveThisKeyId, inventory, keyId)
    return ok and item ~= nil
end

-- IsoDoor.canBeOpenFromInside() is private and player-only, so a locked interior
-- door could only ever be opened by the player, and only then did it become
-- usable for NPCs (that open clears the lock for good). Mirror the engine's own
-- test with the same public data: the character is not outside and stands in the
-- door's room or in its opposite square's room, and the door is not forceLocked.
local function canClearLockFromInside(object, zombie)
    local isOutside = methodOf(zombie, "isOutside")
    local doorSquareMethod = methodOf(object, "getSquare")
    local oppositeMethod = methodOf(object, "getOppositeSquare")
    local currentSquareMethod = methodOf(zombie, "getCurrentSquare")
    local ok
    local outside
    local characterRoom
    local doorSquare
    local opposite
    if not isOutside or not doorSquareMethod or not currentSquareMethod then
        return false
    end
    if spriteHasProperty(object, "forceLocked") then return false end
    ok, outside = pcall(isOutside, zombie)
    if not ok or outside == true then return false end
    local function roomOf(square)
        local method = methodOf(square, "getRoom")
        local roomOk
        local room
        if not method then return nil end
        roomOk, room = pcall(method, square)
        if not roomOk then return nil end
        return room
    end
    local currentSquare = select(2, pcall(currentSquareMethod, zombie))
    characterRoom = roomOf(currentSquare)
    if not characterRoom then return false end
    doorSquare = select(2, pcall(doorSquareMethod, object))
    opposite = oppositeMethod and select(2, pcall(oppositeMethod, object)) or nil
    return characterRoom == roomOf(doorSquare)
        or (opposite ~= nil and characterRoom == roomOf(opposite))
end

local function toggleDoorSilently(object, square)
    local method = methodOf(object, "DirtySlice")
    local ok
    local failure
    if method then pcall(method, object) end
    method = methodOf(square, "InvalidateSpecialObjectPaths")
    if method then pcall(method, square) end
    method = methodOf(object, "ToggleDoorSilent")
        or methodOf(object, "toggleDoorSilent")
    if method then
        ok, failure = pcall(method, object)
        if not ok then return false, failure end
    end
    return true
end

-- An engine door toggle raises for some door shapes (a zombie body has no
-- IsoPlayer, so multi-tile door branches throw). Report the first failure per
-- door once instead of letting every attempt dump a stack trace.
local DOOR_FAILURE_LOGGED = setmetatable({}, { __mode = "k" })

local function reportDoorFailure(object, square, failure)
    local message
    if DOOR_FAILURE_LOGGED[square] then return end
    DOOR_FAILURE_LOGGED[square] = true
    if not (PNC.Core and PNC.Core.LogWarn) then return end
    message = tostring(failure or "unknown")
    if #message > 200 then message = string.sub(message, 1, 200) end
    PNC.Core.LogWarn(
        "[PNC][PATH] door_toggle_failed square="
            .. tostring(square and (square:getX() .. "," .. square:getY())
                or "unknown")
            .. " error=" .. message
    )
end

function Internal.openDoorForNPC(zombie, object)
    local square
    local properties
    local doorSound
    local opened
    local refusedUntil
    local now
    local locked
    local method
    local ok
    local failure
    if not object then return false end
    if methodReturnsTrue(object, { "IsOpen", "isOpen" }) then return true end
    method = methodOf(object, "getSquare")
    square = method and method(object) or nil
    if not square then return false end
    now = Internal.Core and Internal.Core.Now and Internal.Core.Now() or 0
    refusedUntil = tonumber(DOOR_REFUSED_UNTIL[object])
    if refusedUntil and now > 0 and now < refusedUntil then return false end
    if characterCannotOpen(object, zombie) then
        DOOR_REFUSED_UNTIL[object] = now + DOOR_REFUSE_BACKOFF_MS
        return false
    end

    -- A locked door opens only for a key holder or from the inside, exactly like
    -- the engine allows for a player (IsoDoor.canBeOpenFromInside is private and
    -- player-only, so this mirrors its test).
    locked = doorIsLocked(object)
    if locked and not holdsDoorKey(object, zombie)
        and not canClearLockFromInside(object, zombie)
    then
        DOOR_REFUSED_UNTIL[object] = now + DOOR_REFUSE_BACKOFF_MS
        return false
    end

    -- Never use IsoDoor.ToggleDoor(character): for a zombie body it dereferences
    -- a null IsoPlayer (NullPointerException in ToggleDoorActual for plain, double
    -- and garage doors alike). The silent toggle is character independent, still
    -- barricade aware, and swaps the sprite the same way.
    ok, failure = toggleDoorSilently(object, square)
    if not ok then reportDoorFailure(object, square, failure) end

    opened = methodReturnsTrue(object, { "IsOpen", "isOpen" })
    if not opened then
        method = methodOf(object, "setOpen") or methodOf(object, "SetOpen")
        if type(method) == "function" then
            method(object, true)
            opened = methodReturnsTrue(object, { "IsOpen", "isOpen" })
        end
    end
    if not opened then
        -- The engine refused (locked, barricaded, blocked); do not retry it on
        -- every tick.
        DOOR_REFUSED_UNTIL[object] = now + DOOR_REFUSE_BACKOFF_MS
        return false
    end
    DOOR_REFUSED_UNTIL[object] = nil
    -- The engine clears a lock on a successful character open; mirror that so a
    -- door an NPC opened from inside stays usable for everyone, like a player's
    -- first open did before.
    if locked then clearDoorLock(object) end
    method = methodOf(square, "InvalidateSpecialObjectPaths")
    if method then method(square) end
    method = methodOf(square, "RecalcProperties")
    if method then method(square) end
    method = methodOf(object, "syncIsoObject")
    if method then method(object, false, 1, nil, nil) end
    if LuaEventManager and LuaEventManager.triggerEvent then
        LuaEventManager.triggerEvent("OnContainerUpdate")
    end
    method = methodOf(object, "invalidateRenderChunkLevel")
    if method and FBORenderChunk then
        method(object, FBORenderChunk.DIRTY_OBJECT_MODIFY)
    end
    method = methodOf(object, "getProperties")
    properties = method and method(object) or nil
    doorSound = properties and properties:has("DoorSound")
        and properties:get("DoorSound") or "WoodDoor"
    if zombie and zombie.playSound then
        zombie:playSound(doorSound .. "Open")
    end
    return opened
end

function Internal.openWindowForNPC(zombie, object)
    local square
    if not object or methodReturnsTrue(object, { "IsOpen", "isOpen" }) then
        return object ~= nil
    end
    if methodReturnsTrue(object, { "isSmashed", "IsSmashed" })
        or methodReturnsTrue(object, { "isPermaLocked" })
    then
        return false
    end
    if object.ToggleWindow then
        object:ToggleWindow(zombie)
    elseif object.toggleWindow then
        object:toggleWindow(zombie)
    else
        return false
    end
    if not methodReturnsTrue(object, { "IsOpen", "isOpen" }) then
        return false
    end
    square = object.getSquare and object:getSquare() or nil
    if object.syncIsoObject then object:syncIsoObject(false, 1, nil, nil) end
    if square and square.InvalidateSpecialObjectPaths then
        square:InvalidateSpecialObjectPaths()
    end
    if square and square.RecalcProperties then square:RecalcProperties() end
    if zombie and zombie.playSound then zombie:playSound("OpenWindow") end
    return true
end

function Internal.smashWindowForNPC(zombie, object)
    if not object then return false end
    if methodReturnsTrue(object, { "isSmashed", "IsSmashed" }) then
        return true
    end
    if not object.smashWindow then return false end
    object:smashWindow()
    if not methodReturnsTrue(object, { "isSmashed", "IsSmashed" }) then
        return false
    end
    local square = object.getSquare and object:getSquare() or nil
    if square and square.InvalidateSpecialObjectPaths then
        square:InvalidateSpecialObjectPaths()
    end
    if square and square.RecalcProperties then square:RecalcProperties() end
    return true
end
