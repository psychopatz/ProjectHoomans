-- Production Project Hoomans actor adapter for generic semantic scenes.
-- Read-only projection only: no registry, relationship, faction, knowledge or
-- gameplay mutation is owned here.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Adapter = PNC.Semantics.InteractionActorAdapterProjectHoomans or {}
PNC.Semantics.InteractionActorAdapterProjectHoomans = Adapter

Adapter.ID = "projecthoomans.managed_npc"
Adapter.PRIORITY = 100

local function managedRecord(actor)
    if type(actor) ~= "table" or actor.alive == false then return nil end
    local id = tostring(actor.id or "")
    if id == "" then return nil end
    local registry = PNC.Registry
    if type(registry) ~= "table" or type(registry.Get) ~= "function" then
        return nil
    end
    local ok, record = pcall(registry.Get, id)
    if not ok or type(record) ~= "table" or record ~= actor
        or record.alive == false
    then
        return nil
    end
    return record
end

local function unit(value, scale)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    if scale and scale > 1 then value = value / scale end
    return math.max(0, math.min(1, value))
end

local function personality(record)
    local graph = PNC.RelationshipGraph
    if graph and type(graph.ResolveNPCPersonality) == "function" then
        local ok, projected = pcall(graph.ResolveNPCPersonality, record)
        if ok and type(projected) == "table" then return projected end
    end
    if type(record.personality) == "table" then return record.personality end
    if type(record.socialProfile) == "table" then
        return type(record.socialProfile.personality) == "table"
            and record.socialProfile.personality or record.socialProfile
    end
    local social = type(record.social) == "table" and record.social or {}
    return type(social.personality) == "table" and social.personality or {}
end

local function traits(record)
    if type(record.npcTraits) == "table" then return record.npcTraits end
    if type(record.dynamicTraits) == "table" then return record.dynamicTraits end
    return {}
end

local function activity(record)
    local runtime = type(record.runtime) == "table" and record.runtime or {}
    return record.activeJob
        or record.activeBehavior
        or record.orderKind
        or runtime.activeJob
        or runtime.activeBehavior
        or runtime.orderKind
        or runtime.currentTask
        or "idle"
end

local function needs(record)
    local value = type(record.needs) == "table" and record.needs or nil
    if value then return value end
    local runtime = type(record.runtime) == "table" and record.runtime or {}
    return type(runtime.needs) == "table"
        and type(runtime.needs.cachedLevels) == "table"
        and runtime.needs.cachedLevels or {}
end

local function condition(record)
    return type(record.conditionStats) == "table"
        and record.conditionStats or {}
end

local function otherID(other)
    if type(other) ~= "table" then return nil end
    local id = tostring(other.id or other.actorId or "")
    return id ~= "" and id or nil
end

local function targetKey(id)
    if not id then return nil end
    local ref = PNC.EntityRef
    if ref and type(ref.ForNPC) == "function" then
        local ok, value = pcall(ref.ForNPC, id)
        if ok and value then return value end
    end
    return "npc:" .. tostring(id)
end

local function relationshipFor(record, other)
    local id = otherID(other)
    if not id then return {} end
    local key = targetKey(id)
    local relationships = PNC.Relationships
    if relationships and type(relationships.Get) == "function" and key then
        local ok, value = pcall(relationships.Get, record.id, key)
        if ok and type(value) == "table" then return value end
    end
    local social = type(record.social) == "table" and record.social or {}
    local values = type(social.relationships) == "table"
        and social.relationships or {}
    return type(values[key]) == "table" and values[key] or {}
end

local function factionID(record)
    local factions = PNC.Factions
    if factions and type(factions.GetFactionID) == "function" then
        local ok, value = pcall(factions.GetFactionID, record)
        if ok and value then return tostring(value) end
    end
    local affiliation = type(record.affiliation) == "table"
        and record.affiliation or {}
    return affiliation.factionID and tostring(affiliation.factionID) or nil
end

local function factionRelation(record, other)
    local otherRecord = managedRecord(other)
    if not otherRecord then return nil end
    local left = factionID(record)
    local right = factionID(otherRecord)
    if not left or not right then return nil end
    if left == right then return "same_faction" end
    local factions = PNC.Factions
    if factions and type(factions.GetRelation) == "function" then
        local ok, value = pcall(factions.GetRelation, left, right)
        if ok and type(value) == "table" and value.state then
            return tostring(value.state)
        end
    end
    return nil
end

local function knowledgeRefs(record)
    local world = PNC.WorldKnowledge
    if world and type(world.BuildConversationContext) == "function" then
        local ok, context = pcall(
            world.BuildConversationContext,
            record,
            { max = 16 }
        )
        local gossip = ok and type(context) == "table"
            and type(context.npcGossip) == "table"
            and context.npcGossip or nil
        if gossip and type(gossip.factRefs) == "table" then
            return gossip.factRefs
        end
    end
    local direct = type(record.knowledge) == "table"
        and record.knowledge or nil
    if direct then
        if type(direct.factRefs) == "table" then return direct.factRefs end
        local refs = {}
        for key, value in pairs(direct) do
            if type(key) == "string" and value == true then
                refs[#refs + 1] = key
            end
        end
        table.sort(refs)
        return refs
    end
    return {}
end

function Adapter.CanAdapt(actor)
    return managedRecord(actor) ~= nil
end

function Adapter.ProjectActor(actor)
    local record = managedRecord(actor)
    if not record then return nil end
    local profile = personality(record)
    local state = condition(record)
    local actorNeeds = needs(record)
    local current = tostring(activity(record))
    return {
        id = tostring(record.id),
        capabilities = {
            speech = record.speechDisabled ~= true
                and record.canSpeak ~= false,
            emote = record.emoteDisabled ~= true
                and record.canEmote ~= false,
            movement = record.alive ~= false,
            gameplayIntent = record.alive ~= false,
        },
        disposition = {
            aggression = unit(profile.aggression),
            confidence = unit(profile.bravery),
            forgiveness = unit(profile.forgiveness),
            sociability = unit(profile.sociability),
            empathy = unit(profile.compassion),
            riskTolerance = unit(profile.bravery),
        },
        condition = {
            panic = unit(state.panic, 100),
            stress = unit(state.stress),
            injury = unit(record.injury),
            hunger = unit(actorNeeds.hunger),
            thirst = unit(actorNeeds.thirst),
            fatigue = unit(actorNeeds.fatigue),
        },
        activity = {
            currentTask = current,
            idle = current == "" or current == "idle",
        },
        traits = traits(record),
    }
end

function Adapter.ProjectRelationship(actor, other)
    local record = managedRecord(actor)
    if not record then return {} end
    local relationship = relationshipFor(record, other)
    return {
        state = relationship.state,
        familiarity = relationship.familiarity,
        approval = relationship.approval,
        trust = relationship.trust,
        respect = relationship.respect,
        factionRelation = factionRelation(record, other),
    }
end

function Adapter.ProjectKnowledge(actor)
    local record = managedRecord(actor)
    if not record then return { available = false } end
    local refs = knowledgeRefs(record)
    return {
        available = true,
        factRefs = refs,
        factCount = #refs,
    }
end

function Adapter.Install(Providers)
    if type(Providers) ~= "table"
        or type(Providers.RegisterActorAdapter) ~= "function"
    then
        return false, "providers_unavailable"
    end
    for _, id in ipairs(
        type(Providers.AdapterIDs) == "function"
            and Providers.AdapterIDs() or {}
    ) do
        if id == Adapter.ID then return true, "already_installed" end
    end
    return Providers.RegisterActorAdapter({
        id = Adapter.ID,
        priority = Adapter.PRIORITY,
        CanAdapt = Adapter.CanAdapt,
        ProjectActor = Adapter.ProjectActor,
        ProjectRelationship = Adapter.ProjectRelationship,
        ProjectKnowledge = Adapter.ProjectKnowledge,
    })
end

return Adapter
