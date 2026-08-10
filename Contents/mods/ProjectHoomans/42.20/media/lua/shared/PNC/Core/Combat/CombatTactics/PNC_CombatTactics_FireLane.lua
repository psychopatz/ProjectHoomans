-- Friendly-fire lane validation and blocker diagnostics.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex

function Tactics.IsFriendlyFireSafe(record, target)
    local now
    local targetKey
    local cached
    local distance
    local midpointX
    local midpointY
    local corridor = tonumber(Const.RANGED_FRIENDLY_FIRE_CORRIDOR) or 0.62
    local candidates
    local other
    local players
    local player
    local i
    local unsafeKind
    local unsafeID
    local unsafeX
    local unsafeY
    local unsafeZ
    if not record or not target or target.x == nil or target.y == nil then
        return false, "invalid_fire_lane"
    end
    record.runtime = record.runtime or {}
    now = Core.Now()
    targetKey = tostring(target.kind or "") .. ":"
        .. tostring(target.id or target.zombieId or target.onlineID or "")
    cached = record.runtime.combatFireLane
    if cached
        and cached.targetKey == targetKey
        and now < (tonumber(cached.expiresAt) or 0)
        and Core.DistanceSq(cached.shooterX, cached.shooterY, record.x, record.y)
            <= 0.04
        and Core.DistanceSq(cached.targetX, cached.targetY, target.x, target.y)
            <= 0.04
    then
        return cached.safe == true,
            cached.safe == true and "fire_lane_clear" or "friendly_fire_risk"
    end
    distance = math.sqrt(Core.DistanceSq(record.x, record.y, target.x, target.y))
    midpointX = (record.x + target.x) * 0.5
    midpointY = (record.y + target.y) * 0.5
    candidates = Spatial and Spatial.QueryNPCs
        and Spatial.QueryNPCs(midpointX, midpointY, distance * 0.5 + corridor)
        or {}
    for i = 1, #candidates do
        other = candidates[i]
        if Internal.IsProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
            and Internal.PointNearSegment(
                tonumber(other.x) or 0, tonumber(other.y) or 0,
                record.x, record.y, target.x, target.y, corridor
            )
        then
            unsafeKind = "npc"
            unsafeID = other.id
            unsafeX = other.x
            unsafeY = other.y
            unsafeZ = other.z
            break
        end
    end
    if not unsafeKind then
        players = Spatial and Spatial.QueryPlayers
            and Spatial.QueryPlayers(
                midpointX, midpointY, distance * 0.5 + corridor
            ) or {}
        for i = 1, #players do
            player = players[i]
            if player
                and player ~= target.player
                and not (
                    target.kind == "player"
                    and target.onlineID ~= nil
                    and player.getOnlineID
                    and tonumber(player:getOnlineID()) == tonumber(target.onlineID)
                )
                and math.abs(player:getZ() - record.z) < 1
                and Internal.PointNearSegment(
                    player:getX(), player:getY(), record.x, record.y,
                    target.x, target.y, corridor
                )
            then
                unsafeKind = "player"
                unsafeID = player.getOnlineID and player:getOnlineID() or nil
                unsafeX = player:getX()
                unsafeY = player:getY()
                unsafeZ = player:getZ()
                break
            end
        end
    end
    record.runtime.combatFireLane = {
        targetKey = targetKey,
        safe = unsafeKind == nil,
        blockerKind = unsafeKind,
        blockerID = unsafeID,
        blockerX = unsafeX,
        blockerY = unsafeY,
        blockerZ = unsafeZ,
        shooterX = record.x,
        shooterY = record.y,
        targetX = target.x,
        targetY = target.y,
        checkedAt = now,
        expiresAt = now + (tonumber(Const.RANGED_FIRE_LANE_CACHE_MS) or 120),
    }
    if unsafeKind then return false, "friendly_fire_risk" end
    return true, "fire_lane_clear"
end

return Tactics
