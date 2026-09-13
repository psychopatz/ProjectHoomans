--[[
    PNC Client Firearm Effects
    Replays authoritative firearm-shot events as short-lived local effects.
    It never applies damage or changes ammunition.
]]

PNC = PNC or {}
PNC.ClientFirearmEffects = PNC.ClientFirearmEffects or {}

local Effects = PNC.ClientFirearmEffects

Effects.ActiveLights = Effects.ActiveLights or {}
Effects.ActiveTracers = Effects.ActiveTracers or {}
Effects.SeenShots = Effects.SeenShots or {}
Effects.Texture = Effects.Texture or (getTexture and getTexture("media/textures/mask_white.png") or nil)
local NativeEffects = require "PNC/PNC_ClientNativeFirearmEffects"
Effects.Native = NativeEffects

local MAX_FALLBACK_TRACERS = 256
local TRACER_TTL = 8

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
    local forward = weapon and readMethod(weapon, "isTwoHandWeapon") == true and 0.75 or 0.45
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

local function resolveLightSquare(body, payload)
    local cell
    local square
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

local function spawnLight(body, payload)
    local cell
    local square
    local lightSource
    local x
    local y
    local z
    if not IsoLightSource or not getCell then return false end
    cell = getCell()
    if not cell or not cell.addLamppost then return false end
    square = resolveLightSquare(body, payload)
    if not square then return false end
    x = tonumber(readMethod(square, "getX"))
    y = tonumber(readMethod(square, "getY"))
    z = tonumber(readMethod(square, "getZ"))
    if not x or not y or not z then return false end
    -- Match Bandits' proven B42 fallback: the final 1 is the light's
    -- one-tick lifetime, which lets the engine own its cleanup.
    lightSource = IsoLightSource.new(
        x,
        y,
        z,
        0.8,
        0.8,
        0.7,
        18,
        1
    )
    cell:addLamppost(lightSource)
    return true
end

local function projectToScreen(x, y, z)
    local converter = ISCoordConversion
    local sx
    local sy
    local cameraX
    local cameraY
    local zoom = 1
    local core
    if getCore then
        core = getCore()
        zoom = tonumber(core and readMethod(core, "getZoom", 0)) or 1
    end
    zoom = math.max(0.1, zoom)
    if converter and type(converter.ToScreen) == "function" then
        sx, sy = converter.ToScreen(x, y, z)
        return sx / zoom, sy / zoom
    end
    if IsoUtils and type(IsoUtils.XToScreen) == "function"
        and type(IsoUtils.YToScreen) == "function"
    then
        sx = IsoUtils.XToScreen(x, y, z)
        sy = IsoUtils.YToScreen(x, y, z)
        cameraX = getCameraOffX and getCameraOffX() or 0
        cameraY = getCameraOffY and getCameraOffY() or 0
        return (sx - cameraX) / zoom, (sy - cameraY) / zoom
    end
    return nil, nil
end

local function resolveTraceEndpoint(payload, muzzleX, muzzleY, muzzleZ, index, count, spread)
    local sx = tonumber(muzzleX)
    local sy = tonumber(muzzleY)
    local tx = tonumber(payload.tx)
    local ty = tonumber(payload.ty)
    local tz = tonumber(payload.tz) or tonumber(muzzleZ) or 0
    local dx
    local dy
    local length
    local centered
    local normalized
    local spreadAngle
    local lateralOffset
    if not sx or not sy or not tx or not ty then return nil, nil, nil end
    if count <= 1 or (tonumber(spread) or 0) <= 0 then
        return tx, ty, tz
    end
    dx = tx - sx
    dy = ty - sy
    length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.0001 then return tx, ty, tz end
    centered = index - ((count + 1) * 0.5)
    normalized = centered / math.max(1, (count - 1) * 0.5)
    spreadAngle = math.max(0, math.min(89, tonumber(spread) or 0))
    lateralOffset = math.tan(spreadAngle * math.pi / 180) * length * normalized
    return tx - ((dy / length) * lateralOffset),
        ty + ((dx / length) * lateralOffset),
        tz
end

local function addTracer(payload, muzzleX, muzzleY, muzzleZ)
    local sx = tonumber(muzzleX) or tonumber(payload.sx)
    local sy = tonumber(muzzleY) or tonumber(payload.sy)
    local sz = tonumber(muzzleZ) or tonumber(payload.sz) or 0
    local count = math.max(1, math.min(16, math.floor(tonumber(payload.projectileCount) or 1)))
    local spread = math.max(0, tonumber(payload.projectileSpread) or 0)
    local startX
    local startY
    local endX
    local endY
    local tx
    local ty
    local tz
    local color
    local added = 0
    local i
    if not sx or not sy then return false end
    startX, startY = projectToScreen(sx, sy, sz)
    if not startX or not startY then return false end
    color = payload.ammoType and string.find(
        string.lower(tostring(payload.ammoType)),
        "shell",
        1,
        true
    ) and { r = 1.0, g = 0.62, b = 0.12 } or { r = 1.0, g = 0.78, b = 0.28 }
    for i = 1, count do
        if #Effects.ActiveTracers >= MAX_FALLBACK_TRACERS then break end
        tx, ty, tz = resolveTraceEndpoint(payload, sx, sy, sz, i, count, spread)
        if tx and ty then
            endX, endY = projectToScreen(tx, ty, tz)
            if endX and endY then
                Effects.ActiveTracers[#Effects.ActiveTracers + 1] = {
                    startX = startX,
                    startY = startY,
                    endX = endX,
                    endY = endY,
                    altitudeVariation = ZombRandFloat and ZombRandFloat(-10, 10) or 0,
                    tick = 0,
                    ttl = TRACER_TTL,
                    color = color,
                }
                added = added + 1
            end
        end
    end
    return added > 0
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
    if type(payload) ~= "table" then return false end
    shotId = tostring(payload.shotId or "")
    if shotId ~= "" and Effects.SeenShots[shotId] then
        return false
    end
    if shotId ~= "" then
        Effects.SeenShots[shotId] = (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    end
    body = resolveBody(payload)
    weapon = resolveWeapon(body, payload)
    nativeResult, nativeReason = NativeEffects.PlayMuzzleFlash(body, weapon)
    if not nativeResult then
        recordNativeFailure(nativeReason)
        spawnLight(body, payload)
    end
    playShotAudio(body, weapon, payload)
    nativeResult, nativeReason = NativeEffects.PlayTracer(body, weapon, payload)
    if not nativeResult then
        recordNativeFailure(nativeReason)
        if not x then
            x, y, z = getMuzzlePosition(body, weapon, payload)
        end
        addTracer(payload, x, y, z)
    end
    playImpact(payload)
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
    local progress
    local tailProgress
    local tracer
    local x1
    local y1
    local x2
    local y2
    local alpha
    local zoom
    local baseAltitude
    if isIngameState and not isIngameState() then return end
    if isServer and isServer() then return end
    if not renderer then return end
    renderline = renderer.renderline
    if not texture or type(renderline) ~= "function" then return end
    zoom = 1
    if getCore then
        zoom = tonumber(readMethod(getCore(), "getZoom", 0)) or 1
    end
    zoom = math.max(0.1, zoom)
    baseAltitude = 85 / zoom
    for i = #Effects.ActiveTracers, 1, -1 do
        tracer = Effects.ActiveTracers[i]
        if tracer.startX and tracer.startY and tracer.endX and tracer.endY then
            progress = math.min(1, (tracer.tick + 1) / tracer.ttl)
            tailProgress = math.max(0, progress - 0.22)
            x1 = tracer.startX + ((tracer.endX - tracer.startX) * tailProgress)
            y1 = tracer.startY + ((tracer.endY - tracer.startY) * tailProgress)
            x2 = tracer.startX + ((tracer.endX - tracer.startX) * progress)
            y2 = tracer.startY + ((tracer.endY - tracer.startY) * progress)
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
        end
        tracer.tick = tracer.tick + 1
        if tracer.tick >= tracer.ttl then
            table.remove(Effects.ActiveTracers, i)
        end
    end
end

function Effects.Reset()
    Effects.ActiveLights = {}
    Effects.ActiveTracers = {}
    Effects.SeenShots = {}
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
