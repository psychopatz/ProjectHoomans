local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Presence/PNC_BodyLifecycle/")

local removedId
local broadcastId
local authority = true
PNC = {
    Core = {
        Now = function() return 1000 end,
        GenerateID = function() return "token" end,
        IsAuthority = function() return authority end,
        LogWarn = function() end,
    },
    Const = {
        BODY_TAG_VERSION = 1,
        PRESENCE_CORPSE = "corpse",
    },
    Registry = {
        MarkDirty = function() end,
        RemoveRecord = function(id) removedId = id end,
    },
    Network = {
        BroadcastRemoval = function(id) broadcastId = id end,
    },
    BodyLifecycle = { Internal = {} },
    VisualProfiles = {
        ResolveSpawnOutfit = function() return "Survivalist" end,
    },
}

getGameTime = function()
    return { getWorldAgeHours = function() return 25 end }
end

T.load(ROOT .. "PNC_BodyLifecycle_State.lua")
T.load(ROOT .. "PNC_BodyLifecycle_World.lua")
T.load(ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")
T.load(ROOT .. "PNC_BodyLifecycle_Corpses.lua")
T.load(ROOT .. "PNC_BodyLifecycle_Reanimation.lua")
T.load(ROOT .. "PNC_BodyLifecycle_CorpseAudit.lua")

local reanimateAt
local corpseModData = {}
local corpse = {
    getModData = function() return corpseModData end,
    getX = function() return 1 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
    setFakeDead = function() end,
    setReanimateTime = function(_, value) reanimateAt = value end,
}
local record = {
    id = "infected_npc",
    alive = false,
    presenceState = "corpse",
    x = 1, y = 2, z = 0,
    runtime = {},
    corpse = { token = "corpse_token", createdWorldHour = 20 },
    health = {
        body = {
            infection = { fatal = true, reanimateAtWorldHour = 25 },
        },
    },
}

T.truthy(PNC.BodyLifecycle.Internal.stampCorpse(record, corpse, "corpse_token"), "corpse stamp failed")
T.truthy(reanimateAt > 25, "managed corpse was not kept inert for authority handoff")
T.equal(corpseModData.PNC_NPC, nil, "corpse released from managed NPC tag")
T.equal(corpseModData.PNC_UUID, nil, "corpse released from managed UUID")
T.equal(corpseModData.PNC_DeathMarkerID, "infected_npc", "death marker corpse tag")

local clearedVariables = {}
local released = {}
released.getModData = function() return corpseModData end
released.clearVariable = function(_, name) clearedVariables[name] = true end
released.setUseless = function(_, value) released.useless = value end
released.setNoTeeth = function(_, value) released.noTeeth = value end
released.setZombiesDontAttack = function(_, value) released.zombiesDontAttack = value end
released.setInvincible = function(_, value) released.invincible = value end

T.truthy(PNC.BodyLifecycle.ReleaseReanimatedNPC(record, released), "reanimated release failed")
T.equal(corpseModData.PNC_NPC, nil, "managed NPC tag cleared")
T.equal(corpseModData.PNC_UUID, nil, "managed UUID cleared")
T.equal(corpseModData.PNC_ReanimatedFrom, "infected_npc", "reanimation provenance")
T.equal(released.useless, false, "ordinary zombie AI restored")
T.equal(released.noTeeth, false, "ordinary zombie bite restored")
T.equal(released.zombiesDontAttack, false, "ordinary zombie is attackable")
T.equal(released.invincible, false, "ordinary zombie is vulnerable")
T.equal(clearedVariables.PNCLive, true, "humanized variables cleared")
T.equal(broadcastId, "infected_npc", "client removal broadcast")
T.equal(removedId, "infected_npc", "registry removal")

local spawnedFlags = {}
local spawnedModData = {
    PNC_NPC = true,
    PNC_UUID = "stale",
    PNC_PersistedShell = true,
    PNC_ShellVersion = 1,
    PNC_BaseOutfit = "Naked",
}
local spawnedZombie = {
    getModData = function() return spawnedModData end,
    clearVariable = function(_, name) spawnedFlags["cleared_" .. name] = true end,
    setUseless = function(_, value) spawnedFlags.useless = value end,
    setNoTeeth = function(_, value) spawnedFlags.noTeeth = value end,
    setZombiesDontAttack = function(_, value) spawnedFlags.zombiesDontAttack = value end,
    setInvincible = function(_, value) spawnedFlags.invincible = value end,
    setCanWalk = function(_, value) spawnedFlags.canWalk = value end,
    setCrawler = function(_, value) spawnedFlags.crawler = value end,
    setOnFloor = function(_, value) spawnedFlags.onFloor = value end,
    setHealth = function(_, value) spawnedFlags.health = value end,
    DoZombieStats = function() spawnedFlags.stats = true end,
}
local spawnArgs
local spawnCalls = 0
addZombiesInOutfit = function(...)
    spawnCalls = spawnCalls + 1
    spawnArgs = { ... }
    return {
        size = function() return 1 end,
        get = function() return spawnedZombie end,
    }
end

local corpseRemoved = false
local corpseReanimateCalls = 0
local spawnCorpseModData = {
    PNC_NPC = true,
    PNC_UUID = "spawn_infected_npc",
    PNC_BodyKind = "corpse",
    PNC_CorpseToken = "spawn_token",
}
local square
local spawnCorpse = {
    getModData = function() return spawnCorpseModData end,
    getX = function() return 4 end,
    getY = function() return 5 end,
    getZ = function() return 0 end,
    getSquare = function() return square end,
    setFakeDead = function() end,
    setReanimateTime = function() end,
    reanimate = function()
        corpseReanimateCalls = corpseReanimateCalls + 1
        corpseRemoved = true
        return spawnedZombie
    end,
    removeFromWorld = function() corpseRemoved = true end,
    removeFromSquare = function() corpseRemoved = true end,
    setSquare = function() end,
}
local corpseList = {
    size = function() return 1 end,
    get = function() return spawnCorpse end,
}
square = {
    getDeadBodys = function() return corpseList end,
    getStaticMovingObjects = function() return nil end,
    transmitRemoveItemFromSquare = function() corpseRemoved = true end,
}
getCell = function()
    return {
        getGridSquare = function() return square end,
    }
end
local spawnRecord = {
    id = "spawn_infected_npc",
    alive = false,
    isFemale = true,
    x = 4, y = 5, z = 0,
    runtime = {},
    corpse = {
        token = "spawn_token",
        x = 4, y = 5, z = 0,
        createdWorldHour = 20,
    },
    health = {
        body = {
            infection = {
                fatal = true,
                reanimateAtWorldHour = 25,
            },
        },
    },
}

removedId = nil
broadcastId = nil
local identityEnsureCount = 0
PNC.BodyLifecycle.Internal.ensureCorpseIdentityCard = function(_, target)
    T.equal(target, spawnCorpse, "identity card target before reanimation")
    identityEnsureCount = identityEnsureCount + 1
    spawnCorpseModData.IdentityCardReady = true
    return {}, true
end
local originalReanimate = spawnCorpse.reanimate
spawnCorpse.reanimate = function(self)
    T.equal(spawnCorpseModData.IdentityCardReady, true,
        "identity card ensured before reanimation")
    return originalReanimate(self)
end
PNC.BodyLifecycle.Internal.auditCorpseRecord(spawnRecord)
T.equal(identityEnsureCount, 1, "infected corpse identity ensure count")
T.equal(spawnCalls, 0, "fallback used despite vanilla corpse reanimation")
T.equal(corpseReanimateCalls, 1, "vanilla corpse reanimation count")
T.equal(corpseRemoved, true, "vanilla reanimation consumed corpse")
T.equal(spawnedFlags.useless, false, "spawned zombie AI enabled")
T.equal(spawnedFlags.noTeeth, false, "spawned zombie teeth enabled")
T.equal(spawnedFlags.zombiesDontAttack, false, "spawned zombie is attackable")
T.equal(spawnedFlags.invincible, false, "spawned zombie vulnerability enabled")
T.equal(spawnedFlags.canWalk, nil, "vanilla locomotion state was overwritten")
T.equal(spawnedFlags.crawler, nil, "vanilla crawler state was overwritten")
T.equal(spawnedFlags.onFloor, nil, "vanilla reanimation pose was overwritten")
T.equal(spawnedFlags.health, nil, "vanilla toughness health was overwritten")
T.equal(spawnedModData.PNC_NPC, nil, "spawned zombie managed tag cleared")
T.equal(spawnedModData.PNC_UUID, nil, "spawned zombie managed UUID cleared")
T.equal(spawnedModData.PNC_PersistedShell, nil,
    "spawned zombie persisted-shell marker cleared")
T.equal(spawnedModData.PNC_ShellVersion, nil,
    "spawned zombie shell version cleared")
T.equal(spawnedModData.PNC_BaseOutfit, nil,
    "spawned zombie shell outfit marker cleared")
T.equal(spawnedModData.PNC_ReanimatedFrom, "spawn_infected_npc",
    "spawned zombie provenance")
T.equal(broadcastId, "spawn_infected_npc", "spawned NPC client removal")
T.equal(removedId, "spawn_infected_npc", "spawned NPC registry removal")

local spawnedAgain, duplicateReason =
    PNC.BodyLifecycle.SpawnReanimatedZombie(spawnRecord, spawnCorpse)
T.equal(spawnedAgain, false, "duplicate zombie spawn")
T.equal(duplicateReason, "already_spawned", "duplicate spawn guard")
T.equal(spawnCalls, 0, "reanimated zombie fallback unexpectedly ran")
T.equal(corpseReanimateCalls, 1, "duplicate vanilla corpse reanimation")

local fallbackRecord = {
    id = "fallback_infected_npc",
    alive = false,
    isFemale = true,
    x = 4, y = 5, z = 0,
    runtime = {},
    health = {
        body = {
            infection = { fatal = true, reanimateAtWorldHour = 25 },
        },
    },
}
local fallbackCorpse = {
    getX = function() return 4 end,
    getY = function() return 5 end,
    getZ = function() return 0 end,
    getSquare = function() return square end,
    removeFromWorld = function() corpseRemoved = true end,
    removeFromSquare = function() corpseRemoved = true end,
    setSquare = function() end,
}
local fallbackSpawned =
    PNC.BodyLifecycle.SpawnReanimatedZombie(fallbackRecord, fallbackCorpse)
T.equal(fallbackSpawned, true, "authority fallback spawn failed")
T.equal(spawnCalls, 1, "authority fallback spawn count")
T.equal(spawnArgs[1], 4, "fallback spawn x")
T.equal(spawnArgs[2], 5, "fallback spawn y")
T.equal(spawnArgs[4], 1, "single fallback zombie")
T.equal(spawnArgs[5], "Survivalist", "fallback outfit")
T.equal(spawnArgs[6], 100, "fallback sex")
T.equal(spawnArgs[11], false, "fallback zombie is not invulnerable")
T.equal(spawnedFlags.stats, true, "fallback vanilla stats initialized")

authority = false
local clientSpawned, clientReason =
    PNC.BodyLifecycle.SpawnReanimatedZombie({
        id = "client_must_not_spawn",
        alive = false,
        runtime = {},
        health = {
            body = {
                infection = { fatal = true, reanimateAtWorldHour = 25 },
            },
        },
    }, spawnCorpse)
T.equal(clientSpawned, false, "client created a reanimated zombie")
T.equal(clientReason, "not_authority_or_missing", "client authority guard")
T.equal(spawnCalls, 1, "client invoked vanilla zombie spawn API")
T.equal(corpseReanimateCalls, 1, "client invoked vanilla corpse reanimation")
T.finish("pnc_infected_reanimation_smoke")

T.finish("pnc_infected_reanimation_smoke")
