-- Walkability and planner-only traversal edge classification.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}

local TraversalQuery = PNC.TraversalQuery

function TraversalQuery.CanStep(fromX, fromY, fromZ, toX, toY, toZ, cell)
    local fromSquare
    local toSquare
    local passage
    local fence
    local toReason
    fromSquare = TraversalQuery.GetSquare(fromX, fromY, fromZ, cell)
    toSquare = TraversalQuery.GetSquare(toX, toY, toZ, cell)
    if not fromSquare or not toSquare then
        return false, "unloaded"
    end
    toReason = TraversalQuery.GetTraversalOccupancyReason(
        toX,
        toY,
        toZ,
        cell
    )
    -- Exact vehicle occupancy must win over passage handling. Otherwise a
    -- window or fence on the same edge could start a traversal whose landing
    -- tile is inside a vehicle chassis.
    if toReason == "vehicle" then
        return false, toReason
    end
    if fromSquare == toSquare then
        if not toReason then return true, "clear" end
        return false, toReason
    end
    passage = TraversalQuery.GetPassageBetween(fromSquare, toSquare)
    if passage and TraversalQuery.IsWindow(passage) then
        return false, "window"
    end
    if passage and TraversalQuery.IsClosedPassage(passage) then
        return false, "door"
    end
    fence = TraversalQuery.GetFenceBetween(fromSquare, toSquare)
    if fence then
        return false, "fence"
    end
    if fromSquare.isWallTo and fromSquare:isWallTo(toSquare) then
        return false, "wall"
    end
    if fromSquare.isBlockedTo and fromSquare:isBlockedTo(toSquare) then
        return false, "blocked_edge"
    end
    if toReason then return false, toReason end
    return true, "clear"
end

-- Planner-only edge classification. This does not start interactions and does
-- not move the body; it merely exposes the same doors/windows/fences that the
-- PathService traversal runtime knows how to execute.
function TraversalQuery.CanPlanStep(
    fromX,
    fromY,
    fromZ,
    toX,
    toY,
    toZ,
    cell,
    body,
    options
)
    local canStep
    local reason
    local fromSquare
    local toSquare
    local passage
    local fence
    local tall
    canStep, reason = TraversalQuery.CanStep(
        fromX,
        fromY,
        fromZ,
        toX,
        toY,
        toZ,
        cell
    )
    if canStep then
        return true, "walk", 0
    end
    if reason ~= "door" and reason ~= "window" and reason ~= "fence" then
        return false, reason, 0
    end
    fromSquare = TraversalQuery.GetSquare(fromX, fromY, fromZ, cell)
    toSquare = TraversalQuery.GetSquare(toX, toY, toZ, cell)
    if not fromSquare or not toSquare then
        return false, "unloaded", 0
    end
    if reason == "door" then
        if options and options.allowDoors == false then
            return false, reason, 0
        end
        passage = TraversalQuery.GetPassageBetween(fromSquare, toSquare)
        if TraversalQuery.CanOpenDoor(passage) then
            return true, "door_open", 2
        end
        return false, "door_unusable", 0
    end
    if reason == "window" then
        if options and options.allowWindows == false then
            return false, reason, 0
        end
        passage = TraversalQuery.GetPassageBetween(fromSquare, toSquare)
        if TraversalQuery.CanUseWindow(passage, body) then
            return true, "window_climb", 5
        end
        return false, "window_unusable", 0
    end
    if options and options.allowFences == false then
        return false, reason, 0
    end
    fence, tall = TraversalQuery.GetFenceBetween(fromSquare, toSquare)
    if fence and TraversalQuery.CanTraverseAt(
        toX,
        toY,
        toZ,
        cell
    ) then
        return true, tall and "fence_climb_tall" or "fence_climb",
            tall and 6 or 3
    end
    return false, "fence_unusable", 0
end
