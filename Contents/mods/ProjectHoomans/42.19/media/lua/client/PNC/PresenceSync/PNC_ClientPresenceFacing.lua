--[[
    PNC Client Presence Facing
    Applies throttled authoritative facing to remote visual replicas.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const
local Interpolation = PNC.ClientInterpolation

local function applySnapshotFacing(zombie, snapshot)
    local visualState
    local hint
    local interpState
    local targetX
    local targetY
    local dirX
    local dirY
    local len
    local now
    local facingState
    local facingKey
    local dot
    local authoritativeDirX
    local authoritativeDirY
    local locomotionFacing
    local facingElapsed
    if not zombie or not snapshot then
        return false
    end
    visualState = snapshot.visualState or {}
    if visualState.specialActive == true
        or (visualState.moving ~= true
            and visualState.attackActive ~= true
            and visualState.stationaryFacing ~= true)
    then
        return false
    end
    hint = type(visualState.motionHint) == "table" and visualState.motionHint or nil
    interpState = snapshot and snapshot.id ~= nil and Interpolation and Interpolation.StateByID
        and Interpolation.StateByID[tostring(snapshot.id)] or nil
    targetX = tonumber(snapshot and snapshot.x) or zombie:getX()
    targetY = tonumber(snapshot and snapshot.y) or zombie:getY()
    authoritativeDirX = (visualState.attackActive == true or visualState.stationaryFacing == true)
        and tonumber(visualState.facingDirX)
        or tonumber(visualState.travelDirX)
    authoritativeDirY = (visualState.attackActive == true or visualState.stationaryFacing == true)
        and tonumber(visualState.facingDirY)
        or tonumber(visualState.travelDirY)
    if authoritativeDirX == nil
        and authoritativeDirY == nil
        and not hint
        and not interpState
        and math.abs(targetX - zombie:getX()) <= 0.001
        and math.abs(targetY - zombie:getY()) <= 0.001
    then
        return false
    end
    dirX = authoritativeDirX
        or tonumber(interpState and interpState.renderDirX)
        or tonumber(hint and hint.dirX)
        or tonumber(interpState and interpState.dirX)
        or ((tonumber(hint and hint.toX) or targetX) - (tonumber(hint and hint.fromX) or zombie:getX()))
    dirY = authoritativeDirY
        or tonumber(interpState and interpState.renderDirY)
        or tonumber(hint and hint.dirY)
        or tonumber(interpState and interpState.dirY)
        or ((tonumber(hint and hint.toY) or targetY) - (tonumber(hint and hint.fromY) or zombie:getY()))
    len = math.sqrt((dirX * dirX) + (dirY * dirY))
    if len <= 0.0001 then
        dirX = targetX - zombie:getX()
        dirY = targetY - zombie:getY()
        len = math.sqrt((dirX * dirX) + (dirY * dirY))
    end
    if len <= 0.0001 then
        return false
    end
    dirX = dirX / len
    dirY = dirY / len
    now = Core.Now()
    locomotionFacing = visualState.moving == true
        and visualState.attackActive ~= true
        and visualState.stationaryFacing ~= true
    facingKey = tostring(snapshot.id or zombie)
    facingState = Sync.FacingByID[facingKey]
    if facingState and facingState.body == zombie then
        dot = (tonumber(facingState.dirX) or 0) * dirX
            + (tonumber(facingState.dirY) or 0) * dirY
        facingElapsed = now
            - (tonumber(facingState.appliedAt) or 0)
        if locomotionFacing and (
            dot >= 0.99998
            or facingElapsed
                < (
                    tonumber(
                        Const.CLIENT_LOCOMOTION_FACING_MS
                    ) or 40
                )
        )
        then
            return false
        end
        if not locomotionFacing
            and (
                (
                    dot >= 0.998
                    and facingElapsed
                        < (
                            tonumber(
                                Const.CLIENT_FACING_REASSERT_MS
                            ) or 220
                        )
                )
                or (
                    dot >= 0.985
                    and facingElapsed < 120
                )
            )
        then
            return false
        end
    end
    if zombie.faceLocation then
        zombie:faceLocation(zombie:getX() + dirX, zombie:getY() + dirY)
    elseif zombie.faceLocationF then
        zombie:faceLocationF(zombie:getX() + dirX, zombie:getY() + dirY)
    else
        return false
    end
    Sync.FacingByID[facingKey] = {
        body = zombie,
        dirX = dirX,
        dirY = dirY,
        appliedAt = now,
    }
    return true
end

Internal.ApplySnapshotFacing = applySnapshotFacing
