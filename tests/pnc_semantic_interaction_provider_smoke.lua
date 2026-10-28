local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Predicate = require "PNC/Semantics/PNC_SemanticPredicate"
local SuggestionPredicates = require
    "PNC/Semantics/PNC_SemanticDialogueSuggestionPredicates"
local Stimulus = require "PNC/Semantics/PNC_SemanticInteractionStimulus"
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"

T.truthy(Predicate == SuggestionPredicates,
    "suggestions and interactions share one semantic predicate contract")

local stimulus, stimulusReason = Stimulus.Normalize({
    type = "NPC_SEMANTIC_ACT",
    source = {
        kind = "npc",
        actorID = "third-party-a",
        providerID = "third.party.test",
    },
    targets = { "third-party-b" },
    semantic = {
        intent = "SHARE_MEMORY",
        speechAct = "DISCLOSE",
        topic = "FORMER_JOB",
        factID = "fact.former_job.mechanic",
    },
})
T.truthy(stimulus, stimulusReason or "semantic stimulus validates")
T.equal(stimulus.type, "NPC_SEMANTIC_ACT",
    "NPC semantic acts use the same typed stimulus contract")
T.equal(stimulus.semantic.factID, "fact.former_job.mechanic",
    "typed stimulus carries grounded fact identity without wording")

local invalid = Stimulus.Normalize({ type = "NOT_A_REAL_STIMULUS" })
T.falsy(invalid, "unknown stimulus types are rejected")

local contextProjection = Providers.ProjectDialogue({
    npcID = "mara",
    npcPersonality = {
        aggression = 0.8,
        confidence = 0.7,
        forgiveness = 0.3,
    },
    npcState = {
        activeBehavior = "idle",
        orderKind = "idle",
        needs = {
            hunger = 0.25,
            thirst = 0.4,
            fatigue = 0.2,
        },
        conditionStats = {
            stress = 0.1,
        },
        traits = {
            Brave = true,
        },
    },
    relationshipState = "guarded",
    relationship = {
        familiarity = 2,
        approval = -10,
        respect = 5,
    },
    worldContext = {
        worldAgeHours = 120,
    },
    dialogueSituation = {
        npc = {
            inCombat = false,
            emotion = {
                highest = "panic",
                urgency = "critical",
            },
        },
    },
    entry = {
        id = "mara",
        snapshot = {
            knowledge = {},
        },
    },
})
T.equal(contextProjection.actor.id, "mara",
    "Project Hoomans projects into the generic actor contract")
T.equal(contextProjection.actor.disposition.aggression, 0.8,
    "normalized actor keeps grounded aggression")
T.equal(contextProjection.actor.condition.panic, 0.85,
    "production situation panic is normalized")
T.equal(contextProjection.relationship.familiarity, 2,
    "relationship projection stays independent of actor implementation")
T.equal(contextProjection.world.immediateDanger, false,
    "explicit false world state is preserved rather than becoming unknown")
T.equal(contextProjection.provenance.actor,
    "projecthoomans.dialogue_context",
    "provider provenance identifies the Project Hoomans adapter seam")

local unknownActor = Providers.NormalizeActor({
    id = "minimal",
}, "synthetic.minimal")
T.truthy(unknownActor.disposition.aggression == nil,
    "missing disposition stays unknown")
T.truthy(unknownActor.condition.panic == nil,
    "missing condition stays unknown")
T.truthy(unknownActor.capabilities.speech == nil,
    "missing capability stays unknown")

local registered, adapterID = Providers.RegisterActorAdapter({
    id = "synthetic.third_party",
    priority = 10,
    CanAdapt = function(actor)
        return type(actor) == "table"
            and actor.system == "third-party"
    end,
    ProjectActor = function(actor)
        return {
            id = actor.id,
            capabilities = {
                speech = actor.canSpeak,
                emote = actor.canEmote,
            },
            disposition = {
                aggression = actor.temper,
                confidence = actor.courage,
            },
            condition = {
                panic = actor.fear,
            },
            activity = {
                currentTask = actor.task,
                idle = actor.task == "idle",
            },
            traits = actor.tags,
        }
    end,
    ProjectRelationship = function(actor, other)
        return {
            familiarity = actor.familiarityByID
                and actor.familiarityByID[other.id],
            approval = actor.approvalByID
                and actor.approvalByID[other.id],
        }
    end,
    ProjectKnowledge = function(actor)
        return {
            available = true,
            factRefs = actor.factRefs,
        }
    end,
})
T.truthy(registered, adapterID or "synthetic adapter registers")

local external, externalReason = Providers.ProjectExternalContext(
    {
        system = "third-party",
        id = "npc-a",
        canSpeak = true,
        canEmote = false,
        temper = 0.9,
        courage = 0.6,
        fear = 0.15,
        task = "idle",
        tags = { "outsider" },
        familiarityByID = { ["npc-b"] = 4 },
        approvalByID = { ["npc-b"] = -20 },
        factRefs = { "fact.former_job.mechanic" },
    },
    { id = "npc-b" },
    {}
)
T.truthy(external, externalReason or "third-party projection succeeds")
T.equal(external.actor.id, "npc-a",
    "third-party actor uses the common actor snapshot")
T.equal(external.actor.disposition.aggression, 0.9,
    "third-party trait model normalizes to common disposition")
T.equal(external.actor.capabilities.speech, true,
    "third-party speech capability is explicit")
T.equal(external.actor.capabilities.emote, false,
    "third-party false capability remains false")
T.equal(external.relationship.familiarity, 4,
    "third-party relationship uses the common relationship snapshot")
T.equal(external.knowledge.factRefs[1],
    "fact.former_job.mechanic",
    "third-party knowledge retains grounded semantic fact identity")
T.equal(external.provenance.actor, "synthetic.third_party",
    "third-party projection provenance is inspectable")

local predicate = Predicate.Evaluate({
    all = {
        {
            path = "actor.disposition.aggression",
            op = "gte",
            value = 0.8,
        },
        {
            path = "actor.capabilities.speech",
            op = "truthy",
        },
    },
}, external)
T.truthy(predicate.allowed,
    "common predicates evaluate third-party normalized state")

local privateResult = Predicate.Evaluate({
    path = "actor.secret.plan",
    op = "exists",
}, external)
T.equal(privateResult.status, "private",
    "shared predicate refuses private fields")

T.finish("pnc_semantic_interaction_provider_smoke")
