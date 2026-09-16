-- Wakes locally simulated zombies for vanilla networked world sounds.
--
-- IsoZombie:RespondToSound() exits early while a zombie is marked useless.
-- Bandits explicitly re-enable that flag on their client-owned zombies. We
-- do the same only when the client receives an actual zombie-attracting sound,
-- avoiding a per-frame NPC scan and preserving the vanilla owner/client
-- movement model.
--
-- Build 42's getBiggestSoundZomb() returns ResultBiggestSound Java userdata.
-- That wrapper is not a Lua table, so its public Java fields cannot be read as
-- result.sound/result.attract from Kahlua. OnWorldSound exposes the primitive
-- event payload safely, including sounds rebuilt from a WorldSoundPacket.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics
local NEXT_PROBE_AT = setmetatable({}, { __mode = "k" })
local OBSERVATION_BY_ZOMBIE = setmetatable({}, { __mode = "k" })

require "PNC/PresenceSync/PNC_ClientWorldSoundMirror"
local Mirror = Sync.WorldSoundMirror
if Mirror and Mirror.Attach then Mirror.Attach() end

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end

local function isLocalZombie(zombie)
    return zombie
        and not (zombie.isRemoteZombie and zombie:isRemoteZombie())
        and not (zombie.isDead and zombie:isDead())
end

local function increment(name, amount)
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment(name, amount)
    end
end

local function cacheObservation(zombie, now, value)
    local cached = {
        nextAt = now
            + (tonumber(Const.ZOMBIE_NPC_STIMULUS_PROBE_MS) or 250),
        value = value,
    }
    OBSERVATION_BY_ZOMBIE[zombie] = cached
    increment("ZombieAggro.StimulusSoundProbes")
    return cached.value
end

function Internal.GetClientZombieSoundObservation(zombie, now)
    local manager
    local query
    local ok
    local result
    local sound
    local safeSound
    local resultIsTable
    local cached
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not isLocalZombie(zombie) then return nil end
    cached = OBSERVATION_BY_ZOMBIE[zombie]
    if cached and now < (tonumber(cached.nextAt) or 0) then
        return cached.value
    end
    manager = WorldSoundManager and WorldSoundManager.instance or nil
    if Mirror and Mirror.Enabled then
        sound, result = Mirror.Find(manager, zombie, now)
        return cacheObservation(zombie, now, {
            available = manager ~= nil,
            found = manager ~= nil and sound ~= nil,
            observedAt = now,
            attract = sound and result or nil,
            x = sound and sound.x or nil,
            y = sound and sound.y or nil,
            z = sound and sound.z or nil,
            radius = sound and sound.radius or nil,
            volume = sound and sound.volume or nil,
            sourceIsZombie = sound
                and sound.sourceIsZombie == true or false,
            sourceIsPlayer = sound
                and sound.sourceIsPlayer == true or false,
        })
    end
    if not manager or not manager.getBiggestSoundZomb then
        cached = {
            nextAt = now
                + (tonumber(Const.ZOMBIE_NPC_STIMULUS_PROBE_MS) or 250),
            value = {
                available = false,
                found = false,
                observedAt = now,
            },
        }
        OBSERVATION_BY_ZOMBIE[zombie] = cached
        return cached.value
    end
    query = manager.getBiggestSoundZomb
    ok, result = pcall(
        query,
        manager,
        math.floor(tonumber(zombie:getX()) or 0),
        math.floor(tonumber(zombie:getY()) or 0),
        math.floor(tonumber(zombie:getZ()) or 0),
        true,
        zombie
    )
    resultIsTable = ok and type(result) == "table"
    if not resultIsTable then
        if ok and result ~= nil then
            increment("ZombieAggro.StimulusSoundProbeOpaqueResult")
        end
        return cacheObservation(zombie, now, {
            available = false,
            found = false,
            observedAt = now,
        })
    end
    -- Only Lua tables may be indexed here. A WorldSound value from a build
    -- that exposes the wrapper but not its fields is still a valid presence
    -- signal, while its optional metadata must remain unread.
    sound = result.sound
    safeSound = type(sound) == "table" and sound or nil
    return cacheObservation(zombie, now, {
        available = true,
        found = sound ~= nil,
        observedAt = now,
        attract = tonumber(result.attract),
        x = safeSound and tonumber(safeSound.x) or nil,
        y = safeSound and tonumber(safeSound.y) or nil,
        z = safeSound and tonumber(safeSound.z) or nil,
        radius = safeSound and tonumber(safeSound.radius) or nil,
        volume = safeSound and tonumber(safeSound.volume) or nil,
        sourceIsZombie = safeSound
            and safeSound.sourceIsZombie == true or false,
        sourceIsPlayer = safeSound
            and safeSound.sourceIsPlayer == true or false,
    })
end

local function hasZombieSound(zombie, now)
    local observation = Internal.GetClientZombieSoundObservation(zombie, now)
    return observation and observation.found == true
end

function Internal.OnClientZombieStimulusUpdate(zombie)
    local now
    if not isClient or isClient() ~= true or not isLocalZombie(zombie)
        or not zombie.isUseless or not zombie:isUseless()
    then
        return false
    end
    if isForeignOwnedBody(zombie) then
        return false
    end
    now = Core and Core.Now and Core.Now() or 0
    if now < (tonumber(NEXT_PROBE_AT[zombie]) or 0) then
        return false
    end
    NEXT_PROBE_AT[zombie] = now
        + (tonumber(Const.ZOMBIE_NPC_STIMULUS_PROBE_MS) or 250)
    if not hasZombieSound(zombie, now) then
        return false
    end
    if zombie.setUseless then
        zombie:setUseless(false)
        increment("ZombieAggro.StimulusUselessReactivated")
        return true
    end
    return false
end

function Internal.ResetClientZombieStimulus()
    NEXT_PROBE_AT = setmetatable({}, { __mode = "k" })
    OBSERVATION_BY_ZOMBIE = setmetatable({}, { __mode = "k" })
    if Mirror and Mirror.Reset then Mirror.Reset() end
    if Mirror and Mirror.Attach then Mirror.Attach() end
end

if Events and isClient and isClient() == true then
    if Events.OnZombieUpdate then
        if Sync.ClientZombieStimulusHandler then
            Events.OnZombieUpdate.Remove(
                Sync.ClientZombieStimulusHandler
            )
        end
        Sync.ClientZombieStimulusHandler =
            Internal.OnClientZombieStimulusUpdate
        Events.OnZombieUpdate.Add(Sync.ClientZombieStimulusHandler)
    end
end

return Internal
