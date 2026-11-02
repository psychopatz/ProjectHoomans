local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipTypes.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Context.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Commit.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Queries.lua")

local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = CoreActors.Social
local Adapter = PNC.Persistence.CoreSocial

-- Isolated Core registry
local registry = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = registry

-- 1. Create a Core actor representing an NPC
local actor, createErr = registry:Create({
    actorId = "actor:adversarial:trader",
    identitySeed = "seed-adversarial-trader",
    archetypeID = "trader.resident",
    providerLease = { leaseID = "lease:adversarial:1", provider = "DTAbstract", owner = "DynamicTrading" },
})
T.truthy(actor, createErr)

local playerKey = "player:online:101"

-- Initial Core social state
local committedSocial, commitErr = registry:Commit(actor.actorId, {
    social = {
        relationships = {
            [playerKey] = {
                approval = 20,
                respect = 15,
                familiarity = 10,
                revision = 1,
                memories = {
                    { id = "mem_initial_meet", type = "meet", approvalEffect = 5 },
                },
                extensions = {
                    ["ProjectHoomans"] = {
                        baselineApproval = 5,
                        baselineRespect = 5,
                        state = "neutral",
                        bond = { schemaVersion = 1, class = "acquaintance", stage = "established" },
                    },
                },
            },
        },
    },
})
T.truthy(committedSocial, commitErr)

-- Hoomans takes an early snapshot of this social state
local staleHoomansRecord = {
    id = "npc:adversarial:trader",
    coreActorID = "actor:adversarial:trader",
    alive = true,
    social = Adapter.FromCoreSocial(committedSocial.social),
}
PNC.Registry = PNC.Registry or {}
PNC.Registry.Get = function(id)
    if id == staleHoomansRecord.id then return staleHoomansRecord end
    return nil
end
PNC.Registry.MarkDirty = function() end

-- Verify stale snapshot values
T.equal(staleHoomansRecord.social.relationships[playerKey].approval, 20)
T.equal(staleHoomansRecord.social.relationships[playerKey].revision, 1)

-- 2. Dynamic Trading executes a trade in Core while Hoomans is dormant
package.path = "../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/?.lua;" .. package.path
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua")
local DTPolicy = DTCommon.CoreActorPolicy

local playerObj = {
    getOnlineID = function() return 101 end,
}
local traderDTRecord = {
    ca = {
        actorID = "actor:adversarial:trader",
        relationshipPricing = true,
        priceBias = 0.0,
    },
}

local dtUpdatedSocial, tradeErr = DTPolicy.RecordTradeEvent(traderDTRecord, playerObj, {
    requestID = "trade_evt_101",
    approvalDelta = 8,
    familiarityDelta = 6,
    totalValue = 500,
})
T.truthy(dtUpdatedSocial, tradeErr)

-- Check Core truth: approval is 28, revision is 2, DT extension and memory are present
local coreActorAfterTrade = registry:Get("actor:adversarial:trader")
local coreRelAfterTrade = Social.Get(coreActorAfterTrade.social, playerKey)
T.truthy(coreRelAfterTrade, "Social.Get resolves playerKey (via alias or direct)")
T.equal(coreRelAfterTrade.approval, 28, "Core approval after trade is 28")
T.truthy(coreRelAfterTrade.extensions.DynamicTrading, "DT extension present in Core")
T.equal(coreRelAfterTrade.extensions.DynamicTrading.totalTrades, 1)
local hasTradeMem = false
for _, m in ipairs(coreRelAfterTrade.memories) do
    if m.eventID == "dt:trade:trade_evt_101" or m.id == "dt:trade:trade_evt_101" then
        hasTradeMem = true
    end
end
T.truthy(hasTradeMem, "DT trade memory exists in Core")

-- 3. ADVERSARIAL TEST: Stale Hoomans calls SyncToCore
-- Stale record has approval 20, revision 1, NO DynamicTrading extension, NO trade memory.
local syncOk, syncReason = Adapter.SyncToCore(staleHoomansRecord, PsychopatzCore)
T.truthy(syncOk, syncReason)

-- Inspect Core state after stale SyncToCore:
local coreActorAfterStaleSync = registry:Get("actor:adversarial:trader")
local coreRelAfterStaleSync = Social.Get(coreActorAfterStaleSync.social, playerKey)

-- CRITICAL ASSERTIONS:
-- A. DynamicTrading extension MUST NOT be wiped out
T.truthy(coreRelAfterStaleSync.extensions.DynamicTrading ~= nil, "DT extension SURVIVED stale SyncToCore")
T.equal(coreRelAfterStaleSync.extensions.DynamicTrading.totalTrades, 1, "DT totalTrades preserved")

-- B. DT trade memory MUST NOT be wiped out
local tradeMemSurvives = false
for _, m in ipairs(coreRelAfterStaleSync.memories) do
    if m.eventID == "dt:trade:trade_evt_101" or m.id == "dt:trade:trade_evt_101" then
        tradeMemSurvives = true
    end
end
T.truthy(tradeMemSurvives, "DT trade memory SURVIVED stale SyncToCore")

-- C. Stale Hoomans approval (20) MUST NOT overwrite newer Core approval (28)
T.equal(coreRelAfterStaleSync.approval, 28, "Newer Core approval preserved against stale Hoomans snapshot")

-- D. Hoomans record.social was refreshed with Core data
local hoomansRefreshedRel = staleHoomansRecord.social.relationships[playerKey]
    or (coreRelAfterStaleSync.targetKey and staleHoomansRecord.social.relationships[coreRelAfterStaleSync.targetKey])
T.truthy(hoomansRefreshedRel, "Hoomans record refreshed relationship exists")
T.equal(hoomansRefreshedRel.approval, 28, "Hoomans record refreshed to Core approval")
T.truthy(hoomansRefreshedRel.extensions.DynamicTrading, "Hoomans record received DT extension")

-- 4. Hoomans now performs an authorized social mutation (e.g. +7 approval, updated bond, hoomans memory)
local hoomansRel = PNC.Relationships.Get("npc:adversarial:trader", playerKey)
T.truthy(hoomansRel)
T.equal(hoomansRel.approval, 28, "Hoomans reads latest Core approval")

-- Apply Hoomans mutation
local hoomRelTarget = hoomansRefreshedRel.targetKey or playerKey
staleHoomansRecord.social.relationships[hoomRelTarget].approval = 35
staleHoomansRecord.social.relationships[hoomRelTarget].revision = coreRelAfterStaleSync.revision + 1
staleHoomansRecord.social.relationships[hoomRelTarget].bond = {
    schemaVersion = 1,
    class = "friend",
    stage = "candidate",
}
table.insert(staleHoomansRecord.social.relationships[hoomRelTarget].memories, {
    id = "mem_hoomans_gift",
    type = "gift",
    approvalEffect = 7,
})

local hoomansSyncOk, hoomansSyncErr = Adapter.SyncToCore(staleHoomansRecord, PsychopatzCore)
T.truthy(hoomansSyncOk, hoomansSyncErr)

-- Inspect Core state after Hoomans mutation:
local coreActorAfterHoomans = registry:Get("actor:adversarial:trader")
local coreRelAfterHoomans = Social.Get(coreActorAfterHoomans.social, playerKey)

T.equal(coreRelAfterHoomans.approval, 35, "Core approval reflects Hoomans +7 update")
T.equal(coreRelAfterHoomans.extensions.ProjectHoomans.bond.class, "friend", "Core has updated Hoomans bond")
T.truthy(coreRelAfterHoomans.extensions.DynamicTrading, "DT extension STILL intact after Hoomans update")
T.equal(coreRelAfterHoomans.extensions.DynamicTrading.totalTrades, 1)

-- Both memories (initial, DT trade, and Hoomans gift) must coexist!
local foundMemIDs = {}
for _, m in ipairs(coreRelAfterHoomans.memories) do
    local mid = m.id or m.eventID
    if mid then foundMemIDs[mid] = true end
end
T.truthy(foundMemIDs["mem_initial_meet"], "Initial meet memory exists")
T.truthy(foundMemIDs["dt:trade:trade_evt_101"], "DT trade memory exists")
T.truthy(foundMemIDs["mem_hoomans_gift"], "Hoomans gift memory exists")

-- 5. DT executes second trade:
local dtUpdatedSocial2, tradeErr2 = DTPolicy.RecordTradeEvent(traderDTRecord, playerObj, {
    requestID = "trade_evt_102",
    approvalDelta = 4,
    familiarityDelta = 5,
    totalValue = 250,
})
T.truthy(dtUpdatedSocial2, tradeErr2)

local finalCoreActor = registry:Get("actor:adversarial:trader")
local finalCoreRel = Social.Get(finalCoreActor.social, playerKey)
T.equal(finalCoreRel.approval, 39, "Final approval is 35 + 4 = 39")
T.equal(finalCoreRel.extensions.DynamicTrading.totalTrades, 2, "DT totalTrades is now 2")
T.equal(finalCoreRel.extensions.ProjectHoomans.bond.class, "friend", "Hoomans bond preserved after second trade")

T.finish("pnc_non_destructive_social_mutation_smoke")
