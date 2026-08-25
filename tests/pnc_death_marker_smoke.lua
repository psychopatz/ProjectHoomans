local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local now = 1000
local authority = true
local directory = { records = {}, deathMarkers = {} }
local removedRecords = {}
local removalBroadcasts = {}
local deathRetirementOrder = {}
local releasedWorker

local function recordRemovalBroadcast(id, reason)
    deathRetirementOrder[#deathRetirementOrder + 1] = "broadcast"
    removalBroadcasts[#removalBroadcasts + 1] = {
        id = tostring(id),
        reason = tostring(reason),
    }
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return authority end,
        GenerateID = function(prefix) return tostring(prefix) .. "_token" end,
        LogWarn = function() end,
    },
    Const = {
        BODY_TAG_VERSION = 1,
        PRESENCE_CORPSE = "corpse",
        PRESENCE_ABSTRACT = "abstract",
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEFAULT_HP_MAX = 100,
        DEATH_MARKER_MISSING_GRACE_MS = 5000,
        CORPSE_REANIMATE_RETRY_MS = 2000,
    },
    Sandbox = {
        NPCReanimationSeconds = function() return 3 end,
    },
    Identity = {
        BuildPortraitSummary = function(record)
            return record and record.portrait or nil
        end,
        NormalizePortraitSummary = function(source)
            return source
        end,
    },
    Registry = {
        Data = {},
        LiveByID = {},
        GetStorageDirectory = function() return directory end,
        RemoveRecord = function(id)
            id = tostring(id)
            deathRetirementOrder[#deathRetirementOrder + 1] = "remove"
            removedRecords[id] = true
            PNC.Registry.Data[id] = nil
        end,
        MarkDirty = function() end,
    },
    Network = {
        BroadcastRemoval = recordRemovalBroadcast,
        BroadcastDeathMarkerRemoval = recordRemovalBroadcast,
    },
    BodyLifecycle = { Internal = {} },
    WorkService = { Commands = {
        ReleaseWorker = function(id, reason)
            releasedWorker = { id = id, reason = reason }
            deathRetirementOrder[#deathRetirementOrder + 1] = "release_work"
            return true
        end,
    } },
}

T.load(ROOT .. "Registry/PNC_DeathMarkers.lua")

local record = {
    id = "dead_npc",
    name = "Morgan Reed",
    x = 10,
    y = 20,
    z = 0,
    alive = false,
    recruited = true,
    faction = "colonist",
    portrait = {
        identitySeed = 12,
        faceOnly = true,
        appearance = { hairModel = "Short" },
        equipment = { worn = { Hat = "Base.Hat_HardHat" } },
    },
    runtime = {},
    inventory = { deliberately = "large" },
    equipment = { deliberately = "large" },
    corpse = {
        token = "corpse_dead_npc",
        x = 11,
        y = 21,
        z = 0,
        createdWorldHour = 50,
    },
    health = {
        body = {
            infection = { fatal = true },
        },
    },
}
PNC.Registry.Data[record.id] = record
local marker = PNC.Registry.AddDeathMarker(record)
T.truthy(marker, "death marker was not created")
T.equal(marker.name, "Morgan Reed", "death marker name")
T.equal(marker.x, 11, "death marker corpse x")
T.equal(marker.corpseToken, "corpse_dead_npc", "death marker token")
T.equal(marker.infected, true, "death marker infection")
T.equal(marker.colonist, true, "death marker colonist classification")
T.equal(marker.portrait.appearance.hairModel, "Short",
    "death marker compact portrait")
T.equal(marker.inventory, nil, "death marker retained inventory")
T.equal(marker.equipment, nil, "death marker retained equipment")
T.equal(marker.health, nil, "death marker retained health")
T.equal(PNC.Registry.GetDeathMarkerRuntime(record.id).reanimateAt, 4000,
    "three-second wall-clock reanimation")

local communityRecord = {
    id = "community_dead_npc",
    name = "Community Resident",
    faction = "neutral",
    affiliation = { communityID = "community_1" },
    x = 12,
    y = 13,
    z = 0,
}
local communityMarker = PNC.Registry.AddDeathMarker(communityRecord)
T.truthy(communityMarker and communityMarker.colonyOwned == true,
    "community-owned NPC was not eligible for a death marker")

PNC.BodyLifecycle.CreateInertCorpse = function(killedRecord)
    killedRecord.corpse = killedRecord.corpse or {
        token = "health_kill_token",
        x = killedRecord.x,
        y = killedRecord.y,
        z = killedRecord.z,
        createdWorldHour = 50,
    }
    return true, {}
end
T.load(ROOT .. "Health/PNC_Health.lua")

local normalRecord = {
    id = "ordinary_dead_npc",
    name = "Taylor Wells",
    x = 4,
    y = 5,
    z = 0,
    alive = true,
    recruited = false,
    faction = "neutral",
    presenceState = "live",
    presenceRevision = 1,
    runtime = {},
    health = { current = 5, max = 100, state = "normal" },
}
PNC.Registry.Data[normalRecord.id] = normalRecord
local sourceBody = { setHealth = function() end }
local retired, normalMarker =
    PNC.Health.Kill(normalRecord, sourceBody, "weapon_damage")
T.equal(retired, true, "ordinary dead NPC was not retired")
T.equal(releasedWorker.id, normalRecord.id,
    "death did not release the active worker")
T.equal(releasedWorker.reason, "worker_died",
    "death worker release reason")
T.equal(normalMarker, nil, "ordinary death created a persistent marker")
T.equal(removedRecords[normalRecord.id], true, "full NPC record was retained")
T.equal(PNC.Registry.Data[normalRecord.id], nil, "retired NPC still registered")
T.equal(removalBroadcasts[#removalBroadcasts].id, normalRecord.id,
    "retired NPC removal was not broadcast")
T.equal(removalBroadcasts[#removalBroadcasts].reason, "death_untracked",
    "unowned death used the persistent death-marker event")
T.equal(deathRetirementOrder[#deathRetirementOrder - 1], "broadcast",
    "death snapshot was broadcast after registry retirement")
T.equal(deathRetirementOrder[#deathRetirementOrder], "remove",
    "death record was not retired after its final snapshot")

getGameTime = function()
    return { getWorldAgeHours = function() return 50 end }
end
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Corpses.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Reanimation.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAudit.lua")

local zombieFlags = {}
local zombieModData = {
    PNC_DeathMarkerID = marker.id,
    PNC_DeathName = marker.name,
}
local reanimatedZombie = {
    getModData = function() return zombieModData end,
    clearVariable = function() end,
    setUseless = function(_, value) zombieFlags.useless = value end,
    setNoTeeth = function(_, value) zombieFlags.noTeeth = value end,
    setZombiesDontAttack = function(_, value) zombieFlags.zombiesDontAttack = value end,
    setInvincible = function(_, value) zombieFlags.invincible = value end,
}
local reanimateCalls = 0
local corpseModData = {
    PNC_DeathMarkerID = marker.id,
    PNC_DeathName = marker.name,
    PNC_CorpseToken = marker.corpseToken,
}
local corpse = {
    getModData = function() return corpseModData end,
    getX = function() return marker.x end,
    getY = function() return marker.y end,
    getZ = function() return marker.z end,
    reanimate = function()
        reanimateCalls = reanimateCalls + 1
        return reanimatedZombie
    end,
}
local corpseList = {
    size = function() return 1 end,
    get = function() return corpse end,
}
local square = {
    getDeadBodys = function() return corpseList end,
    getStaticMovingObjects = function() return nil end,
}
getCell = function()
    return { getGridSquare = function() return square end }
end

now = 3999
PNC.BodyLifecycle.Internal.auditCorpseRecord(marker)
T.equal(reanimateCalls, 0, "infected corpse reanimated before three seconds")
T.truthy(PNC.Registry.GetDeathMarker(marker.id), "early audit removed death marker")

now = 4000
PNC.BodyLifecycle.Internal.auditCorpseRecord(marker)
T.equal(reanimateCalls, 1, "infected corpse did not reanimate at three seconds")
T.equal(PNC.Registry.GetDeathMarker(marker.id), nil,
    "reanimated corpse marker was retained")
T.equal(zombieFlags.useless, false, "reanimated zombie remained useless")
T.equal(zombieFlags.noTeeth, false, "reanimated zombie remained toothless")
T.equal(zombieFlags.zombiesDontAttack, false,
    "reanimated zombie retained NPC targeting safeguard")
T.equal(zombieFlags.invincible, false,
    "reanimated zombie remained invincible")
T.equal(zombieModData.PNC_DeathMarkerID, nil,
    "reanimated zombie retained death-marker ownership")

local authorityMarker = PNC.Registry.AddDeathMarker({
    id = "authority_marker",
    name = "Authority Marker",
    recruited = true,
    x = 7,
    y = 8,
    z = 0,
})
T.truthy(authorityMarker, "authority guard fixture marker was not created")
authority = false
T.equal(PNC.Registry.AddDeathMarker({
    id = "client_marker",
    name = "Client Marker",
}), nil, "client created an authoritative death marker")
T.equal(PNC.Registry.RemoveDeathMarker(authorityMarker.id), false,
    "client removed an authoritative death marker")
T.truthy(PNC.Registry.GetDeathMarker(authorityMarker.id),
    "client authority guard lost an existing death marker")
authority = true

local missingRecord = {
    id = "missing_corpse",
    name = "Missing Body",
    x = 30,
    y = 40,
    z = 0,
    recruited = true,
    corpse = {
        token = "missing_token",
        x = 30,
        y = 40,
        z = 0,
        createdWorldHour = 50,
    },
    health = { body = { infection = { fatal = false } } },
}
local missingMarker = PNC.Registry.AddDeathMarker(missingRecord)
local emptyList = { size = function() return 0 end }
local emptySquare = {
    getDeadBodys = function() return emptyList end,
    getStaticMovingObjects = function() return nil end,
}
getCell = function()
    return { getGridSquare = function() return emptySquare end }
end
now = 5000
PNC.BodyLifecycle.Internal.auditCorpseRecord(missingMarker)
T.truthy(PNC.Registry.GetDeathMarker(missingMarker.id),
    "missing corpse marker ignored cleanup grace")
now = 10001
PNC.BodyLifecycle.Internal.auditCorpseRecord(missingMarker)
T.equal(PNC.Registry.GetDeathMarker(missingMarker.id), nil,
    "missing loaded corpse marker was not cleared")
T.equal(removalBroadcasts[#removalBroadcasts].reason, "corpse_collected",
    "garbage-collected corpse did not broadcast marker removal")

local collectedRecord = {
    id = "collected_corpse",
    name = "Collected Body",
    x = 50,
    y = 60,
    z = 0,
    recruited = true,
    corpse = {
        token = "collected_token",
        x = 50,
        y = 60,
        z = 0,
        createdWorldHour = 50,
    },
    health = { body = { infection = { fatal = false } } },
}
local collectedMarker = PNC.Registry.AddDeathMarker(collectedRecord)
PNC.Registry.GetDeathMarkerRuntime(collectedMarker.id).corpseState =
    "inert_loaded"
now = 11000
PNC.BodyLifecycle.Internal.auditCorpseRecord(collectedMarker)
T.equal(PNC.Registry.GetDeathMarker(collectedMarker.id), nil,
    "known loaded corpse marker survived corpse garbage collection")
T.equal(removalBroadcasts[#removalBroadcasts].id, collectedMarker.id,
    "garbage-collected corpse broadcast the wrong marker removal")
T.equal(removalBroadcasts[#removalBroadcasts].reason, "corpse_collected",
    "garbage-collected corpse removal reason")

directory.deathMarkers = {
    retained_colony = {
        id = "retained_colony",
        name = "Retained Colony NPC",
        colonist = true,
        x = 1, y = 2, z = 0,
    },
    legacy_world_npc = {
        id = "legacy_world_npc",
        name = "Legacy World NPC",
        colonist = false,
        x = 3, y = 4, z = 0,
    },
}
PNC.Registry.DirectoryDirty = false
local loadedMarkers = PNC.Registry.LoadDeathMarkers(directory)
T.truthy(loadedMarkers.retained_colony ~= nil,
    "colony death marker was discarded during load cleanup")
T.equal(loadedMarkers.legacy_world_npc, nil,
    "legacy unowned death marker survived load cleanup")
T.equal(PNC.Registry.DirectoryDirty, true,
    "death-marker cleanup was not scheduled for persistence")
T.finish("pnc_death_marker_smoke")

T.finish("pnc_death_marker_smoke")
