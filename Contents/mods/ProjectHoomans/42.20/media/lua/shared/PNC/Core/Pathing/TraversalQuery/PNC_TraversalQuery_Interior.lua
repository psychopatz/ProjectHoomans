-- Indoor/outdoor state derived from the loaded engine squares.
--
-- This deliberately does not cache or persist building state.  A square is
-- the source of truth because normal buildings and player-built enclosed
-- regions do not expose the same building object shape.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}

local TraversalQuery = PNC.TraversalQuery

-- Return true for an indoor square, false for an outdoor square, and nil when
-- the engine cannot classify the square yet (usually because it is unloaded
-- or a test/compatibility object does not expose either API).
function TraversalQuery.GetInteriorState(square)
    if not square then return nil end
    if type(square.isInARoom) == "function" then
        return square:isInARoom() == true
    end
    if type(square.getRoom) == "function" then
        return square:getRoom() ~= nil
    end
    return nil
end

function TraversalQuery.IsIndoorSquare(square)
    return TraversalQuery.GetInteriorState(square) == true
end

-- Compare the transient interior context of two loaded squares. The broad
-- room-state check handles player-built enclosures; the identity checks keep
-- formation targets inside the same ordinary room/building when that detail
-- is available. Unknown data remains neutral for compatibility.
function TraversalQuery.AreSameInteriorContext(left, right)
    local leftState = TraversalQuery.GetInteriorState(left)
    local rightState = TraversalQuery.GetInteriorState(right)
    local leftRoom
    local rightRoom
    local leftBuilding
    local rightBuilding
    local leftRegion
    local rightRegion
    if leftState == nil or rightState == nil then return nil end
    if leftState ~= rightState then return false end
    if leftState ~= true then return true end

    leftRoom = type(left.getRoom) == "function" and left:getRoom() or nil
    rightRoom = type(right.getRoom) == "function" and right:getRoom() or nil
    if leftRoom ~= nil or rightRoom ~= nil then
        if leftRoom ~= rightRoom then return false end
    end

    leftBuilding = type(left.getBuilding) == "function"
        and left:getBuilding() or nil
    rightBuilding = type(right.getBuilding) == "function"
        and right:getBuilding() or nil
    if leftBuilding ~= nil or rightBuilding ~= nil then
        if leftBuilding ~= rightBuilding then return false end
    end

    leftRegion = type(left.getIsoWorldRegion) == "function"
        and left:getIsoWorldRegion() or nil
    rightRegion = type(right.getIsoWorldRegion) == "function"
        and right:getIsoWorldRegion() or nil
    if leftRegion ~= nil or rightRegion ~= nil then
        if leftRegion ~= rightRegion then return false end
    end
    return true
end

-- Return true only when the two adjacent squares cross the indoor boundary.
-- Unknown state is intentionally neutral so a missing square cannot cause an
-- NPC to be trapped by a false positive.
function TraversalQuery.IsInteriorBoundary(fromSquare, toSquare)
    local fromState = TraversalQuery.GetInteriorState(fromSquare)
    local toState = TraversalQuery.GetInteriorState(toSquare)
    if fromState == nil or toState == nil then return nil end
    return fromState ~= toState
end
