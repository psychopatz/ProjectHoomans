--[[
    Stable PathService passage-interaction entry point.
    Providers are ordered before the thin public orchestrator.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

require "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassagePolicy"
require "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageObjects"
require "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageDoors"
require "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageWindowBreach"
require "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageWindows"
require "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageFences"

local Internal = PNC.PathService.Internal
local TraversalQuery = PNC.TraversalQuery

local function buildContext(zombie, record, lane, goalX, goalY, goalZ)
    if not zombie or not getCell then return nil end
    local cell = getCell()
    local zx = math.floor(zombie:getX())
    local zy = math.floor(zombie:getY())
    local zz = zombie:getZ()
    local fromX = zombie:getX()
    local fromY = zombie:getY()
    local actorSquare = zombie.getSquare and zombie:getSquare()
        or cell:getGridSquare(zx, zy, zz)
    local forward = zombie:getForwardDirection()
    local blockedSquare = lane and lane.blockedStepToX ~= nil
        and cell:getGridSquare(
            math.floor(lane.blockedStepToX),
            math.floor(lane.blockedStepToY),
            lane.blockedStepToZ or zz
        ) or nil
    local blockedFromSquare = lane and lane.blockedStepFromX ~= nil
        and cell:getGridSquare(
            math.floor(lane.blockedStepFromX),
            math.floor(lane.blockedStepFromY),
            lane.blockedStepFromZ or zz
        ) or nil
    local blockedPassage = blockedFromSquare and blockedSquare
        and TraversalQuery and TraversalQuery.GetPassageBetween
        and TraversalQuery.GetPassageBetween(
            blockedFromSquare, blockedSquare
        ) or nil
    if not blockedPassage and TraversalQuery
        and TraversalQuery.FindPassageToward
    then
        local passage = TraversalQuery.FindPassageToward(
            zombie, goalX, goalY, goalZ, cell
        )
        if passage then
            blockedPassage = passage.object
            blockedFromSquare = passage.fromSquare
            blockedSquare = passage.toSquare
        end
    end
    return {
        zombie = zombie,
        record = record,
        lane = lane,
        goalX = goalX,
        goalY = goalY,
        goalZ = goalZ,
        cell = cell,
        now = Internal.Core.Now(),
        zx = zx,
        zy = zy,
        zz = zz,
        fromX = fromX,
        fromY = fromY,
        fromZ = zz,
        fromPoint = Internal.describePoint(
            string.format("%.2f", fromX),
            string.format("%.2f", fromY),
            zz
        ),
        actorSquare = actorSquare,
        forwardX = Internal.roundHalf(forward:getX()),
        forwardY = Internal.roundHalf(forward:getY()),
        collided = Internal.isDoorCollision(zombie),
        blockedSquare = blockedSquare,
        blockedFromSquare = blockedFromSquare,
        blockedPassage = blockedPassage,
    }
end
local function buildCandidates(context)
    local candidates = {
        { x = context.zx, y = context.zy, z = context.zz },
        context.blockedSquare and {
            x = context.blockedSquare:getX(),
            y = context.blockedSquare:getY(),
            z = context.blockedSquare:getZ(),
        } or {
            x = context.zx,
            y = context.zy,
            z = context.zz,
            skip = true,
        },
        {
            x = context.zx + context.forwardX,
            y = context.zy + context.forwardY,
            z = context.zz,
        },
    }
    local seen = {}
    for index = 1, #candidates do
        local candidate = candidates[index]
        candidate.index = index
        local key = candidate.x .. ":" .. candidate.y .. ":" .. candidate.z
        if seen[key] then candidate.skip = true else seen[key] = true end
    end
    return candidates
end

function Internal.tryDoorOrWindowInteraction(
    zombie, record, lane, goalX, goalY, goalZ
)
    local context = buildContext(
        zombie, record, lane, goalX, goalY, goalZ
    )
    if not context then return false, nil end

    local handled, reason, decided = Internal.tryBlockedDoorPassage(context)
    if decided then return handled, reason end

    local candidates = buildCandidates(context)
    for index = 1, #candidates do
        local candidate = candidates[index]
        local square = not candidate.skip and context.cell:getGridSquare(
            candidate.x, candidate.y, candidate.z
        ) or nil
        local objects = square and square:getObjects() or nil
        if objects then
            for objectIndex = 0, objects:size() - 1 do
                local object = objects:get(objectIndex)
                if object then
                    handled, reason, decided =
                        Internal.tryDoorPassageCandidate(
                            context, object, candidate
                        )
                    if decided then return handled, reason end
                    handled, reason, decided =
                        Internal.tryWindowPassageCandidate(
                            context, object, candidate
                        )
                    if decided then return handled, reason end
                end
            end
        end
    end

    handled, reason, decided = Internal.tryFencePassage(context)
    if decided then return handled, reason end
    return false, nil
end

function Internal.hasClosedPassageToward(zombie, goalX, goalY, goalZ)
    local query = Internal.TraversalQuery or TraversalQuery
    if not query or not query.FindPassageToward
        or not query.IsClosedPassage
    then
        return false
    end
    local passage = query.FindPassageToward(zombie, goalX, goalY, goalZ)
    return passage ~= nil and passage.object ~= nil
        and query.IsClosedPassage(passage.object)
end
