--[[
    PNC Client Firearm Effects
    Replays authoritative firearm-shot events as short-lived local effects.
    It never applies damage or changes ammunition.
]]

PNC = PNC or {}
PNC.ClientFirearmEffects = PNC.ClientFirearmEffects or {}

local Effects = PNC.ClientFirearmEffects
local Diagnostics = PNC.PerformanceScalingDiagnostics

Effects.ActiveLights = Effects.ActiveLights or {}
Effects.ActiveTracers = Effects.ActiveTracers or {}
Effects.ActiveMuzzleFlashes = Effects.ActiveMuzzleFlashes or {}
Effects.SeenShots = Effects.SeenShots or {}
Effects.DrawAuditState = Effects.DrawAuditState or {}
Effects.Texture = Effects.Texture or (getTexture and getTexture("media/textures/mask_white.png") or nil)
local NativeEffects = require "PNC/PNC_ClientNativeFirearmEffects"
Effects.Native = NativeEffects

local MAX_FALLBACK_TRACERS = 256
local MAX_MUZZLE_FLASHES = 128
local TRACER_TTL = 12
local MUZZLE_FLASH_TTL = 2
local MUZZLE_FLASH_LENGTH = 42

local function nowMs()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return 0
end

local function logFirearmAudit(eventName, payload, ...)
    local fields
    local i
    if not Diagnostics
        or Diagnostics.FirearmAuditEnabled ~= true
        or type(Diagnostics.LogFirearmAudit) ~= "function"
    then
        return false
    end
    fields = {
        "side=client",
        "shotId=" .. tostring(payload and payload.shotId or ""),
        "npc=" .. tostring(payload and payload.npcId or ""),
        "class=" .. tostring(payload and payload.tacticalClass or "unknown"),
        "faction=" .. tostring(payload and payload.factionID or ""),
        "hostility=" .. tostring(payload and payload.hostilityMode or ""),
        "t=" .. tostring(nowMs()),
    }
    for i = 1, select("#", ...) do
        fields[#fields + 1] = tostring(select(i, ...))
    end
    return Diagnostics.LogFirearmAudit(eventName, fields)
end

local function logDrawBlocked(reason)
    local effect
    local tracer
    local key = tostring(reason or "unknown")
    if (#Effects.ActiveTracers <= 0 and #Effects.ActiveMuzzleFlashes <= 0)
        or Effects.DrawAuditState[key]
    then
        return
    end
    tracer = Effects.ActiveTracers[#Effects.ActiveTracers]
    effect = tracer or Effects.ActiveMuzzleFlashes[#Effects.ActiveMuzzleFlashes]
    logFirearmAudit("draw_blocked", effect and effect.auditPayload or nil,
        "reason=" .. key,
        "activeTracers=" .. tostring(#Effects.ActiveTracers),
        "activeMuzzleFlashes=" .. tostring(#Effects.ActiveMuzzleFlashes))
    Effects.DrawAuditState[key] = true
end

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    return method(target, ...)
end

local function recordNativeFailure(reason)
    if NativeEffects and NativeEffects.RecordFailure then
        NativeEffects.RecordFailure(reason)
    end
end

local function sameWeaponType(weapon, fullType)
    local weaponType
    if not weapon then return false end
    if not fullType or tostring(fullType) == "" then return true end
    weaponType = readMethod(weapon, "getFullType")
    return tostring(weaponType or "") == tostring(fullType)
end

local function resolveBody(payload)
    local body
    local key
    if not payload then return nil end
    if payload.shooterOnlineID ~= nil and PNC.Network and PNC.Network.FindZombieByOnlineID then
        body = PNC.Network.FindZombieByOnlineID(payload.shooterOnlineID)
    end
    if body then return body end
    key = tostring(payload.npcId or "")
    if key == "" then return nil end
    if PNC.ClientPresenceSync then
        body = PNC.ClientPresenceSync.BodyByID and PNC.ClientPresenceSync.BodyByID[key] or nil
    end
    if not body and PNC.Registry and PNC.Registry.GetLiveZombie then
        body = PNC.Registry.GetLiveZombie(key)
    end
    return body
end

local function resolveWeapon(body, payload)
    local weapon
    if not body then return nil end
    weapon = readMethod(body, "getPrimaryHandItem")
    if sameWeaponType(weapon, payload and payload.weaponFullType) then
        return weapon
    end
    weapon = readMethod(body, "getUseHandWeapon")
    if sameWeaponType(weapon, payload and payload.weaponFullType) then
        return weapon
    end
    weapon = readMethod(body, "getAttackingWeapon")
    if sameWeaponType(weapon, payload and payload.weaponFullType) then
        return weapon
    end
    return nil
end

local function getMuzzlePosition(body, weapon, payload)
    local x = tonumber(body and readMethod(body, "getX")) or tonumber(payload.sx) or 0
    local y = tonumber(body and readMethod(body, "getY")) or tonumber(payload.sy) or 0
    local squareZ = tonumber(body and readMethod(body, "getZ")) or tonumber(payload.sz) or 0
    local angle = tonumber(body and readMethod(body, "getAnimAngleRadians"))
    -- HandWeapon does not expose a stable B42 isTwoHandWeapon() Lua method.
    -- Use a weapon-agnostic forward offset, then refine it from the model's
    -- muzzle attachment when a modded weapon supplies one.
    local forward = 0.65
    local right = 0.05
    local up = 1.1
    local staticModel = weapon and readMethod(weapon, "getStaticModel") or nil
    local model
    local attachment
    local offset
    local manager
    if staticModel and getScriptManager then
        manager = getScriptManager()
        model = manager and readMethod(manager, "getModelScript", staticModel) or nil
        attachment = model and readMethod(model, "getAttachmentById", "muzzle") or nil
        offset = attachment and readMethod(attachment, "getOffset") or nil
        if offset then
            forward = tonumber(readMethod(offset, "y")) or forward
            right = tonumber(readMethod(offset, "x")) or right
            up = up + (tonumber(readMethod(offset, "z")) or 0)
        end
    end
    if not angle then
        local tx = tonumber(payload.tx)
        local ty = tonumber(payload.ty)
        if tx and ty and (math.abs(tx - x) > 0.0001 or math.abs(ty - y) > 0.0001) then
            -- The animation angle is preferable, but target-derived facing
            -- keeps remote/modded bodies useful if that method is unavailable.
            angle = math.atan2 and math.atan2(x - tx, ty - y)
                or math.atan((x - tx) / ((ty - y) ~= 0 and (ty - y) or 0.0001))
        else
            angle = 0
        end
    end
    local forwardX = math.sin(angle)
    local forwardY = -math.cos(angle)
    local rightX = math.cos(angle)
    local rightY = math.sin(angle)
    return x + (forwardX * forward) + (rightX * right),
        y + (forwardY * forward) + (rightY * right),
        squareZ + up,
        squareZ
end

function Effects.GetNativeCapabilities(body, payload)
    local weapon = resolveWeapon(body, payload or {})
    return NativeEffects.GetCapabilities(body, weapon)
end

local function playShotAudio(body, weapon, payload)
    local sound = weapon and readMethod(weapon, "getSwingSound") or payload.shotSound
    local shellSound = payload.shellFallSound and (
        weapon and readMethod(weapon, "getShellFallSound") or payload.shellFallSound
    ) or nil
    local emitter
    local world
    local soundId
    local gain = tonumber(weapon and readMethod(weapon, "getSoundGain"))
        or tonumber(payload.soundGain)
        or 1
    emitter = body and readMethod(body, "getEmitter") or nil
    if not emitter and getWorld then
        world = getWorld()
        emitter = world and readMethod(
            world,
            "getFreeEmitter",
            tonumber(payload.sx) or 0,
            tonumber(payload.sy) or 0,
            tonumber(payload.sz) or 0
        ) or nil
    end
    if not emitter then return false end
    if sound and tostring(sound) ~= "" and emitter and emitter.playSound then
        local ok
        ok, soundId = pcall(emitter.playSound, emitter, tostring(sound))
        if ok and soundId and emitter.setVolume then
            pcall(emitter.setVolume, emitter, soundId, gain)
        end
    end
    if shellSound and tostring(shellSound) ~= "" and emitter and emitter.playSound then
        pcall(emitter.playSound, emitter, tostring(shellSound))
    end
    return sound ~= nil
end

local function resolveLightSquare(body, payload, muzzleX, muzzleY, muzzleZ)
    local cell
    local square
    local squareZ
    if getCell and muzzleX and muzzleY and muzzleZ then
        cell = getCell()
        if cell and type(cell.getGridSquare) == "function" then
            squareZ = tonumber(body and readMethod(body, "getZ"))
                or tonumber(payload and payload.sz)
                or 0
            square = cell:getGridSquare(
                math.floor(tonumber(muzzleX) or 0),
                math.floor(tonumber(muzzleY) or 0),
                math.floor(squareZ)
            )
            if square then return square end
        end
    end
    if body then
        square = readMethod(body, "getSquare")
        if square then return square end
    end
    if not getCell then return nil end
    cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(payload.sx) or 0),
        math.floor(tonumber(payload.sy) or 0),
        math.floor(tonumber(payload.sz) or 0)
    )
end

local function spawnLight(body, payload, muzzleX, muzzleY, muzzleZ)
    local cell
    local square
    local lightSource
    local x
    local y
    local z
    if not IsoLightSource or not getCell then return false, "api_unavailable" end
    cell = getCell()
    if not cell or not cell.addLamppost then return false, "cell_unavailable" end
    square = resolveLightSquare(body, payload, muzzleX, muzzleY, muzzleZ)
    if not square then return false, "square_unavailable" end
    x = tonumber(readMethod(square, "getX"))
    y = tonumber(readMethod(square, "getY"))
    z = tonumber(readMethod(square, "getZ"))
    if not x or not y or not z then
        return false, "square_coordinates_unavailable"
    end
    -- Match Bandits' proven B42 fallback: the final 1 is the light's
    -- one-tick lifetime, which lets the engine own its cleanup. Use an
    -- Use a desaturated warm-white flash. IsoLightSource has RGB and radius,
    -- not an alpha channel, so lower RGB/radius is the transparent-looking
    -- equivalent and avoids an artificial orange pool of light.
    lightSource = IsoLightSource.new(
        x,
        y,
        z,
        0.82,
        0.70,
        0.54,
        12,
        1
    )
    cell:addLamppost(lightSource)
    return true, "created", x, y, z
end

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

local function resolveDirectionDegrees(body, payload, muzzleX, muzzleY)
    local sx = tonumber(muzzleX) or tonumber(payload and payload.sx)
    local sy = tonumber(muzzleY) or tonumber(payload and payload.sy)
    local tx = tonumber(payload.tx)
    local ty = tonumber(payload.ty)
    local angle
    if sx and sy and tx and ty
        and (math.abs(tx - sx) > 0.0001 or math.abs(ty - sy) > 0.0001)
    then
        return angleRadians(ty - sy, tx - sx) * 180 / math.pi
    end
    angle = tonumber(body and readMethod(body, "getAnimAngleRadians"))
    if angle then
        -- getAnimAngleRadians points down the character's facing axis, while
        -- the isometric projectile formula uses +X as zero degrees.
        return (angle - (math.pi * 0.5)) * 180 / math.pi
    end
    return 0
end

local function isometricDirection(directionDegrees)
    local theta = (tonumber(directionDegrees) or 0) * math.pi / 180
    local cosine = math.cos(theta)
    local sine = math.sin(theta)
    return cosine - sine, (cosine + sine) * 0.5
end

local function getTracerColor(payload)
    local ammoType = string.lower(tostring(payload and payload.ammoType or ""))
    if string.find(ammoType, "shell", 1, true) then
        return { r = 1.0, g = 0.56, b = 0.06 }
    end
    return { r = 1.0, g = 0.76, b = 0.18 }
end

local function addMuzzleFlash(body, payload, muzzleX, muzzleY, muzzleZ)
    local screenX
    local screenY
    local direction
    local dx
    local dy
    local color
    if #Effects.ActiveMuzzleFlashes >= MAX_MUZZLE_FLASHES then
        return 0
    end
    screenX, screenY = projectToScreen(muzzleX, muzzleY, muzzleZ)
    if not screenX or not screenY then return 0 end
    direction = resolveDirectionDegrees(body, payload, muzzleX, muzzleY)
    dx, dy = isometricDirection(direction)
    color = getTracerColor(payload)
    Effects.ActiveMuzzleFlashes[#Effects.ActiveMuzzleFlashes + 1] = {
        x = screenX,
        y = screenY,
        dx = dx,
        dy = dy,
        length = MUZZLE_FLASH_LENGTH,
        tick = 0,
        ttl = MUZZLE_FLASH_TTL,
        auditPayload = payload,
        color = color,
    }
    return 1
end

local function addTracer(body, payload, muzzleX, muzzleY, muzzleZ)
    local sx = tonumber(muzzleX) or tonumber(payload.sx)
    local sy = tonumber(muzzleY) or tonumber(payload.sy)
    local sz = tonumber(muzzleZ) or tonumber(payload.sz) or 0
    local count = math.max(1, math.min(16, math.floor(tonumber(payload.projectileCount) or 1)))
    local spread = math.max(0, tonumber(payload.projectileSpread) or 0)
    local startX
    local startY
    local direction
    local projectileDirection
    local dx
    local dy
    local centered
    local normalized
    local jitter
    local color
    local added = 0
    local i
    if not sx or not sy then return 0 end
    startX, startY = projectToScreen(sx, sy, sz)
    if not startX or not startY then return 0 end
    direction = resolveDirectionDegrees(body, payload, sx, sy)
    for i = 1, count do
        if #Effects.ActiveTracers >= MAX_FALLBACK_TRACERS then break end
        centered = i - ((count + 1) * 0.5)
        normalized = centered / math.max(1, (count - 1) * 0.5)
        jitter = ZombRandFloat and ZombRandFloat(-0.3, 0.3) or 0
        projectileDirection = direction + (normalized * spread) + jitter
        dx, dy = isometricDirection(projectileDirection)
        color = getTracerColor(payload)
        Effects.ActiveTracers[#Effects.ActiveTracers + 1] = {
            x = startX,
            y = startY,
            dx = dx,
            dy = dy,
            direction = projectileDirection,
            altitudeVariation = ZombRandFloat and ZombRandFloat(-10, 10) or 0,
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

function Effects.Play(payload)
    local shotId
    local body
    local weapon
    local x
    local y
    local z
    local nativeResult
    local nativeReason
    local lightResult
    local lightReason
    local lightX
    local lightY
    local lightZ
    local audioResult
    local tracerCount
    local muzzleCount
    local impactResult
    local startedAt = nowMs()
    if type(payload) ~= "table" then
        logFirearmAudit("play_rejected", nil,
            "reason=payload_not_table",
            "elapsedMs=" .. tostring(nowMs() - startedAt))
        return false
    end
    shotId = tostring(payload.shotId or "")
    logFirearmAudit("play_start", payload,
        "weapon=" .. tostring(payload.weaponFullType or ""),
        "position=" .. tostring(payload.sx or "") .. ","
            .. tostring(payload.sy or "") .. "," .. tostring(payload.sz or ""))
    if shotId ~= "" and Effects.SeenShots[shotId] then
        logFirearmAudit("play_duplicate", payload, "reason=shot_already_seen")
        return false
    end
    if shotId ~= "" then
        Effects.SeenShots[shotId] = (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    end
    body = resolveBody(payload)
    weapon = resolveWeapon(body, payload)
    logFirearmAudit("body_weapon_resolved", payload,
        "body=" .. tostring(body ~= nil),
        "weapon=" .. tostring(weapon ~= nil),
        "weaponType=" .. tostring(weapon and readMethod(weapon, "getFullType") or ""))
    nativeResult, nativeReason = NativeEffects.PlayMuzzleFlash(body, weapon)
    logFirearmAudit("muzzle_native_complete", payload,
        "result=" .. tostring(nativeResult),
        "reason=" .. tostring(nativeReason or ""))
    if not nativeResult then
        recordNativeFailure(nativeReason)
        x, y, z = getMuzzlePosition(body, weapon, payload)
        muzzleCount = addMuzzleFlash(body, payload, x, y, z)
        logFirearmAudit("muzzle_visual_queue_complete", payload,
            "result=" .. tostring(muzzleCount > 0),
            "queued=" .. tostring(muzzleCount),
            "active=" .. tostring(#Effects.ActiveMuzzleFlashes),
            "muzzle=" .. tostring(x or "") .. "," .. tostring(y or "")
                .. "," .. tostring(z or ""))
        lightResult, lightReason, lightX, lightY, lightZ = spawnLight(
            body,
            payload,
            x,
            y,
            z
        )
        logFirearmAudit("muzzle_light_complete", payload,
            "result=" .. tostring(lightResult),
            "reason=" .. tostring(lightReason or ""),
            "square=" .. tostring(lightX or "") .. ","
                .. tostring(lightY or "") .. "," .. tostring(lightZ or ""))
    end
    audioResult = playShotAudio(body, weapon, payload)
    logFirearmAudit("audio_complete", payload,
        "result=" .. tostring(audioResult),
        "sound=" .. tostring(payload.shotSound or ""),
        "shellSound=" .. tostring(payload.shellFallSound or ""))
    nativeResult, nativeReason = NativeEffects.PlayTracer(body, weapon, payload)
    logFirearmAudit("tracer_native_complete", payload,
        "result=" .. tostring(nativeResult),
        "reason=" .. tostring(nativeReason or ""))
    if not nativeResult then
        recordNativeFailure(nativeReason)
        if not x then
            x, y, z = getMuzzlePosition(body, weapon, payload)
        end
        tracerCount = addTracer(body, payload, x, y, z)
        logFirearmAudit("tracer_screen_queue_complete", payload,
            "result=" .. tostring(tracerCount > 0),
            "queued=" .. tostring(tracerCount),
            "active=" .. tostring(#Effects.ActiveTracers),
            "muzzle=" .. tostring(x or "") .. "," .. tostring(y or "")
                .. "," .. tostring(z or ""))
    end
    impactResult = playImpact(payload)
    logFirearmAudit("impact_audio_complete", payload,
        "result=" .. tostring(impactResult),
        "impactSound=" .. tostring(payload.impactSound or ""))
    logFirearmAudit("play_complete", payload,
        "elapsedMs=" .. tostring(nowMs() - startedAt),
        "activeTracers=" .. tostring(#Effects.ActiveTracers))
    return true
end

function Effects.OnTick()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    for shotId, seenAt in pairs(Effects.SeenShots) do
        if now - (tonumber(seenAt) or 0) > 10000 then
            Effects.SeenShots[shotId] = nil
        end
    end
end

function Effects.OnPreUIDraw()
    local renderer = getRenderer and getRenderer() or nil
    local texture = Effects.Texture
    local renderline
    local i
    local flash
    local tracer
    local alpha
    local zoom
    local baseAltitude
    local length
    local halfWidth
    local x
    local y
    local tipX
    local tipY
    local centerX
    local centerY
    local perpX
    local perpY
    local stepLength
    local stepX
    local stepY
    local x1
    local y1
    local x2
    local y2
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
    if Diagnostics and Diagnostics.FirearmAuditEnabled == true then
        Effects.DrawAuditState = {}
    end
    zoom = 1
    if getCore then
        zoom = tonumber(readMethod(getCore(), "getZoom", 0)) or 1
    end
    zoom = math.max(0.1, zoom)
    baseAltitude = 85 / zoom

    -- The muzzle fallback deliberately uses the same B42-safe renderline
    -- overload as the Bandits projectile. Three short colored lines make a
    -- directional flash at the computed muzzle point without invoking the
    -- unavailable SpriteRenderer texture-draw callback overload.
    for i = #Effects.ActiveMuzzleFlashes, 1, -1 do
        flash = Effects.ActiveMuzzleFlashes[i]
        if flash.drawAuditStarted ~= true then
            logFirearmAudit("muzzle_draw_begin", flash.auditPayload,
                "muzzleIndex=" .. tostring(i),
                "activeMuzzleFlashes=" .. tostring(#Effects.ActiveMuzzleFlashes),
                "ttl=" .. tostring(flash.ttl or ""))
            flash.drawAuditStarted = true
        end
        if flash.x and flash.y and flash.dx and flash.dy then
            alpha = math.max(0.25, 1.0 - (flash.tick / flash.ttl))
            length = (tonumber(flash.length) or MUZZLE_FLASH_LENGTH) / zoom
            halfWidth = length * 0.28
            x = flash.x / zoom
            y = (flash.y / zoom) - baseAltitude
            tipX = x + (flash.dx * length)
            tipY = y + (flash.dy * length)
            renderer:renderline(
                texture,
                math.floor(x),
                math.floor(y),
                math.floor(tipX),
                math.floor(tipY),
                1.0,
                0.28,
                0.02,
                alpha
            )
            centerX = x + (flash.dx * length * 0.58)
            centerY = y + (flash.dy * length * 0.58)
            perpX = -flash.dy
            perpY = flash.dx
            renderer:renderline(
                texture,
                math.floor(x + (flash.dx * (length * 0.18))),
                math.floor(y + (flash.dy * (length * 0.18))),
                math.floor(centerX + (perpX * halfWidth)),
                math.floor(centerY + (perpY * halfWidth)),
                1.0,
                0.72,
                0.08,
                alpha
            )
            renderer:renderline(
                texture,
                math.floor(centerX - (perpX * halfWidth)),
                math.floor(centerY - (perpY * halfWidth)),
                math.floor(centerX + (perpX * halfWidth)),
                math.floor(centerY + (perpY * halfWidth)),
                1.0,
                0.95,
                0.46,
                alpha
            )
            if flash.drawRendered ~= true then
                logFirearmAudit("muzzle_renderline_complete", flash.auditPayload,
                    "muzzleIndex=" .. tostring(i),
                    "renderer=SpriteRenderer",
                    "x=" .. tostring(math.floor(x)),
                    "y=" .. tostring(math.floor(y)),
                    "tipX=" .. tostring(math.floor(tipX)),
                    "tipY=" .. tostring(math.floor(tipY)))
                flash.drawRendered = true
            end
        end
        flash.tick = flash.tick + 1
        if flash.tick >= flash.ttl then
            logFirearmAudit("muzzle_draw_complete", flash.auditPayload,
                "muzzleIndex=" .. tostring(i),
                "rendered=" .. tostring(flash.drawRendered == true),
                "frames=" .. tostring(flash.tick))
            table.remove(Effects.ActiveMuzzleFlashes, i)
        end
    end

    -- Match Bandits' proven projectile motion: start at the unscaled
    -- isometric screen coordinate, advance by a fixed screen-space step, and
    -- apply zoom only at render time. This is visibly a flying trajectory,
    -- rather than a line that fades in place between two ground points.
    for i = #Effects.ActiveTracers, 1, -1 do
        tracer = Effects.ActiveTracers[i]
        if tracer.drawAuditStarted ~= true then
            logFirearmAudit("draw_begin", tracer.auditPayload,
                "tracerIndex=" .. tostring(i),
                "activeTracers=" .. tostring(#Effects.ActiveTracers),
                "ttl=" .. tostring(tracer.ttl or ""))
            tracer.drawAuditStarted = true
        end
        if tracer.x and tracer.y and tracer.dx and tracer.dy then
            stepLength = 600 / zoom
            x1 = tracer.x / zoom
            y1 = tracer.y / zoom
            stepX = math.floor(stepLength * tracer.dx)
            stepY = math.floor(stepLength * tracer.dy)
            x2 = x1 + stepX
            y2 = y1 + stepY
            alpha = math.max(0.2, 1.0 - (tracer.tick / tracer.ttl))
            renderer:renderline(
                texture,
                math.floor(x1),
                math.floor(y1 - baseAltitude),
                math.floor(x2),
                math.floor(y2 - (baseAltitude + ((tonumber(tracer.altitudeVariation) or 0) / zoom))),
                tracer.color.r,
                tracer.color.g,
                tracer.color.b,
                alpha
            )
            if tracer.drawRendered ~= true then
                logFirearmAudit("draw_renderline_complete", tracer.auditPayload,
                    "tracerIndex=" .. tostring(i),
                    "renderer=SpriteRenderer",
                    "x1=" .. tostring(math.floor(x1)),
                    "y1=" .. tostring(math.floor(y1 - baseAltitude)),
                    "x2=" .. tostring(math.floor(x2)),
                    "y2=" .. tostring(math.floor(y2
                        - (baseAltitude + ((tonumber(tracer.altitudeVariation) or 0) / zoom)))))
                tracer.drawRendered = true
            end
            tracer.x = tracer.x + stepX
            tracer.y = tracer.y + stepY
        end
        tracer.tick = tracer.tick + 1
        if tracer.tick >= tracer.ttl then
            logFirearmAudit("draw_complete", tracer.auditPayload,
                "tracerIndex=" .. tostring(i),
                "rendered=" .. tostring(tracer.drawRendered == true),
                "frames=" .. tostring(tracer.tick))
            table.remove(Effects.ActiveTracers, i)
        end
    end
end

function Effects.Reset()
    Effects.ActiveLights = {}
    Effects.ActiveTracers = {}
    Effects.ActiveMuzzleFlashes = {}
    Effects.SeenShots = {}
    Effects.DrawAuditState = {}
end

if Events and Events.OnTick then
    Events.OnTick.Add(Effects.OnTick)
end
if Events and Events.OnPreUIDraw then
    Events.OnPreUIDraw.Add(Effects.OnPreUIDraw)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Effects.Reset)
end

return Effects
