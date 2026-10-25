-- Scenario-owned world knowledge projection for the semantic harness.

local function configureWorldKnowledge(context, Runtime, Values, npcData, runtime)
    local Adapter = PNC.WorldKnowledge
    local core = Adapter and Adapter.Core or nil
    if not core then return end
    if type(core.Reset) == "function" then
        core.Reset({
            maxFacts = runtime.worldKnowledge
                and runtime.worldKnowledge.maxFacts or nil,
            maxRefs = runtime.worldKnowledge
                and runtime.worldKnowledge.maxRefs or nil,
        })
    end
    if type(Adapter.ResetWorldStateRuntime) == "function" then
        Adapter.ResetWorldStateRuntime()
    end
    Runtime.worldKnowledgeScenario = nil
    local fixture = runtime.worldKnowledge
    if type(fixture) ~= "table" then return end

    local records = {}
    local originalGet = PNC.Registry and PNC.Registry.Get
    local function addRecord(record)
        if type(record) ~= "table" then return end
        record.id = record.id or record.npcID
        record.npcID = record.npcID or record.id
        record.coreActorID = record.coreActorID
            or ("actor:" .. tostring(record.id or "unknown"))
        records[tostring(record.id or "")] = record
        records[tostring(record.coreActorID or "")] = record
    end
    -- SAVE imports must expose the production-hydrated record to knowledge
    -- and downstream services. The scenario projection remains an engine/UI
    -- view, never a second Hoomans registry record.
    addRecord(Runtime.hydratedNpcRecord or npcData)
    if type(fixture.actors) == "table" then
        for key, value in pairs(fixture.actors) do
            if type(value) == "table" then
                value.id = value.id or (type(key) == "string" and key or nil)
                addRecord(value)
            end
        end
    end
    PNC.Registry = PNC.Registry or {}
    PNC.Registry.Get = function(id)
        return records[tostring(id or "")]
            or (type(originalGet) == "function" and originalGet(id) or nil)
    end

    local facts = {}
    local factByIndex = {}
    if type(fixture.facts) == "table" then
        for index = 1, #fixture.facts do
            local specification = Values.copy(fixture.facts[index])
            if type(specification) == "table" then
                specification.producer = specification.producer
                    or "semantic_lab:scenario"
                specification.payload = specification.payload or {}
                specification.payload.scenarioOwned = true
                local fact = core.Publish(specification)
                if fact then
                    facts[#facts + 1] = fact
                    factByIndex[index] = fact
                end
            end
        end
    end
    local acquisitions = {}
    if type(fixture.acquisitions) == "table" then
        for index = 1, #fixture.acquisitions do
            local item = fixture.acquisitions[index]
            local fact = item and factByIndex[item.factIndex]
            local target = item and records[tostring(item.actorID or "")]
            if fact and target then
                local reference = core.Acquire(target.coreActorID, fact.factID, {
                    authorized = true,
                    provenance = item.provenance or "witnessed",
                    confidence = item.confidence or 0.9,
                    sourceActorID = item.sourceActorID,
                    source = item.source or "semantic_lab_scenario",
                    acquisitionPath = item.acquisitionPath or "scenario_authority",
                    learnedAt = item.learnedAt or Runtime.now,
                })
                if reference then
                    acquisitions[#acquisitions + 1] = {
                        actorID = target.coreActorID,
                        factID = fact.factID,
                        reference = reference,
                    }
                end
            end
        end
    end
    Runtime.worldKnowledgeScenario = {
        scenarioOwned = true,
        facts = Values.copy(facts),
        actors = Values.copy(records),
        acquisitions = Values.copy(acquisitions),
    }
end

return function(deps)
    configureWorldKnowledge(
        deps.context,
        deps.Runtime,
        deps.Values,
        deps.npcData,
        deps.runtime
    )
end
