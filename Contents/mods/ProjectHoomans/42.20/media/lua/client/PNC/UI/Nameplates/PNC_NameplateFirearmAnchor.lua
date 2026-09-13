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
Anchor.Config = Anchor.Config or {}
Anchor.Config.screenOffsetX = tonumber(Anchor.Config.screenOffsetX) or 0
Anchor.Config.screenOffsetY = tonumber(Anchor.Config.screenOffsetY) or 72
Anchor.Config.sideOffset = tonumber(Anchor.Config.sideOffset) or 18
Anchor.Config.sideSign = tonumber(Anchor.Config.sideSign) or 1
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

local function offsetFor(cache)
    local offsetX
    local offsetY
    offsetX, offsetY = Anchor.GetOffsetParts(cache)
    return offsetX, offsetY
end

function Anchor.GetOffsetParts(cache)
    local zoom = math.max(0.1, tonumber(cache and cache.zoom) or 1)
    local sideOffset = (tonumber(Anchor.Config.sideOffset) or 18) / zoom
    local sideSign = tonumber(Anchor.Config.sideSign) or 1
    local baseX = (tonumber(Anchor.Config.screenOffsetX) or 0) / zoom
    local baseY = (tonumber(Anchor.Config.screenOffsetY) or 72) / zoom
    local sideX = (tonumber(cache and cache.sideScreenX) or 0)
        * sideOffset * sideSign
    local sideY = (tonumber(cache and cache.sideScreenY) or 0)
        * sideOffset * sideSign
    return baseX + sideX, baseY + sideY, baseX, baseY, sideX, sideY
end

function Anchor.Update(body, id, playerIndex, managerX, managerY, zoom,
    nameX, nameY, groundX, groundY, worldX, worldY, worldZ)
    local resolvedID = resolveID(body, id)
    local key = cacheKey(resolvedID)
    local cache
    local facingX
    local facingY
    local sideWorldX
    local sideWorldY
    local sideScreenX
    local sideScreenY
    local sideScreenLength
    if not body or not nameX or not nameY then return nil end

    facingX, facingY = facing(body)
    sideWorldX = -facingY
    sideWorldY = facingX
    sideScreenX = sideWorldX - sideWorldY
    sideScreenY = (sideWorldX + sideWorldY) * 0.5
    sideScreenLength = math.sqrt(
        (sideScreenX * sideScreenX) + (sideScreenY * sideScreenY)
    )
    if sideScreenLength > 0.001 then
        sideScreenX = sideScreenX / sideScreenLength
        sideScreenY = sideScreenY / sideScreenLength
    else
        sideScreenX = 0
        sideScreenY = 0
    end

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
        sideScreenX = sideScreenX,
        sideScreenY = sideScreenY,
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

function Anchor.GetRenderMuzzle(body, id)
    local cache = Anchor.Get(body, id)
    local localX
    local localY
    if not cache then return nil, nil, nil end
    localX, localY = Anchor.GetLocalMuzzle(cache)
    -- FirearmEffects stores unscaled coordinates and divides by the active
    -- zoom at draw time, matching ISCoordConversion.ToScreen.
    return (localX + cache.managerX) * cache.zoom,
        (localY + cache.managerY) * cache.zoom,
        cache
end

function Anchor.GetConfig()
    return {
        screenOffsetX = tonumber(Anchor.Config.screenOffsetX) or 0,
        screenOffsetY = tonumber(Anchor.Config.screenOffsetY) or 72,
        sideOffset = tonumber(Anchor.Config.sideOffset) or 18,
        sideSign = tonumber(Anchor.Config.sideSign) or 1,
    }
end

function Anchor.AdjustOffset(axis, delta)
    local key
    local minimum = -math.huge
    local value
    axis = tostring(axis or "")
    if axis == "x" then
        key = "screenOffsetX"
    elseif axis == "y" then
        key = "screenOffsetY"
        minimum = -math.huge
    elseif axis == "side" then
        key = "sideOffset"
        minimum = 0
    else
        return nil
    end
    value = (tonumber(Anchor.Config[key]) or 0) + (tonumber(delta) or 0)
    Anchor.Config[key] = math.max(minimum, value)
    return Anchor.Config[key]
end

function Anchor.FlipSide()
    Anchor.Config.sideSign = -((tonumber(Anchor.Config.sideSign) or 1))
    return Anchor.Config.sideSign
end

function Anchor.ResetOffsets()
    Anchor.Config.screenOffsetX = 0
    Anchor.Config.screenOffsetY = 72
    Anchor.Config.sideOffset = 18
    Anchor.Config.sideSign = 1
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
    offsetX, offsetY, baseX, baseY, sideX, sideY = Anchor.GetOffsetParts(cache)
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
    state.renderX = (localX + cache.managerX) * cache.zoom
    state.renderY = (localY + cache.managerY) * cache.zoom
    -- The inspector reports offsets in final screen pixels, while the
    -- cached nameplate/local points remain in the renderer's zoom-relative
    -- coordinate space.
    state.offsetX = offsetX * cache.zoom
    state.offsetY = offsetY * cache.zoom
    state.baseOffsetX = baseX * cache.zoom
    state.baseOffsetY = baseY * cache.zoom
    state.sideOffsetX = sideX * cache.zoom
    state.sideOffsetY = sideY * cache.zoom
    state.sideScreenX = cache.sideScreenX
    state.sideScreenY = cache.sideScreenY
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

local function directionScreen(body)
    local x
    local y
    x, y = facing(body)
    return x - y, (x + y) * 0.5, x, y
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

    directionX, directionY, facingX, facingY = directionScreen(body)
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
        "offset=" .. rounded(muzzleX - nameX) .. ","
            .. rounded(muzzleY - nameY)
            .. "  world=" .. rounded(worldX) .. "," .. rounded(worldY)
            .. "," .. rounded(worldZ),
        textX, textY + 28, GROUND_COLOR, font)
    debugText(manager,
        "facing=" .. rounded(facingX) .. "," .. rounded(facingY)
            .. "  line=orange",
        textX, textY + 42, DIRECTION_COLOR, font)
    return true
end

function Anchor.Reset()
    Anchor.CacheByID = {}
    Anchor.CacheByBody = {}
    Anchor.Target = nil
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Anchor.Reset)
end

return Anchor
