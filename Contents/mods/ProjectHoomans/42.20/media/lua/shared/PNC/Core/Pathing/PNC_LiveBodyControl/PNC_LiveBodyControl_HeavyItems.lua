local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal

local function isHeavyHeldItem(item)
    local ok
    local value
    local itemType
    if not item then
        return false
    end
    if item.IsInventoryContainer then
        ok, value = pcall(item.IsInventoryContainer, item)
        if ok and value == true then
            return true
        end
    end
    if item.hasTag and ItemTag and ItemTag.HEAVY_ITEM then
        ok, value = pcall(item.hasTag, item, ItemTag.HEAVY_ITEM)
        if ok and value == true then
            return true
        end
    end
    if item.getType then
        ok, value = pcall(item.getType, item)
        itemType = ok and tostring(value or "") or ""
        if itemType == "Generator" or itemType == "CorpseMale"
            or itemType == "CorpseFemale" or itemType == "Animal"
            or itemType == "CorpseAnimal"
        then
            return true
        end
    end
    return false
end

--[[
    Mirrors the movement test vanilla uses before trying a window climb
    (IsoZombie.updateInternal only reaches tryThump() while the body is moving,
    i.e. next position differs from current). Used to decide whether a climbable
    passage ahead must be blocked even without a PNC passage state.
]]
function LiveBodyControl.IsNativeMoving(zombie)
    local ok
    local nextX
    local nextY
    local x
    local y
    if not (zombie and zombie.getNextX and zombie.getNextY
        and zombie.getX and zombie.getY)
    then
        return false
    end
    ok, nextX, nextY = pcall(function()
        return zombie:getNextX(), zombie:getNextY()
    end)
    if not ok then
        return false
    end
    ok, x, y = pcall(function()
        return zombie:getX(), zombie:getY()
    end)
    if not ok then
        return false
    end
    return nextX ~= x or nextY ~= y
end

--[[
    Climb-ahead probe used by the zombie-update lane.

    Vanilla can only climb a window it finds on the feeler tile, so this is the
    cheap, exact test for "the engine may reach climbThroughWindow() this
    frame". It must run for every PNC shell, including shells the managed-safety
    gate rejects (duplicates, lease mismatches): those are the bodies that
    otherwise fall through to the player-only climb and its player-only drop
    packet, throwing a ClassCastException for the IsoZombie.
]]
--[[
    The broken engine path is client-only: dropHeavyItems() sends
    PlayerDropHeldItems only when the engine is a client and the character is
    local. On a dedicated server there is no packet to fail, so the guard must
    not touch the authoritative hand slots there.
]]
local function isClientState()
    return isClient ~= nil and isClient() == true
end
Internal.isClientState = isClientState

function LiveBodyControl.ClearHeavyItemsForClimbAhead(zombie)
    if not isClientState() then
        return false
    end
    return LiveBodyControl.ClearHeavyItemsForClimbAheadUnchecked(zombie)
end

function LiveBodyControl.ClearHeavyItemsForClimbAheadUnchecked(zombie)
    local object
    local kind
    if not zombie then
        return false
    end
    object, kind = LiveBodyControl.GetVanillaPassageAhead(zombie)
    if not object then
        return false
    end
    if kind ~= "window" and kind ~= "window_frame" and kind ~= "thumpable" then
        return false
    end
    return LiveBodyControl.ClearHeavyHeldItems(zombie)
end

function LiveBodyControl.ClearHeavyHeldItems(zombie)
    local hasPrimary
    local hasSecondary
    local moved = false
    if not zombie or not zombie.getPrimaryHandItem then
        return false
    end
    -- Match the engine's own client branch of dropHeavyItems() and the existing
    -- ordinary-zombie mitigation: clear the hand slot only. The item still
    -- exists in the shell's server-side inventory, so nothing can be lost or
    -- duplicated, and the next equipment sync re-renders it.
    if zombie.setPrimaryHandItem then
        hasPrimary = zombie:getPrimaryHandItem()
        if hasPrimary ~= nil and isHeavyHeldItem(hasPrimary) then
            pcall(zombie.setPrimaryHandItem, zombie, nil)
            moved = true
        end
    end
    if zombie.setSecondaryHandItem then
        hasSecondary = zombie:getSecondaryHandItem()
        if hasSecondary ~= nil and isHeavyHeldItem(hasSecondary) then
            pcall(zombie.setSecondaryHandItem, zombie, nil)
            moved = true
        end
    end
    if moved and PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.Increment
    then
        pcall(PNC.PerformanceScalingDiagnostics.Increment,
            "LiveBodyControl.HeavyItemsCleared")
    end
    return moved
end
