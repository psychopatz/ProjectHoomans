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

-- Set up isolated Core registry
local registry = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = registry

-- 1. Create a Core actor representing an NPC
local actor, createErr = registry:Create({
    actorId = "actor:converged:trader",
    identitySeed = "seed-converged-trader",
    archetypeID = "trader.resident",
    providerLease = { leaseID = "lease:converged:1", provider = "DTAbstract", owner = "DynamicTrading" },
})
T.truthy(actor, createErr)

local playerKey = "player:online:42"

-- 2. Populate initial Core social state with both Hoomans and DT extensions
local committedSocial, commitErr = registry:Commit(actor.actorId, {
    social = {
        relationships = {
            [playerKey] = {
                approval = 20,
                respect = 15,
                familiarity = 10,
                extensions = {
                    ["ProjectHoomans"] = {
                        baselineApproval = 5,
                        baselineRespect = 5,
                        state = "neutral",
                        bond = { schemaVersion = 1, class = "friend", stage = "candidate" },
                    },
                    ["DynamicTrading"] = {
                        commercialReliability = 90,
                        totalTrades = 3,
                    },
                },
            },
        },
    },
})
T.truthy(committedSocial, commitErr)

-- 3. Mock PNC Registry record pointing to this Core actor
local mockRecord = {
    id = "npc:converged:trader",
    coreActorID = "actor:converged:trader",
    alive = true,
    social = Adapter.FromCoreSocial(committedSocial.social),
}
PNC.Registry = PNC.Registry or {}
PNC.Registry.Get = function(id)
    if id == mockRecord.id then return mockRecord end
    return nil
end
PNC.Registry.MarkDirty = function() end

-- 4. Hoomans queries relationship through RelationshipService.Get
local hoomansRel, getReason = PNC.Relationships.Get("npc:converged:trader", playerKey)
T.truthy(hoomansRel, getReason)
T.equal(hoomansRel.approval, 20, "Hoomans reads Core approval")
T.equal(hoomansRel.respect, 15, "Hoomans reads Core respect")
T.equal(hoomansRel.familiarity, 10, "Hoomans reads Core familiarity")
T.equal(hoomansRel.bond.class, "friend", "Hoomans reads bond from extension")

-- 5. Dynamic Trading executes a trade with this trader
package.path = "../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/?.lua;" .. package.path
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua")
local DTPolicy = DTCommon.CoreActorPolicy

local playerObj = {
    getOnlineID = function() return 42 end,
}
local traderDTRecord = {
    ca = {
        actorID = "actor:converged:trader",
        relationshipPricing = true,
        priceBias = 0.0,
    },
}

-- DT records trade event
local dtUpdatedSocial, tradeErr = DTPolicy.RecordTradeEvent(traderDTRecord, playerObj, {
    requestID = "req-converged-trade",
    approvalDelta = 8,
    familiarityDelta = 6,
    totalValue = 200,
})
T.truthy(dtUpdatedSocial, tradeErr)

-- 6. Hoomans queries relationship again: observes updated Core approval & familiarity!
local hoomansRelAfterTrade, getReason2 = PNC.Relationships.Get("npc:converged:trader", playerKey)
T.truthy(hoomansRelAfterTrade, getReason2)
T.equal(hoomansRelAfterTrade.approval, 28, "Hoomans immediately observes DT trade approval boost")
T.equal(hoomansRelAfterTrade.familiarity, 16, "Hoomans immediately observes DT trade familiarity boost")
T.equal(hoomansRelAfterTrade.bond.class, "friend", "Hoomans bond preserved after DT trade")

-- 7. Check Core extensions: both Hoomans and DT extensions are intact!
local updatedActor = registry:Get("actor:converged:trader")
local coreRel = updatedActor.social.relationships[playerKey]
T.equal(coreRel.approval, 28, "canonical Core approval is 28")
T.equal(coreRel.extensions.ProjectHoomans.bond.class, "friend", "Hoomans bond intact in Core")
T.equal(coreRel.extensions.DynamicTrading.totalTrades, 4, "DT total trades incremented in Core")

T.finish("pnc_core_social_convergence_smoke")
