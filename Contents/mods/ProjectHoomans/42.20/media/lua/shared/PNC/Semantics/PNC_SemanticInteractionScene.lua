-- Bounded semantic scene session for NPC-to-NPC and multi-NPC interaction.
-- Stores semantic events only; realized wording is presentation output, not memory.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Presentation = require
    "PNC/Semantics/PNC_SemanticInteractionPresentation"
local Scheduler = require "PNC/Semantics/PNC_SemanticInteractionScheduler"
local Continuation = require
    "PNC/Semantics/PNC_SemanticInteractionContinuation"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Scene = PNC.Semantics.InteractionScene or {}
PNC.Semantics.InteractionScene = Scene

Scene.VERSION = 1
Scene.MAX_HISTORY = 8
Scene.MAX_FACT_REFS = 16
Scene.MAX_WORLD_EVENTS = 32

local function copy(value)
    return ValueBounds.Copy(value)
end

local function boundedID(value)
    value = tostring(value or "")
    if value == "" or #value > 128 then return nil end
    if string.find(value, "[^%w_%.:%-]") then return nil end
    return value
end

local function hasValue(values, target)
    if type(values) ~= "table" then return false end
    for index = 1, #values do
        if values[index] == target then return true end
    end
    return false
end

local function boundedRefs(values, limit)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local id = boundedID(value)
        if id and not seen[id] then
            output[#output + 1] = id
            seen[id] = true
            if #output >= (limit or Scene.MAX_FACT_REFS) then break end
        end
    end
    return output
end

local function boundedDirectorState(value)
    value = type(value) == "table" and value or {}
    local recent = {}
    local sourceRecent = type(value.recent) == "table" and value.recent or {}
    local first = math.max(1, #sourceRecent - 3)
    for index = first, #sourceRecent do
        recent[#recent + 1] = copy(sourceRecent[index])
    end
    local cooldowns = {}
    local keys = {}
    if type(value.cooldowns) == "table" then
        for key in pairs(value.cooldowns) do
            if type(key) == "string" then keys[#keys + 1] = key end
        end
        table.sort(keys)
        for index = 1, math.min(#keys, 16) do
            local number = tonumber(value.cooldowns[keys[index]])
            if number then cooldowns[keys[index]] = number end
        end
    end
    return {
        active = type(value.active) == "table" and copy(value.active) or nil,
        recent = recent,
        cooldowns = cooldowns,
        revision = tonumber(value.revision) or 0,
    }
end

local function makeSemanticState(scene)
    local state = {
        sequence = 0,
        currentTopic = scene.topic,
        lastEvent = nil,
        directorState = boundedDirectorState(nil),
    }

    function state:Recent(limit)
        limit = math.max(0, math.floor(tonumber(limit) or Scene.MAX_HISTORY))
        local output = {}
        for index = #scene.semanticHistory, 1, -1 do
            if #output >= limit then break end
            output[#output + 1] = copy(scene.semanticHistory[index])
        end
        return output
    end

    function state:GetDirectorState()
        self.directorState = boundedDirectorState(self.directorState)
        return copy(self.directorState)
    end

    function state:StoreDirectorState(value)
        local normalized = boundedDirectorState(value)
        normalized.revision =
            (tonumber(self.directorState.revision) or 0) + 1
        self.directorState = normalized
        return true, copy(normalized)
    end

    function state:ToContext()
        local recent = {}
        for index = #scene.semanticHistory, 1, -1 do
            if #recent >= Scene.MAX_HISTORY then break end
            local row = scene.semanticHistory[index]
            recent[#recent + 1] = {
                sequence = row.sequence,
                speaker = row.sourceActorID,
                intent = row.intent,
                speechAct = row.speechAct,
                topic = row.topic,
                source = row.sourceType,
            }
        end
        return {
            sequence = self.sequence,
            currentTopic = self.currentTopic,
            recentTurns = recent,
            agenda = {},
            flowSessions = {},
            pendingFollowUp = nil,
            director = self:GetDirectorState(),
        }
    end

    return state
end

local function participantMap(spec)
    local values = type(spec.participants) == "table"
        and spec.participants or {}
    if #values < 2 or #values > Scheduler.MAX_PARTICIPANTS then
        return nil, nil, "scene_participant_count_invalid"
    end
    local map = {}
    local order = {}
    for index = 1, #values do
        local raw = values[index]
        if type(raw) ~= "table" then
            return nil, nil, "scene_participant_invalid"
        end
        local id = boundedID(raw.id)
        if not id then return nil, nil, "scene_participant_id_invalid" end
        if map[id] then
            return nil, nil, "scene_participant_duplicate:" .. id
        end
        if raw.actor == nil and type(raw.projection) ~= "table" then
            return nil, nil, "scene_participant_actor_missing:" .. id
        end
        map[id] = {
            id = id,
            actor = raw.actor,
            projection = type(raw.projection) == "table"
                and copy(raw.projection) or nil,
            adapterContext = copy(raw.adapterContext) or {},
            isPlayer = raw.isPlayer == true
                or tostring(raw.kind or "") == "player",
            kind = raw.isPlayer == true
                and "player" or tostring(raw.kind or "npc"),
        }
        order[#order + 1] = id
    end
    return map, order
end

local function projectionFor(scene, participant, other)
    local projection
    local reason
    if type(participant.projection) == "table" then
        projection = copy(participant.projection)
    else
        projection, reason = Providers.ProjectExternalContext(
            participant.actor,
            other and other.actor or nil,
            participant.adapterContext
        )
        if not projection then return nil, reason end
    end
    projection.world = copy(scene.world)
    projection.provenance = type(projection.provenance) == "table"
        and projection.provenance or {}
    projection.provenance.world =
        scene.world.providerID or "interaction.scene.world"
    return projection
end

local function sourceKnowsFact(scene, source, target, factID)
    if not factID then return true end
    local localFacts = scene.disclosedFacts
        and scene.disclosedFacts[source.id] or nil
    if localFacts and localFacts[factID] == true then return true end
    local projection, reason = projectionFor(scene, source, target)
    if not projection then return false, reason end
    local knowledge = type(projection.knowledge) == "table"
        and projection.knowledge or {}
    if hasValue(knowledge.factRefs, factID) then return true end
    return false, "source_fact_unknown:" .. tostring(factID)
end

local function sourceKnowsFacts(scene, source, target, factRefs)
    for _, factID in ipairs(factRefs or {}) do
        local known, reason = sourceKnowsFact(scene, source, target, factID)
        if not known then return false, reason end
    end
    return true
end

local function rememberDisclosure(scene, targetID, stimulus)
    if not targetID or type(stimulus) ~= "table" then return end
    local payload = type(stimulus.payload) == "table"
        and stimulus.payload or {}
    local facts = boundedRefs(payload.factRefs, Scene.MAX_FACT_REFS)
    local events = boundedRefs(payload.eventRefs, Scene.MAX_WORLD_EVENTS)
    scene.disclosedFacts[targetID] = scene.disclosedFacts[targetID] or {}
    scene.disclosedEvents[targetID] = scene.disclosedEvents[targetID] or {}
    local factMap = scene.disclosedFacts[targetID]
    local eventMap = scene.disclosedEvents[targetID]
    for _, id in ipairs(facts) do factMap[id] = true end
    for _, id in ipairs(events) do eventMap[id] = true end

    local function trim(map, limit)
        local keys = {}
        for key in pairs(map) do keys[#keys + 1] = key end
        table.sort(keys)
        while #keys > limit do
            map[keys[1]] = nil
            table.remove(keys, 1)
        end
    end
    trim(factMap, Scene.MAX_FACT_REFS)
    trim(eventMap, Scene.MAX_WORLD_EVENTS)
end

local function appendHistory(scene, stimulus, preview, sourceID, targetID)
    local semantic = type(stimulus.semantic) == "table"
        and stimulus.semantic or {}
    scene.semanticState.sequence = scene.semanticState.sequence + 1
    scene.semanticState.currentTopic =
        preview.interactionPlan and preview.interactionPlan.topic
        or semantic.topic
        or scene.semanticState.currentTopic
    scene.topic = scene.semanticState.currentTopic
    local row = {
        sequence = scene.semanticState.sequence,
        sourceActorID = sourceID,
        targetActorID = targetID,
        sourceType = stimulus.type,
        intent = semantic.intent,
        speechAct = semantic.speechAct,
        topic = semantic.topic,
        factID = semantic.factID,
        eventID = semantic.eventID,
        factRefs = boundedRefs(
            stimulus.payload and stimulus.payload.factRefs,
            Scene.MAX_FACT_REFS
        ),
        eventRefs = boundedRefs(
            stimulus.payload and stimulus.payload.eventRefs,
            Scene.MAX_WORLD_EVENTS
        ),
        behaviorID = preview.interactionPlan
            and preview.interactionPlan.behaviorID or nil,
        behaviorAct = preview.interactionPlan
            and preview.interactionPlan.behaviorAct or nil,
        beatID = preview.interactionPlan
            and preview.interactionPlan.beatID or nil,
    }
    scene.semanticHistory[#scene.semanticHistory + 1] = row
    while #scene.semanticHistory > Scene.MAX_HISTORY do
        table.remove(scene.semanticHistory, 1)
    end
    scene.semanticState.lastEvent = {
        intent = semantic.intent,
        speechAct = semantic.speechAct,
        topic = semantic.topic,
        rawText = nil,
    }
    return row
end

local function sceneContext(scene, sourceID, responderID, projection)
    return {
        interactionProjection = projection,
        interactionScene = {
            id = scene.id,
            participantIDs = copy(scene.participantOrder),
            sourceActorID = sourceID,
            responderActorID = responderID,
            currentTopic = scene.topic,
            ended = scene.status ~= "active",
        },
        semanticContextState = scene.semanticState,
        currentTopic = scene.topic,
        conversationEnded = scene.status ~= "active",
    }
end

local function process(
    scene, stimulus, sourceID, responderID, projection, options
)
    local context = sceneContext(
        scene, sourceID, responderID, projection
    )
    local handled, reason = scene.scheduler:HandleStimulus(
        scene.id,
        stimulus,
        scene.semanticState,
        context,
        {
            meaningfulOutcome = true,
            commitBeatState = true,
        }
    )
    if not handled then return nil, reason end
    if handled.skipped then
        return {
            schemaVersion = Scene.VERSION,
            sceneID = scene.id,
            stimulus = copy(stimulus),
            skipped = true,
            reason = handled.reason,
            realizationPolicy = copy(handled.realization),
        }
    end

    local preview = handled.preview
    local presentation = Presentation.Build(
        preview.interactionPlan,
        handled.realization,
        projection,
        responderID
    )
    local history = appendHistory(
        scene, stimulus, preview, sourceID, responderID
    )
    rememberDisclosure(scene, responderID, stimulus)
    scene.lastTurn = {
        sequence = history.sequence,
        sourceID = sourceID,
        responderID = responderID,
        stimulus = copy(stimulus),
        plan = copy(preview.interactionPlan),
    }
    local continuation = Continuation.Decide(scene, scene.lastTurn)
    scene.lastContinuation = copy(continuation)
    return {
        schemaVersion = Scene.VERSION,
        sceneID = scene.id,
        stimulus = copy(stimulus),
        decision = copy(preview),
        interactionPlan = copy(preview.interactionPlan),
        presentation = presentation,
        semanticHistoryEvent = copy(history),
        realizationPolicy = copy(handled.realization),
        sceneTurn = handled.sceneTurn,
        continuation = copy(continuation),
    }
end

function Scene.New(spec)
    spec = type(spec) == "table" and spec or {}
    local id = boundedID(spec.id)
    if not id then return nil, "scene_id_invalid" end
    local participants, participantOrder, reason = participantMap(spec)
    if not participants then return nil, reason end

    local scheduler = spec.scheduler
    local ownsScheduler = false
    if scheduler == nil then
        scheduler = Scheduler.New({
            maxActiveScenes = 1,
            maxParticipants = #participantOrder,
            maxTurns = Scheduler.MAX_TURNS_PER_SCENE,
        })
        ownsScheduler = true
    end
    if type(scheduler) ~= "table"
        or type(scheduler.OpenScene) ~= "function"
        or type(scheduler.HandleStimulus) ~= "function"
        or type(scheduler.CloseScene) ~= "function"
    then
        return nil, "scene_scheduler_invalid"
    end
    local scheduled, scheduleReason = scheduler:OpenScene({
        id = id,
        participants = participantOrder,
        playerParticipant = spec.playerParticipant == true,
        perceived = spec.perceived == true,
        distance = spec.distance,
        maxTurns = math.min(
            tonumber(spec.maxTurns) or Scheduler.MAX_TURNS_PER_SCENE,
            Scheduler.MAX_TURNS_PER_SCENE
        ),
    })
    if not scheduled then return nil, scheduleReason end

    local world = Providers.NormalizeWorld(
        spec.world or {},
        spec.worldProviderID or "interaction.scene.world"
    )
    local worldEvents = {}
    local eventValues = type(spec.worldEvents) == "table"
        and spec.worldEvents or {}
    for index = 1, math.min(#eventValues, Scene.MAX_WORLD_EVENTS) do
        local eventID = boundedID(eventValues[index])
        if eventID then worldEvents[eventID] = true end
    end

    local instance = {
        schemaVersion = Scene.VERSION,
        id = id,
        status = "active",
        participants = participants,
        participantOrder = participantOrder,
        semanticHistory = {},
        topic = spec.topic,
        world = world,
        worldEvents = worldEvents,
        scheduler = scheduler,
        ownsScheduler = ownsScheduler,
        disclosedFacts = {},
        disclosedEvents = {},
        continuationHistory = {},
        lastTurn = nil,
        lastContinuation = nil,
    }
    instance.semanticState = makeSemanticState(instance)

    local Methods = {}

    function Methods:EmitSemanticAct(request)
        request = type(request) == "table" and request or {}
        if self.status ~= "active" then return nil, "scene_closed" end
        local sourceID = boundedID(request.sourceID)
        local responderID = boundedID(request.responderID)
        local source = sourceID and self.participants[sourceID] or nil
        local responder = responderID and self.participants[responderID] or nil
        if not source then return nil, "scene_source_unknown" end
        if not responder then return nil, "scene_responder_unknown" end
        if sourceID == responderID then
            return nil, "scene_self_response_invalid"
        end

        local factRefs = boundedRefs(
            request.factRefs, Scene.MAX_FACT_REFS
        )
        local factID = request.factID and boundedID(request.factID)
            or factRefs[1]
        if factID and not hasValue(factRefs, factID) then
            table.insert(factRefs, 1, factID)
            while #factRefs > Scene.MAX_FACT_REFS do
                table.remove(factRefs)
            end
        end
        local knows, knowledgeReason = sourceKnowsFacts(
            self, source, responder, factRefs
        )
        if not knows then return nil, knowledgeReason end
        local eventRefs = boundedRefs(
            request.eventRefs, Scene.MAX_WORLD_EVENTS
        )
        local eventID = request.eventID and boundedID(request.eventID)
            or eventRefs[1]
        if eventID and not hasValue(eventRefs, eventID) then
            table.insert(eventRefs, 1, eventID)
            while #eventRefs > Scene.MAX_WORLD_EVENTS do
                table.remove(eventRefs)
            end
        end

        local projection, projectionReason = projectionFor(
            self, responder, source
        )
        if not projection then return nil, projectionReason end

        local stimulus = {
            type = "NPC_SEMANTIC_ACT",
            source = {
                kind = source.isPlayer == true and "player" or "npc",
                actorID = sourceID,
                providerID = request.providerID
                    or "interaction.scene.semantic_act",
            },
            targets = { responderID },
            semantic = {
                intent = request.intent,
                speechAct = request.speechAct,
                subject = request.subject,
                topic = request.topic or self.topic,
                confidence = tonumber(request.confidence) or 1,
                factID = factID,
                eventID = eventID,
                modifiers = copy(request.modifiers) or {},
            },
            payload = {
                factRefs = factRefs,
                eventRefs = eventRefs,
            },
        }
        return process(
            self, stimulus, sourceID, responderID, projection, request
        )
    end

    function Methods:EmitWorldEvent(request)
        request = type(request) == "table" and request or {}
        if self.status ~= "active" then return nil, "scene_closed" end
        local responderID = boundedID(request.responderID)
        local responder = responderID and self.participants[responderID] or nil
        if not responder then return nil, "scene_responder_unknown" end
        local eventID = boundedID(request.eventID)
        if not eventID or self.worldEvents[eventID] ~= true then
            return nil, "scene_world_event_unknown:" .. tostring(eventID)
        end

        if type(request.worldPatch) == "table" then
            local merged = copy(self.world) or {}
            for key, value in pairs(request.worldPatch) do
                merged[key] = value
            end
            self.world = Providers.NormalizeWorld(
                merged,
                request.worldProviderID
                    or self.world.providerID
                    or "interaction.scene.world"
            )
        end

        local projection, projectionReason = projectionFor(
            self, responder, nil
        )
        if not projection then return nil, projectionReason end

        local stimulusType = tostring(request.type or "WORLD_EVENT")
        if stimulusType ~= "WORLD_EVENT"
            and stimulusType ~= "DANGER_CHANGED"
        then
            return nil, "scene_world_stimulus_invalid"
        end
        local stimulus = {
            type = stimulusType,
            source = {
                kind = "engine",
                providerID = request.providerID
                    or self.world.providerID
                    or "interaction.scene.world",
            },
            targets = { responderID },
            semantic = {
                intent = request.intent or "WORLD_EVENT",
                speechAct = request.speechAct,
                topic = request.topic or self.topic,
                confidence = 1,
                eventID = eventID,
            },
            payload = {
                eventRefs = { eventID },
            },
        }
        return process(
            self, stimulus, nil, responderID, projection, request
        )
    end

    function Methods:Continue(result)
        if self.status ~= "active" then return nil, "scene_closed" end
        result = type(result) == "table" and result or {}
        local sequence = result.semanticHistoryEvent
            and tonumber(result.semanticHistoryEvent.sequence) or nil
        if not self.lastTurn or sequence ~= self.lastTurn.sequence then
            return nil, "scene_continuation_stale"
        end

        local decision = Continuation.Decide(self, self.lastTurn)
        self.lastContinuation = copy(decision)
        if decision.mode == "terminate" then
            local closed, closeReason = self:Close(
                decision.reason or "continuation_terminate"
            )
            return {
                decision = copy(decision),
                terminated = closed ~= nil,
                closeReason = closeReason,
            }
        end
        if decision.mode == "wait" or decision.mode == "none" then
            return {
                decision = copy(decision),
                emitted = false,
            }
        end
        if decision.mode ~= "emit" then
            return nil, "scene_continuation_invalid"
        end

        local emitted, emitReason = self:EmitSemanticAct({
            sourceID = decision.sourceID,
            responderID = decision.targetID,
            intent = decision.intent,
            speechAct = decision.speechAct,
            topic = decision.topic,
            subject = decision.subject,
            factRefs = decision.factRefs,
            eventRefs = decision.eventRefs,
            providerID = "interaction.scene.continuation",
        })
        if not emitted then return nil, emitReason end
        Continuation.Remember(self, decision, sequence)
        return {
            decision = copy(decision),
            emitted = true,
            result = emitted,
        }
    end

    function Methods:RunContinuations(result, options)
        options = type(options) == "table" and options or {}
        local maxSteps = math.min(
            Continuation.MAX_STEPS,
            math.max(1, math.floor(tonumber(options.maxSteps) or 4))
        )
        local current = result
        local steps = {}
        for _ = 1, maxSteps do
            local advanced, reason = self:Continue(current)
            if not advanced then
                return {
                    steps = steps,
                    stopped = true,
                    reason = reason,
                }
            end
            steps[#steps + 1] = advanced
            if not advanced.emitted or not advanced.result then
                return {
                    steps = steps,
                    stopped = true,
                    reason = advanced.decision
                        and advanced.decision.reason
                        or "continuation_stopped",
                }
            end
            current = advanced.result
        end
        return {
            steps = steps,
            stopped = true,
            reason = "continuation_step_limit",
        }
    end

    function Methods:UpdateVisibility(specification)
        local updated, updateReason = self.scheduler:UpdateVisibility(
            self.id, specification
        )
        if not updated then return nil, updateReason end
        return updated
    end

    function Methods:Close(reason)
        self.status = "closed"
        return self.scheduler:CloseScene(
            self.id, reason or "scene_closed"
        )
    end

    function Methods:Snapshot()
        local schedulerSnapshot = self.scheduler:Snapshot()
        return {
            schemaVersion = Scene.VERSION,
            id = self.id,
            status = self.status,
            participants = copy(self.participantOrder),
            participantCount = #self.participantOrder,
            topic = self.topic,
            world = copy(self.world),
            semanticHistory = copy(self.semanticHistory),
            semanticHistoryCount = #self.semanticHistory,
            sequence = self.semanticState.sequence,
            director = self.semanticState:GetDirectorState(),
            continuation = Continuation.Snapshot(self),
            scheduler = schedulerSnapshot,
            transcriptStored = false,
        }
    end

    return setmetatable(instance, { __index = Methods })
end

return Scene
