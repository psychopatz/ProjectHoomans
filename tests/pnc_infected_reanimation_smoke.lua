local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

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

dofile(ROOT .. "PNC_BodyLifecycle_State.lua")
dofile(ROOT .. "PNC_BodyLifecycle_World.lua")
dofile(ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")
dofile(ROOT .. "PNC_BodyLifecycle_Corpses.lua")
dofile(ROOT .. "PNC_BodyLifecycle_Reanimation.lua")
dofile(ROOT .. "PNC_BodyLifecycle_CorpseAudit.lua")

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

assert(PNC.BodyLifecycle.Internal.stampCorpse(record, corpse, "corpse_token"), "corpse stamp failed")
assert(reanimateAt > 25, "managed corpse was not kept inert for authority handoff")
assertEqual(corpseModData.PNC_NPC, nil, "corpse released from managed NPC tag")
assertEqual(corpseModData.PNC_UUID, nil, "corpse released from managed UUID")
assertEqual(corpseModData.PNC_DeathMarkerID, "infected_npc", "death marker corpse tag")

local clearedVariables = {}
local released = {}
released.getModData = function() return corpseModData end
released.clearVariable = function(_, name) clearedVariables[name] = true end
released.setUseless = function(_, value) released.useless = value end
released.setNoTeeth = function(_, value) released.noTeeth = value end
released.setZombiesDontAttack = function(_, value) released.zombiesDontAttack = value end
released.setInvincible = function(_, value) released.invincible = value end

assert(PNC.BodyLifecycle.ReleaseReanimatedNPC(record, released), "reanimated release failed")
assertEqual(corpseModData.PNC_NPC, nil, "managed NPC tag cleared")
assertEqual(corpseModData.PNC_UUID, nil, "managed UUID cleared")
assertEqual(corpseModData.PNC_ReanimatedFrom, "infected_npc", "reanimation provenance")
assertEqual(released.useless, false, "ordinary zombie AI restored")
assertEqual(released.noTeeth, false, "ordinary zombie bite restored")
assertEqual(released.zombiesDontAttack, false, "ordinary zombie is attackable")
assertEqual(released.invincible, false, "ordinary zombie is vulnerable")
assertEqual(clearedVariables.PNCLive, true, "humanized variables cleared")
assertEqual(broadcastId, "infected_npc", "client removal broadcast")
assertEqual(removedId, "infected_npc", "registry removal")

local spawnedFlags = {}
local spawnedModData = { PNC_NPC = true, PNC_UUID = "stale" }
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
    assertEqual(target, spawnCorpse, "identity card target before reanimation")
    identityEnsureCount = identityEnsureCount + 1
    spawnCorpseModData.IdentityCardReady = true
    return {}, true
end
local originalReanimate = spawnCorpse.reanimate
spawnCorpse.reanimate = function(self)
    assertEqual(spawnCorpseModData.IdentityCardReady, true,
        "identity card ensured before reanimation")
    return originalReanimate(self)
end
PNC.BodyLifecycle.Internal.auditCorpseRecord(spawnRecord)
assertEqual(identityEnsureCount, 1, "infected corpse identity ensure count")
assertEqual(spawnCalls, 0, "fallback used despite vanilla corpse reanimation")
assertEqual(corpseReanimateCalls, 1, "vanilla corpse reanimation count")
assertEqual(corpseRemoved, true, "vanilla reanimation consumed corpse")
assertEqual(spawnedFlags.useless, false, "spawned zombie AI enabled")
assertEqual(spawnedFlags.noTeeth, false, "spawned zombie teeth enabled")
assertEqual(spawnedFlags.zombiesDontAttack, false, "spawned zombie is attackable")
assertEqual(spawnedFlags.invincible, false, "spawned zombie vulnerability enabled")
assertEqual(spawnedFlags.canWalk, nil, "vanilla locomotion state was overwritten")
assertEqual(spawnedFlags.crawler, nil, "vanilla crawler state was overwritten")
assertEqual(spawnedFlags.onFloor, nil, "vanilla reanimation pose was overwritten")
assertEqual(spawnedFlags.health, nil, "vanilla toughness health was overwritten")
assertEqual(spawnedModData.PNC_NPC, nil, "spawned zombie managed tag cleared")
assertEqual(spawnedModData.PNC_UUID, nil, "spawned zombie managed UUID cleared")
assertEqual(spawnedModData.PNC_ReanimatedFrom, "spawn_infected_npc",
    "spawned zombie provenance")
assertEqual(broadcastId, "spawn_infected_npc", "spawned NPC client removal")
assertEqual(removedId, "spawn_infected_npc", "spawned NPC registry removal")

local spawnedAgain, duplicateReason =
    PNC.BodyLifecycle.SpawnReanimatedZombie(spawnRecord, spawnCorpse)
assertEqual(spawnedAgain, false, "duplicate zombie spawn")
assertEqual(duplicateReason, "already_spawned", "duplicate spawn guard")
assertEqual(spawnCalls, 0, "reanimated zombie fallback unexpectedly ran")
assertEqual(corpseReanimateCalls, 1, "duplicate vanilla corpse reanimation")

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
assertEqual(fallbackSpawned, true, "authority fallback spawn failed")
assertEqual(spawnCalls, 1, "authority fallback spawn count")
assertEqual(spawnArgs[1], 4, "fallback spawn x")
assertEqual(spawnArgs[2], 5, "fallback spawn y")
assertEqual(spawnArgs[4], 1, "single fallback zombie")
assertEqual(spawnArgs[5], "Survivalist", "fallback outfit")
assertEqual(spawnArgs[6], 100, "fallback sex")
assertEqual(spawnArgs[11], false, "fallback zombie is not invulnerable")
assertEqual(spawnedFlags.stats, true, "fallback vanilla stats initialized")

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
assertEqual(clientSpawned, false, "client created a reanimated zombie")
assertEqual(clientReason, "not_authority_or_missing", "client authority guard")
assertEqual(spawnCalls, 1, "client invoked vanilla zombie spawn API")
assertEqual(corpseReanimateCalls, 1, "client invoked vanilla corpse reanimation")

print("pnc_infected_reanimation_smoke: ok")
