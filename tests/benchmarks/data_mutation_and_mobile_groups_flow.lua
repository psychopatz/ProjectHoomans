-- Micro-benchmark for kill detection, data mutation, idle paths, and mobile groups.
-- Usage:
--   lua tests/benchmarks/data_mutation_and_mobile_groups_flow.lua
local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 10000
local worldHours = 24
isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
        getTimeOfDay = function() return 14 end,
    }
end
Events = {
    OnWeaponHitCharacter = { Add = function() end },
    OnZombieDead = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
instanceof = function(obj, cls) return type(obj) == "table" and obj._class == cls end

local function bench(name, iterations, fn)
    collectgarbage("collect")
    local t0 = os.clock()
    for i = 1, iterations do
        fn(i)
    end
    local elapsedMs = (os.clock() - t0) * 1000
    local avgUs = (elapsedMs * 1000) / iterations
    print(string.format("[BENCH] %-42s iters=%5d total=%7.3fms avg=%7.3fus",
        name, iterations, elapsedMs, avgUs))
    return elapsedMs, avgUs
end

-- 1. Kill detector non-player fast path with AuditEnabled = false
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }
T.load("PsychopatzCore", "common", "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Core.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Events.lua")
PsychopatzCore.ZombieKillDetector.AuditEnabled = false

local npcKiller = { _class = "IsoZombie" }
local deadZombie = {
    _class = "IsoZombie",
    getAttackedBy = function() return npcKiller end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 55 end,
}

local _, kdAvgUs = bench("ZombieKillDetector non-player fast path", 4000, function()
    PsychopatzCore.ZombieKillDetector.Internal.OnZombieDead(deadZombie)
end)
T.truthy(kdAvgUs < 50, "kill detector non-player fast path averages < 50us in C Lua")

-- 2. ConditionStats steady-state unchanged update
T.load("PsychopatzCore", "shared", "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua")
PNC = { PerformanceScalingDiagnostics = nil }
local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
PNC.Core.Now = function() return nowMs end
PNC.Core.IsAuthority = function() return true end
T.load(SHARED .. "Needs/PNC_ConditionStats.lua")
T.load(SHARED .. "Identity/PNC_Identity.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Relationships/PNC_SocialProfileConstants.lua")
T.load(SHARED .. "Relationships/PNC_SocialProfileGenerator.lua")
T.load(SHARED .. "Relationships/PNC_SocialProfileTypes.lua")
T.load(SHARED .. "Relationships/PNC_SocialTraits.lua")
T.load(SHARED .. "Relationships/PNC_SocialProfileMath.lua")
T.load(SHARED .. "Conduct/PNC_ConductConstants.lua")
T.load(SHARED .. "Conduct/PNC_ConductTypes.lua")
T.load(SHARED .. "Conduct/PNC_ConductMath.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipConstants.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipStates.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipTypes.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipMath.lua")
T.load(SHARED .. "Relationships/PNC_SocialEventDefinitions.lua")
T.load(SHARED .. "Base/PNC_Types.lua")
T.load(SHARED .. "Relationships/PNC_Relationships.lua")
T.load(SHARED .. "Persistence/PNC_Persistence.lua")
T.load(SHARED .. "Communities/PNC_CommunityConstants.lua")
T.load(SHARED .. "Communities/PNC_CommunityProfiles.lua")
T.load(SHARED .. "Communities/PNC_CommunityMath.lua")
T.load(SHARED .. "Communities/PNC_CommunityTypes.lua")
T.load(SERVER .. "Communities/PNC_CommunitySiteResolver.lua")

local condNpc = {
    id = "bench_cond_1",
    traits = { "brave", "outdoorsman" },
    conditionStats = { panic = 0, stress = 0, boredom = 0, unhappiness = 0, endurance = 100, fatigue = 0, lastUpdatedAt = 24 },
}
PNC.ConditionStats.Ensure(condNpc, 24)
local _, condAvgUs = bench("ConditionStats.Update (unchanged dt=0)", 4000, function()
    PNC.ConditionStats.Update(condNpc, 24, {})
end)
T.truthy(condAvgUs < 80, "ConditionStats unchanged tick averages < 80us")

-- 3. BehaviorCommon.ClearCombatTarget idle fast path
PNC.Equipment = PNC.Equipment or {
    Describe = function()
        return { equipped = false }
    end,
}
T.load(SHARED .. "Behaviors/PNC_Behavior_Common.lua")
local idleNpc = {
    id = "bench_idle_1",
    runtime = {},
}
local _, clearAvgUs = bench("BehaviorCommon.ClearCombatTarget (idle)", 10000, function()
    PNC.BehaviorCommon.ClearCombatTarget(idleNpc)
end)
T.truthy(clearAvgUs < 20, "ClearCombatTarget idle fast path averages < 20us")

-- 4. RelationshipService scalar queries + targeted mutation with 30 existing relationships
local dirtyCount = 0
local registryData = {}
PNC.Registry = {
    Data = registryData,
    Get = function(id) return registryData[tostring(id)] end,
    MarkDirty = function() dirtyCount = dirtyCount + 1 return true end,
}
T.load(SERVER .. "Social/PNC_RelationshipService.lua")

local relNpc = {
    id = "bench_rel_1",
    alive = true,
    identitySeed = 1,
    archetypeID = "General",
    social = {
        profile = { baselineBias = 0 },
        relationships = {},
        recentEventIDs = {},
        recentInteractions = {},
        cooldowns = {},
        saturation = {},
    },
}
for idx = 1, 30 do
    relNpc.social.relationships["npc:peer_" .. tostring(idx)] = {
        targetKey = "npc:peer_" .. tostring(idx),
        approval = 15, respect = 10, trust = 20, fear = 0, familiarity = 12,
        memories = {},
    }
end
registryData[relNpc.id] = relNpc

local _, scalarAvgUs = bench("RelationshipService scalar GetApproval", 5000, function(i)
    local val = PNC.Relationships.GetApproval(relNpc.id, "npc:peer_" .. tostring((i % 30) + 1))
    assert(val ~= nil)
end)
T.truthy(scalarAvgUs < 40, "RelationshipService scalar GetApproval averages < 40us")

local _, mutateAvgUs = bench("RelationshipService targeted mutation (30 peers)", 500, function(i)
    local ok = PNC.Relationships.ApplyEventMutation(relNpc.id, "npc:peer_1", {
        eventID = "bench_ev_" .. tostring(i),
        interactionType = "greeting",
        worldAgeHours = worldHours + i * 0.01,
        familiarityDelta = 1,
        memory = {
            id = "mem_" .. tostring(i),
            type = "player_greeted",
            approvalEffect = 1,
            respectEffect = 0,
            moraleEffect = 0,
            familiarityGain = 1,
            decayPerDay = 0.05,
            knowledgeSource = "experienced",
        },
    })
    assert(ok == true)
end)
T.truthy(mutateAvgUs < 500, "RelationshipService targeted mutation averages < 500us")

-- 5. MobileGroupDirector.PumpAmbient across 30 mobile groups
local factionStore = { byID = {}, revision = 1 }
PNC.Factions = {
    Registry = factionStore,
    Peek = function(id) return factionStore.byID[id] end,
    Get = function(id) return factionStore.byID[id] end,
    IsMobileGroup = function(f) return f and f.mobile and f.mobile.active == true end,
    ForEachActiveMobileGroup = function(fn)
        for _, f in pairs(factionStore.byID) do
            if f and f.mobile and f.mobile.active == true then
                fn(f)
            end
        end
    end,
    TouchMobileAmbientCheck = function(id, at)
        local f = factionStore.byID[id]
        if f and f.mobile then
            f.mobile.lastAmbientCheckAt = at
            return true
        end
        return false
    end,
}
PNC.OrderSystem = { SetOrder = function() end }
T.load(SERVER .. "Director/PNC_MobileGroupDirector.lua")

for g = 1, 30 do
    local fid = string.format("mob_%02d", g)
    local mIds = {}
    for m = 1, 3 do
        local nid = fid .. "_m" .. m
        mIds[m] = nid
        registryData[nid] = {
            id = nid,
            factionID = fid,
            alive = true,
            x = g * 20, y = 100, z = 0,
            orderSpec = { kind = "wander" },
            runtime = {},
        }
    end
    factionStore.byID[fid] = {
        id = fid,
        leaderID = mIds[1],
        memberIDs = mIds,
        mobile = {
            active = true,
            mode = "roam",
            lastAmbientCheckAt = worldHours,
            anchor = { x = g * 20, y = 100, z = 0 },
        },
    }
end

local _, mobileAvgUs = bench("MobileGroupDirector.PumpAmbient (30 groups)", 500, function(i)
    worldHours = worldHours + 0.002
    PNC.MobileGroupDirector.PumpAmbient(worldHours, { nowMs = nowMs + i * 100 })
end)
T.truthy(mobileAvgUs < 500, "MobileGroupDirector.PumpAmbient across 30 groups averages < 500us")

T.finish("data_mutation_and_mobile_groups_flow")
