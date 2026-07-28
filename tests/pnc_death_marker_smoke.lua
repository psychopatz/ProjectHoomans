local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local authority = true
local directory = { records = {}, deathMarkers = {} }
local removedRecords = {}
local removalBroadcasts = {}
local deathRetirementOrder = {}

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
}

dofile(ROOT .. "Registry/PNC_DeathMarkers.lua")

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
assert(marker, "death marker was not created")
assertEqual(marker.name, "Morgan Reed", "death marker name")
assertEqual(marker.x, 11, "death marker corpse x")
assertEqual(marker.corpseToken, "corpse_dead_npc", "death marker token")
assertEqual(marker.infected, true, "death marker infection")
assertEqual(marker.colonist, true, "death marker colonist classification")
assertEqual(marker.portrait.appearance.hairModel, "Short",
    "death marker compact portrait")
assertEqual(marker.inventory, nil, "death marker retained inventory")
assertEqual(marker.equipment, nil, "death marker retained equipment")
assertEqual(marker.health, nil, "death marker retained health")
assertEqual(PNC.Registry.GetDeathMarkerRuntime(record.id).reanimateAt, 4000,
    "three-second wall-clock reanimation")

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
dofile(ROOT .. "Health/PNC_Health.lua")

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
assertEqual(retired, true, "ordinary dead NPC was not retired")
assert(normalMarker, "ordinary death marker missing")
assertEqual(normalMarker.infected, false, "ordinary death marked infected")
assertEqual(normalMarker.colonist, false, "ordinary death marked colonist")
assertEqual(removedRecords[normalRecord.id], true, "full NPC record was retained")
assertEqual(PNC.Registry.Data[normalRecord.id], nil, "retired NPC still registered")
assertEqual(removalBroadcasts[#removalBroadcasts].id, normalRecord.id,
    "retired NPC removal was not broadcast")
assertEqual(deathRetirementOrder[#deathRetirementOrder - 1], "broadcast",
    "death snapshot was broadcast after registry retirement")
assertEqual(deathRetirementOrder[#deathRetirementOrder], "remove",
    "death record was not retired after its final snapshot")

getGameTime = function()
    return { getWorldAgeHours = function() return 50 end }
end
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Corpses.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Reanimation.lua")
dofile(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAudit.lua")

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
assertEqual(reanimateCalls, 0, "infected corpse reanimated before three seconds")
assert(PNC.Registry.GetDeathMarker(marker.id), "early audit removed death marker")

now = 4000
PNC.BodyLifecycle.Internal.auditCorpseRecord(marker)
assertEqual(reanimateCalls, 1, "infected corpse did not reanimate at three seconds")
assertEqual(PNC.Registry.GetDeathMarker(marker.id), nil,
    "reanimated corpse marker was retained")
assertEqual(zombieFlags.useless, false, "reanimated zombie remained useless")
assertEqual(zombieFlags.noTeeth, false, "reanimated zombie remained toothless")
assertEqual(zombieFlags.zombiesDontAttack, false,
    "reanimated zombie retained NPC targeting safeguard")
assertEqual(zombieFlags.invincible, false,
    "reanimated zombie remained invincible")
assertEqual(zombieModData.PNC_DeathMarkerID, nil,
    "reanimated zombie retained death-marker ownership")

authority = false
assertEqual(PNC.Registry.AddDeathMarker({
    id = "client_marker",
    name = "Client Marker",
}), nil, "client created an authoritative death marker")
assertEqual(PNC.Registry.RemoveDeathMarker(normalMarker.id), false,
    "client removed an authoritative death marker")
assert(PNC.Registry.GetDeathMarker(normalMarker.id),
    "client authority guard lost an existing death marker")
authority = true

local missingRecord = {
    id = "missing_corpse",
    name = "Missing Body",
    x = 30,
    y = 40,
    z = 0,
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
assert(PNC.Registry.GetDeathMarker(missingMarker.id),
    "missing corpse marker ignored cleanup grace")
now = 10001
PNC.BodyLifecycle.Internal.auditCorpseRecord(missingMarker)
assertEqual(PNC.Registry.GetDeathMarker(missingMarker.id), nil,
    "missing loaded corpse marker was not cleared")
assertEqual(removalBroadcasts[#removalBroadcasts].reason, "corpse_collected",
    "garbage-collected corpse did not broadcast marker removal")

local collectedRecord = {
    id = "collected_corpse",
    name = "Collected Body",
    x = 50,
    y = 60,
    z = 0,
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
assertEqual(PNC.Registry.GetDeathMarker(collectedMarker.id), nil,
    "known loaded corpse marker survived corpse garbage collection")
assertEqual(removalBroadcasts[#removalBroadcasts].id, collectedMarker.id,
    "garbage-collected corpse broadcast the wrong marker removal")
assertEqual(removalBroadcasts[#removalBroadcasts].reason, "corpse_collected",
    "garbage-collected corpse removal reason")

print("pnc_death_marker_smoke: ok")
