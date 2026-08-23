-- Interaction provider: Project Zomboid door/window mutation adapters.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local methodReturnsTrue = Internal.passageMethodReturnsTrue

function Internal.openDoorForNPC(zombie, object)
    local square
    local properties
    local doorSound
    local opened
    local doubleDoor
    local garageDoor
    if not object then return false end
    if methodReturnsTrue(object, { "IsOpen", "isOpen" }) then return true end
    doubleDoor = IsoDoor and IsoDoor.getDoubleDoorIndex
        and IsoDoor.getDoubleDoorIndex(object) > -1 or false
    garageDoor = IsoDoor and IsoDoor.getGarageDoorIndex
        and IsoDoor.getGarageDoorIndex(object) > -1 or false
    if not garageDoor
        and (
            methodReturnsTrue(object, { "isLocked", "IsLocked" })
            or methodReturnsTrue(object, { "isLockedByKey" })
            or methodReturnsTrue(object, { "isBarricaded", "IsBarricaded" })
            or methodReturnsTrue(object, { "isObstructed" })
        )
    then
        return false
    end
    square = object.getSquare and object:getSquare() or nil
    if not square then return false end

    if doubleDoor then
        IsoDoor.toggleDoubleDoor(object, true)
        opened = true
    elseif garageDoor then
        IsoDoor.toggleGarageDoor(object, true)
        opened = true
    else
        if object.DirtySlice then object:DirtySlice() end
        if square.InvalidateSpecialObjectPaths then
            square:InvalidateSpecialObjectPaths()
        end
        if object.ToggleDoorSilent then
            object:ToggleDoorSilent()
        elseif object.toggleDoorSilent then
            object:toggleDoorSilent()
        end
    end

    opened = opened or methodReturnsTrue(object, { "IsOpen", "isOpen" })
    if not opened and object.setOpen then
        object:setOpen(true)
        opened = methodReturnsTrue(object, { "IsOpen", "isOpen" })
    elseif not opened and object.SetOpen then
        object:SetOpen(true)
        opened = methodReturnsTrue(object, { "IsOpen", "isOpen" })
    end
    if not opened then return false end
    if square.InvalidateSpecialObjectPaths then
        square:InvalidateSpecialObjectPaths()
    end
    if square.RecalcProperties then square:RecalcProperties() end
    if object.syncIsoObject then object:syncIsoObject(false, 1, nil, nil) end
    if LuaEventManager and LuaEventManager.triggerEvent then
        LuaEventManager.triggerEvent("OnContainerUpdate")
    end
    if FBORenderChunk and object.invalidateRenderChunkLevel then
        object:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)
    end
    properties = object.getProperties and object:getProperties() or nil
    doorSound = properties and properties:has("DoorSound")
        and properties:get("DoorSound") or "WoodDoor"
    if zombie.playSound then zombie:playSound(doorSound .. "Open") end
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
