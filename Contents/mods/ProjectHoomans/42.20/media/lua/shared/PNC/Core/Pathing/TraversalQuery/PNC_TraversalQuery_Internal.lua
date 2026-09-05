-- Shared compatibility and geometry helpers for traversal query providers.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local Internal = PNC.TraversalQuery.Internal
local REPORTED_CALL_ERRORS = {}

Internal.NativeQueryErrorCounts =
    Internal.NativeQueryErrorCounts or {}

function Internal.ReportCallError(methodName, errorValue)
    local key = tostring(methodName or "unknown")
    local count = (tonumber(Internal.NativeQueryErrorCounts[key]) or 0) + 1
    local core = PNC.Core
    Internal.NativeQueryErrorCounts[key] = count
    if REPORTED_CALL_ERRORS[key]
        or not core
        or not core.LogWarn
    then
        return
    end
    REPORTED_CALL_ERRORS[key] = true
    local message = tostring(errorValue or "unknown")
    if #message > 240 then
        message = string.sub(message, 1, 240)
    end
    core.LogWarn(
        "[PNC][PATH] native_query_error method=" .. key
            .. " count=" .. tostring(count)
            .. " error=" .. message
    )
end

function Internal.CallFirst(object, names, ...)
    local i
    local method
    local ok
    local result
    if not object then
        return nil
    end
    for i = 1, #names do
        method = object[names[i]]
        if type(method) == "function" then
            -- Passage APIs differ slightly between PZ point releases. Keep
            -- that compatibility uncertainty isolated to this query seam.
            ok, result = pcall(method, object, ...)
            if not ok then
                Internal.ReportCallError(names[i], result)
            end
            if ok and result ~= nil then
                return result
            end
        end
    end
    return nil
end

function Internal.ObjectBool(object, names, defaultValue)
    local result = Internal.CallFirst(object, names)
    if result == nil then
        return defaultValue == true
    end
    return result == true
end

local function listSize(list)
    if not list or not list.size then
        return 0
    end
    return list:size()
end

local function listItem(list, index)
    if not list or not list.get then
        return nil
    end
    return list:get(index)
end

function Internal.CardinalDelta(fromSquare, toSquare)
    local dx
    local dy
    if not fromSquare or not toSquare then
        return nil, nil
    end
    if fromSquare:getZ() ~= toSquare:getZ() then
        return nil, nil
    end
    dx = toSquare:getX() - fromSquare:getX()
    dy = toSquare:getY() - fromSquare:getY()
    if math.abs(dx) + math.abs(dy) ~= 1 then
        return nil, nil
    end
    return dx, dy
end

function Internal.GoalCrossesEdge(fromSquare, toX, toY, goalX, goalY)
    local fromX
    local fromY
    if not fromSquare then
        return false
    end
    fromX = fromSquare:getX()
    fromY = fromSquare:getY()
    if toX ~= fromX then
        return toX > fromX
            and (tonumber(goalX) or fromX) >= fromX + 1
            or toX < fromX
                and (tonumber(goalX) or fromX) < fromX
    end
    if toY ~= fromY then
        return toY > fromY
            and (tonumber(goalY) or fromY) >= fromY + 1
            or toY < fromY
                and (tonumber(goalY) or fromY) < fromY
    end
    return false
end

function Internal.GetMaterializationObstacle(square)
    local objects
    local object
    local sprite
    local i
    if not square or not square.getObjects then
        return nil
    end
    objects = square:getObjects()
    for i = 0, listSize(objects) - 1 do
        object = listItem(objects, i)
        if object and not (object.isFloor and object:isFloor()) then
            if instanceof and instanceof(object, "IsoFeedingTrough") then
                return "feeding_trough"
            end
            if object.isTableSurface and object:isTableSurface() then
                return "table_surface"
            end
            if object.getContainer and object:getContainer() then
                return "container_object"
            end
            sprite = object.getSprite and object:getSprite() or nil
            if sprite and sprite.getSpriteGrid and sprite:getSpriteGrid() then
                return "multi_tile_object"
            end
        end
    end
    return nil
end

function Internal.FindNearestByReason(x, y, z, maxRadius, cell, reasonResolver)
    local originX = math.floor(tonumber(x) or 0)
    local originY = math.floor(tonumber(y) or 0)
    local originZ = math.floor(tonumber(z) or 0)
    local originalReason
    local radius
    local dx
    local dy
    local candidateX
    local candidateY
    local candidateDistSq
    local best
    maxRadius = math.max(0, math.floor(tonumber(maxRadius) or 3))
    originalReason = reasonResolver(
        originX + 0.5,
        originY + 0.5,
        originZ,
        cell
    )
    if not originalReason then
        return tonumber(x) or originX + 0.5,
            tonumber(y) or originY + 0.5,
            originZ,
            nil
    end
    for radius = 1, maxRadius do
        best = nil
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.max(math.abs(dx), math.abs(dy)) == radius then
                    candidateX = originX + dx + 0.5
                    candidateY = originY + dy + 0.5
                    if not reasonResolver(candidateX, candidateY, originZ, cell) then
                        candidateDistSq = (candidateX - (tonumber(x) or originX + 0.5)) ^ 2
                            + (candidateY - (tonumber(y) or originY + 0.5)) ^ 2
                        if not best
                            or candidateDistSq < best.distSq
                            or (
                                candidateDistSq == best.distSq
                                and (
                                    candidateX < best.x
                                    or (candidateX == best.x and candidateY < best.y)
                                )
                            )
                        then
                            best = {
                                x = candidateX,
                                y = candidateY,
                                z = originZ,
                                distSq = candidateDistSq,
                            }
                        end
                    end
                end
            end
        end
        if best then
            return best.x, best.y, best.z, originalReason
        end
    end
    return nil, nil, nil, originalReason
end
