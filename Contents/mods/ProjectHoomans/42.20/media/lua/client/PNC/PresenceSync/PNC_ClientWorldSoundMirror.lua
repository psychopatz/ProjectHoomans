-- Lua-safe mirror of the primitive OnWorldSound payload.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}

local Sync = PNC.ClientPresenceSync
local Core = PNC.Core
local Mirror = Sync.WorldSoundMirror or {}
local WORLD_SOUNDS = {}
-- Vanilla WorldSound life is 16 updates; keep a small timing cushion for
-- the 250 ms probe interval and packet delivery.
local WORLD_SOUND_TTL_MS = 750
local WORLD_SOUND_MAX_COUNT = 128

Sync.WorldSoundMirror = Mirror
Mirror.Enabled = false

local function isInstanceOf(value, className)
    local ok
    local result
    if not value or type(instanceof) ~= "function" then
        return false
    end
    ok, result = pcall(instanceof, value, className)
    return ok and result == true
end

local function prune(now)
    local index = #WORLD_SOUNDS
    while index > 0 do
        local sound = WORLD_SOUNDS[index]
        if not sound
            or now - (tonumber(sound.observedAt) or 0)
                > WORLD_SOUND_TTL_MS
        then
            table.remove(WORLD_SOUNDS, index)
        end
        index = index - 1
    end
end

function Mirror.OnWorldSound(x, y, z, radius, volume, source)
    local now
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    radius = tonumber(radius)
    volume = tonumber(volume)
    if not x or not y or not z or not radius or not volume
        or radius <= 0 or volume <= 0
        or isInstanceOf(source, "IsoZombie")
    then
        return
    end
    -- OnWorldSound omits the stress flags and zombieIgnoreDist. The PNC MP
    -- stimulus uses STRESS_ZOMBIES with an ignore distance of zero, and the
    -- normal addSound overload uses the same zombie-stress default.
    now = tonumber(Core and Core.Now and Core.Now() or 0) or 0
    prune(now)
    WORLD_SOUNDS[#WORLD_SOUNDS + 1] = {
        x = x,
        y = y,
        z = z,
        radius = radius,
        volume = volume,
        sourceIsZombie = false,
        sourceIsPlayer = isInstanceOf(source, "IsoPlayer"),
        observedAt = now,
    }
    while #WORLD_SOUNDS > WORLD_SOUND_MAX_COUNT do
        table.remove(WORLD_SOUNDS, 1)
    end
end

local function hearingMultiplier(manager, zombie)
    local ok
    local value
    if not manager or not manager.getHearingMultiplier then
        return 1
    end
    ok, value = pcall(manager.getHearingMultiplier, manager, zombie)
    value = ok and tonumber(value) or nil
    return value and math.max(0, value) or 1
end

function Mirror.Find(manager, zombie, now)
    local x = math.floor(tonumber(zombie:getX()) or 0)
    local y = math.floor(tonumber(zombie:getY()) or 0)
    local z = math.floor(tonumber(zombie:getZ()) or 0)
    local multiplier = hearingMultiplier(manager, zombie)
    local best
    local bestAttract = 0
    prune(now)
    for index = 1, #WORLD_SOUNDS do
        local sound = WORLD_SOUNDS[index]
        local dx = x - sound.x
        local dy = y - sound.y
        local dz = (z - sound.z) * 3
        local radius = sound.radius * multiplier
        local distanceSq = (dx * dx) + (dy * dy) + (dz * dz)
        if radius > 0 and distanceSq <= radius * radius then
            local attract = sound.volume
                * (1 - (distanceSq / (radius * radius)))
            if attract > bestAttract then
                best = sound
                bestAttract = attract
            end
        end
    end
    return best, bestAttract
end

function Mirror.Reset()
    WORLD_SOUNDS = {}
end

function Mirror.Attach()
    Mirror.Enabled = false
    if not (Events and Events.OnWorldSound
        and isClient and isClient() == true)
    then
        return false
    end
    if Sync.ClientWorldSoundHandler then
        Events.OnWorldSound.Remove(Sync.ClientWorldSoundHandler)
    end
    Sync.ClientWorldSoundHandler = Mirror.OnWorldSound
    Events.OnWorldSound.Add(Sync.ClientWorldSoundHandler)
    Mirror.Enabled = true
    return true
end

return Mirror
