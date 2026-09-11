-- Multiplayer NPC attraction through the exposed vanilla world-sound path.
--
-- The server selects the eligible NPC through ZombieAggro's existing nearest
-- target logic. This module only creates the movement stimulus. Vanilla
-- WorldSoundPacket replication then delivers it to the clients that can
-- simulate the affected area, and the owning client runs RespondToSound().

PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Settings = PNC.Sandbox
local Stealth = PNC.Stealth

local Stimulus = ZombieAggro.Stimulus or {}
ZombieAggro.Stimulus = Stimulus
Stimulus.NextEmitAtByNPC = Stimulus.NextEmitAtByNPC or {}
Stimulus.Sequence = tonumber(Stimulus.Sequence) or 0

local function isMultiplayerServer()
    return isServer and isServer() == true or false
end

local function increment(name, amount)
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment(name, amount)
    end
end

local function copyPosition(body)
    if not body then return nil end
    return {
        x = math.floor(tonumber(body:getX()) or 0),
        y = math.floor(tonumber(body:getY()) or 0),
        z = math.floor(tonumber(body:getZ()) or 0),
    }
end

local function setDebugState(record, body, state, reason, now, sound)
    local runtime
    local position
    local previous
    if not record then return end
    runtime = record.runtime or {}
    record.runtime = runtime
    position = copyPosition(body)
    previous = runtime.zombieStimulus
    Stimulus.Sequence = Stimulus.Sequence + 1
    runtime.zombieStimulus = {
        sequence = Stimulus.Sequence,
        state = tostring(state or "unknown"),
        reason = reason and tostring(reason) or nil,
        emittedAt = now,
        x = position and position.x or previous and previous.x or record.x,
        y = position and position.y or previous and previous.y or record.y,
        z = position and position.z or previous and previous.z or record.z,
        radius = sound and tonumber(sound.radius) or previous and previous.radius or nil,
        volume = sound and tonumber(sound.volume) or previous and previous.volume or nil,
    }
end

local function isEligible(record, body, now)
    if not record or not body
        or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or (body.isDead and body:isDead())
    then
        return false
    end
    if Settings and Settings.CanZombieTargetRecord
        and not Settings.CanZombieTargetRecord(record, now)
    then
        return false
    end
    if Stealth and Stealth.ShouldSuppressZombieAggro
        and Stealth.ShouldSuppressZombieAggro(record)
    then
        increment("ZombieAggro.StimulusSuppressedStealth")
        return false
    end
    return true
end

function Stimulus.Emit(record, body, now)
    local id
    local nextAt
    local manager
    local x
    local y
    local z
    local radius
    local volume
    local ok
    local sound
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not isMultiplayerServer() or not isEligible(record, body, now) then
        return false
    end
    id = record.id and tostring(record.id) or nil
    if not id then
        return false
    end
    nextAt = tonumber(Stimulus.NextEmitAtByNPC[id]) or 0
    if now < nextAt then
        return false
    end
    if not WorldSoundManager or not WorldSoundManager.instance
        or not WorldSoundManager.instance.addSound
    then
        increment("ZombieAggro.StimulusUnavailable")
        Stimulus.NextEmitAtByNPC[id] = now + 1000
        setDebugState(record, body, "unavailable", "world_sound_manager", now)
        return false
    end
    x = math.floor(tonumber(body:getX()) or 0)
    y = math.floor(tonumber(body:getY()) or 0)
    z = math.floor(tonumber(body:getZ()) or 0)
    radius = math.max(
        1,
        math.floor(tonumber(Const.ZOMBIE_NPC_STIMULUS_RADIUS) or 14)
    )
    volume = math.max(
        1,
        math.floor(tonumber(Const.ZOMBIE_NPC_STIMULUS_VOLUME) or 8)
    )
    manager = WorldSoundManager.instance
    -- Use a nil source. An IsoZombie NPC shell is marked sourceIsZombie by
    -- the engine, and vanilla zombie hearing intentionally ignores those
    -- sounds. This overload is the public AI-only, networked sound route.
    ok, sound = pcall(
        manager.addSound,
        manager,
        nil,
        x,
        y,
        z,
        radius,
        volume
    )
    Stimulus.NextEmitAtByNPC[id] = now
        + (tonumber(Const.ZOMBIE_NPC_STIMULUS_INTERVAL_MS) or 500)
    if not ok or not sound then
        increment("ZombieAggro.StimulusUnavailable")
        setDebugState(
            record,
            body,
            "unavailable",
            ok and "add_sound_returned_nil" or "add_sound_error",
            now
        )
        return false
    end
    setDebugState(record, body, "emitted", "npc_world_sound", now, sound)
    increment("ZombieAggro.StimulusEmitted")
    return true
end

function Stimulus.Mark(record, body, state, reason, now)
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    setDebugState(record, body, state, reason, now)
end

function Stimulus.Reset()
    Stimulus.NextEmitAtByNPC = {}
    Stimulus.Sequence = 0
end

return Stimulus
