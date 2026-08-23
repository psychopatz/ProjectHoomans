local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local MaterializationSafety = PNC.MaterializationSafety

function Internal.FindMaterializeSquare(record, now, reason)
    local cell
    local query
    if not getCell then
        return record.x, record.y, record.z, nil
    end
    cell = getCell()
    if MaterializationSafety and MaterializationSafety.Resolve then
        return MaterializationSafety.Resolve(record, now, cell, {
            requireSettle = tostring(reason or "") == "range_enter",
        })
    end
    query = PNC.TraversalQuery
    if query and query.FindNearestMaterializationSquare then
        return query.FindNearestMaterializationSquare(
            record.x,
            record.y,
            record.z,
            tonumber(Const.MATERIALIZE_SAFE_RADIUS) or 8,
            cell
        )
    end
    return record.x, record.y, record.z, nil
end

function Internal.LogPositionRecovery(
    record, eventName, recoveryReason,
    fromX, fromY, fromZ, toX, toY, toZ
)
    local recovery
    local message
    if not record then return end
    record.runtime = record.runtime or {}
    recovery = record.runtime.positionRecovery or {}
    record.runtime.positionRecovery = recovery
    recovery.count = (tonumber(recovery.count) or 0) + 1
    recovery.lastAt = Core.Now()
    recovery.lastEvent = eventName
    recovery.lastReason = recoveryReason
    recovery.fromX = fromX
    recovery.fromY = fromY
    recovery.fromZ = fromZ
    recovery.toX = toX
    recovery.toY = toY
    recovery.toZ = toZ
    message = "NPC position recovery npc=" .. tostring(record.id)
        .. " name=" .. tostring(record.name or "Unknown NPC")
        .. " event=" .. tostring(eventName)
        .. " reason=" .. tostring(recoveryReason or "blocked")
        .. " from=" .. tostring(fromX) .. "," .. tostring(fromY)
        .. "," .. tostring(fromZ)
        .. " to=" .. tostring(toX) .. "," .. tostring(toY)
        .. "," .. tostring(toZ)
        .. " count=" .. tostring(recovery.count)
    Core.LogWarn(message)
    Core.LogRecordDebug(record, message)
end

function Internal.FindNearestPlayer(record)
    local radius = math.max(
        tonumber(Const.ABSTRACT_NEAR_DISTANCE) or 80,
        tonumber(Const.ABSTRACT_DISTANCE) or 40
    )
    local players = Spatial and Spatial.QueryPlayers
        and Spatial.QueryPlayers(record.x, record.y, radius) or nil
    local nearest
    local bestDistSq = math.huge
    local i
    local player
    local distSq
    if not players then
        return Core.GetNearestPlayerPosition(record.x, record.y)
    end
    for i = 1, #players do
        player = players[i]
        if player then
            distSq = Core.DistanceSq(
                record.x, record.y, player:getX(), player:getY()
            )
            if distSq < bestDistSq then
                bestDistSq = distSq
                nearest = {
                    player = player,
                    x = player:getX(),
                    y = player:getY(),
                    z = player:getZ(),
                    distSq = distSq,
                }
            end
        end
    end
    return nearest
end
