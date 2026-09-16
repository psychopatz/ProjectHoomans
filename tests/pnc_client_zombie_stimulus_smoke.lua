local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "client",
    "PNC/PresenceSync/PNC_ClientZombieStimulus.lua"
)

local now = 1000
local queryCalls = 0

local function makeEvent()
    local handlers = {}
    return {
        Add = function(handler)
            handlers[#handlers + 1] = handler
        end,
        Remove = function(handler)
            for index = #handlers, 1, -1 do
                if handlers[index] == handler then
                    table.remove(handlers, index)
                end
            end
        end,
        Fire = function(...)
            for index = 1, #handlers do
                handlers[index](...)
            end
        end,
    }
end

local function makeZombie()
    local zombie = {
        x = 10.8,
        y = 20.2,
        z = 0,
        useless = true,
    }
    function zombie:getX() return self.x end
    function zombie:getY() return self.y end
    function zombie:getZ() return self.z end
    function zombie:isRemoteZombie() return false end
    function zombie:isDead() return false end
    function zombie:isUseless() return self.useless end
    function zombie:setUseless(value) self.useless = value end
    return zombie
end

PNC = {
    ClientPresenceSync = { Internal = {} },
    Const = { ZOMBIE_NPC_STIMULUS_PROBE_MS = 250 },
    Core = { Now = function() return now end },
    PerformanceScalingDiagnostics = { Increment = function() end },
}

Events = {
    OnWorldSound = makeEvent(),
    OnZombieUpdate = makeEvent(),
    OnResetLua = makeEvent(),
}

WorldSoundManager = {
    instance = {
        getHearingMultiplier = function() return 1 end,
        getBiggestSoundZomb = function()
            queryCalls = queryCalls + 1
            return io.tmpfile()
        end,
    },
}

isClient = function() return true end
T.load(FILE)

-- OnWorldSound carries primitive data for both local sounds and sounds
-- reconstructed from a multiplayer WorldSoundPacket. The probe must use it
-- instead of indexing Build 42's opaque ResultBiggestSound userdata.
Events.OnWorldSound.Fire(10, 20, 0, 72, 1, nil)
local zombie = makeZombie()
local observation = PNC.ClientPresenceSync.Internal
    .GetClientZombieSoundObservation(zombie, now)
T.truthy(observation.available, "world-sound mirror was unavailable")
T.truthy(observation.found, "world-sound mirror missed the sound")
T.equal(observation.x, 10, "world-sound mirror stored the wrong X")
T.equal(queryCalls, 0, "event-backed probe called the opaque-result API")
T.truthy(
    PNC.ClientPresenceSync.Internal.OnClientZombieStimulusUpdate(zombie),
    "sound did not reactivate the useless zombie"
)
T.falsy(zombie.useless, "sound probe left the zombie useless")

-- Compatibility fallback: a Java ResultBiggestSound is userdata, not a Lua
-- table. It must be treated as unavailable without attempting result.sound.
now = 2000
Events = {
    OnZombieUpdate = makeEvent(),
    OnResetLua = makeEvent(),
}
T.load(FILE)
local fallbackZombie = makeZombie()
local fallbackObservation = PNC.ClientPresenceSync.Internal
    .GetClientZombieSoundObservation(fallbackZombie, now)
T.falsy(
    fallbackObservation.available,
    "opaque Java result was reported as a readable Lua result"
)
T.falsy(
    fallbackObservation.found,
    "opaque Java result falsely reactivated a zombie"
)
T.equal(queryCalls, 1, "opaque-result compatibility fallback was skipped")

T.finish("pnc_client_zombie_stimulus_smoke")
