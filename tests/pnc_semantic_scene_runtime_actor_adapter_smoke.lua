local T = require "tests/support/test"
T.addPackagePaths()

local factID = "fact.scene.runtime.adapter"
local records = {
    ["npc-a"] = {
        id = "npc-a",
        alive = true,
        personality = {
            aggression = 0.8,
            bravery = 0.7,
            compassion = 0.2,
            sociability = 0.9,
            forgiveness = 0.3,
        },
        npcTraits = { pnc_brave = true, pnc_loud = true },
        conditionStats = { stress = 0.25, panic = 40 },
        needs = { hunger = 0.2, thirst = 0.3, fatigue = 0.4 },
        activeBehavior = "Guard",
        affiliation = { factionID = "faction-red" },
        social = {
            relationships = {
                ["npc:npc-b"] = {
                    state = "friendly",
                    familiarity = 8,
                    approval = 35,
                    respect = 20,
                },
            },
        },
        knowledge = { factRefs = { factID } },
    },
    ["npc-b"] = {
        id = "npc-b",
        alive = true,
        personality = {
            aggression = 0.2,
            bravery = 0.35,
            compassion = 0.9,
            sociability = 0.4,
            forgiveness = 0.8,
        },
        npcTraits = { pnc_cautious = true },
        conditionStats = { stress = 0.1, panic = 10 },
        needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.2 },
        activeBehavior = "idle",
        affiliation = { factionID = "faction-blue" },
        social = {
            relationships = {
                ["npc:npc-a"] = {
                    state = "guarded",
                    familiarity = 3,
                    approval = -15,
                    respect = 45,
                },
            },
        },
        knowledge = { factRefs = {} },
    },
    ["npc-dead"] = {
        id = "npc-dead",
        alive = false,
    },
}

PNC = {
    Registry = {
        Get = function(id) return records[tostring(id or "")] end,
    },
    RelationshipGraph = {
        ResolveNPCPersonality = function(record)
            return record.personality or {}
        end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Relationships = {
        Get = function(observerID, targetKey)
            local record = records[observerID]
            return record and record.social
                and record.social.relationships
                and record.social.relationships[targetKey] or nil
        end,
    },
    Factions = {
        GetFactionID = function(record)
            return record and record.affiliation
                and record.affiliation.factionID or nil
        end,
        GetRelation = function(left, right)
            if left == "faction-red" and right == "faction-blue" then
                return { state = "hostile" }
            end
            if left == "faction-blue" and right == "faction-red" then
                return { state = "fearful" }
            end
            return nil
        end,
    },
    WorldKnowledge = {
        BuildConversationContext = function(record)
            return {
                npcGossip = {
                    factRefs = record and record.knowledge
                        and record.knowledge.factRefs or {},
                },
            }
        end,
    },
}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Adapter = require
    "PNC/Semantics/PNC_SemanticInteractionActorAdapter_ProjectHoomans"
local Scene = require "PNC/Semantics/PNC_SemanticInteractionScene"

local installed = false
for _, id in ipairs(Providers.AdapterIDs()) do
    if id == "projecthoomans.managed_npc" then installed = true end
end
T.truthy(installed, "production Project Hoomans actor adapter auto-installs")

local again, againReason = Adapter.Install(Providers)
T.truthy(again, "production actor adapter install is idempotent")
T.equal(againReason, "already_installed",
    "duplicate installation returns stable reason")

local aToB, aReason = Providers.ProjectExternalContext(
    records["npc-a"],
    records["npc-b"],
    {}
)
T.truthy(aToB, aReason or "managed NPC A projects")
T.equal(aToB.actor.id, "npc-a", "managed NPC identity projects")
T.equal(aToB.actor.disposition.aggression, 0.8,
    "aggression comes from canonical personality")
T.equal(aToB.actor.disposition.confidence, 0.7,
    "bravery projects into generic confidence")
T.equal(aToB.actor.disposition.empathy, 0.2,
    "compassion projects into generic empathy")
T.equal(aToB.actor.condition.stress, 0.25,
    "normalized stress remains unit-scaled")
T.equal(aToB.actor.condition.panic, 0.4,
    "0-100 panic projects into generic unit scale")
T.equal(aToB.actor.condition.fatigue, 0.4,
    "needs project into generic actor condition")
T.equal(aToB.actor.activity.currentTask, "Guard",
    "current behavior projects without mutation")
T.truthy(aToB.actor.traits[1] ~= nil,
    "bounded traits project through common actor normalization")
T.equal(aToB.relationship.state, "friendly",
    "directed personal relationship projects")
T.equal(aToB.relationship.approval, 35,
    "directed approval projects")
T.equal(aToB.relationship.factionRelation, "hostile",
    "directed faction relation projects")
T.equal(aToB.knowledge.factRefs[1], factID,
    "known fact refs project from existing knowledge authority")
T.equal(aToB.provenance.actor, "projecthoomans.managed_npc",
    "actor projection provenance is inspectable")

local bToA, bReason = Providers.ProjectExternalContext(
    records["npc-b"],
    records["npc-a"],
    {}
)
T.truthy(bToA, bReason or "managed NPC B projects")
T.equal(bToA.relationship.state, "guarded",
    "reverse relationship remains asymmetric")
T.equal(bToA.relationship.approval, -15,
    "reverse approval remains asymmetric")
T.equal(bToA.relationship.factionRelation, "fearful",
    "reverse faction relation remains asymmetric")

local dead, deadReason = Providers.ProjectExternalContext(
    records["npc-dead"],
    records["npc-a"],
    {}
)
T.equal(dead, nil, "dead managed NPC fails closed")
T.equal(deadReason, "actor_adapter_unavailable",
    "dead NPC cannot enter production scene adapter")

local unmanaged = { id = "npc-unmanaged", alive = true }
local missing, missingReason = Providers.ProjectExternalContext(
    unmanaged,
    records["npc-a"],
    {}
)
T.equal(missing, nil, "unregistered table does not masquerade as managed NPC")
T.equal(missingReason, "actor_adapter_unavailable",
    "only canonical registry record can use production adapter")

local scene, sceneReason = Scene.New({
    id = "scene.production.adapter",
    participants = {
        { id = "npc-a", actor = records["npc-a"] },
        { id = "npc-b", actor = records["npc-b"] },
    },
    perceived = true,
    distance = 8,
    topic = "FORMER_JOB",
})
T.truthy(scene, sceneReason or "real managed NPC records enter scene")
local result, resultReason = scene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    topic = "FORMER_JOB",
    factID = factID,
})
T.truthy(result, resultReason or "production-adapted NPC semantic turn resolves")
T.equal(result.stimulus.source.actorID, "npc-a",
    "scene stimulus preserves managed source identity")
T.equal(result.stimulus.targets[1], "npc-b",
    "scene stimulus preserves managed recipient identity")
T.equal(result.interactionPlan.groundedFactRefs[1], factID,
    "scene remains grounded in projected knowledge")
T.falsy(scene:Snapshot().transcriptStored,
    "production adapter introduces no transcript persistence")

T.finish("pnc_semantic_scene_runtime_actor_adapter_smoke")
