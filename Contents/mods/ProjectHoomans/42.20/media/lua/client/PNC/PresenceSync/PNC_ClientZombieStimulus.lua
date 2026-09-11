-- Wakes locally simulated zombies for vanilla networked world sounds.
--
-- IsoZombie:RespondToSound() exits early while a zombie is marked useless.
-- Bandits explicitly re-enable that flag on their client-owned zombies. We
-- do the same only when the local WorldSoundManager reports an actual
-- zombie-attracting sound, avoiding a per-frame NPC scan and preserving the
-- vanilla owner/client movement model.

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

function Internal.GetClientZombieSoundObservation(zombie, now)
    local manager
    local query
    local ok
    local result
    local sound
    local cached
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not isLocalZombie(zombie) then return nil end
    cached = OBSERVATION_BY_ZOMBIE[zombie]
    if cached and now < (tonumber(cached.nextAt) or 0) then
        return cached.value
    end
    if not WorldSoundManager or not WorldSoundManager.instance
        or not WorldSoundManager.instance.getBiggestSoundZomb
    then
        cached = {
            nextAt = now + (tonumber(Const.ZOMBIE_NPC_STIMULUS_PROBE_MS) or 250),
            value = {
                available = false,
                found = false,
                observedAt = now,
            },
        }
        OBSERVATION_BY_ZOMBIE[zombie] = cached
        return cached.value
    end
    manager = WorldSoundManager.instance
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
    -- Build 42 returns ResultBiggestSound, whose public `sound` field is nil
    -- when no eligible sound was found. Checking only the wrapper would wake
    -- every useless zombie on the probe interval.
    sound = ok and result and result.sound or nil
    cached = {
        nextAt = now + (tonumber(Const.ZOMBIE_NPC_STIMULUS_PROBE_MS) or 250),
        value = {
            available = ok == true,
            found = sound ~= nil,
            observedAt = now,
            attract = result and tonumber(result.attract) or nil,
            x = sound and tonumber(sound.x) or nil,
            y = sound and tonumber(sound.y) or nil,
            z = sound and tonumber(sound.z) or nil,
            radius = sound and tonumber(sound.radius) or nil,
            volume = sound and tonumber(sound.volume) or nil,
            sourceIsZombie = sound and sound.sourceIsZombie == true or false,
            sourceIsPlayer = sound and sound.sourceIsPlayer == true or false,
        },
    }
    OBSERVATION_BY_ZOMBIE[zombie] = cached
    increment("ZombieAggro.StimulusSoundProbes")
    return cached.value
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
end

if Events and Events.OnZombieUpdate
    and isClient and isClient() == true
then
    if Sync.ClientZombieStimulusHandler then
        Events.OnZombieUpdate.Remove(
            Sync.ClientZombieStimulusHandler
        )
    end
    Sync.ClientZombieStimulusHandler =
        Internal.OnClientZombieStimulusUpdate
    Events.OnZombieUpdate.Add(Sync.ClientZombieStimulusHandler)
end

return Internal
