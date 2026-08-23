-- Door, window, and fence object classification and usability policy.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local TraversalQuery = PNC.TraversalQuery
local Internal = TraversalQuery.Internal

function TraversalQuery.IsDoor(object)
    if not object then
        return false
    end
    if instanceof and instanceof(object, "IsoDoor") then
        return true
    end
    return Internal.ObjectBool(object, { "isDoor", "IsDoor" }, false)
end

function TraversalQuery.IsWindow(object)
    return object ~= nil and instanceof ~= nil and instanceof(object, "IsoWindow")
end

function TraversalQuery.IsFence(object)
    local properties
    local low
    local high
    local hoppable
    local tallHoppable
    local isDoor
    local isWindow
    if not object then
        return false, false
    end
    -- Hoppable is the engine's broad traversal flag and is required for
    -- map-authored rail/chain-link fences that do not carry FenceType*. Keep
    -- it, but exclude passage objects first: getHoppableTo() also returns
    -- windows, and doors can expose the same sprite flags.
    isDoor = instanceof and instanceof(object, "IsoDoor") or false
    isDoor = isDoor or Internal.ObjectBool(object, { "isDoor", "IsDoor" }, false)
    isWindow = instanceof and instanceof(object, "IsoWindow") or false
    isWindow = isWindow or Internal.ObjectBool(object, { "isWindow", "IsWindow" }, false)
    if isDoor or isWindow then
        return false, false
    end
    properties = object.getProperties and object:getProperties() or nil
    low = properties and properties.get
        and properties:get("FenceTypeLow") ~= nil or false
    high = properties and properties.get and properties:get("FenceTypeHigh") ~= nil or false
    hoppable = Internal.ObjectBool(object, { "isHoppable" }, false)
    tallHoppable = Internal.ObjectBool(object, { "isTallHoppable" }, false)
    return low or high or hoppable or tallHoppable, high or tallHoppable
end

function TraversalQuery.IsClosedPassage(object)
    if TraversalQuery.IsDoor(object) then
        return not Internal.ObjectBool(object, { "IsOpen", "isOpen" }, false)
    end
    if TraversalQuery.IsWindow(object) then
        return not Internal.ObjectBool(object, { "IsOpen", "isOpen" }, false)
            and not Internal.ObjectBool(object, { "isDestroyed", "IsDestroyed", "isSmashed" }, false)
    end
    return false
end

function TraversalQuery.CanOpenDoor(object)
    local lockedByKey
    if not TraversalQuery.IsDoor(object) then
        return false
    end
    if not TraversalQuery.IsClosedPassage(object) then
        return true
    end
    lockedByKey = Internal.CallFirst(object, { "getLockedByKey" })
    return not Internal.ObjectBool(object, { "isLocked", "IsLocked" }, false)
        and not Internal.ObjectBool(object, { "isLockedByKey" }, false)
        and (
            lockedByKey == nil
            or lockedByKey == false
            or lockedByKey == 0
            or lockedByKey == ""
        )
        and not Internal.ObjectBool(
            object,
            { "isBarricaded", "IsBarricaded" },
            false
        )
        and not Internal.ObjectBool(object, { "isObstructed" }, false)
end

function TraversalQuery.CanUseWindow(object, body)
    local open
    local smashed
    if not TraversalQuery.IsWindow(object) then
        return false
    end
    open = Internal.ObjectBool(object, { "IsOpen", "isOpen" }, false)
    smashed = Internal.ObjectBool(
        object,
        { "isDestroyed", "IsDestroyed", "isSmashed" },
        false
    )
    if not open and not smashed then
        if Internal.ObjectBool(
            object,
            { "isPermaLocked", "IsPermaLocked" },
            false
        ) or Internal.ObjectBool(
            object,
            { "isBarricaded", "IsBarricaded" },
            false
        ) then
            return false
        end
        -- Runtime opens the window before testing the climb. A closed but
        -- usable window is therefore a valid (and more expensive) route edge.
        return true
    end
    if body and type(object.canClimbThrough) == "function" then
        local ok
        local canClimb
        ok, canClimb = pcall(object.canClimbThrough, object, body)
        return ok and canClimb == true
    end
    return true
end
