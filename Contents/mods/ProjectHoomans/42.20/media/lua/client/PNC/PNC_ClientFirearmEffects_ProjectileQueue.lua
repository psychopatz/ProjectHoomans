local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.ProjectileVisualDeps or {}
local Geometry = Internal.ScreenGeometry or {}
local readMethod = Deps.readMethod
local MAX_FALLBACK_TRACERS = Deps.MAX_FALLBACK_TRACERS
local MAX_VISIBLE_TRACERS_PER_SHOT = Deps.MAX_VISIBLE_TRACERS_PER_SHOT
local MAX_MUZZLE_FLASHES = Deps.MAX_MUZZLE_FLASHES
local TRACER_TTL = Deps.TRACER_TTL
local MUZZLE_FLASH_TTL = Deps.MUZZLE_FLASH_TTL
local MUZZLE_FLASH_LENGTH = Deps.MUZZLE_FLASH_LENGTH

local angleRadians = Geometry.angleRadians
local normalizeScreen = Geometry.normalizeScreen
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
    local sx = tonumber(muzzleX) or tonumber(payload.sx)
    local sy = tonumber(muzzleY) or tonumber(payload.sy)
    local sz = tonumber(muzzleZ) or tonumber(payload.sz) or 0
    local count = math.max(1, math.min(16, math.floor(tonumber(payload.projectileCount) or 1)))
    local visualCount = math.min(count, MAX_VISIBLE_TRACERS_PER_SHOT)
    local spread = math.max(0, tonumber(payload.projectileSpread) or 0)
    local startX
    local startY
    local anchorSource
    local directionX
    local directionY
    local directionRadians
    local projectileDirection
    local dx
    local dy
    local centered
    local normalized
    local jitter
    local color = getTracerColor(payload)
    local added = 0
    local i
    if not sx or not sy then return 0 end
    startX, startY, anchorSource = resolveMuzzleScreen(body, payload, sx, sy, sz)
    if not startX or not startY then return 0 end
    directionX, directionY = resolveScreenDirection(
        body,
        payload,
        sx,
        sy,
        sz
    )
    directionRadians = angleRadians(directionY, directionX)
    for i = 1, visualCount do
        if #Effects.ActiveTracers >= MAX_FALLBACK_TRACERS then break end
        centered = i - ((visualCount + 1) * 0.5)
        normalized = centered / math.max(1, (visualCount - 1) * 0.5)
        jitter = ZombRandFloat and ZombRandFloat(-0.3, 0.3) or 0
        projectileDirection = directionRadians * 180 / math.pi
            + (normalized * spread) + jitter
        dx, dy = normalizeScreen(
            math.cos(projectileDirection * math.pi / 180),
            math.sin(projectileDirection * math.pi / 180),
            1,
            0
        )
        color = getTracerColor(payload)
        Effects.ActiveTracers[#Effects.ActiveTracers + 1] = {
            x = startX,
            y = startY,
            dx = dx,
            dy = dy,
            direction = projectileDirection,
            altitudeVariation = ZombRandFloat and ZombRandFloat(-10, 10) or 0,
            anchorSource = anchorSource,
            auditPayload = payload,
            tick = 1,
            ttl = TRACER_TTL,
            color = color,
        }
        added = added + 1
    end
    return added
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
