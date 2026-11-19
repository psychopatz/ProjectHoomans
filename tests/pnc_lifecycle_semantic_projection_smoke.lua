local T = require "tests/support/test"
T.addPackagePaths()

local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = CoreActors.Social
local SocialQuery = CoreActors.SocialQuery
local GC = CoreActors.GC

local worldHours = 300
local nowMs = 5000
getGameTime = function()
    return { getWorldAgeHours = function() return worldHours end }
end
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnServerStarted = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = { Add = function() end },
}
local modDataStore = {}
ModData = {
    getOrCreate = function(k)
        modDataStore[k] = modDataStore[k] or {}
        return modDataStore[k]
    end,
    transmit = function() end,
}
isServer = function() return true end
isClient = function() return false end

local reg = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = reg
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local liveRecords = {}
local deathMarkers = {}
PNC = {
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do out[k] = PNC.Core.DeepCopy(val) end
            return out
        end,
        Log = function() end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    Registry = {
        Data = liveRecords,
        DeathMarkers = deathMarkers,
        Get = function(id) return liveRecords[tostring(id or "")] end,
        List = function()
            local out = {}
            for _, v in pairs(liveRecords) do out[#out + 1] = v end
            return out
        end,
    },
    PlayerContext = {
        Resolve = function()
            return { characterUUID = "char_h4_hero" }
        end,
    },
    PlayerCharacters = {
        EnsureLoaded = function() end,
        Get = function(uuid) return PNC.PlayerCharacters.Registry.byUUID[uuid] end,
        Registry = {
            byUUID = {
                ["char_h4_hero"] = {
                    uuid = "char_h4_hero",
                    accountKey = "acc_h4",
                    status = "active",
                },
            },
        },
        GetEntityKey = function()
            return "player:acc_h4:char_h4_hero"
        end,
        GetCharacterUUID = function()
            return "char_h4_hero"
        end,
    },
    Relationships = {
        Get = function(npcID, targetKey)
            local rec = liveRecords[tostring(npcID)]
            return rec and rec.social and rec.social.relationships
                and rec.social.relationships[targetKey] or nil
        end,
    },
    KnowledgeDescriptors = {
        Get = function(id) return { id = id, category = "identity", valueType = "string" } end,
    },
    KnowledgeRegistry = {
        EnsureLoaded = function() return { records = {} } end,
        Get = function() return nil end,
        GetState = function() return { schemaVersion = 1, byPlayer = {} } end,
    },
    KnowledgeProviders = {},
    KnowledgeResolvers = {},
    KnowledgeEvidenceSources = {},
}

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
T.load(SHARED .. "Relationships/PNC_RecruitmentPersonalityPolicy.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipGraph.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipPresentation.lua")
T.load(SHARED .. "Persistence/PNC_Persistence_CoreSocial.lua")
T.load(SHARED .. "Persistence/PNC_Persistence_CoreLifecycle.lua")
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Core"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Normalization"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Persistence"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_Resolution"
require "PNC/Knowledge/NPCKnowledgeService/PNC_NPCKnowledgeService_PlayerSnapshots"

PNC.Persistence.CoreLifecycle.EnsureGCProvider({ Actors = CoreActors })
CoreActors.PlayerIdentity.RegisterIssuedIdentity("char_h4_hero", "acc_h4", {
    authority = "server",
    displayName = "Hero",
})

-- Create actors: Speaker Elena (LIVE), Deceased Named Owen (RETIRED), Purged Companion Quinn (FORGOTTEN)
local elenaActor = assert(reg:Create({
    actorId = "npc:hoom:elena",
    ownerMod = "ProjectHoomans",
    identitySeed = "elena",
    identity = { displayName = "Elena Vance", role = "medic" },
}))
assert(reg:Create({
    actorId = "npc:hoom:owen",
    ownerMod = "ProjectHoomans",
    identitySeed = "owen",
    identity = { displayName = "Owen Marsh", role = "guard" },
}))
assert(reg:Create({
    actorId = "npc:hoom:quinn",
    ownerMod = "ProjectHoomans",
    identitySeed = "quinn",
    identity = { displayName = "Quinn Frost", role = "companion" },
}))

-- Verify H3: ToCoreSocial persists exclusively to memoryBank (zero rel.memories)
local elenaHoomans = {
    id = "npc:hoom:elena",
    coreActorID = "npc:hoom:elena",
    displayName = "Elena Vance",
    alive = true,
    social = {
        revision = 2,
        personality = { sociability = 0.8 },
        relationships = {
            ["player:acc_h4:char_h4_hero"] = {
                target = "player:acc_h4:char_h4_hero",
                approval = 45,
                respect = 30,
                familiarity = 50,
                revision = 3,
                memories = {
                    {
                        id = "mem:hoom:hero_heal",
                        type = "treated_wound",
                        retentionClass = "LONG",
                        refStrength = "WEAK",
                        salience = 70,
                        createdAt = worldHours - 2,
                    },
                },
            },
            ["npc:hoom:owen"] = {
                target = "npc:hoom:owen",
                approval = 55,
                respect = 40,
                familiarity = 60,
                revision = 2,
                memories = {
                    {
                        id = "mem:hoom:owen_saved",
                        type = "saved_from_incapacitation",
                        retentionClass = "ANCHOR",
                        refStrength = "STRONG",
                        salience = 95,
                        createdAt = worldHours - 10,
                    },
                },
            },
            ["npc:hoom:quinn"] = {
                target = "npc:hoom:quinn",
                approval = 20,
                respect = 15,
                familiarity = 25,
                historicalLabel = "former_companion",
                degradedLabel = "former_companion",
                revision = 1,
                memories = {
                    {
                        id = "mem:hoom:quinn_patrol",
                        type = "shared_ration",
                        retentionClass = "LONG",
                        refStrength = "LABEL_ONLY",
                        degradedLabel = "former_companion",
                        salience = 50,
                        createdAt = worldHours - 120,
                    },
                },
            },
        },
    },
}
liveRecords[elenaHoomans.id] = elenaHoomans

local coreSocial = assert(PNC.Persistence.CoreSocial.ToCoreSocial(elenaHoomans.social, PsychopatzCore))
for _, rel in pairs(coreSocial.relationships) do
    T.equal(rel.memories, nil, "H3Core memoryBank migration removes persisted rel.memories")
end
assert(reg:Commit(elenaActor.actorId, { social = coreSocial }, elenaActor.revision))

-- Verify H4 (Presentation): O(1) lifecycle projection without GC
local genBefore = (reg.gcMeta and reg.gcMeta.generation) or 0
local convSummary = assert(PNC.RelationshipPresentation.BuildForConversation(
    { getUsername = function() return "acc_h4" end },
    elenaHoomans.id
))
T.equal(convSummary.lifecycleStatus, "LIVE", "Presentation attaches speaker lifecycleStatus")
T.equal(convSummary.lifecycleRevision, 1, "Presentation attaches speaker lifecycleRevision")
T.equal(convSummary.targetLifecycleStatus, "LIVE", "Presentation attaches live player lifecycleStatus")
T.equal((reg.gcMeta and reg.gcMeta.generation) or 0, genBefore,
    "Presentation build never runs GC")

-- Retire Owen (ANCHOR STRONG -> stays RETIRED) & Quinn (WEAK -> purges FORGOTTEN)
assert(reg:Retire("npc:hoom:owen", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours - 10,
    graceHours = 12,
    label = "Owen Marsh",
    role = "guard",
}))
deathMarkers["npc:hoom:owen"] = {
    id = "npc:hoom:owen",
    name = "Owen Marsh",
    reason = "bitten",
    hoursAt = worldHours - 10,
}
assert(reg:Retire("npc:hoom:quinn", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours - 100,
    graceHours = 12,
    label = "Quinn Frost",
    role = "companion",
}))

GC.RunFull(reg, { authority = "server", now = worldHours })
T.equal(reg:GetLifecycleState("npc:hoom:owen"), "RETIRED", "strong bond keeps Owen named RETIRED")
T.equal(reg:GetLifecycleState("npc:hoom:quinn"), "FORGOTTEN", "weak unpinned Quinn purges FORGOTTEN")

-- Verify Core SocialQuery & historical knowledge snapshots across LIVE / RETIRED / FORGOTTEN
local ctxOwen = assert(SocialQuery.OpenInteractionHotContext(reg, "npc:hoom:elena", "npc:hoom:owen", {
    now = worldHours,
}))
T.equal(ctxOwen.targetIdentity.referenceMode, "HISTORICAL_NAMED")
T.equal(ctxOwen.targetIdentity.displayName, "Owen Marsh")
T.equal(ctxOwen.targetIdentity.recentlyDead, true)

local ctxQuinn = assert(SocialQuery.OpenInteractionHotContext(reg, "npc:hoom:elena", "npc:hoom:quinn", {
    now = worldHours,
    degradedLabel = "former_companion",
}))
T.equal(ctxQuinn.targetIdentity.referenceMode, "LABEL_ONLY")
T.equal(ctxQuinn.targetIdentity.displayName, nil)
T.equal(ctxQuinn.targetIdentity.degradedLabel, "former_companion")

local quinnPlan = assert(SocialQuery.ExecutePlan(reg, "npc:hoom:elena", {
    eventTypes = { "shared_ration" },
    maxMemories = 4,
}, { now = worldHours }))
T.equal(#quinnPlan.memories, 1, "LABEL_ONLY companion memory survives GC purge")
T.equal(quinnPlan.memories[1].targetReference.referenceMode, "LABEL_ONLY")
T.equal(quinnPlan.memories[1].targetReference.degradedLabel, "former_companion")

-- Stale lifecycle revision check
local staleToken = ctxOwen.decisionToken
staleToken.actorLifecycleRevision = 99
local tokOK, tokReason = SocialQuery.ValidateDecisionToken(reg, staleToken)
T.falsy(tokOK, "stale actorLifecycleRevision token must reject")
T.equal(tokReason, "lifecycle_revision_conflict")

-- PlayerSnapshots historical identity degradation
local playerObj = { getUsername = function() return "acc_h4" end }
local snapOwen = assert(PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(playerObj, "npc:hoom:owen"))
T.equal(snapOwen.historical, true, "knowledge snapshot marked historical")
T.equal(snapOwen.lifecycleStatus, "RETIRED", "knowledge snapshot preserves RETIRED status")
T.equal(snapOwen.identity.displayName, "Owen Marsh", "knowledge snapshot preserves retired displayName")
local snapQuinn, snapQuinnErr = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(playerObj, "npc:hoom:quinn")
T.equal(snapQuinn, nil, "purged unknown npc returns clean forgotten/not_found error")
T.truthy(snapQuinnErr == "npc_forgotten" or snapQuinnErr == "npc_not_found")

T.finish("pnc_lifecycle_semantic_projection_smoke")
