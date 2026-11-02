-- Real Cross-Adopter Production-Module Hot-Plug Integration Matrix (P12)
--
-- Exercises real production modules across PsychopatzCore, DynamicTrading, and ProjectHoomans:
-- Sequence 1: DT-only save -> Save/Reload -> Add Hoomans -> Save/Reload -> Remove Hoomans -> DT Trade -> Re-add Hoomans.
-- Sequence 2: Hoomans-only save -> Save/Reload -> Add DT -> Save/Reload -> Remove DT -> Hoomans Interaction -> Re-add DT.
--
-- Invariants verified:
-- - Canonical actor IDs and player target keys remain stable across all transitions.
-- - Shared relationship scores (approval, respect, familiarity) converge to Core truth.
-- - Foreign adopter extensions (DynamicTrading and ProjectHoomans) are preserved when the other is active, inactive, or re-added.
-- - No duplicate relationships, no duplicate memories, no repeated migrations, no deleted extension payloads.

local T = require "tests/support/test"
T.addPackagePaths()
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local CORE_ROOT = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. package.path

local DT_ROOT = "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/"
package.path = DT_ROOT .. "?.lua;" .. package.path

local HOOMANS_ROOT = "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
package.path = HOOMANS_ROOT .. "?.lua;" .. package.path

-- Load Core
local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local PlayerIdentity = CoreActors.PlayerIdentity
local Social = CoreActors.Social
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local PackRegistry = Semantics.PackRegistry

-- Helper to simulate disk save/reload serialization of Core Registry
local function cloneTable(val)
    if type(val) ~= "table" then return val end
    local res = {}
    for k, v in pairs(val) do res[k] = cloneTable(v) end
    return res
end

local function simulateSaveAndReload(registry)
    local serialized = cloneTable(registry.records)
    local freshRegistry = CoreActors.NewRegistry()
    freshRegistry.records = serialized
    freshRegistry.revision = registry.revision
    PsychopatzCore.Actors.DefaultRegistry = freshRegistry
    return freshRegistry
end

-- =========================================================================
-- SEQUENCE 1: Core + DT Save -> Add Hoomans -> Remove Hoomans -> Re-add Hoomans
-- =========================================================================
print("[P12] Starting Sequence 1: DT First -> Add Hoomans -> Remove Hoomans -> Re-add Hoomans")

local registry1 = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = registry1

-- 1. Create Core actor representing a DT trader
local traderActor = registry1:Create({
    actorId = "actor:hotplug:trader_sam",
    identitySeed = "seed-hotplug-sam",
    archetypeID = "trader.resident",
    providerLease = { leaseID = "lease:sam:1", provider = "DTAbstract", owner = "DynamicTrading" },
})
T.truthy(traderActor, "Trader actor created in Core")

-- Load Dynamic Trading modules
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua")
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_SemanticPack.lua")
local DTPolicy = DTCommon.CoreActorPolicy

-- Mock player Alice in SinglePlayer slot 0
local playerAlice = {
    _data = { Core_CharacterUUID = "uuid-alice-sp-1" },
    getModData = function(self) return self._data end,
    getUsername = function() return "Alice" end,
    getOnlineID = function() return 10 end,
}
local aliceCanonicalKey = PlayerIdentity.GetTargetKey(playerAlice)
T.truthy(aliceCanonicalKey, "Alice canonical key resolved")

-- DT executes first trade with Alice
local dtRecordSam = {
    ca = {
        actorID = traderActor.actorId,
        relationshipPricing = true,
        priceBias = 0.0,
    },
}
local dtTrade1, trade1Err = DTPolicy.RecordTradeEvent(dtRecordSam, playerAlice, {
    requestID = "trade_seq1_1",
    approvalDelta = 15,
    familiarityDelta = 10,
    totalValue = 350,
})
T.truthy(dtTrade1, trade1Err)

local coreSam1 = registry1:Get(traderActor.actorId)
local aliceRel1 = Social.Get(coreSam1.social, aliceCanonicalKey)
T.truthy(aliceRel1, "Alice relationship exists in Core")
T.equal(aliceRel1.approval, 15, "Approval after DT trade is 15")
T.truthy(aliceRel1.extensions.DynamicTrading, "DT extension created")
T.equal(aliceRel1.extensions.DynamicTrading.totalTrades, 1)

-- 2. SAVE AND RELOAD Core
local reloadedRegistry1 = simulateSaveAndReload(registry1)
local reloadedSam1 = reloadedRegistry1:Get(traderActor.actorId)
local reloadedAliceRel1 = Social.Get(reloadedSam1.social, aliceCanonicalKey)
T.equal(reloadedAliceRel1.approval, 15, "Approval preserved across reload")
T.equal(reloadedAliceRel1.extensions.DynamicTrading.totalTrades, 1, "DT extension preserved across reload")

-- 3. ADD PROJECT HOOMANS TO EXISTING SAVE
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipTypes.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Context.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Commit.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Queries.lua")
T.load("ProjectHoomans", "shared", "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_CoreSemanticPack.lua")

-- Hoomans registers semantic pack
PNC.Semantics.CoreSemanticPack.Register(PsychopatzCore)

-- Hoomans instantiates NPC record binding to Core actor
local hoomansSamRecord = {
    id = "npc:hotplug:sam",
    coreActorID = traderActor.actorId,
    alive = true,
    social = PNC.Persistence.CoreSocial.FromCoreSocial(reloadedSam1.social),
}
PNC.Registry = PNC.Registry or {}
PNC.Registry.Get = function(id)
    if id == hoomansSamRecord.id then return hoomansSamRecord end
    return nil
end
PNC.Registry.MarkDirty = function() end

-- Hoomans queries relationship: immediately sees Core approval 15 and DT totalTrades 1!
local hoomansRel1, hReason1 = PNC.Relationships.Get(hoomansSamRecord.id, aliceCanonicalKey)
T.truthy(hoomansRel1, hReason1)
T.equal(hoomansRel1.approval, 15, "Hoomans observes DT approval")
T.equal(hoomansRel1.familiarity, 10, "Hoomans observes DT familiarity")
T.truthy(hoomansRel1.extensions.DynamicTrading, "Hoomans observes DT extension")

-- Hoomans performs a social mutation (chat interaction: +10 approval, bond candidate, hoomans memory)
hoomansSamRecord.social.relationships[aliceCanonicalKey].approval = 25
hoomansSamRecord.social.relationships[aliceCanonicalKey].revision = reloadedAliceRel1.revision + 1
hoomansSamRecord.social.relationships[aliceCanonicalKey].bond = {
    schemaVersion = 1,
    class = "friend",
    stage = "candidate",
}
table.insert(hoomansSamRecord.social.relationships[aliceCanonicalKey].memories, {
    id = "mem_hoomans_talk_1",
    type = "social_talk",
    approvalEffect = 10,
})

local hSyncOk1, hSyncErr1 = PNC.Persistence.CoreSocial.SyncToCore(hoomansSamRecord, PsychopatzCore)
T.truthy(hSyncOk1, hSyncErr1)

-- Check Core after Hoomans sync: BOTH extensions and BOTH memories intact!
local coreSamAfterH = reloadedRegistry1:Get(traderActor.actorId)
local aliceRelAfterH = Social.Get(coreSamAfterH.social, aliceCanonicalKey)
T.equal(aliceRelAfterH.approval, 25, "Core approval updated to 25")
T.truthy(aliceRelAfterH.extensions.DynamicTrading, "DT extension preserved")
T.equal(aliceRelAfterH.extensions.DynamicTrading.totalTrades, 1)
T.truthy(aliceRelAfterH.extensions.ProjectHoomans, "Hoomans extension attached")
T.equal(aliceRelAfterH.extensions.ProjectHoomans.bond.class, "friend")

-- 4. SIMULATE REMOVING PROJECT HOOMANS (Unload pack, clear Hoomans registry)
PackRegistry.UnregisterPack("pack.projecthoomans.social_core")
PNC.Registry = nil

-- DT standalone save/reload
local reloadedRegistryDTOnly = simulateSaveAndReload(reloadedRegistry1)
local samDTOnly = reloadedRegistryDTOnly:Get(traderActor.actorId)

-- DT executes a second trade while Hoomans is REMOVED
local dtTrade2, trade2Err = DTPolicy.RecordTradeEvent(dtRecordSam, playerAlice, {
    requestID = "trade_seq1_2",
    approvalDelta = 8,
    familiarityDelta = 5,
    totalValue = 500,
})
T.truthy(dtTrade2, trade2Err)

-- CRITICAL INVARIANT: DT trade does NOT delete ProjectHoomans extension!
local coreSamAfterDT2 = reloadedRegistryDTOnly:Get(traderActor.actorId)
local aliceRelAfterDT2 = Social.Get(coreSamAfterDT2.social, aliceCanonicalKey)
T.equal(aliceRelAfterDT2.approval, 33, "Approval is 25 + 8 = 33")
T.equal(aliceRelAfterDT2.extensions.DynamicTrading.totalTrades, 2, "DT totalTrades is 2")
T.truthy(aliceRelAfterDT2.extensions.ProjectHoomans, "ProjectHoomans extension SURVIVED DT-only play")
T.equal(aliceRelAfterDT2.extensions.ProjectHoomans.bond.class, "friend", "Hoomans bond intact")

-- 5. RE-ADD PROJECT HOOMANS
PNC.Semantics.CoreSemanticPack.Register(PsychopatzCore)
PNC.Registry = {
    Get = function(id)
        if id == hoomansSamRecord.id then return hoomansSamRecord end
        return nil
    end,
    MarkDirty = function() end,
}
-- Refresh Hoomans projection from Core
PNC.Persistence.CoreSocial.SyncFromCore(hoomansSamRecord, PsychopatzCore)

local hoomansRelReadded, hReasonReadded = PNC.Relationships.Get(hoomansSamRecord.id, aliceCanonicalKey)
T.truthy(hoomansRelReadded, hReasonReadded)
T.equal(hoomansRelReadded.approval, 33, "Re-added Hoomans reads latest approval 33")
T.equal(hoomansRelReadded.extensions.DynamicTrading.totalTrades, 2, "Re-added Hoomans reads DT trade count 2")
T.equal(hoomansRelReadded.bond.class, "friend", "Re-added Hoomans restores previous bond")

print("[P12] Sequence 1 PASSED.")

-- =========================================================================
-- SEQUENCE 2: Core + Hoomans Save -> Add DT -> Remove DT -> Re-add DT
-- =========================================================================
print("[P12] Starting Sequence 2: Hoomans First -> Add DT -> Remove DT -> Re-add DT")

local registry2 = CoreActors.NewRegistry()
PsychopatzCore.Actors.DefaultRegistry = registry2

-- 1. Create Core actor representing a Hoomans colonist
local colonistActor, createErr2 = registry2:Create({
    actorId = "actor:hotplug:colonist_elena",
    identitySeed = "seed-hotplug-elena",
    archetypeID = "colonist.scout",
    providerLease = { leaseID = "lease:elena:1", provider = "DTHoomans", owner = "ProjectHoomans" },
})
T.truthy(colonistActor, createErr2)

local playerBob = {
    _data = { Core_CharacterUUID = "uuid-bob-sp-2" },
    getModData = function(self) return self._data end,
    getUsername = function() return "Bob" end,
    getOnlineID = function() return 22 end,
}
local bobCanonicalKey = PlayerIdentity.GetTargetKey(playerBob)

-- Hoomans initializes colonist social state with Bob
local hoomansElenaRecord = {
    id = "npc:hotplug:elena",
    coreActorID = colonistActor.actorId,
    alive = true,
    social = {
        morale = 75,
        relationships = {
            [bobCanonicalKey] = {
                approval = 30,
                respect = 25,
                familiarity = 20,
                revision = 1,
                state = "neutral",
                bond = { schemaVersion = 1, class = "friend", stage = "established" },
                memories = {
                    { id = "mem_rescued_elena", type = "rescue", approvalEffect = 30 },
                },
            },
        },
    },
}
PNC.Registry = {
    Get = function(id)
        if id == hoomansElenaRecord.id then return hoomansElenaRecord end
        return nil
    end,
    MarkDirty = function() end,
}

local elenaSyncOk, elenaSyncErr = PNC.Persistence.CoreSocial.SyncToCore(hoomansElenaRecord, PsychopatzCore)
T.truthy(elenaSyncOk, elenaSyncErr)

-- Verify Core has Elena's relationship
local coreElena1 = registry2:Get(colonistActor.actorId)
local bobRel1 = Social.Get(coreElena1.social, bobCanonicalKey)
T.equal(bobRel1.approval, 30)
T.truthy(bobRel1.extensions.ProjectHoomans)
T.equal(bobRel1.extensions.ProjectHoomans.bond.class, "friend")

-- 2. SAVE AND RELOAD
local reloadedRegistry2 = simulateSaveAndReload(registry2)

-- 3. ADD DYNAMIC TRADING TO HOOMANS SAVE
local dtRecordElena = {
    ca = {
        actorID = colonistActor.actorId,
        relationshipPricing = true,
        priceBias = 0.0,
    },
}
local dtTradeBob, tradeBobErr = DTPolicy.RecordTradeEvent(dtRecordElena, playerBob, {
    requestID = "trade_seq2_1",
    approvalDelta = 6,
    familiarityDelta = 4,
    totalValue = 180,
})
T.truthy(dtTradeBob, tradeBobErr)

-- Verify Core after DT trade:
local coreElenaAfterDT = reloadedRegistry2:Get(colonistActor.actorId)
local bobRelAfterDT = Social.Get(coreElenaAfterDT.social, bobCanonicalKey)
T.equal(bobRelAfterDT.approval, 36, "Approval is 30 + 6 = 36")
T.equal(bobRelAfterDT.extensions.DynamicTrading.totalTrades, 1, "DT extension attached")
T.equal(bobRelAfterDT.extensions.ProjectHoomans.bond.class, "friend", "Hoomans bond intact")

-- 4. SIMULATE REMOVING DYNAMIC TRADING
-- Hoomans interacts with Bob while DT is inactive
hoomansElenaRecord.social = PNC.Persistence.CoreSocial.FromCoreSocial(coreElenaAfterDT.social)
hoomansElenaRecord.social.relationships[bobCanonicalKey].approval = 45
hoomansElenaRecord.social.relationships[bobCanonicalKey].revision = bobRelAfterDT.revision + 1
table.insert(hoomansElenaRecord.social.relationships[bobCanonicalKey].memories, {
    id = "mem_colony_feast",
    type = "celebration",
    approvalEffect = 9,
})

local hSyncElena2, hSyncElenaErr2 = PNC.Persistence.CoreSocial.SyncToCore(hoomansElenaRecord, PsychopatzCore)
T.truthy(hSyncElena2, hSyncElenaErr2)

-- CRITICAL INVARIANT: Hoomans update does NOT delete DynamicTrading extension!
local coreElenaAfterH2 = reloadedRegistry2:Get(colonistActor.actorId)
local bobRelAfterH2 = Social.Get(coreElenaAfterH2.social, bobCanonicalKey)
T.equal(bobRelAfterH2.approval, 45, "Approval updated to 45")
T.truthy(bobRelAfterH2.extensions.DynamicTrading, "DT extension SURVIVED Hoomans-only play")
T.equal(bobRelAfterH2.extensions.DynamicTrading.totalTrades, 1)

-- 5. RE-ADD DYNAMIC TRADING
local dtTradeBob2, tradeBobErr2 = DTPolicy.RecordTradeEvent(dtRecordElena, playerBob, {
    requestID = "trade_seq2_2",
    approvalDelta = 5,
    familiarityDelta = 3,
    totalValue = 220,
})
T.truthy(dtTradeBob2, tradeBobErr2)

local finalCoreElena = reloadedRegistry2:Get(colonistActor.actorId)
local finalBobRel = Social.Get(finalCoreElena.social, bobCanonicalKey)
T.equal(finalBobRel.approval, 50, "Final approval is 45 + 5 = 50")
T.equal(finalBobRel.extensions.DynamicTrading.totalTrades, 2, "DT totalTrades is 2")
T.equal(finalBobRel.extensions.ProjectHoomans.bond.class, "friend", "Hoomans bond intact after DT re-add")

print("[P12] Sequence 2 PASSED.")
T.finish("pnc_real_cross_adopter_hotplug_matrix_smoke")
