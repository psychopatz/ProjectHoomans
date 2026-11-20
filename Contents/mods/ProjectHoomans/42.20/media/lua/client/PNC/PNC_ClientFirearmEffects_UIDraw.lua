local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then
    return
end

local Internal = Effects.Internal
local Draw = Internal and Internal.UIDraw
local Deps = Internal and Internal.UIDrawDeps
if not Draw or not Deps then
    return
end

local Diagnostics = Deps.Diagnostics
local SCREEN_CULL_MARGIN = Deps.SCREEN_CULL_MARGIN
local MUZZLE_FLASH_LENGTH = Deps.MUZZLE_FLASH_LENGTH
local MUZZLE_FLASH_COLOR = Deps.MUZZLE_FLASH_COLOR
local MUZZLE_CORE_COLOR = Deps.MUZZLE_CORE_COLOR
local logFirearmAudit = Deps.logFirearmAudit
local logDrawBlocked = Deps.logDrawBlocked
local readMethod = Deps.readMethod

local function lineVisible(x1, y1, x2, y2, screenWidth, screenHeight)
    if (tonumber(screenWidth) or 0) <= 0
        or (tonumber(screenHeight) or 0) <= 0
    then
        return true
    end
    return not (
        math.max(x1, x2) < -SCREEN_CULL_MARGIN
        or math.min(x1, x2) > screenWidth + SCREEN_CULL_MARGIN
        or math.max(y1, y2) < -SCREEN_CULL_MARGIN
        or math.min(y1, y2) > screenHeight + SCREEN_CULL_MARGIN
    )
end

local function render()
    local tracers = Effects.ActiveTracers
    local flashes = Effects.ActiveMuzzleFlashes
    if #tracers == 0 and #flashes == 0 then return end
    local renderer = getRenderer and getRenderer() or nil
    local texture = Effects.Texture
    local renderline
    local i
    local flash
    local alpha
    local zoom
    local length
    local x
    local y
    local tipX
    local tipY
    local screenWidth
    local screenHeight
    local core
    if isIngameState and not isIngameState() then
        logDrawBlocked("not_ingame")
        return
    end
    if isServer and isServer() then
        logDrawBlocked("server_context")
        return
    end
    if not renderer then
        logDrawBlocked("renderer_unavailable")
        return
    end
    renderline = renderer.renderline
    if not texture then
        logDrawBlocked("texture_unavailable")
        return
    end
    if type(renderline) ~= "function" then
        logDrawBlocked("renderline_unavailable")
        return
    end
    local audit = Diagnostics and Diagnostics.FirearmAuditEnabled == true
    if audit then
        Effects.DrawAuditState = {}
    end
    zoom = 1
    screenWidth = 0
    screenHeight = 0
    if getCore then
        core = getCore()
        zoom = tonumber(readMethod(core, "getZoom", 0)) or 1
        screenWidth = tonumber(readMethod(core, "getScreenWidth")) or 0
        screenHeight = tonumber(readMethod(core, "getScreenHeight")) or 0
    end
    zoom = math.max(0.1, zoom)

    -- The muzzle fallback deliberately uses the same B42-safe renderline
    -- overload as the Bandits projectile. Two short colored lines make a
    -- directional flash at the computed muzzle point without invoking the
    -- unavailable SpriteRenderer texture-draw callback overload.
    for i = #Effects.ActiveMuzzleFlashes, 1, -1 do
        flash = Effects.ActiveMuzzleFlashes[i]
        if audit and flash.drawAuditStarted ~= true then
            logFirearmAudit("muzzle_draw_begin", flash.auditPayload,
                "muzzleIndex=" .. tostring(i),
                "activeMuzzleFlashes=" .. tostring(#Effects.ActiveMuzzleFlashes),
                "ttl=" .. tostring(flash.ttl or ""))
            flash.drawAuditStarted = true
        end
        if flash.x and flash.y and flash.dx and flash.dy then
            alpha = math.max(0.25, 1.0 - (flash.tick / flash.ttl))
            length = (tonumber(flash.length) or MUZZLE_FLASH_LENGTH) / zoom
            x = flash.x / zoom
            y = flash.y / zoom
            tipX = x + (flash.dx * length)
            tipY = y + (flash.dy * length)
            if lineVisible(x, y, tipX, tipY, screenWidth, screenHeight) then
                renderer:renderline(
                    texture,
                    math.floor(x),
                    math.floor(y),
                    math.floor(tipX),
                    math.floor(tipY),
                    MUZZLE_FLASH_COLOR.r,
                    MUZZLE_FLASH_COLOR.g,
                    MUZZLE_FLASH_COLOR.b,
                    alpha
                )
                renderer:renderline(
                    texture,
                    math.floor(x + (flash.dx * (length * 0.18))),
                    math.floor(y + (flash.dy * (length * 0.18))),
                    math.floor(tipX),
                    math.floor(tipY),
                    MUZZLE_CORE_COLOR.r,
                    MUZZLE_CORE_COLOR.g,
                    MUZZLE_CORE_COLOR.b,
                    alpha
                )
                if audit and flash.drawRendered ~= true then
                    logFirearmAudit("muzzle_renderline_complete", flash.auditPayload,
                        "muzzleIndex=" .. tostring(i),
                        "renderer=SpriteRenderer",
                        "x=" .. tostring(math.floor(x)),
                        "y=" .. tostring(math.floor(y)),
                        "tipX=" .. tostring(math.floor(tipX)),
                        "tipY=" .. tostring(math.floor(tipY)))
                    flash.drawRendered = true
                end
                flash.tick = flash.tick + 1
                if flash.tick >= flash.ttl then
                    logFirearmAudit("muzzle_draw_complete", flash.auditPayload,
                        "muzzleIndex=" .. tostring(i),
                        "rendered=true",
                        "frames=" .. tostring(flash.tick))
                    table.remove(Effects.ActiveMuzzleFlashes, i)
                end
            else
                logFirearmAudit("muzzle_draw_complete", flash.auditPayload,
                    "muzzleIndex=" .. tostring(i),
                    "rendered=false",
                    "culled=true")
                table.remove(Effects.ActiveMuzzleFlashes, i)
            end
        end
    end

    if #tracers == 0 then return end
    local cameraX = getCameraOffX and getCameraOffX() or 0
    local cameraY = getCameraOffY and getCameraOffY() or 0
    for index = #tracers, 1, -1 do
        local tracer = tracers[index]
        local offsetX = tracer.cameraX - cameraX
        local offsetY = tracer.cameraY - cameraY
        local from = tracer.traveled
        local to = math.min(from + tracer.step, tracer.distance)
        local reached = to >= tracer.distance
        local x1 = (tracer.x + tracer.dx * from + offsetX) / zoom
        local y1 = (tracer.y + tracer.dy * from + offsetY) / zoom
        local endX = (tracer.endX + offsetX) / zoom
        local endY = (tracer.endY + offsetY) / zoom
        local x2 = reached and endX or (tracer.x + tracer.dx * to + offsetX) / zoom
        local y2 = reached and endY or (tracer.y + tracer.dy * to + offsetY) / zoom
        local visible = lineVisible(x1, y1, x2, y2, screenWidth, screenHeight)
        if audit and not tracer.drawAuditStarted then
            logFirearmAudit("draw_begin", tracer.auditPayload,
                "tracerIndex=" .. tostring(index),
                "activeTracers=" .. tostring(#tracers))
            tracer.drawAuditStarted = true
        end
        if visible then
            renderer:renderline(texture,
                math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2),
                tracer.color.r, tracer.color.g, tracer.color.b,
                math.max(0.2, 1 - from / tracer.distance))
            if audit and not tracer.drawRendered then
                logFirearmAudit("draw_renderline_complete", tracer.auditPayload,
                    "tracerIndex=" .. tostring(index),
                    "x1=" .. tostring(x1), "y1=" .. tostring(y1),
                    "x2=" .. tostring(x2), "y2=" .. tostring(y2))
                tracer.drawRendered = true
            end
        end
        local culled = not visible and not lineVisible(
            x2, y2, endX, endY, screenWidth, screenHeight)
        if reached or culled then
            if audit then
                logFirearmAudit("draw_complete", tracer.auditPayload,
                    "rendered=" .. tostring(tracer.drawRendered == true),
                    "culled=" .. tostring(culled))
            end
            local last = #tracers
            tracers[index] = tracers[last]
            tracers[last] = nil
        else
            tracer.traveled = to
        end
    end
end


Draw.render = render
