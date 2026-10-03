local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.ProjectileVisualDeps or {}
local readMethod = Deps.readMethod
local NameplateAnchor = Deps.NameplateAnchor
local TRACER_COLOR = Deps.TRACER_COLOR
local SHELL_TRACER_COLOR = Deps.SHELL_TRACER_COLOR

local function projectToScreen(x, y, z)
    local converter = ISCoordConversion
    local sx
    local sy
    local cameraX
    local cameraY
    if converter and type(converter.ToScreen) == "function" then
        sx, sy = converter.ToScreen(x, y, z)
        -- Keep the unscaled coordinates. The base Bandits projectile path
        -- feeds these through the active zoom at draw time; doing the zoom
        -- conversion here makes the effect disappear or drift at non-1x
        -- zoom levels.
        return sx, sy
    end
    if IsoUtils and type(IsoUtils.XToScreen) == "function"
        and type(IsoUtils.YToScreen) == "function"
    then
        sx = IsoUtils.XToScreen(x, y, z)
        sy = IsoUtils.YToScreen(x, y, z)
        cameraX = getCameraOffX and getCameraOffX() or 0
        cameraY = getCameraOffY and getCameraOffY() or 0
        return sx - cameraX, sy - cameraY
    end
    return nil, nil
end

local function angleRadians(y, x)
    local pi = math.pi
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + pi end
    if x < 0 and y < 0 then return math.atan(y / x) - pi end
    if y > 0 then return pi * 0.5 end
    if y < 0 then return -pi * 0.5 end
    return 0
end

local function normalizeScreen(x, y, fallbackX, fallbackY)
    local length = math.sqrt((x * x) + (y * y))
    if length <= 0.001 then return fallbackX, fallbackY end
    return x / length, y / length
end

local function cachedMuzzleScreen(body, payload)
    if not NameplateAnchor or not NameplateAnchor.GetRenderMuzzle then
        return nil, nil
    end
    return NameplateAnchor.GetRenderMuzzle(
        body,
        payload and payload.npcId or nil
    )
end

local function hasLiveAnchor(body, payload)
    if not body then return false end
    local _, _, cache = cachedMuzzleScreen(body, payload)
    return cache ~= nil
end

local function resolveDirectionDegrees(body, payload, muzzleX, muzzleY)
    local sx = tonumber(muzzleX) or tonumber(payload and payload.sx)
    local sy = tonumber(muzzleY) or tonumber(payload and payload.sy)
    local tx = tonumber(payload and payload.tx)
    local ty = tonumber(payload and payload.ty)
    local bodyX = tonumber(body and readMethod(body, "getX"))
    local bodyY = tonumber(body and readMethod(body, "getY"))
    local targetIsShooter = bodyX and bodyY and tx and ty
        and math.abs(tx - bodyX) <= 0.25
        and math.abs(ty - bodyY) <= 0.25
    local angle
    local forward
    local forwardX
    local forwardY
    if sx and sy and tx and ty
        and not targetIsShooter
        and (math.abs(tx - sx) > 0.0001 or math.abs(ty - sy) > 0.0001)
    then
        return angleRadians(ty - sy, tx - sx) * 180 / math.pi
    end
    forward = body and readMethod(body, "getForwardDirection") or nil
    forwardX = forward and tonumber(readMethod(forward, "getX")) or nil
    forwardY = forward and tonumber(readMethod(forward, "getY")) or nil
    if forwardX and forwardY
        and math.abs(forwardX) + math.abs(forwardY) > 0.001
    then
        return angleRadians(forwardY, forwardX) * 180 / math.pi
    end
    angle = tonumber(body and readMethod(body, "getAnimAngleRadians"))
    if angle then
        -- getAnimAngleRadians uses the same +X world-space convention as
        -- getForwardDirection; do not rotate it through the old down-axis
        -- approximation.
        return angle * 180 / math.pi
    end
    return 0
end

local function isometricDirection(directionDegrees)
    local theta = (tonumber(directionDegrees) or 0) * math.pi / 180
    local cosine = math.cos(theta)
    local sine = math.sin(theta)
    return normalizeScreen(
        cosine - sine,
        (cosine + sine) * 0.5,
        1,
        0
    )
end

local function bodyWorldPosition(body, payload)
    return tonumber(body and readMethod(body, "getX"))
        or tonumber(payload and payload.sx),
        tonumber(body and readMethod(body, "getY"))
        or tonumber(payload and payload.sy),
        tonumber(body and readMethod(body, "getZ"))
        or tonumber(payload and payload.sz)
        or 0
end

local function targetIsShooter(body, payload)
    local bodyX
    local bodyY
    local targetX = tonumber(payload and payload.tx)
    local targetY = tonumber(payload and payload.ty)
    if not body or not targetX or not targetY then return false end
    bodyX, bodyY = bodyWorldPosition(body, payload)
    return bodyX and bodyY
        and math.abs(targetX - bodyX) <= 0.25
        and math.abs(targetY - bodyY) <= 0.25
end

local function resolveScreenDirection(body, payload, muzzleX, muzzleY, muzzleZ)
    local targetX = tonumber(payload and payload.tx)
    local targetY = tonumber(payload and payload.ty)
    local targetZ = tonumber(payload and payload.tz) or 0
    local bodyX
    local bodyY
    local bodyZ
    local originX
    local originY
    local originZ
    local originScreenX
    local originScreenY
    local targetScreenX
    local targetScreenY
    local dx
    local dy
    local forwardX
    local forwardY
    local direction
    if targetX and targetY and not targetIsShooter(body, payload) then
        bodyX, bodyY, bodyZ = bodyWorldPosition(body, payload)
        originX = tonumber(muzzleX) or bodyX
        originY = tonumber(muzzleY) or bodyY
        originZ = tonumber(muzzleZ) or bodyZ
        originScreenX, originScreenY = projectToScreen(originX, originY, originZ)
        targetScreenX, targetScreenY = projectToScreen(
            targetX,
            targetY,
            targetZ
        )
        if originScreenX and originScreenY and targetScreenX and targetScreenY then
            dx = targetScreenX - originScreenX
            dy = targetScreenY - originScreenY
            if math.abs(dx) + math.abs(dy) > 0.001 then
                return normalizeScreen(dx, dy, 1, 0)
            end
        end
    end
    if NameplateAnchor and NameplateAnchor.GetScreenDirection then
        forwardX, forwardY = NameplateAnchor.GetScreenDirection(
            body,
            payload and payload.npcId or nil,
            payload and payload.playerIndex or 0
        )
        if forwardX and forwardY then
            return normalizeScreen(forwardX, forwardY, 1, 0)
        end
    end
    direction = resolveDirectionDegrees(body, payload, muzzleX, muzzleY)
    forwardX, forwardY = isometricDirection(direction)
    return normalizeScreen(forwardX, forwardY, 1, 0)
end

local function getTracerColor(payload)
    local ammoType = string.lower(tostring(payload and payload.ammoType or ""))
    if string.find(ammoType, "shell", 1, true) then
        return SHELL_TRACER_COLOR
    end
    return TRACER_COLOR
end

-- Screen origin for a barrel-anchored effect. A real shot projects the
-- world-space barrel tip, which is the same coordinate space Project A-Life's
-- tracers render in, so origin and direction finally agree. The cached
-- nameplate anchor is only a fallback now, or the explicit target of the
-- dry-fire anchor probe used by the debug action.
local function resolveMuzzleScreen(body, payload, muzzleX, muzzleY, muzzleZ)
    local screenX
    local screenY
    local cache
    if payload and payload.anchorProbe == true then
        screenX, screenY, cache = cachedMuzzleScreen(body, payload)
        if cache then return screenX, screenY, "nameplate_relative" end
    end
    screenX, screenY = projectToScreen(muzzleX, muzzleY, muzzleZ)
    if screenX and screenY then return screenX, screenY, "world_bore" end
    screenX, screenY, cache = cachedMuzzleScreen(body, payload)
    if cache then return screenX, screenY, "nameplate_relative" end
    return nil, nil, "none"
end

Effects.Internal.ScreenGeometry = {
    angleRadians = angleRadians,
    normalizeScreen = normalizeScreen,
    resolveScreenDirection = resolveScreenDirection,
    resolveMuzzleScreen = resolveMuzzleScreen,
    getTracerColor = getTracerColor,
    hasLiveAnchor = hasLiveAnchor,
}
