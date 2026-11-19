local T = require "tests/support/test"
T.addPackagePaths()

local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = CoreActors.Social
local GC = CoreActors.GC

local nowMs = 2000
local worldHours = 400
local modDataStore = {}

ModData = {
    get = function(k) return modDataStore[k] end,
    getOrCreate = function(k)
        modDataStore[k] = modDataStore[k] or {}
        return modDataStore[k]
    end,
    transmit = function() end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnServerStarted = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = { Add = function() end },
}
getGameTime = function()
    return { getWorldAgeHours = function() return worldHours end }
end
isServer = function() return true end
isClient = function() return false end

local reg = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = reg
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local liveRecords = {}
local deathMarkers = {}
local uniqueWorldStates = {}

PNC = {
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        GenerateID = function(p) return tostring(p) .. "_soak" end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do out[k] = PNC.Core.DeepCopy(val) end
            return out
        end,
        Log = function() end,
        LogInfo = function() end,
        LogWarn = function() end,
        LogRecordDebug = function() end,
    },
    Const = { PRESENCE_CORPSE = "corpse", PRESENCE_ABSTRACT = "abstract", PRESENCE_LIVE = "live" },
    Presence = { Abstract = function(r) r.presenceState = "abstract" end },
    Registry = {
        Data = liveRecords,
        DeathMarkers = deathMarkers,
        Get = function(id) return liveRecords[tostring(id or "")] end,
        IsColonyOwnedNPC = function(r) return r and r.colonyOwned == true end,
        RemoveRecord = function(id) liveRecords[tostring(id)] = nil end,
        MarkDirty = function() end,
        GetLiveZombie = function() return nil end,
        List = function()
            local out = {}
            for _, v in pairs(liveRecords) do out[#out + 1] = v end
            return out
        end,
    },
    UniqueNPCs = { List = function() return {} end },
    UniqueNPCRegistry = {
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
    },
    Factions = {
        Registry = { byID = {} },
        Internal = { touchFaction = function() end, touchRegistry = function() end },
        OnNPCDeath = function() return true end,
    },
    Persistence = {
        CoreProvider = {
            BuildRecord = function(_, _, base) return base end,
            Release = function(actor, _, opts)
                return {
                    providerLease = {
                        schema = "PsychopatzCore.NPC.ProviderLease",
                        schemaVersion = 1,
                        actorID = actor.actorId,
                        provider = opts.provider or "ProjectHoomans",
                        owner = nil,
                        state = "released",
                        revision = ((actor.providerLease and actor.providerLease.revision) or 1) + 1,
                    },
                }
            end,
        },
    },
}

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")
T.load(SHARED .. "Persistence/PNC_Persistence_CoreLifecycle.lua")
T.load(SERVER .. "Quests/PNC_QuestRepository.lua")

local questByKey = {}
PNC.QuestRepository = {
    State = { byKey = questByKey },
    TERMINAL = { completed = true, failed = true, cancelled = true, expired = true },
}

assert(PNC.Persistence.CoreLifecycle.EnsureGCProvider({ Actors = CoreActors }))

-- Survivor holding durable bonds to NPCs 41..60
local bondRels = {}
for idx = 41, 60 do
    local id = string.format("npc:soak_h5:%04d", idx)
    bondRels[id] = {
        target = id,
        approval = 70,
        respect = 50,
        familiarity = 80,
        bond = { class = "close_friend" },
    }
end
assert(reg:Create({
    actorId = "npc:soak_h5:survivor",
    ownerMod = "ProjectHoomans",
    identitySeed = "h5-survivor",
    identity = { displayName = "Soak Survivor" },
}))
liveRecords["npc:soak_h5:survivor"] = {
    id = "npc:soak_h5:survivor",
    coreActorID = "npc:soak_h5:survivor",
    alive = true,
    social = { relationships = bondRels },
}

-- Register and retire 200 Hoomans NPCs cleanly
--   1..20: colony DeathMarkers (1..10 released early, 11..20 released later)
--   21..40: active quests (21..30 completed before Gen 2, 31..40 remain active)
--   41..60: durable bonds on live survivor (stay pinned)
--   61..80: dead unique NPCs (WEAK ref -> purges tombstone while keeping status="dead")
--   81..200: ordinary unowned deaths (purge in Gen 1)
for idx = 1, 200 do
    local id = string.format("npc:soak_h5:%04d", idx)
    assert(reg:Create({
        actorId = id,
        ownerMod = "ProjectHoomans",
        identitySeed = "h5-" .. tostring(idx),
        identity = { displayName = "NPC " .. tostring(idx) },
        providerLease = {
            leaseID = "lease:" .. id,
            provider = "ProjectHoomans",
            owner = "ProjectHoomans",
            state = "materialized",
            bodyID = "body:" .. id,
        },
    }))
    local rec = {
        id = id,
        coreActorID = id,
        displayName = "NPC " .. tostring(idx),
        alive = true,
        colonyOwned = idx <= 20,
        uniqueDefinitionId = (idx >= 61 and idx <= 80) and ("uniq_" .. tostring(idx)) or nil,
        runtime = {},
    }
    liveRecords[id] = rec
    if rec.uniqueDefinitionId then
        PNC.UniqueNPCRegistry.MarkDead(rec, "death")
    end
    if idx <= 20 then
        deathMarkers[id] = {
            id = id,
            name = rec.displayName,
            infected = idx > 10,
            corpseToken = "corpse_" .. tostring(idx),
        }
    end
    if idx >= 21 and idx <= 40 then
        questByKey["quest:" .. tostring(idx)] = {
            questID = "quest:" .. tostring(idx),
            giverNPCID = id,
            status = "active",
        }
    end

    PNC.Registry.RemoveRecord(id)
    local retired, rReason = PNC.Persistence.CoreLifecycle.RetireActor(rec, "death", {
        retiredAt = worldHours,
        graceHours = 12,
    })
    T.truthy(retired, rReason)
end

-- Release DeathMarkers 1..10 before Gen 1
for idx = 1, 10 do
    deathMarkers[string.format("npc:soak_h5:%04d", idx)] = nil
end

-- Gen 1: advance past grace and run cursor-budgeted GC (budget=20)
worldHours = worldHours + 48
local stepCount = 0
local res
repeat
    res = assert(GC.Step(reg, { authority = "server", budget = 20, now = worldHours }))
    stepCount = stepCount + 1
    assert(stepCount <= 100)
until res.completed == true

-- Expected purged in Gen 1: 1..10 (10) + 61..80 (20) + 81..200 (120) = 150 purged!
-- Expected retained in Gen 1: 11..20 (10 markers) + 21..40 (20 quests) + 41..60 (20 bonds) = 50 tombstones!
T.equal(#reg:ListTombstones(), 50, "Gen 1 must retain exactly 50 rooted Hoomans tombstones")
for idx = 61, 80 do
    local uniq = uniqueWorldStates["uniq_" .. tostring(idx)]
    T.equal(uniq.status, "dead", "dead unique NPC status preserved after purge")
    T.equal(uniq.runtimeNpcId, nil, "dead unique NPC stale runtimeNpcId scrubbed")
    T.equal(uniq.tombstonePurged, true)
end

-- Now reanimate/clear markers 11..20 and complete quests 21..30, run Gen 2 -> 30 remain (41..60 bonds + 31..40 quests)
for idx = 11, 20 do
    deathMarkers[string.format("npc:soak_h5:%04d", idx)] = nil
end
for idx = 21, 30 do
    questByKey["quest:" .. tostring(idx)].status = "completed"
end

worldHours = worldHours + 24
GC.RunFull(reg, { authority = "server", now = worldHours })
T.equal(#reg:ListTombstones(), 30, "Gen 2 must retain only 20 durable bonds + 10 remaining active quests")

-- Save/Load Core registry under _G.next = nil
local savedNext = _G.next
_G.next = nil
local okS, ser = pcall(reg.Save, reg)
local restored = CoreActors.NewRegistry()
local okL, loadRes, loadErr = pcall(restored.Load, restored, ser)
_G.next = savedNext
T.truthy(okS and ser, "Core Save under _G.next=nil failed")
T.truthy(okL and loadRes, loadErr)
T.equal(#restored:ListTombstones(), 30, "reloaded tombstone count preserved")

T.finish("pnc_lifecycle_gc_scale_soak_smoke")
