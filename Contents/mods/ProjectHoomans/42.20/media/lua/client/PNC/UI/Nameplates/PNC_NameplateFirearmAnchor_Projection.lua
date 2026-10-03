-- Cached muzzle projection, offsets, debug state, and target selection.
local Anchor = PNC.NameplateFirearmAnchor
local Internal = Anchor.Internal
local resolveID = Internal.resolveID
local cacheKey = Internal.cacheKey
local currentTime = Internal.currentTime
local facingBasis = Internal.facingBasis
local refreshFacingBasis = Internal.refreshFacingBasis
local migrateLegacyScreenX = Internal.migrateLegacyScreenX
local offsetFor = Internal.offsetFor
local DEFAULT_FORWARD_OFFSET = Internal.DEFAULT_FORWARD_OFFSET
local DEFAULT_SIDE_OFFSET = Internal.DEFAULT_SIDE_OFFSET
local DEFAULT_HEIGHT_OFFSET = Internal.DEFAULT_HEIGHT_OFFSET
local LEGACY_OFFSET_VERSION = Internal.LEGACY_OFFSET_VERSION
local NAMEPLATE_ANCHOR_MAX_AGE_MS = Internal.NAMEPLATE_ANCHOR_MAX_AGE_MS

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


return Anchor
