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

local function safeMethod(target, methodName, ...)
    local method
    local ok
    local value
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target, ...)
    return ok and value or nil
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
    local weapon = body and safeMethod(body, "getPrimaryHandItem") or nil
    local fullType = weapon and safeMethod(weapon, "getFullType") or nil
    if weapon and (
        not payload.weaponFullType
        or tostring(fullType or "") == tostring(payload.weaponFullType)
    ) then
        return weapon
    end
    return nil
end

local function getMuzzlePosition(body, weapon, payload)
    local x = tonumber(body and safeMethod(body, "getX")) or tonumber(payload.sx) or 0
    local y = tonumber(body and safeMethod(body, "getY")) or tonumber(payload.sy) or 0
    local squareZ = tonumber(body and safeMethod(body, "getZ")) or tonumber(payload.sz) or 0
    local angle = tonumber(body and safeMethod(body, "getAnimAngleRadians"))
    local forward = weapon and safeMethod(weapon, "isTwoHandWeapon") == true and 0.75 or 0.45
    local right = 0.05
    local up = 1.1
    local staticModel = weapon and safeMethod(weapon, "getStaticModel") or nil
    local model
    local attachment
    local offset
    local manager
    if staticModel and getScriptManager then
        local ok
        ok, manager = pcall(getScriptManager)
        model = ok and manager and safeMethod(manager, "getModelScript", staticModel) or nil
        attachment = model and safeMethod(model, "getAttachmentById", "muzzle") or nil
        offset = attachment and safeMethod(attachment, "getOffset") or nil
        if offset then
            forward = tonumber(safeMethod(offset, "y")) or forward
            right = tonumber(safeMethod(offset, "x")) or right
            up = up + (tonumber(safeMethod(offset, "z")) or 0)
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

local function playShotAudio(body, weapon, payload)
    local sound = weapon and safeMethod(weapon, "getSwingSound") or payload.shotSound
    local shellSound = payload.shellFallSound and (
        weapon and safeMethod(weapon, "getShellFallSound") or payload.shellFallSound
    ) or nil
    local emitter
    local world
    local soundId
    local gain = tonumber(weapon and safeMethod(weapon, "getSoundGain"))
        or tonumber(payload.soundGain)
        or 1
    emitter = body and safeMethod(body, "getEmitter") or nil
    if not emitter and getWorld then
        local ok
        ok, world = pcall(getWorld)
        emitter = ok and world and safeMethod(
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

local function spawnLight(x, y, squareZ)
    local cell
    local light
    local square
    if not IsoLightSource or not getCell then return false end
    cell = getCell()
    if not cell or not cell.addLamppost then return false end
    square = cell.getGridSquare and cell:getGridSquare(
        math.floor(x),
        math.floor(y),
        math.floor(squareZ)
    ) or nil
    if not square then return false end
    local ok
    ok, light = pcall(
        IsoLightSource.new,
        math.floor(x),
        math.floor(y),
        math.floor(squareZ),
        1.0,
        0.46,
        0.14,
        18
    )
    if not ok or not light then return false end
    if not pcall(cell.addLamppost, cell, light) then return false end
    Effects.ActiveLights[#Effects.ActiveLights + 1] = {
        light = light,
        ticksRemaining = 2,
    }
    return true
end

local function addTracer(payload, x, y, z)
    local toScreen = ISCoordConversion and ISCoordConversion.ToScreen
    local startX
    local startY
    local endX
    local endY
    local tx = tonumber(payload.tx)
    local ty = tonumber(payload.ty)
    local tz = tonumber(payload.tz) or tonumber(payload.sz) or 0
    local count = math.max(1, math.min(16, math.floor(tonumber(payload.projectileCount) or 1)))
    local spread = math.max(0, tonumber(payload.projectileSpread) or 0)
    local i
    if not toScreen or not tx or not ty then return false end
    startX, startY = toScreen(x, y, z)
    endX, endY = toScreen(tx, ty, tz + 0.8)
    if not startX or not startY or not endX or not endY then return false end
    for i = 1, count do
        local centered = i - ((count + 1) * 0.5)
        local visualSpread = centered * math.max(2, spread * 0.8)
        Effects.ActiveTracers[#Effects.ActiveTracers + 1] = {
            sx = startX,
            sy = startY,
            tx = endX + visualSpread,
            ty = endY - (math.abs(centered) * 1.5),
            tick = 0,
            ttl = 4,
            color = payload.ammoType and string.find(string.lower(payload.ammoType), "shell", 1, true)
                and { r = 1.0, g = 0.62, b = 0.12 }
                or { r = 1.0, g = 0.78, b = 0.28 },
        }
    end
    return true
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
    local squareZ
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
    x, y, z, squareZ = getMuzzlePosition(body, weapon, payload)
    if body and body.startMuzzleFlash then
        pcall(body.startMuzzleFlash, body)
    end
    playShotAudio(body, weapon, payload)
    spawnLight(x, y, squareZ)
    addTracer(payload, x, y, z)
    playImpact(payload)
    return true
end

function Effects.OnTick()
    local cell = getCell and getCell() or nil
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local i
    for i = #Effects.ActiveLights, 1, -1 do
        local entry = Effects.ActiveLights[i]
        entry.ticksRemaining = entry.ticksRemaining - 1
        if entry.ticksRemaining <= 0 then
            if cell and entry.light and cell.removeLamppost then
                pcall(cell.removeLamppost, cell, entry.light)
            end
            table.remove(Effects.ActiveLights, i)
        end
    end
    for shotId, seenAt in pairs(Effects.SeenShots) do
        if now - (tonumber(seenAt) or 0) > 10000 then
            Effects.SeenShots[shotId] = nil
        end
    end
end

function Effects.OnPreUIDraw()
    local renderer = getRenderer and getRenderer() or nil
    local texture = Effects.Texture
    local zoom = getCore and getCore() and tonumber(getCore():getZoom(0)) or 1
    local i
    if not renderer or not texture then return end
    zoom = math.max(0.1, zoom or 1)
    for i = #Effects.ActiveTracers, 1, -1 do
        local tracer = Effects.ActiveTracers[i]
        local progress = math.min(1, (tracer.tick + 1) / tracer.ttl)
        local dx = tracer.tx - tracer.sx
        local dy = tracer.ty - tracer.sy
        local distance = math.sqrt((dx * dx) + (dy * dy))
        local headX = tracer.sx + (dx * progress)
        local headY = tracer.sy + (dy * progress)
        local tailProgress = math.max(0, progress - (math.min(90 / zoom, distance) / math.max(1, distance)))
        local tailX = tracer.sx + (dx * tailProgress)
        local tailY = tracer.sy + (dy * tailProgress)
        local alpha = 1.0 - (tracer.tick / tracer.ttl)
        renderer:renderline(
            texture,
            tailX / zoom,
            tailY / zoom,
            headX / zoom,
            headY / zoom,
            tracer.color.r,
            tracer.color.g,
            tracer.color.b,
            alpha
        )
        tracer.tick = tracer.tick + 1
        if tracer.tick >= tracer.ttl then
            table.remove(Effects.ActiveTracers, i)
        end
    end
end

function Effects.Reset()
    local cell = getCell and getCell() or nil
    local i
    for i = #Effects.ActiveLights, 1, -1 do
        if cell and Effects.ActiveLights[i].light and cell.removeLamppost then
            pcall(cell.removeLamppost, cell, Effects.ActiveLights[i].light)
        end
    end
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
