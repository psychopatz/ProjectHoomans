--[[-
    Project Hoomans firearm anchor bridge.

    Nameplates already calculate the most useful screen-space point for a
    visible NPC. Cache that point once during nameplate rendering and let the
    firearm fallback add a small, explicit shoulder offset to it. This keeps
    the tracer and its debug probe on the same coordinate system.
]]

PNC = PNC or {}
PNC.NameplateFirearmAnchor = PNC.NameplateFirearmAnchor or {}

local Anchor = PNC.NameplateFirearmAnchor

Anchor.CacheByID = Anchor.CacheByID or {}
Anchor.CacheByBody = Anchor.CacheByBody or {}
Anchor.ProjectionByPlayer = Anchor.ProjectionByPlayer or {}
Anchor.Config = Anchor.Config or {}
local DEFAULT_FORWARD_OFFSET = 84
local DEFAULT_SIDE_OFFSET = 18
local DEFAULT_HEIGHT_OFFSET = 72
local LEGACY_OFFSET_VERSION = 2
local previousOffsetVersion = tonumber(Anchor.Config.relativeOffsetVersion) or 0
local previousScreenX = tonumber(Anchor.Config.screenOffsetX)
local previousScreenY = tonumber(Anchor.Config.screenOffsetY)
local previousSide = tonumber(Anchor.Config.sideOffset)
local previousSideSign = tonumber(Anchor.Config.sideSign) or 1
Anchor.Config.relativeOffsetVersion = LEGACY_OFFSET_VERSION
Anchor.Config.forwardOffset = tonumber(Anchor.Config.forwardOffset)
    or DEFAULT_FORWARD_OFFSET
Anchor.Config.heightOffset = tonumber(Anchor.Config.heightOffset)
    or previousScreenY or DEFAULT_HEIGHT_OFFSET
if previousOffsetVersion < LEGACY_OFFSET_VERSION then
    -- The old X correction was screen-relative and cannot be converted until
    -- a live facing basis is available. Keep it for one lazy migration pass.
    Anchor.Config.legacyScreenOffsetX = previousScreenX or 0
    Anchor.Config.sideOffset = (previousSide or DEFAULT_SIDE_OFFSET)
        * previousSideSign
else
    Anchor.Config.sideOffset = tonumber(Anchor.Config.sideOffset)
        or DEFAULT_SIDE_OFFSET
end
Anchor.Config.sideSign = Anchor.Config.sideOffset < 0 and -1 or 1
if Anchor.Config.showDebugText == nil then
    Anchor.Config.showDebugText = true
end
Anchor.Target = Anchor.Target

local NAMEPLATE_ANCHOR_MAX_AGE_MS = 1000
local DEBUG_DIRECTION_LENGTH = 120
local ANCHOR_COLOR = { r = 0.25, g = 0.9, b = 1.0, a = 0.95 }
local SHOULDER_COLOR = { r = 1.0, g = 0.84, b = 0.18, a = 0.98 }
local DIRECTION_COLOR = { r = 1.0, g = 0.34, b = 0.12, a = 0.9 }
local GROUND_COLOR = { r = 0.78, g = 0.38, b = 1.0, a = 0.85 }

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    return method(target, ...)
end

local function bodyID(body)
    local modData
    if not body then return nil end
    modData = readMethod(body, "getModData")
    return modData and modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
end

local function resolveID(body, id)
    local value = id ~= nil and tostring(id) or ""
    if value ~= "" then return value end
    return bodyID(body)
end

local function cacheKey(id)
    local value = id ~= nil and tostring(id) or ""
    return value ~= "" and value or nil
end

local function currentTime()
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis()) or 0
    end
    return 0
end

local function facing(body)
    local forward = readMethod(body, "getForwardDirection")
    local x = forward and tonumber(readMethod(forward, "getX")) or nil
    local y = forward and tonumber(readMethod(forward, "getY")) or nil
    local angle
    if x and y and math.abs(x) + math.abs(y) > 0.001 then
        return x, y
    end
    angle = tonumber(readMethod(body, "getAnimAngleRadians"))
    if angle then return math.cos(angle), math.sin(angle) end
    return 1, 0
end

local function normalize(x, y, fallbackX, fallbackY)
    local length = math.sqrt((x * x) + (y * y))
    if length <= 0.001 then return fallbackX, fallbackY end
    return x / length, y / length
end

local function projectionDelta(playerIndex, deltaX, deltaY, deltaZ)
    local key
    local projection
    local baseX
    local baseY
    if type(isoToScreenX) ~= "function"
        or type(isoToScreenY) ~= "function"
    then
        return deltaX - deltaY, (deltaX + deltaY) * 0.5 - deltaZ
    end
    key = tostring(tonumber(playerIndex) or 0)
    projection = Anchor.ProjectionByPlayer[key]
    if not projection then
        baseX = isoToScreenX(playerIndex or 0, 0, 0, 0)
        baseY = isoToScreenY(playerIndex or 0, 0, 0, 0)
        projection = {
            xX = isoToScreenX(playerIndex or 0, 1, 0, 0) - baseX,
            xY = isoToScreenX(playerIndex or 0, 0, 1, 0) - baseX,
            xZ = isoToScreenX(playerIndex or 0, 0, 0, 1) - baseX,
            yX = isoToScreenY(playerIndex or 0, 1, 0, 0) - baseY,
            yY = isoToScreenY(playerIndex or 0, 0, 1, 0) - baseY,
            yZ = isoToScreenY(playerIndex or 0, 0, 0, 1) - baseY,
        }
        Anchor.ProjectionByPlayer[key] = projection
    end
    return projection.xX * deltaX
        + projection.xY * deltaY
        + projection.xZ * deltaZ,
        projection.yX * deltaX
        + projection.yY * deltaY
        + projection.yZ * deltaZ
end

local function facingBasis(body, playerIndex)
    local facingX, facingY = facing(body)
    local forwardDeltaX, forwardDeltaY = projectionDelta(
        playerIndex,
        facingX,
        facingY,
        0
    )
    local forwardScreenX, forwardScreenY = normalize(
        forwardDeltaX,
        forwardDeltaY,
        1,
        0
    )
    local sideWorldX = -facingY
    local sideWorldY = facingX
    local sideDeltaX, sideDeltaY = projectionDelta(
        playerIndex,
        sideWorldX,
        sideWorldY,
        0
    )
    local sideScreenX, sideScreenY = normalize(
        sideDeltaX,
        sideDeltaY,
        0,
        1
    )
    local heightDeltaX, heightDeltaY = projectionDelta(
        playerIndex,
        0,
        0,
        1
    )
    -- Positive H is deliberately toward the body (down the screen), because
    -- the nameplate is above the body and the inspector has always used a
    -- positive value to move the launch point down toward the hands.
    local heightScreenX, heightScreenY = normalize(
        -heightDeltaX,
        -heightDeltaY,
        0,
        1
    )
    return facingX, facingY,
        forwardScreenX, forwardScreenY,
        sideScreenX, sideScreenY,
        heightScreenX, heightScreenY
end

local function refreshFacingBasis(cache)
    local facingX
    local facingY
    local forwardScreenX
    local forwardScreenY
    local sideScreenX
    local sideScreenY
    local heightScreenX
    local heightScreenY
    if not cache or not cache.body then return cache end
    facingX, facingY, forwardScreenX, forwardScreenY, sideScreenX, sideScreenY,
        heightScreenX, heightScreenY = facingBasis(cache.body, cache.playerIndex)
    cache.facingX = facingX
    cache.facingY = facingY
    cache.forwardScreenX = forwardScreenX
    cache.forwardScreenY = forwardScreenY
    cache.sideScreenX = sideScreenX
    cache.sideScreenY = sideScreenY
    cache.heightScreenX = heightScreenX
    cache.heightScreenY = heightScreenY
    return cache
end

local function migrateLegacyScreenX(cache)
    local targetX
    local determinant
    local forwardCorrection
    local sideCorrection
    if not cache or cache.legacyMigrated then return end
    targetX = tonumber(Anchor.Config.legacyScreenOffsetX)
    if not targetX or math.abs(targetX) <= 0.001 then
        cache.legacyMigrated = true
        Anchor.Config.legacyScreenOffsetX = nil
        return
    end
    -- Solve F*forwardBasis + S*sideBasis = (legacyX, 0). This preserves the
    -- old visible point once, then stores the correction in NPC-local axes.
    determinant = cache.forwardScreenX * cache.sideScreenY
        - cache.forwardScreenY * cache.sideScreenX
    if math.abs(determinant) <= 0.001 then return end
    forwardCorrection = (targetX * cache.sideScreenY) / determinant
    sideCorrection = (-targetX * cache.forwardScreenY) / determinant
    Anchor.Config.forwardOffset = (tonumber(Anchor.Config.forwardOffset)
        or DEFAULT_FORWARD_OFFSET)
        + forwardCorrection
    Anchor.Config.sideOffset = (tonumber(Anchor.Config.sideOffset)
        or DEFAULT_SIDE_OFFSET)
        + sideCorrection
    Anchor.Config.sideSign = Anchor.Config.sideOffset < 0 and -1 or 1
    Anchor.Config.legacyScreenOffsetX = nil
    cache.legacyMigrated = true
end

local function offsetFor(cache)
    local offsetX
    local offsetY
    offsetX, offsetY = Anchor.GetOffsetParts(cache)
    return offsetX, offsetY
end


Anchor.Internal = Anchor.Internal or {}
local Internal = Anchor.Internal
Internal.resolveID = resolveID
Internal.cacheKey = cacheKey
Internal.currentTime = currentTime
Internal.facing = facing
Internal.normalize = normalize
Internal.projectionDelta = projectionDelta
Internal.facingBasis = facingBasis
Internal.refreshFacingBasis = refreshFacingBasis
Internal.migrateLegacyScreenX = migrateLegacyScreenX
Internal.offsetFor = offsetFor
Internal.DEFAULT_FORWARD_OFFSET = DEFAULT_FORWARD_OFFSET
Internal.DEFAULT_SIDE_OFFSET = DEFAULT_SIDE_OFFSET
Internal.DEFAULT_HEIGHT_OFFSET = DEFAULT_HEIGHT_OFFSET
Internal.LEGACY_OFFSET_VERSION = LEGACY_OFFSET_VERSION
Internal.NAMEPLATE_ANCHOR_MAX_AGE_MS = NAMEPLATE_ANCHOR_MAX_AGE_MS
Internal.DEBUG_DIRECTION_LENGTH = DEBUG_DIRECTION_LENGTH
Internal.ANCHOR_COLOR = ANCHOR_COLOR
Internal.SHOULDER_COLOR = SHOULDER_COLOR
Internal.DIRECTION_COLOR = DIRECTION_COLOR
Internal.GROUND_COLOR = GROUND_COLOR

return Anchor
