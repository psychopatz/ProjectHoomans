local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_Stimulus.lua"
)

local calls = {}
local now = 1000
local body = {
    getX = function() return 10.8 end,
    getY = function() return 20.2 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}
local record = {
    id = "npc-1",
    alive = true,
    presenceState = "live",
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_NPC_STIMULUS_INTERVAL_MS = 500,
        ZOMBIE_NPC_STIMULUS_RADIUS = 72,
        ZOMBIE_NPC_STIMULUS_VOLUME = 1,
    },
    Core = {
        Now = function() return now end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Stealth = {},
    PerformanceScalingDiagnostics = {
        Increment = function() end,
    },
    ZombieAggro = {},
}

WorldSoundManager = {
    instance = {
        addSound = function(
            _, source, x, y, z, radius, volume,
            stressHumans, zombieIgnoreDist, stressMod,
            sourceIsZombie, doSend, remote
        )
            calls[#calls + 1] = {
                source = source,
                x = x,
                y = y,
                z = z,
                radius = radius,
                volume = volume,
                stressHumans = stressHumans,
                zombieIgnoreDist = zombieIgnoreDist,
                stressMod = stressMod,
                sourceIsZombie = sourceIsZombie,
                doSend = doSend,
                remote = remote,
            }
            return {
                radius = radius,
                volume = volume,
                sourceIsZombie = sourceIsZombie,
            }
        end,
    },
}

isServer = function() return true end
isClient = function() return false end
T.load(FILE)

T.truthy(
    PNC.ZombieAggro.Stimulus.Emit(record, body, now),
    "MP stimulus did not emit"
)
T.equal(#calls, 1, "MP stimulus emitted an unexpected number of sounds")
T.equal(calls[1].source, nil, "MP stimulus used an NPC shell source")
T.equal(calls[1].x, 10, "MP stimulus X was not grid-snapped")
T.equal(calls[1].y, 20, "MP stimulus Y was not grid-snapped")
T.equal(calls[1].radius, 72, "MP stimulus radius was wrong")
T.equal(calls[1].volume, 1, "MP stimulus volume was wrong")
T.equal(calls[1].stressHumans, false, "MP stimulus stressed humans")
T.equal(calls[1].zombieIgnoreDist, 0,
    "MP stimulus changed zombie ignore distance")
T.equal(calls[1].stressMod, 1, "MP stimulus changed stress modifier")
T.equal(calls[1].sourceIsZombie, false,
    "MP stimulus was marked as a zombie source")
T.equal(calls[1].doSend, true,
    "MP stimulus did not request WorldSoundPacket replication")
T.equal(calls[1].remote, false,
    "MP stimulus was incorrectly marked as remote")

isServer = function() return false end
isClient = function() return false end
now = 2000
PNC.ZombieAggro.Stimulus.Reset()
T.truthy(
    PNC.ZombieAggro.Stimulus.Emit(record, body, now),
    "SP stimulus did not emit"
)
T.equal(#calls, 2, "SP stimulus emitted an unexpected number of sounds")
T.equal(calls[2].doSend, false,
    "SP stimulus attempted multiplayer packet replication")
T.equal(calls[2].sourceIsZombie, false,
    "SP stimulus was marked as a zombie source")

-- PathFindState already owns Behavior2:update(). The aggro path helper must
-- refresh that location goal directly instead of calling IsoZombie's guarded
-- wrapper, while idle zombies still use the wrapper to establish locomotion.
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_Update.lua"
)
local directCalls = 0
local wrapperCalls = 0
local actionState = "pathfind"
local behavior = {
    pathToLocationF = function(_, x, y, z)
        T.truthy(x == 1 and y == 2 and z == 0,
            "Behavior2 received the wrong coordinate goal")
        directCalls = directCalls + 1
    end,
}
local pathZombie = {
    getActionStateName = function() return actionState end,
    getPathFindBehavior2 = function() return behavior end,
    pathToLocationF = function()
        wrapperCalls = wrapperCalls + 1
    end,
}
T.truthy(
    PNC.ZombieAggro.RequestCoordinatePath(pathZombie, 1, 2, 0),
    "PathFindState did not accept a coordinate goal"
)
T.equal(directCalls, 1,
    "PathFindState did not use the direct Behavior2 goal route")
T.equal(wrapperCalls, 0,
    "PathFindState used the guarded IsoZombie wrapper")

actionState = "idle"
T.truthy(
    PNC.ZombieAggro.RequestCoordinatePath(pathZombie, 1, 2, 0),
    "idle zombie did not accept a coordinate goal")
T.equal(wrapperCalls, 1,
    "idle zombie did not use the locomotion wrapper route")

isClient = function() return true end
now = 3000
PNC.ZombieAggro.Stimulus.Reset()
T.falsy(
    PNC.ZombieAggro.Stimulus.Emit(record, body, now),
    "MP client emitted an authority-only NPC stimulus"
)
T.equal(#calls, 2, "MP client changed the world-sound call count")

T.finish("pnc_zombie_aggro_stimulus_smoke")
