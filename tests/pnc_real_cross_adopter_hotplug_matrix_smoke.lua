-- Real Cross-Adopter Production-Module Hot-Plug Integration Matrix (P15C)
--
-- Exercises real production modules across PsychopatzCore, DynamicTrading, and ProjectHoomans:
-- Sequence 1: DT-only save -> Save/Reload -> Add Hoomans -> Save/Reload -> Remove Hoomans -> DT Trade -> Re-add Hoomans.
-- Sequence 2: Hoomans-only save -> Save/Reload -> Add DT -> Save/Reload -> Remove DT -> Hoomans Interaction -> Re-add DT.
-- Sequence 3: Production Conversation Capability Isolation with real production packs.
-- Sequence 4: Grounded DT Whereabouts, Road News, and Storytelling.
-- Sequence 5: Pack unregister / re-register lifecycle residue check.
-- Sequence 6: Repeated migration & sync idempotence.
--
-- Invariants verified:
-- - Canonical actor IDs and player target keys remain stable across all transitions.
-- - Real Hoomans PlayerCharacterService adopts Core-issued player UUID and canonical key.
-- - Shared relationship scores (approval, respect, familiarity) converge to Core truth.
-- - Foreign adopter extensions (DynamicTrading and ProjectHoomans) are preserved when the other is active, inactive, or re-added.
-- - No duplicate relationships, no duplicate memories, no repeated migrations, no deleted extension payloads.
-- - Conversation capability isolation prevents cross-adopter grammar leaks.
-- - Trader whereabouts and road news ground in real world knowledge or state bounded uncertainty.

local T = require "tests/support/test"
T.addPackagePaths()
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local CORE_ROOT = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. package.path

local DT_ROOT = "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/"
package.path = DT_ROOT .. "?.lua;" .. package.path

local HOOMANS_ROOT = "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
package.path = HOOMANS_ROOT .. "?.lua;" .. package.path

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER_ROOT = T.path("ProjectHoomans", "server", "PNC/")

-- Engine environment stubs for real PlayerCharacterService
local globalModData = {}
local worldHour = 100
local randomCounter = 0

ModData = {
    getOrCreate = function(key)
        globalModData[key] = globalModData[key] or {}
        return globalModData[key]
    end,
}

function getGameTime()
    return {
        getYear = function() return 1993 end,
        getMonth = function() return 8 end,
        getDay = function() return 1 end,
        getWorldAgeHours = function() return worldHour end,
    }
end

function getTimeInMillis()
    return math.floor(worldHour * 3600000)
end

function ZombRand(x)
    randomCounter = randomCounter + 1
    return randomCounter % (x or 1000)
end

local isServerMode = false
local isClientMode = false
function isServer() return isServerMode end
function isClient() return isClientMode end

-- Load Hoomans Player Character Service
T.load(SHARED_ROOT .. "Base/PNC_Core.lua")
T.load(SHARED_ROOT .. "Base/PNC_Constants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_PlayerCharacterConstants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_PlayerCharacterTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterDebug.lua")
T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterService.lua")

local function resetHoomansPlayerRegistry()
    globalModData["PNC.PlayerCharacters"] = nil
    PNC.PlayerCharacters.Registry = PNC.PlayerCharacterTypes.NewRegistry()
    PNC.PlayerCharacters.RuntimeByPlayer = setmetatable({}, { __mode = "k" })
    PNC.PlayerCharacters.RuntimeByUUID = {}
    PNC.PlayerCharacters.RuntimeContexts = setmetatable({}, { __mode = "k" })
    PNC.PlayerCharacters.Loaded = true
end

local function makePlayer(accountIdentity, modData, options)
    options = options or {}
    modData = modData or {}
    local player = {}
    player.getUsername = function() return accountIdentity end
    player.getOnlineID = function() return options.onlineID or -1 end
    player.getPlayerNum = function() return options.playerNum or 0 end
    player.getPlayerIndex = function() return options.playerNum or 0 end
    player.getModData = function() return modData end
    player.getDisplayName = function() return options.displayName or accountIdentity end
    player.getDescriptor = function()
        return {
            getForename = function() return options.forename or "Test" end,
            getSurname = function() return options.surname or "Survivor" end,
        }
    end
    player.getX = function() return 10 end
    player.getY = function() return 10 end
    player.getZ = function() return 0 end
    player.isDead = function() return false end
    return player, modData
end

-- Load Core Modules
local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local PlayerIdentity = CoreActors.PlayerIdentity
local Social = CoreActors.Social
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local PackRegistry = Semantics.PackRegistry
local ActorConversationService = require "PsychopatzCore/Conversation/PsychopatzActorConversationService"

-- Load DT Modules
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua")
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderService.lua")
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_SemanticPack.lua")
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_WorldKnowledge.lua")
T.load("../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TalkService.lua")
local DTPolicy = DTCommon.CoreActorPolicy

-- Load Hoomans Modules
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipTypes.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Context.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Commit.lua")
T.load("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Queries.lua")
T.load("ProjectHoomans", "shared", "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_CoreSemanticPack.lua")

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
print("[P15C] Starting Sequence 1: DT First -> Add Hoomans -> Remove Hoomans -> Re-add Hoomans")

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

-- Player Alice starts in SinglePlayer slot 0 with Core + DT only
local playerAlice, aliceModData = makePlayer("Alice", nil, { playerNum = 0 })
local aliceCoreUUID = PlayerIdentity.GetCharacterUUID(playerAlice)
T.truthy(aliceCoreUUID and string.match(aliceCoreUUID, "^char_"), "Core generated valid UUID with provenance")
T.truthy(aliceModData.Core_CharacterSignature, "Core provenance signature exists")

local aliceCanonicalKey = PlayerIdentity.GetTargetKey(playerAlice)
T.equal(aliceCanonicalKey, "player:sp_slot_0:" .. aliceCoreUUID, "Alice canonical key is player:sp_slot_0:<uuid>")

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
T.equal(aliceRel1.familiarity, 10, "Familiarity after DT trade is 10")
T.truthy(aliceRel1.extensions.DynamicTrading, "DT extension created")
T.equal(aliceRel1.extensions.DynamicTrading.totalTrades, 1)

-- 2. SAVE AND RELOAD Core
local reloadedRegistry1 = simulateSaveAndReload(registry1)
local reloadedSam1 = reloadedRegistry1:Get(traderActor.actorId)
local reloadedAliceRel1 = Social.Get(reloadedSam1.social, aliceCanonicalKey)
T.equal(reloadedAliceRel1.approval, 15, "Approval preserved across reload")
T.equal(reloadedAliceRel1.extensions.DynamicTrading.totalTrades, 1, "DT extension preserved across reload")

-- 3. ADD PROJECT HOOMANS TO EXISTING SAVE
resetHoomansPlayerRegistry()

-- Real Hoomans EnsureIdentity adopts Core-issued player UUID
local hAliceUUID, hAdoptReason = PNC.PlayerCharacters.EnsureIdentity(playerAlice)
T.equal(hAliceUUID, aliceCoreUUID, "Real Hoomans adopted exact Core UUID")
T.equal(hAdoptReason, "core_adopted", "Reason was core_adopted")

local hAliceKey = PNC.PlayerCharacters.GetEntityKey(playerAlice)
T.equal(hAliceKey, aliceCanonicalKey, "Real Hoomans entity key exactly equals Core canonical key")

-- Adversarial check: forged UUID with valid-looking signature is rejected because not issued by Core
local forgedPlayer, forgedModData = makePlayer("Mallory", nil, { playerNum = 2 })
local forgedUUID = "char_mallory_forged_99999999"
forgedModData.PNC_CharacterUUID = forgedUUID
forgedModData.PNC_IdentityProvenance = PlayerIdentity.SignProvenance(forgedPlayer, forgedUUID, "sp_slot_2")
local forgedAdopted, forgedReason = PNC.PlayerCharacters.EnsureIdentity(forgedPlayer)
T.truthy(forgedAdopted ~= forgedUUID, "Adversary forged UUID rejected by EnsureIdentity")
T.equal(forgedReason, "new_identity", "Fresh identity created instead of core_adopted")

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

-- Hoomans queries relationship: immediately sees Core approval 15 and DT totalTrades 1
local hoomansRel1, hReason1 = PNC.Relationships.Get(hoomansSamRecord.id, aliceCanonicalKey)
T.truthy(hoomansRel1, hReason1)
T.equal(hoomansRel1.approval, 15, "Hoomans observes DT approval")
T.equal(hoomansRel1.familiarity, 10, "Hoomans observes DT familiarity")
T.truthy(hoomansRel1.extensions.DynamicTrading, "Hoomans observes DT extension")
T.equal(hoomansRel1.extensions.DynamicTrading.totalTrades, 1)

-- Hoomans performs a social mutation (chat interaction: +10 approval, friend bond candidate, hoomans memory)
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

print("[P15C] Sequence 1 PASSED.")

-- =========================================================================
-- SEQUENCE 2: Core + Hoomans Save -> Add DT -> Remove DT -> Re-add DT
-- =========================================================================
print("[P15C] Starting Sequence 2: Hoomans First -> Add DT -> Remove DT -> Re-add DT")

local registry2 = CoreActors.NewRegistry()
PsychopatzCore.Actors.DefaultRegistry = registry2
resetHoomansPlayerRegistry()

-- 1. Create Core actor representing a Hoomans colonist
local colonistActor, createErr2 = registry2:Create({
    actorId = "actor:hotplug:colonist_elena",
    identitySeed = "seed-hotplug-elena",
    archetypeID = "colonist.scout",
    providerLease = { leaseID = "lease:elena:1", provider = "DTHoomans", owner = "ProjectHoomans" },
})
T.truthy(colonistActor, createErr2)

-- Player Bob starts with Hoomans installed first
local playerBob, bobModData = makePlayer("Bob", nil, { playerNum = 1 })
local bobHUUID, bobHReason = PNC.PlayerCharacters.EnsureIdentity(playerBob)
T.truthy(bobHUUID and string.match(bobHUUID, "^char_"), "Hoomans generated valid player UUID")
local bobHKey = PNC.PlayerCharacters.GetEntityKey(playerBob)
local bobCanonicalKey = PlayerIdentity.GetTargetKey(playerBob)
T.equal(bobHKey, bobCanonicalKey, "Bob Hoomans key matches Core canonical key")

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
PackRegistry.UnregisterPack("pack.dynamictrading.trader_story")

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
DTCommon.SemanticPack.Init()

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

print("[P15C] Sequence 2 PASSED.")

-- =========================================================================
-- SEQUENCE 3: Production Conversation Capability Isolation
-- =========================================================================
print("[P15C] Starting Sequence 3: Conversation Capability Isolation")

local convActor = {
    actorId = "actor:hotplug:conv_test",
    identity = { displayName = "Sam Trader" },
    social = { personality = {}, relationships = {} },
}

local convService = ActorConversationService.New({
    actor = convActor,
    stateSpec = { maxEvents = 8 },
})

-- Test 3A: DT-only capabilities must NOT parse Hoomans COMMAND
do
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade", "dynamictrading.whereabouts" },
        targetKey = aliceCanonicalKey,
    }
    local res, why = convService:Submit("follow me", dtContext)
    local matchedPart = res and res.parts and res.parts[1]
    local ir = matchedPart and matchedPart.ir
    T.falsy(ir and ir.intent == "COMMAND", "Hoomans COMMAND must not be parsed in DT-only conversation")
    print("PASS: DT-only conversation isolated from Hoomans COMMAND")
end

-- Test 3B: DT-only capabilities accept DT trade
do
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade", "dynamictrading.whereabouts" },
        targetKey = aliceCanonicalKey,
    }
    local res, why = convService:Submit("trade", dtContext)
    T.truthy(res and res.accepted, "Submit('trade') accepted")
    local ir = res.parts and res.parts[1] and res.parts[1].ir
    T.truthy(ir and ir.intent == "TRADE", "Trade intent parsed under DT capabilities")
    print("PASS: DT trade accepted under DT capabilities")
end

-- Test 3C: Hoomans-only capabilities accept Hoomans COMMAND
do
    local hoomansContext = {
        capabilities = { "core.conversation", "hoomans.social" },
        targetKey = bobCanonicalKey,
    }
    local res, why = convService:Submit("follow me", hoomansContext)
    T.truthy(res and res.accepted, "Submit('follow me') accepted")
    local ir = res.parts and res.parts[1] and res.parts[1].ir
    T.truthy(ir and ir.intent == "COMMAND", "Follow parsed as COMMAND under Hoomans capabilities")
    print("PASS: Hoomans COMMAND accepted under Hoomans capabilities")
end

-- Test 3D: Hoomans-only capabilities must NOT parse DT trade
do
    local hoomansContext = {
        capabilities = { "core.conversation", "hoomans.social" },
        targetKey = bobCanonicalKey,
    }
    local res, why = convService:Submit("trade", hoomansContext)
    local matchedPart = res and res.parts and res.parts[1]
    local ir = matchedPart and matchedPart.ir
    T.falsy(ir and ir.intent == "TRADE", "DT TRADE must not be parsed in Hoomans-only conversation")
    print("PASS: Hoomans-only conversation isolated from DT TRADE")
end

print("[P15C] Sequence 3 PASSED.")

-- =========================================================================
-- SEQUENCE 4: Grounded DT Whereabouts, Road News, and Storytelling
-- =========================================================================
print("[P15C] Starting Sequence 4: Grounded DT Whereabouts, Road News, and Storytelling")

DTCommon.Storage = {
    IsAuthority = function() return true end,
}

local traderTestActor = PsychopatzCore.Actors.DefaultRegistry:Create({
    actorId = "actor:dt:grounded_test",
    identitySeed = "seed-grounded-test",
    archetypeID = "trader.resident",
    providerLease = { leaseID = "lease:grounded:1", provider = "DTAbstract", owner = "DynamicTrading" },
})

local testTraderRecord = {
    id = "trader:hotplug:test",
    ca = { actorID = traderTestActor.actorId, providerRevision = 1, role = "trader" },
}

DTCommon.TraderService = DTCommon.TraderService or {}
DTCommon.TraderService.GetRecord = function(id) return testTraderRecord end
DTCommon.TraderService.ValidateTalkAccess = function() return true end

-- 4A: Unseeded whereabouts query returns bounded uncertainty
do
    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "where are you going", {
        mode = "radio",
        requestID = "turn-where-unk",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local replyText = turn.result.responses[1].text
    T.truthy(string.find(replyText, "cannot confirm"), "Unseeded query returns bounded uncertainty")
    print("PASS: Unseeded destination query returns bounded uncertainty: " .. replyText)
end

-- 4B: Seeded destination in production Policy state returns grounded text containing 'Rosewood'
do
    DTPolicy.SetDestinationSettlement(testTraderRecord, "Rosewood Outpost")
    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "where are you going", {
        mode = "radio",
        requestID = "turn-where-grounded",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local replyText = turn.result.responses[1].text
    T.truthy(string.find(replyText, "Rosewood"), "Whereabouts contains grounded destination 'Rosewood'")
    print("PASS: Production-seeded destination query grounded without answer injection: " .. replyText)
end

-- 4C: Seeded origin in production Policy state returns grounded text
do
    DTPolicy.SetOriginSettlement(testTraderRecord, "March Ridge Depot")
    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "where did you come from", {
        mode = "radio",
        requestID = "turn-orig-grounded",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local replyText = turn.result.responses[1].text
    T.truthy(string.find(replyText, "March Ridge Depot"), "Origin contains grounded text 'March Ridge Depot'")
    print("PASS: Production-seeded origin query grounded without answer injection: " .. replyText)
end

-- 4D: Seeded settlement in production Policy state returns grounded text
do
    DTPolicy.SetCurrentSettlement(testTraderRecord, "Riverside Safehouse")
    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "where is the settlement", {
        mode = "radio",
        requestID = "turn-sett-grounded",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local replyText = turn.result.responses[1].text
    T.truthy(string.find(replyText, "Riverside Safehouse"), "Settlement contains grounded text 'Riverside Safehouse'")
    print("PASS: Production-seeded settlement query grounded without answer injection: " .. replyText)
end

-- 4E: Unseeded road news query returns bounded fallback
do
    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "road news", {
        mode = "radio",
        requestID = "turn-no-news",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local replyText = turn.result.responses[1].text
    T.equal(replyText, "I haven't heard any news lately.", "Unseeded road news returns bounded fallback")
    print("PASS: Unseeded road news returns bounded fallback")
end

-- 4F: Grounded road news from real published WorldKnowledge fact
do
    local publishedFact, pubErr = DTCommon.WorldKnowledge.Publish({
        factID = "fact:report_seq4_news",
        kind = "market.event",
        subject = { id = "westpoint", kind = "settlement" },
        payload = {
            eventType = "BANDIT RAID",
            marketID = "westpoint",
        },
    })
    T.truthy(publishedFact, pubErr)
    local acquired, acqErr = DTCommon.WorldKnowledge.Acquire(testTraderRecord.id, "fact:report_seq4_news", {
        authorized = true,
        provenance = "witnessed",
        confidence = 90,
    })
    T.truthy(acquired, acqErr)

    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "road news", {
        mode = "radio",
        requestID = "turn-news-grounded",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local resp = turn.result.responses[1]
    T.equal(resp.evidence, "fact:report_seq4_news", "Exact fact ID attached as evidence")
    T.truthy(string.find(resp.text, "BANDIT RAID"), "Road news grounded in real published WorldKnowledge event")
    print("PASS: Production WorldKnowledge road news query grounded with active report: " .. resp.text)
end

-- 4G: Storytelling returns rich non-factual narrative
do
    local session, sessionReason = DTCommon.TalkService.Open(playerAlice, testTraderRecord.id, "radio")
    T.truthy(session, sessionReason)
    local turn, turnErr = DTCommon.TalkService.Submit(playerAlice, testTraderRecord.id, session.sessionID, "tell me a caravan story", {
        mode = "radio",
        requestID = "turn-story",
    })
    T.truthy(turn and turn.result and turn.result.responses[1], turnErr)
    local replyText = turn.result.responses[1].text
    T.truthy(string.find(replyText, "road") or string.find(replyText, "caravan") or string.find(replyText, "fog"), "Storytelling returned narrative")
    print("PASS: Caravan story returned rich narrative: " .. replyText)
end

print("[P15C] Sequence 4 PASSED.")

-- =========================================================================
-- SEQUENCE 5: Pack Unregister / Re-register Lifecycle Residue Check
-- =========================================================================
print("[P15C] Starting Sequence 5: Pack Unregister / Re-register Lifecycle")

do
    T.truthy(PackRegistry.GetPack("pack.dynamictrading.trader_story") ~= nil, "DT pack initially registered")
    T.truthy(PackRegistry.GetPack("pack.projecthoomans.social_core") ~= nil, "Hoomans pack initially registered")

    -- Unregister DT pack
    local unregOk, unregErr = PackRegistry.UnregisterPack("pack.dynamictrading.trader_story")
    T.truthy(unregOk, unregErr)
    T.falsy(PackRegistry.GetPack("pack.dynamictrading.trader_story") ~= nil, "DT pack unregistered")

    -- Verify no DT patterns remain in registry
    local patterns = Semantics.Registry.GetPatterns()
    for _, pattern in ipairs(patterns or {}) do
        T.falsy(string.find(pattern.id, "^pattern%.trade%."), "No DT patterns remain after unregister: " .. pattern.id)
    end

    -- Re-register DT pack
    DTCommon.SemanticPack.Init()
    T.truthy(PackRegistry.GetPack("pack.dynamictrading.trader_story") ~= nil, "DT pack re-registered cleanly")

    -- Unregister Hoomans pack
    local unregHOk, unregHErr = PackRegistry.UnregisterPack("pack.projecthoomans.social_core")
    T.truthy(unregHOk, unregHErr)
    T.falsy(PackRegistry.GetPack("pack.projecthoomans.social_core") ~= nil, "Hoomans pack unregistered")

    -- Verify no Hoomans patterns remain in registry
    patterns = Semantics.Registry.GetPatterns()
    for _, pattern in ipairs(patterns or {}) do
        T.falsy(string.find(pattern.id, "^hoomans%.pattern%."), "No Hoomans patterns remain after unregister: " .. pattern.id)
    end

    -- Re-register Hoomans pack
    PNC.Semantics.CoreSemanticPack.Register(PsychopatzCore)
    T.truthy(PackRegistry.GetPack("pack.projecthoomans.social_core") ~= nil, "Hoomans pack re-registered cleanly")
    print("PASS: Pack unregister and re-register lifecycle is residue-free")
end

print("[P15C] Sequence 5 PASSED.")

-- =========================================================================
-- SEQUENCE 6: Repeated Migration & Sync Idempotence
-- =========================================================================
print("[P15C] Starting Sequence 6: Repeated Migration & Sync Idempotence")

do
    local actorTest = PsychopatzCore.Actors.DefaultRegistry:Create({
        actorId = "actor:hotplug:idempotence",
        identitySeed = "seed-idempotence",
        archetypeID = "colonist.scout",
        providerLease = { leaseID = "lease:idem:1", provider = "DTHoomans", owner = "ProjectHoomans" },
    })
    local testRecord = {
        id = "npc:idem:1",
        coreActorID = actorTest.actorId,
        alive = true,
        social = {
            morale = 80,
            relationships = {
                [aliceCanonicalKey] = {
                    approval = 40,
                    respect = 30,
                    familiarity = 20,
                    revision = 1,
                    state = "friend",
                    bond = { schemaVersion = 1, class = "friend", stage = "established" },
                    memories = {
                        { id = "mem_idem_1", type = "talk", approvalEffect = 5 },
                    },
                },
            },
        },
    }

    -- Sync 1
    local ok1, err1 = PNC.Persistence.CoreSocial.SyncToCore(testRecord, PsychopatzCore)
    T.truthy(ok1, err1)
    local actorAfter1 = PsychopatzCore.Actors.DefaultRegistry:Get(actorTest.actorId)
    local relAfter1 = Social.Get(actorAfter1.social, aliceCanonicalKey)
    T.equal(relAfter1.approval, 40)
    T.equal(#relAfter1.memories, 1)

    -- Sync 2 (without changes)
    local ok2, err2 = PNC.Persistence.CoreSocial.SyncToCore(testRecord, PsychopatzCore)
    T.truthy(ok2, err2)
    local actorAfter2 = PsychopatzCore.Actors.DefaultRegistry:Get(actorTest.actorId)
    local relAfter2 = Social.Get(actorAfter2.social, aliceCanonicalKey)
    T.equal(relAfter2.approval, 40, "Approval unchanged after repeated sync")
    T.equal(#relAfter2.memories, 1, "Memories not duplicated after repeated sync")

    -- Sync 3 (without changes)
    local ok3, err3 = PNC.Persistence.CoreSocial.SyncToCore(testRecord, PsychopatzCore)
    T.truthy(ok3, err3)
    local actorAfter3 = PsychopatzCore.Actors.DefaultRegistry:Get(actorTest.actorId)
    local relAfter3 = Social.Get(actorAfter3.social, aliceCanonicalKey)
    T.equal(relAfter3.approval, 40)
    T.equal(#relAfter3.memories, 1)
    print("PASS: Repeated sync is completely idempotent without memory duplication or score inflation")
end

print("[P15C] Sequence 6 PASSED.")

T.finish("pnc_real_cross_adopter_hotplug_matrix_smoke")
