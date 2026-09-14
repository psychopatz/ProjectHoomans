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

function Anchor.GetOffsetParts(cache)
    local zoom
    local forwardOffset
    local sideOffset
    local heightOffset
    local forwardX
    local forwardY
    local sideX
    local sideY
    local baseX
    local baseY
    local heightX
    local heightY
    if not cache then return 0, 0, 0, 0, 0, 0, 0, 0 end
    refreshFacingBasis(cache)
    migrateLegacyScreenX(cache)
    zoom = math.max(0.1, tonumber(cache.zoom) or 1)
    forwardOffset = (tonumber(Anchor.Config.forwardOffset)
        or DEFAULT_FORWARD_OFFSET) / zoom
    sideOffset = (tonumber(Anchor.Config.sideOffset)
        or DEFAULT_SIDE_OFFSET) / zoom
    heightOffset = (tonumber(Anchor.Config.heightOffset)
        or DEFAULT_HEIGHT_OFFSET) / zoom
    forwardX = (tonumber(cache.forwardScreenX) or 0) * forwardOffset
    forwardY = (tonumber(cache.forwardScreenY) or 0) * forwardOffset
    sideX = (tonumber(cache.sideScreenX) or 0) * sideOffset
    sideY = (tonumber(cache.sideScreenY) or 0) * sideOffset
    heightX = (tonumber(cache.heightScreenX) or 0) * heightOffset
    heightY = (tonumber(cache.heightScreenY) or 1) * heightOffset
    baseX = heightX
    baseY = heightY
    return baseX + forwardX + sideX,
        baseY + forwardY + sideY,
        baseX,
        baseY,
        forwardX,
        forwardY,
        sideX,
        sideY
end

function Anchor.Update(body, id, playerIndex, managerX, managerY, zoom,
    nameX, nameY, groundX, groundY, worldX, worldY, worldZ)
    local resolvedID = resolveID(body, id)
    local key = cacheKey(resolvedID)
    local cache
    local facingX
    local facingY
    local forwardScreenX
    local forwardScreenY
    local sideScreenX
    local sideScreenY
    local heightScreenX
    local heightScreenY
    if not body or not nameX or not nameY then return nil end

    facingX, facingY, forwardScreenX, forwardScreenY, sideScreenX, sideScreenY,
        heightScreenX, heightScreenY =
        facingBasis(body, playerIndex)

    cache = {
        body = body,
        id = resolvedID,
        playerIndex = tonumber(playerIndex) or 0,
        managerX = tonumber(managerX) or 0,
        managerY = tonumber(managerY) or 0,
        zoom = math.max(0.1, tonumber(zoom) or 1),
        nameX = tonumber(nameX),
        nameY = tonumber(nameY),
        groundX = tonumber(groundX) or tonumber(nameX),
        groundY = tonumber(groundY) or tonumber(nameY),
        worldX = tonumber(worldX),
        worldY = tonumber(worldY),
        worldZ = tonumber(worldZ),
        facingX = facingX,
        facingY = facingY,
        forwardScreenX = forwardScreenX,
        forwardScreenY = forwardScreenY,
        sideScreenX = sideScreenX,
        sideScreenY = sideScreenY,
        heightScreenX = heightScreenX,
        heightScreenY = heightScreenY,
        updatedAt = currentTime(),
    }
    if key then Anchor.CacheByID[key] = cache end
    Anchor.CacheByBody[body] = cache
    return cache
end

function Anchor.Get(body, id)
    local key = cacheKey(resolveID(body, id))
    local cache = body and Anchor.CacheByBody[body] or nil
    if not cache and key then cache = Anchor.CacheByID[key] end
    if not cache then return nil end
    if currentTime() - (tonumber(cache.updatedAt) or 0)
        > NAMEPLATE_ANCHOR_MAX_AGE_MS
    then
        return nil
    end
    return cache
end

function Anchor.GetLocalMuzzle(cache)
    local offsetX
    local offsetY
    if not cache then return nil, nil end
    offsetX, offsetY = offsetFor(cache)
    return cache.nameX + offsetX, cache.nameY + offsetY
end

function Anchor.GetScreenMuzzle(body, id)
    local cache = Anchor.Get(body, id)
    local localX
    local localY
    if not cache then return nil, nil, nil end
    localX, localY = Anchor.GetLocalMuzzle(cache)
    return localX + cache.managerX,
        localY + cache.managerY,
        cache
end

function Anchor.GetRenderMuzzle(body, id)
    local cache
    local screenX
    local screenY
    screenX, screenY, cache = Anchor.GetScreenMuzzle(body, id)
    if not cache then return nil, nil, nil end
    -- FirearmEffects stores unscaled coordinates and divides by the active
    -- zoom at draw time, matching ISCoordConversion.ToScreen.
    return screenX * cache.zoom,
        screenY * cache.zoom,
        cache
end

function Anchor.GetScreenDirection(body, id, playerIndex)
    local cache = Anchor.Get(body, id)
    local target = Anchor.Target
    playerIndex = tonumber(playerIndex)
        or (target and target.playerIndex)
        or 0
    local facingX
    local facingY
    local forwardX
    local forwardY
    if cache then
        refreshFacingBasis(cache)
        return cache.forwardScreenX, cache.forwardScreenY, cache
    end
    facingX, facingY, forwardX, forwardY = facingBasis(body, playerIndex)
    return forwardX, forwardY, nil
end

function Anchor.GetConfig()
    return {
        relativeOffsetVersion = LEGACY_OFFSET_VERSION,
        forwardOffset = tonumber(Anchor.Config.forwardOffset)
            or DEFAULT_FORWARD_OFFSET,
        heightOffset = tonumber(Anchor.Config.heightOffset)
            or DEFAULT_HEIGHT_OFFSET,
        sideOffset = tonumber(Anchor.Config.sideOffset) or DEFAULT_SIDE_OFFSET,
        sideSign = tonumber(Anchor.Config.sideSign) or 1,
        showDebugText = Anchor.Config.showDebugText == true,
    }
end

function Anchor.IsDebugTextVisible()
    return Anchor.Config.showDebugText == true
end

function Anchor.ToggleDebugText()
    Anchor.Config.showDebugText = not Anchor.IsDebugTextVisible()
    return Anchor.Config.showDebugText
end

function Anchor.SetDebugTextVisible(visible)
    Anchor.Config.showDebugText = visible == true
    return Anchor.Config.showDebugText
end

function Anchor.AdjustOffset(axis, delta)
    local key
    local minimum = -math.huge
    local value
    axis = tostring(axis or "")
    if axis == "x" then
        key = "forwardOffset"
    elseif axis == "y" then
        key = "heightOffset"
        minimum = -math.huge
    elseif axis == "side" then
        key = "sideOffset"
        minimum = -math.huge
    else
        return nil
    end
    value = (tonumber(Anchor.Config[key]) or 0) + (tonumber(delta) or 0)
    Anchor.Config[key] = math.max(minimum, value)
    if key == "sideOffset" then
        Anchor.Config.sideSign = Anchor.Config[key] < 0 and -1 or 1
    end
    return Anchor.Config[key]
end

function Anchor.FlipSide()
    Anchor.Config.sideOffset = -((tonumber(Anchor.Config.sideOffset)
        or DEFAULT_SIDE_OFFSET))
    Anchor.Config.sideSign = Anchor.Config.sideOffset < 0 and -1 or 1
    return Anchor.Config.sideSign
end

function Anchor.ResetOffsets()
    Anchor.Config.relativeOffsetVersion = LEGACY_OFFSET_VERSION
    Anchor.Config.forwardOffset = DEFAULT_FORWARD_OFFSET
    Anchor.Config.heightOffset = DEFAULT_HEIGHT_OFFSET
    Anchor.Config.sideOffset = DEFAULT_SIDE_OFFSET
    Anchor.Config.sideSign = 1
    Anchor.Config.legacyScreenOffsetX = nil
end

function Anchor.GetDebugState(body, id)
    local resolvedID = resolveID(body, id)
    local key = cacheKey(resolvedID)
    local liveCache = Anchor.Get(body, id)
    local cache = liveCache
    local localX
    local localY
    local offsetX
    local offsetY
    local baseX
    local baseY
    local forwardX
    local forwardY
    local sideX
    local sideY
    local state = {
        id = resolvedID,
        status = "MISSING",
        fresh = false,
        config = Anchor.GetConfig(),
    }
    if not cache and body then cache = Anchor.CacheByBody[body] end
    if not cache and key then cache = Anchor.CacheByID[key] end
    if not cache then return state end
    localX, localY = Anchor.GetLocalMuzzle(cache)
    offsetX, offsetY, baseX, baseY, forwardX, forwardY, sideX, sideY =
        Anchor.GetOffsetParts(cache)
    state.status = liveCache and "LIVE" or "STALE"
    state.fresh = liveCache ~= nil
    state.cache = cache
    state.cacheAgeMs = currentTime() - (tonumber(cache.updatedAt) or 0)
    state.nameplateX = cache.nameX
    state.nameplateY = cache.nameY
    state.groundX = cache.groundX
    state.groundY = cache.groundY
    state.launchX = localX
    state.launchY = localY
    -- This is the actual screen coordinate used by the nameplate manager.
    -- GetRenderMuzzle intentionally returns a zoom-buffer coordinate for the
    -- firearm renderer, so it must not be used in the inspector display.
    state.renderX = localX + cache.managerX
    state.renderY = localY + cache.managerY
    -- The inspector reports offsets in final screen pixels, while the
    -- cached nameplate/local points remain in the renderer's zoom-relative
    -- coordinate space.
    state.offsetX = offsetX * cache.zoom
    state.offsetY = offsetY * cache.zoom
    state.baseOffsetX = baseX * cache.zoom
    state.baseOffsetY = baseY * cache.zoom
    state.sideOffsetX = sideX * cache.zoom
    state.sideOffsetY = sideY * cache.zoom
    state.forwardOffsetX = forwardX * cache.zoom
    state.forwardOffsetY = forwardY * cache.zoom
    state.localForward = tonumber(Anchor.Config.forwardOffset)
        or DEFAULT_FORWARD_OFFSET
    state.localSide = tonumber(Anchor.Config.sideOffset) or DEFAULT_SIDE_OFFSET
    state.localHeight = tonumber(Anchor.Config.heightOffset)
        or DEFAULT_HEIGHT_OFFSET
    state.facingX = cache.facingX
    state.facingY = cache.facingY
    state.forwardScreenX = cache.forwardScreenX
    state.forwardScreenY = cache.forwardScreenY
    state.sideScreenX = cache.sideScreenX
    state.sideScreenY = cache.sideScreenY
    state.heightScreenX = cache.heightScreenX
    state.heightScreenY = cache.heightScreenY
    state.source = "nameplate_relative"
    state.worldX = cache.worldX
    state.worldY = cache.worldY
    state.worldZ = cache.worldZ
    state.managerX = cache.managerX
    state.managerY = cache.managerY
    state.zoom = cache.zoom
    return state
end

function Anchor.SetTarget(body, id, playerIndex)
    local resolvedID = resolveID(body, id)
    if not body or resolvedID == nil then return false end
    Anchor.Target = {
        body = body,
        id = resolvedID,
        playerIndex = tonumber(playerIndex),
    }
    return true
end

function Anchor.ClearTarget()
    Anchor.Target = nil
end

function Anchor.ToggleTarget(body, id, playerIndex)
    local resolvedID = resolveID(body, id)
    local target = Anchor.Target
    if target and (target.body == body or target.id == resolvedID) then
        Anchor.ClearTarget()
        return false
    end
    return Anchor.SetTarget(body, resolvedID, playerIndex)
end

function Anchor.IsTarget(body, id)
    local target = Anchor.Target
    local resolvedID = resolveID(body, id)
    if not target then return false end
    if target.body == body then return true end
    return resolvedID ~= nil and target.id == resolvedID
end

local function drawCross(manager, x, y, size, color)
    manager:drawLine2(
        x - size, y, x + size, y,
        color.a, color.r, color.g, color.b
    )
    manager:drawLine2(
        x, y - size, x, y + size,
        color.a, color.r, color.g, color.b
    )
end

local function directionScreen(body, id, playerIndex)
    local directionX
    local directionY
    local facingX
    local facingY
    directionX, directionY = Anchor.GetScreenDirection(body, id, playerIndex)
    facingX, facingY = facing(body)
    return directionX, directionY, facingX, facingY
end

local function rounded(value)
    value = tonumber(value)
    if not value then return "-" end
    return string.format("%.1f", value)
end

local function debugText(manager, text, x, y, color, font)
    local Presentation = PNC.NameplatePresentation
    if Presentation and Presentation.DrawOutlinedText then
        Presentation.DrawOutlinedText(manager, text, x, y, color, 1, font)
    else
        manager:drawText(text, x, y, color.r, color.g, color.b, 1, font)
    end
end

function Anchor.Render(manager, body, id, nameX, nameY, groundX, groundY,
    worldX, worldY, worldZ)
    local cache
    local core
    local zoom = 1
    local muzzleX
    local muzzleY
    local directionX
    local directionY
    local facingX
    local facingY
    local textX
    local textY
    local font
    if not manager or not body or not Anchor.IsTarget(body, id) then
        return false
    end

    cache = Anchor.Get(body, id)
    if not cache then
        core = getCore and getCore() or nil
        if core and type(core.getZoom) == "function" then
            zoom = tonumber(core:getZoom(manager.playerIndex)) or 1
        end
        cache = Anchor.Update(
            body,
            id,
            manager.playerIndex,
            manager.x,
            manager.y,
            zoom,
            nameX,
            nameY,
            groundX,
            groundY,
            worldX,
            worldY,
            worldZ
        )
    end
    muzzleX, muzzleY = Anchor.GetLocalMuzzle(cache)
    if not muzzleX or not muzzleY then return false end
    -- Use the exact cached starter point that the effects bridge resolves.
    -- This prevents a stale caller argument from making the probe line and
    -- the tracer appear to disagree by a frame while an NPC is moving.
    nameX = cache.nameX or nameX
    nameY = cache.nameY or nameY

    drawCross(manager, nameX, nameY, 7, ANCHOR_COLOR)
    drawCross(manager, groundX or nameX, groundY or nameY, 7, GROUND_COLOR)
    drawCross(manager, muzzleX, muzzleY, 9, SHOULDER_COLOR)
    manager:drawLine2(
        nameX,
        nameY,
        muzzleX,
        muzzleY,
        SHOULDER_COLOR.a,
        SHOULDER_COLOR.r,
        SHOULDER_COLOR.g,
        SHOULDER_COLOR.b
    )

    directionX, directionY, facingX, facingY = directionScreen(
        body,
        id,
        manager.playerIndex
    )
    manager:drawLine2(
        muzzleX,
        muzzleY,
        muzzleX + (directionX * DEBUG_DIRECTION_LENGTH),
        muzzleY + (directionY * DEBUG_DIRECTION_LENGTH),
        DIRECTION_COLOR.a,
        DIRECTION_COLOR.r,
        DIRECTION_COLOR.g,
        DIRECTION_COLOR.b
    )

    if Anchor.IsDebugTextVisible() then
        textX = muzzleX + 14
        textY = muzzleY - 48
        font = PNC.NameplatePresentation
            and PNC.NameplatePresentation.Fonts
            and PNC.NameplatePresentation.Fonts.debug or UIFont.Small
        debugText(manager, "FIREARM ANCHOR  " .. tostring(cache.id or "?"),
            textX, textY, SHOULDER_COLOR, font)
        debugText(manager,
            "nameplate=" .. rounded(nameX) .. "," .. rounded(nameY)
                .. "  shoulder=" .. rounded(muzzleX) .. "," .. rounded(muzzleY),
            textX, textY + 14, ANCHOR_COLOR, font)
        debugText(manager,
            "local F/S/H=" .. rounded(Anchor.Config.forwardOffset) .. "/"
                .. rounded(Anchor.Config.sideOffset) .. "/"
                .. rounded(Anchor.Config.heightOffset)
                .. "  world=" .. rounded(worldX) .. "," .. rounded(worldY)
                .. "," .. rounded(worldZ),
            textX, textY + 28, GROUND_COLOR, font)
        debugText(manager,
            "facing=" .. rounded(facingX) .. "," .. rounded(facingY)
                .. "  line=orange",
            textX, textY + 42, DIRECTION_COLOR, font)
    end
    return true
end

function Anchor.Reset()
    Anchor.CacheByID = {}
    Anchor.CacheByBody = {}
    Anchor.ProjectionByPlayer = {}
    Anchor.Target = nil
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Anchor.Reset)
end

return Anchor
