-- Bounded interaction provider/adaptor projections.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local Evidence = require "PNC/Semantics/PNC_SemanticInteractionEvidence"
local Providers = PNC.Semantics.InteractionProviders or {}
PNC.Semantics.InteractionProviders = Providers

Providers.VERSION = 1
Providers.MAX_ADAPTERS = 16
Providers.MAX_TAGS = 16
Providers.MAX_KNOWLEDGE_REFS = 16
Providers.NormalizeEvidence = Evidence.Normalize
Providers.RegisterEvidenceAdapter = Evidence.Register
Providers.QueryEvidence = Evidence.Query
function Providers.EvidenceQueryForStimulus(stimulus)
    local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"
    local semantic = type(stimulus) == "table" and stimulus.semantic or {}
    local metadata = Relations.GetAct(semantic and (semantic.speechAct or semantic.intent))
    local wanted, seen = {}, {}
    for _, kind in ipairs({ "addresses", "resolves", "violates", "explains" }) do
        for _, relation in ipairs(metadata and metadata.relations[kind] or {}) do
            if not seen[relation] and #wanted < 8 then
                wanted[#wanted + 1], seen[relation] = relation, true
            end
        end
    end
    return #wanted > 0 and { relations = wanted } or nil
end

local adapters = {}

local function text(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    if #value > maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function unit(value)
    value = finite(value)
    if value == nil then return nil end
    return math.max(0, math.min(1, value))
end

local function booleanOrNil(value)
    if type(value) == "boolean" then return value end
    return nil
end

local function boundedTags(value)
    local output = {}
    if type(value) ~= "table" then return output end
    local seen = {}
    for key, enabled in pairs(value) do
        local raw = enabled == true and key
            or type(enabled) == "string" and enabled
            or type(key) == "number" and enabled
            or nil
        local tag = text(raw, 64)
        if tag and not seen[tag] and #output < Providers.MAX_TAGS then
            seen[tag] = true
            output[#output + 1] = tag
        end
    end
    table.sort(output)
    return output
end

local function normalizeCapabilities(value)
    value = type(value) == "table" and value or {}
    local output = {}
    for _, key in ipairs({ "speech", "emote", "movement", "gameplayIntent" }) do
        if type(value[key]) == "boolean" then output[key] = value[key] end
    end
    return output
end

function Providers.NormalizeActor(value, providerID)
    value = type(value) == "table" and value or {}
    local disposition = type(value.disposition) == "table"
        and value.disposition or {}
    local condition = type(value.condition) == "table"
        and value.condition or {}
    local activity = type(value.activity) == "table"
        and value.activity or {}
    local output = {
        schemaVersion = Providers.VERSION,
        providerID = text(providerID or value.providerID, 128) or "unknown",
        id = text(value.id, 128),
        capabilities = normalizeCapabilities(value.capabilities),
        disposition = {},
        condition = {},
        activity = {
            currentTask = text(activity.currentTask, 96),
            idle = booleanOrNil(activity.idle),
        },
        traits = boundedTags(value.traits),
    }
    for _, key in ipairs({
        "aggression", "confidence", "forgiveness",
        "sociability", "empathy", "riskTolerance",
    }) do
        output.disposition[key] = unit(disposition[key])
    end
    for _, key in ipairs({
        "panic", "stress", "injury", "hunger", "thirst", "fatigue",
    }) do
        output.condition[key] = unit(condition[key])
    end
    return output
end

function Providers.NormalizeRelationship(value, providerID)
    value = type(value) == "table" and value or {}
    local output = {
        schemaVersion = Providers.VERSION,
        providerID = text(providerID, 128) or "unknown",
        state = text(value.state or value.relationshipState, 64),
        factionRelation = text(value.factionRelation, 64),
        tags = boundedTags(value.tags),
    }
    for _, key in ipairs({ "familiarity", "approval", "trust", "respect" }) do
        local numeric = finite(value[key])
        if numeric ~= nil then output[key] = numeric end
    end
    return output
end

function Providers.NormalizeWorld(value, providerID)
    value = type(value) == "table" and value or {}
    return {
        schemaVersion = Providers.VERSION,
        providerID = text(providerID, 128) or "unknown",
        immediateDanger = booleanOrNil(value.immediateDanger),
        powerStatus = text(value.powerStatus, 32),
        waterStatus = text(value.waterStatus, 32),
        weather = text(value.weather, 64),
        season = text(value.season, 32),
        timeOfDay = text(value.timeOfDay, 32),
        locationType = text(value.locationType, 64),
        zombiePressure = text(value.zombiePressure, 32),
        nearbyZombieCount = finite(value.nearbyZombieCount),
        hordeZombieCount = finite(value.hordeZombieCount),
        tacticalHorde = booleanOrNil(value.tacticalHorde),
        worldAgeHours = finite(value.worldAgeHours),
    }
end

function Providers.NormalizeKnowledge(value, providerID)
    value = type(value) == "table" and value or {}
    local refs = {}
    local source = type(value.factRefs) == "table" and value.factRefs or {}
    for index = 1, math.min(#source, Providers.MAX_KNOWLEDGE_REFS) do
        local id = text(source[index], 128)
        if id then refs[#refs + 1] = id end
    end
    return {
        schemaVersion = Providers.VERSION,
        providerID = text(providerID, 128) or "unknown",
        available = value.available == true,
        factRefs = refs,
        factCount = math.max(0, math.floor(finite(value.factCount) or #refs)),
    }
end

local function urgencyPanic(emotion)
    emotion = type(emotion) == "table" and emotion or {}
    if tostring(emotion.highest or "") ~= "panic" then return 0 end
    local urgency = tostring(emotion.urgency or "stable")
    if urgency == "emergency" then return 1 end
    if urgency == "critical" then return 0.85 end
    if urgency == "low" then return 0.6 end
    return 0
end

local function immediateDanger(context)
    local situation = type(context.dialogueSituation) == "table"
        and context.dialogueSituation or {}
    local npc = type(situation.npc) == "table" and situation.npc or {}
    if npc.inCombat == true then return true end
    local zombieObservation = type(context.zombieObservation) == "table"
        and context.zombieObservation or {}
    if zombieObservation.tacticalHorde == true then return true end
    local tactical = type(context.tacticalHostility) == "table"
        and context.tacticalHostility or {}
    if tactical.attackPlayers == true then return true end
    local state = type(context.npcState) == "table" and context.npcState or {}
    local active = tostring(state.activeBehavior or "")
    return active == "combat" or active == "hostile"
        or active == "flee" or active == "fleeing"
end

local function relationshipSource(context)
    if type(context.relationship) == "table" then return context.relationship end
    if type(context.personalRelationship) == "table" then
        return context.personalRelationship
    end
    local social = type(context.socialContext) == "table"
        and context.socialContext or {}
    return type(social.personalRelationship) == "table"
        and social.personalRelationship or {}
end

function Providers.ProjectDialogue(context, evidenceQuery)
    context = type(context) == "table" and context or {}
    local personality = type(context.npcPersonality) == "table"
        and context.npcPersonality or {}
    local state = type(context.npcState) == "table" and context.npcState or {}
    local needs = type(state.needs) == "table" and state.needs or {}
    local situation = type(context.dialogueSituation) == "table"
        and context.dialogueSituation or {}
    local situationNPC = type(situation.npc) == "table"
        and situation.npc or {}
    local entry = type(context.entry) == "table" and context.entry or {}
    local snapshot = type(entry.snapshot) == "table" and entry.snapshot or {}
    local knowledge = type(snapshot.knowledge) == "table"
        and snapshot.knowledge or nil
    local relationship = relationshipSource(context)
    local worldContext = type(context.worldContext) == "table"
        and context.worldContext or {}

    local actor = Providers.NormalizeActor({
        id = context.npcID or entry.id or "dialogue.npc",
        capabilities = {
            speech = true,
            emote = true,
        },
        disposition = personality,
        condition = {
            panic = urgencyPanic(situationNPC.emotion),
            stress = unit(
                type(state.conditionStats) == "table"
                    and state.conditionStats.stress or nil
            ),
            hunger = unit(needs.hunger),
            thirst = unit(needs.thirst),
            fatigue = unit(needs.fatigue),
        },
        activity = {
            currentTask = state.activeBehavior or state.orderKind
                or situationNPC.activity and situationNPC.activity.id,
            idle = (state.activeBehavior == nil or state.activeBehavior == "idle")
                and (state.orderKind == nil or state.orderKind == "idle"),
        },
        traits = context.npcTraits or state.traits,
    }, "projecthoomans.dialogue_context")

    local relation = Providers.NormalizeRelationship({
        state = context.relationshipState,
        familiarity = relationship.familiarity,
        approval = relationship.approval,
        trust = relationship.trust or context.identityTrust,
        respect = relationship.respect,
        factionRelation = context.factionRelationship
            and context.factionRelationship.state,
    }, "projecthoomans.relationship")

    local zombieObservation = type(context.zombieObservation) == "table"
        and context.zombieObservation or {}
    local world = Providers.NormalizeWorld({
        immediateDanger = immediateDanger(context),
        worldAgeHours = worldContext.worldAgeHours,
        powerStatus = context.powerStatus,
        waterStatus = context.waterStatus,
        weather = context.weather,
        season = context.season,
        timeOfDay = context.timeOfDay,
        locationType = context.locationType,
        zombiePressure = context.zombiePressure or zombieObservation.band,
        nearbyZombieCount = zombieObservation.nearbyCount,
        hordeZombieCount = zombieObservation.hordeCount,
        tacticalHorde = zombieObservation.tacticalHorde,
    }, "projectzomboid.world")

    local knowledgeProjection = Providers.NormalizeKnowledge({
        available = knowledge ~= nil,
        factCount = knowledge and #knowledge or 0,
    }, "projecthoomans.knowledge")

    return {
        schemaVersion = Providers.VERSION,
        actor = actor,
        relationship = relation,
        world = world,
        knowledge = knowledgeProjection,
        evidence = Evidence.Query(context, evidenceQuery or context.evidenceQuery),
        provenance = {
            actor = actor.providerID,
            relationship = relation.providerID,
            world = world.providerID,
            knowledge = knowledgeProjection.providerID,
        },
    }
end

function Providers.RegisterActorAdapter(spec)
    if type(spec) ~= "table" then return false, "adapter_invalid" end
    local id = text(spec.id, 128)
    if not id then return false, "adapter_id_invalid" end
    local projectActor = spec.ProjectActor or spec.Project
    if type(spec.CanAdapt) ~= "function"
        or type(projectActor) ~= "function"
    then
        return false, "adapter_contract_invalid"
    end
    for index = 1, #adapters do
        if adapters[index].id == id then
            return false, "adapter_duplicate:" .. id
        end
    end
    if #adapters >= Providers.MAX_ADAPTERS then
        return false, "adapter_limit"
    end
    adapters[#adapters + 1] = {
        id = id,
        priority = tonumber(spec.priority) or 0,
        CanAdapt = spec.CanAdapt,
        ProjectActor = projectActor,
        ProjectRelationship = spec.ProjectRelationship,
        ProjectKnowledge = spec.ProjectKnowledge,
    }
    table.sort(adapters, function(left, right)
        if left.priority == right.priority then return left.id < right.id end
        return left.priority > right.priority
    end)
    return true, id
end

local function adapterFor(actor, context)
    for index = 1, #adapters do
        local adapter = adapters[index]
        local ok, matches = pcall(adapter.CanAdapt, actor, context)
        if ok and matches == true then return adapter end
    end
    return nil
end

function Providers.ProjectExternalActor(actor, context)
    local adapter = adapterFor(actor, context)
    if not adapter then return nil, "actor_adapter_unavailable" end
    local projectedOK, value = pcall(adapter.ProjectActor, actor, context)
    if not projectedOK or type(value) ~= "table" then
        return nil, "adapter_projection_failed:" .. adapter.id
    end
    return Providers.NormalizeActor(value, adapter.id)
end

function Providers.ProjectExternalContext(actor, otherActor, context)
    local adapter = adapterFor(actor, context)
    if not adapter then return nil, "actor_adapter_unavailable" end
    local projectedOK, actorValue = pcall(
        adapter.ProjectActor, actor, context
    )
    if not projectedOK or type(actorValue) ~= "table" then
        return nil, "adapter_projection_failed:" .. adapter.id
    end
    local relationshipValue = {}
    if type(adapter.ProjectRelationship) == "function" then
        local ok, value = pcall(
            adapter.ProjectRelationship,
            actor,
            otherActor,
            context
        )
        if not ok then
            return nil, "adapter_relationship_failed:" .. adapter.id
        end
        if type(value) == "table" then relationshipValue = value end
    end
    local knowledgeValue = { available = false }
    if type(adapter.ProjectKnowledge) == "function" then
        local ok, value = pcall(
            adapter.ProjectKnowledge,
            actor,
            context
        )
        if not ok then
            return nil, "adapter_knowledge_failed:" .. adapter.id
        end
        if type(value) == "table" then knowledgeValue = value end
    end
    return {
        schemaVersion = Providers.VERSION,
        actor = Providers.NormalizeActor(actorValue, adapter.id),
        evidence = Evidence.Query(context, type(context) == "table" and context.evidenceQuery),
        relationship = Providers.NormalizeRelationship(
            relationshipValue, adapter.id
        ),
        knowledge = Providers.NormalizeKnowledge(
            knowledgeValue, adapter.id
        ),
        provenance = {
            actor = adapter.id,
            relationship = type(adapter.ProjectRelationship) == "function"
                and adapter.id or "unknown",
            knowledge = type(adapter.ProjectKnowledge) == "function"
                and adapter.id or "unknown",
        },
    }
end

function Providers.AdapterIDs()
    local output = {}
    for index = 1, #adapters do output[index] = adapters[index].id end
    return output
end

local EvidenceAdapters = require "PNC/Semantics/PNC_SemanticInteractionEvidenceAdapters"
EvidenceAdapters.Install(Providers)
return Providers
