local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 1000
local worldHours = 100
local modDataStore = {}
local emittedEvents = {}
local removedRecordIDs = {}
local networkRemovals = {}

ModData = {
    get = function(key) return modDataStore[key] end,
    getOrCreate = function(key)
        modDataStore[key] = modDataStore[key] or {}
        return modDataStore[key]
    end,
    remove = function(key) modDataStore[key] = nil end,
    transmit = function() end,
}

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = { Add = function() end },
    OnServerStarted = { Add = function() end },
}

getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
    }
end

local directory = { records = {}, deathMarkers = {} }
local liveRecords = {}

PNC = {
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        GenerateID = function(prefix) return tostring(prefix) .. "_tok_1" end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do
                out[k] = PNC.Core.DeepCopy(val)
            end
            return out
        end,
        Log = function() end,
        LogInfo = function() end,
        LogWarn = function() end,
        LogRecordDebug = function() end,
    },
    Const = {
        PRESENCE_CORPSE = "corpse",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_LIVE = "live",
        RECENT_DAMAGE_SHOW_MS = 4000,
    },
    Presence = {
        Abstract = function(record) record.presenceState = "abstract" end,
    },
    Network = {
        BroadcastRemoval = function(id, reason)
            networkRemovals[#networkRemovals + 1] = { id = tostring(id), reason = tostring(reason) }
        end,
        BroadcastRecord = function() end,
    },
    Types = {},
    Registry = {
        Data = liveRecords,
        Get = function(id) return liveRecords[tostring(id or "")] end,
        GetStorageDirectory = function() return directory end,
        IsColonyOwnedNPC = function(record) return record and record.colonyOwned == true end,
        RemoveRecord = function(id)
            id = tostring(id)
            removedRecordIDs[#removedRecordIDs + 1] = id
            liveRecords[id] = nil
        end,
        MarkDirty = function() end,
        GetLiveZombie = function() return nil end,
    },
    BodyLifecycle = {
        CreateVanillaCorpse = function(record)
            record.corpse = {
                token = record.corpseToken,
                x = record.x or 10,
                y = record.y or 20,
                z = 0,
                createdWorldHour = worldHours,
            }
            return true, record.corpse
        end,
    },
    Tasking = {
        Events = {
            Subscribe = function() end,
            Emit = function(eventType, payload)
                emittedEvents[#emittedEvents + 1] = { type = eventType, payload = payload }
                return true
            end,
        },
    },
}

local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local GC = CoreActors.GC
local Lifecycle = CoreActors.Lifecycle
local reg = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = reg
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

require "PNC/Core/Health/PNC_Health"
require "PNC/Core/Health/PNC_Health/PNC_Health_Death"
require "PNC/Core/Registry/PNC_DeathMarkers"
require "PNC/Core/Persistence/PNC_Persistence_CoreProvider"
require "PNC/Core/Persistence/PNC_Persistence_CoreLifecycle"
require "PNC/Core/API/PNC_API/Lifecycle"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Reanimation"

-- Quest definitions + service
local testQuestDefs = {
    ["q:mortal"] = {
        id = "q:mortal",
        version = 1,
        keepAliveOnGiverDeath = false,
        objective = { id = "obj1", quantity = 1, itemFullType = "Base.Bandage", direction = "player_to_npc" },
    },
    ["q:sticky"] = {
        id = "q:sticky",
        version = 1,
        keepAliveOnGiverDeath = true,
        objective = { id = "obj2", quantity = 1, itemFullType = "Base.Bandage", direction = "player_to_npc" },
    },
}
PNC.QuestDefinitions = {
    Get = function(id) return testQuestDefs[id] end,
    List = function() return { testQuestDefs["q:mortal"], testQuestDefs["q:sticky"] } end,
}
PNC.ModDataStore = {
    Read = function(k) return ModData.get(k) end,
    Write = function(k, v) ModData.getOrCreate(k); modDataStore[k] = v end,
    Mark = function() end,
    Check = function(raw, schemaV, _, fn)
        if type(raw) ~= "table" or tonumber(raw.schemaVersion) ~= schemaV then return "missing" end
        if fn and not fn(raw) then return "invalid" end
        return nil
    end,
}
require "PNC/Quests/PNC_QuestRepository"
require "PNC/Quests/PNC_QuestService"
PNC.QuestRepository.Import({ schemaVersion = 1, nextId = 1, byKey = {} })

-- Medical care service
require "PNC/Medical/PNC_MedicalCareRepository"
require "PNC/Medical/PNC_MedicalCareService"
PNC.MedicalCareRepository.Import({ schemaVersion = 1, nextId = 1, byId = {} })

-- Player characters + NPC knowledge snapshots
local playerUUID = "char_l5player_001"
local playerObj = { characterUUID = playerUUID, accountKey = "acc_l5" }
PNC.PlayerContext = {
    Resolve = function(player)
        return { characterUUID = player and player.characterUUID or playerUUID }
    end,
}
PNC.PlayerCharacters = {
    EnsureLoaded = function() end,
    Get = function(uuid) return PNC.PlayerCharacters.Registry.byUUID[uuid] end,
    Registry = {
        byUUID = {
            [playerUUID] = { uuid = playerUUID, accountKey = "acc_l5", status = "active" },
        },
    },
}
PNC.KnowledgeDescriptors = {
    Get = function(id) return { id = id, category = "identity", valueType = "string" } end,
}
PNC.KnowledgeRegistry = {
    EnsureLoaded = function() return { records = {} } end,
    Get = function() return nil end,
    GetState = function() return { schemaVersion = 1, byPlayer = {} } end,
}
PNC.KnowledgeProviders = {}
PNC.KnowledgeResolvers = {}
PNC.KnowledgeEvidenceSources = {}
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Core"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Normalization"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Persistence"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Resolution"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_PlayerSnapshots"

-- Unique NPC Registry mock backed by PNC.UniqueNPCRegistry contract
local uniqueWorldStates = {}
PNC.UniqueNPCs = { List = function() return {} end }
PNC.UniqueNPCRegistry = {
    Internal = { Ensure = function() return uniqueWorldStates end },
    MarkDead = function(record, reason)
        local defId = record and record.uniqueDefinitionId
        if not defId then return false end
        uniqueWorldStates[defId] = {
            definitionId = defId,
            status = "dead",
            runtimeNpcId = tostring(record.id),
            deathReason = tostring(reason or "death"),
        }
        return true, "dead"
    end,
}

-- Faction registry state
local testFactions = {
    ["fac:colony"] = {
        id = "fac:colony",
        status = "active",
        leaderNPCID = "npc:l5:leader",
        memberIDs = {
            ["npc:l5:leader"] = true,
            ["npc:l5:colonist"] = true,
            ["npc:l5:survivor"] = true,
        },
    },
}
PNC.Factions = {
    Registry = { byID = testFactions },
    Internal = { touchFaction = function() end, touchRegistry = function() end },
    OnNPCDeath = function(npcID)
        local f = testFactions["fac:colony"]
        if f.leaderNPCID == npcID then f.leaderNPCID = "npc:l5:survivor" end
        return true, "death_reconciled"
    end,
}

assert(PNC.Persistence.CoreLifecycle.EnsureGCProvider({ Actors = CoreActors }))

local function registerCoreAndHoomans(id, opts)
    opts = opts or {}
    local actor = assert(reg:Create({
        actorId = id,
        ownerMod = "ProjectHoomans",
        identitySeed = "seed_" .. id,
        identity = { displayName = opts.displayName or id },
        providerLease = {
            leaseID = "lease:" .. id,
            provider = "ProjectHoomans",
            owner = "ProjectHoomans",
            state = "materialized",
            bodyID = "body:" .. id,
        },
    }))
    liveRecords[id] = {
        id = id,
        displayName = opts.displayName or id,
        coreActorID = actor.actorId,
        alive = true,
        colonyOwned = opts.colonyOwned == true,
        uniqueDefinitionId = opts.uniqueDefinitionId,
        deathReason = nil,
        x = 10,
        y = 20,
        z = 0,
        health = {
            current = 100,
            state = "healthy",
            body = {
                infection = opts.infected == true and { fatal = true } or nil,
            },
        },
        social = opts.social,
        runtime = {},
    }
    return liveRecords[id]
end

-- Helper to seed a player note for historical snapshot test
local function seedNote(npcID, name)
    local note = PNC.NPCKnowledge.Internal.mutableNote(playerUUID, npcID, true)
    note.firstMetAt = 25
    note.lastInteractionAt = 90
    note.discovered["identity.name"] = {
        status = "confirmed",
        value = name,
        confidence = 1,
        primarySource = "told",
        evidenceCount = 1,
    }
end

-- 1. Colonist dies -> Health.Kill cleans up quest/medical/RemoveRecord/Core Retire/faction memberIDs,
--    and active colony DeathMarker strongly pins Core tombstone until DeathMarker is removed.
local col = registerCoreAndHoomans("npc:l5:colonist", {
    displayName = "Colonist Mara",
    colonyOwned = true,
})
seedNote(col.id, "Colonist Mara")

local acceptedMortal = assert(PNC.QuestService.AcceptQuest(playerObj, "q:mortal", col.id, {}))
local medTask = assert(PNC.MedicalCareService.CreateRequest({
    patientKind = "npc",
    patientId = col.id,
    woundParts = { "Torso" },
    severity = 80,
}))

local okKill, deathMarker = PNC.Health.Kill(col, { setHealth = function() end }, "combat")
T.truthy(okKill, "Health.Kill succeeds")
T.truthy(deathMarker, "Colony death creates active DeathMarker")
T.equal(liveRecords[col.id], nil, "Live PNC record removed after Health.Kill")
T.equal(reg:Get(col.id), nil, "Live Core actor removed after Health.Kill")
T.truthy(reg:GetTombstone(col.id), "Core tombstone created")
T.equal(col.runtime.coreLifecycleRetired, true, "Core retirement flag set")
T.equal(testFactions["fac:colony"].memberIDs[col.id], nil,
    "Dead non-leader removed from faction.memberIDs after RemoveRecord")

-- Double Kill must be idempotent
local okDoubleKill = PNC.Health.Kill(col, nil, "combat")
T.equal(okDoubleKill, false, "Double Health.Kill is idempotent no-op")

local qAfterDeath = assert(PNC.QuestService.GetInstance(playerObj, "q:mortal", col.id))
T.equal(qAfterDeath.status, PNC.QuestRepository.STATUS.FAILED, "Non-sticky quest failed on giver death")
T.equal(qAfterDeath.failureReason, "giver_died")
local medAfterDeath = assert(PNC.MedicalCareRepository.Get(medTask.id))
T.equal(medAfterDeath.status, PNC.MedicalCareService.STATUS.CANCELLED, "Medical task cancelled on patient death")

-- BuildPlayerSnapshotForPlayer gracefully returns historical snapshot after death!
local histSnap, histErr = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(playerObj, col.id)
T.truthy(histSnap, "Historical player snapshot succeeds: " .. tostring(histErr))
T.equal(histSnap.historical, true, "Snapshot marked historical")
T.equal(histSnap.lifecycleStatus, "RETIRED", "Snapshot reflects RETIRED status")
T.equal(histSnap.identity.displayName, "Colonist Mara", "Snapshot preserves known displayName")

local unknownSnap, unknownErr = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(playerObj, "npc:never_existed")
T.equal(unknownSnap, nil)
T.equal(unknownErr, "npc_not_found", "Unknown NPC with no tombstone/marker/note still returns npc_not_found")

-- GC explain retention shows DeathMarker pinning colonist tombstone
local expMarker = assert(GC.ExplainRetention(reg, col.id, { now = 500 }))
T.equal(expMarker.retained, true, "DeathMarker strongly retains tombstone past grace")
T.equal(expMarker.strongRoots[1].providerID, PNC.Persistence.CoreLifecycle.PROVIDER_ID)
T.equal(expMarker.strongRoots[1].reason, "active_colony_corpse_marker")

-- 2. Infected unowned NPC -> infected DeathMarker pins until ReleaseReanimatedNPC removes marker -> GC purges
local infected = registerCoreAndHoomans("npc:l5:infected", {
    displayName = "Infected Zed",
    colonyOwned = false,
    infected = true,
})
local okInfKill, infMarker = PNC.Health.Kill(infected, { setHealth = function() end }, "infection")
T.truthy(okInfKill and infMarker and infMarker.lifecycleOnly == true,
    "Infected unowned NPC receives lifecycleOnly DeathMarker")
local gcDuringInf = assert(GC.RunFull(reg, { authority = "server", now = 500 }))
T.truthy(reg:GetTombstone(infected.id), "Infected corpse marker pins tombstone before reanimation")
T.truthy(reg:GetTombstone(col.id), "Colony DeathMarker pins colonist tombstone before burial/removal")

local zombieMock = { getModData = function() return { PNC_UUID = infected.id } end }
T.truthy(PNC.BodyLifecycle.ReleaseReanimatedNPC(infected, zombieMock), "ReleaseReanimatedNPC succeeds")
T.equal(PNC.Registry.GetDeathMarker(infected.id), nil, "Reanimation removes infected DeathMarker")

-- Also remove colonist DeathMarker (corpse decayed/buried)
T.truthy(PNC.Registry.RemoveDeathMarker(col.id, "corpse_buried"))

local gcPostCorpse = assert(GC.RunFull(reg, { authority = "server", now = 500 }))
T.equal(gcPostCorpse.purgedCount, 2, "Both tombstones purge cleanly once DeathMarkers are removed")
T.equal(reg:GetTombstone(infected.id), nil)
T.equal(reg:GetTombstone(col.id), nil)

-- 3. Sticky quest (keepAliveOnGiverDeath) + UniqueNPCRegistry + Durable bond
local uniqueNpc = registerCoreAndHoomans("npc:l5:unique_quest", {
    displayName = "Unique Elder",
    uniqueDefinitionId = "unique:elder",
})
local survivorNpc = registerCoreAndHoomans("npc:l5:survivor", {
    displayName = "Survivor Ally",
    social = {
        relationships = {
            ["npc:l5:unique_quest"] = {
                approval = 10,
                respect = 10,
                familiarity = 20,
                bond = { schemaVersion = 1, class = "close_friend" },
            },
        },
    },
})
assert(PNC.QuestService.AcceptQuest(playerObj, "q:sticky", uniqueNpc.id, {}))
T.truthy(PNC.Health.Kill(uniqueNpc, { setHealth = function() end }, "combat"))
T.equal(uniqueWorldStates["unique:elder"].status, "dead", "UniqueNPCRegistry marked dead")

local expSticky = assert(GC.ExplainRetention(reg, uniqueNpc.id, { now = 500 }))
T.equal(expSticky.retained, true, "Sticky quest + bond retain dead uniqueNpc")

-- Clear sticky quest and break durable bond -> UniqueNPCRegistry alone stays WEAK and must allow purge!
local stickyKey = playerUUID .. "\31q:sticky\31" .. uniqueNpc.id
PNC.QuestRepository.State.byKey[stickyKey].status = PNC.QuestRepository.STATUS.REWARDED
survivorNpc.social.relationships["npc:l5:unique_quest"].bond = { class = "none" }

local gcUniquePurge = assert(GC.RunFull(reg, { authority = "server", now = 500 }))
T.equal(gcUniquePurge.purgedCount, 1, "UniqueNPC dead flag alone is WEAK and allows GC purge")
T.equal(reg:GetTombstone(uniqueNpc.id), nil, "uniqueNpc tombstone purged")
T.equal(uniqueWorldStates["unique:elder"].status, "dead", "UniqueNPC stays non-respawnable dead")
T.equal(uniqueWorldStates["unique:elder"].runtimeNpcId, nil, "OnBeforePurge cleared dangling runtimeNpcId")
T.equal(uniqueWorldStates["unique:elder"].tombstonePurged, true)

-- 4. API.Despawn: rollback HardDelete vs departed Retire vs dtProviderProjection skip
local rollbackNpc = registerCoreAndHoomans("npc:l5:rollback", { displayName = "Rollback" })
T.truthy(PNC.API.Despawn(rollbackNpc.id, { reason = "rollback" }))
T.equal(reg:Get(rollbackNpc.id), nil, "Rollback despawn removed live Core actor")
T.equal(reg:GetTombstone(rollbackNpc.id), nil, "Rollback despawn created ZERO fake tombstones")

local departedNpc = registerCoreAndHoomans("npc:l5:departed", { displayName = "Departed" })
T.truthy(PNC.API.Despawn(departedNpc.id, { retire = true, reason = "departed" }))
T.equal(reg:Get(departedNpc.id), nil)
T.truthy(reg:GetTombstone(departedNpc.id), "Permanent departure created Core tombstone")
T.equal(reg:GetTombstone(departedNpc.id).reason, "departed")

local dtProjNpc = registerCoreAndHoomans("npc:l5:dt_proj", { displayName = "DT Caravan" })
dtProjNpc.runtime.dtProviderProjection = true
T.truthy(PNC.API.Despawn(dtProjNpc.id))
T.truthy(reg:Get(dtProjNpc.id), "Despawn of dtProviderProjection leaves DT's canonical Core actor LIVE")

print("pnc_core_actor_lifecycle_gc_smoke: PASS")
T.finish("pnc_core_actor_lifecycle_gc_smoke")
