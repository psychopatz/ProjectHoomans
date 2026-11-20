local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.ProjectileVisualDeps or {}
local Geometry = Internal.ScreenGeometry or {}
local MAX_FALLBACK_TRACERS = Deps.MAX_FALLBACK_TRACERS
local MAX_VISIBLE_TRACERS_PER_SHOT = Deps.MAX_VISIBLE_TRACERS_PER_SHOT
local MAX_MUZZLE_FLASHES = Deps.MAX_MUZZLE_FLASHES
local TRACER_TTL = Deps.TRACER_TTL
local TRACER_SCREEN_LENGTH = Deps.TRACER_SCREEN_LENGTH
local MUZZLE_FLASH_TTL = Deps.MUZZLE_FLASH_TTL
local MUZZLE_FLASH_LENGTH = Deps.MUZZLE_FLASH_LENGTH

local angleRadians = Geometry.angleRadians
local resolveTargetScreen = Geometry.resolveTargetScreen
local resolveScreenDirection = Geometry.resolveScreenDirection
local resolveMuzzleScreen = Geometry.resolveMuzzleScreen
local getTracerColor = Geometry.getTracerColor

local function addMuzzleFlash(body, payload, muzzleX, muzzleY, muzzleZ)
    local screenX
    local screenY
    local anchorSource
    local directionX
    local directionY
    local dx
    local dy
    if #Effects.ActiveMuzzleFlashes >= MAX_MUZZLE_FLASHES then
        return 0
    end
    screenX, screenY, anchorSource = resolveMuzzleScreen(
        body,
        payload,
        muzzleX,
        muzzleY,
        muzzleZ
    )
    if not screenX or not screenY then return 0 end
    directionX, directionY = resolveScreenDirection(
        body,
        payload,
        muzzleX,
        muzzleY,
        muzzleZ
    )
    dx, dy = directionX, directionY
    Effects.ActiveMuzzleFlashes[#Effects.ActiveMuzzleFlashes + 1] = {
        x = screenX,
        y = screenY,
        dx = dx,
        dy = dy,
        length = MUZZLE_FLASH_LENGTH,
        tick = 0,
        ttl = MUZZLE_FLASH_TTL,
        anchorSource = anchorSource,
        auditPayload = payload,
    }
    return 1
end

local function addTracer(body, payload, muzzleX, muzzleY, muzzleZ)
    local tracers = Effects.ActiveTracers
    local available = MAX_FALLBACK_TRACERS - #tracers
    if available <= 0 then return 0 end
    local sx = tonumber(muzzleX) or tonumber(payload.sx)
    local sy = tonumber(muzzleY) or tonumber(payload.sy)
    local sz = tonumber(muzzleZ) or tonumber(payload.sz) or 0
    if not sx or not sy then return 0 end
    local startX, startY, anchorSource = resolveMuzzleScreen(body, payload, sx, sy, sz)
    if not startX or not startY then return 0 end

    local targetX, targetY = resolveTargetScreen(body, payload)
    local directionX, directionY, distance
    if targetX and targetY then
        local dx, dy = targetX - startX, targetY - startY
        distance = math.sqrt(dx * dx + dy * dy)
        if distance <= 0.001 then return 0 end
        directionX, directionY = dx / distance, dy / distance
    else
        directionX, directionY = resolveScreenDirection(body, payload, sx, sy, sz)
        distance = TRACER_SCREEN_LENGTH * 2
        targetX, targetY = startX + directionX * distance, startY + directionY * distance
    end

    local count = math.max(1, math.floor(tonumber(payload.projectileCount) or 1))
    local visualCount = math.min(count, MAX_VISIBLE_TRACERS_PER_SHOT, available)
    local spread = math.rad(math.min(89, math.max(0, tonumber(payload.projectileSpread) or 0)))
    if spread == 0 then visualCount = 1 end
    local angle = visualCount > 1 and angleRadians(directionY, directionX) or nil
    local step = math.max(TRACER_SCREEN_LENGTH, distance / TRACER_TTL)
    local color = getTracerColor(payload)
    local cameraX = getCameraOffX and getCameraOffX() or 0
    local cameraY = getCameraOffY and getCameraOffY() or 0
    for i = 1, visualCount do
        local dx, dy = directionX, directionY
        local endX, endY = targetX, targetY
        local heading
        if angle then
            local offset = (i - (visualCount + 1) * 0.5) / ((visualCount - 1) * 0.5)
            heading = angle + offset * spread
            if offset ~= 0 then
                dx, dy = math.cos(heading), math.sin(heading)
                endX, endY = startX + dx * distance, startY + dy * distance
            end
        end
        tracers[#tracers + 1] = {
            x = startX,
            y = startY,
            endX = endX,
            endY = endY,
            dx = dx,
            dy = dy,
            direction = heading,
            distance = distance,
            step = step,
            traveled = 0,
            cameraX = cameraX,
            cameraY = cameraY,
            anchorSource = anchorSource,
            auditPayload = payload,
            color = color,
        }
    end
    return visualCount
end

local function playImpact(payload)
    local cell
    local square
    if not payload.impactSound or tostring(payload.impactSound) == "" or not getCell then
        return false
    end
    cell = getCell()
    square = cell and cell.getGridSquare and cell:getGridSquare(
        math.floor(tonumber(payload.tx) or 0),
        math.floor(tonumber(payload.ty) or 0),
        math.floor(tonumber(payload.tz) or 0)
    ) or nil
    if square and square.playSound then
        return pcall(square.playSound, square, tostring(payload.impactSound))
    end
    return false
end

Effects.Internal.ProjectileVisual = {
    hasLiveAnchor = Geometry.hasLiveAnchor,
    addMuzzleFlash = addMuzzleFlash,
    addTracer = addTracer,
    playImpact = playImpact,
}
