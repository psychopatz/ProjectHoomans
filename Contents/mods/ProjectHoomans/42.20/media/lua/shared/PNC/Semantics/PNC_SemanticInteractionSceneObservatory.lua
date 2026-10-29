-- Bounded read-only explanation surface for the generic Interaction Scene
-- Runtime. It projects semantic IDs/decisions only; rendered dialogue and
-- actor records are intentionally excluded.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"

local Observatory = PNC.Semantics.InteractionSceneObservatory or {}
PNC.Semantics.InteractionSceneObservatory = Observatory

Observatory.VERSION = 1
Observatory.SCHEMA = "semantic.interaction.scene.observatory.v1"
Observatory.MAX_SCENES = 8
Observatory.MAX_HISTORY = 8
Observatory.MAX_PROVIDERS = 16
Observatory.MAX_REJECTIONS = 8
Observatory.MAX_CLOSURES = 8
Observatory.MAX_REFS = 16

local function clean(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

local function number(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function boundedList(values, limit)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local item = clean(value, 128)
        if item and not seen[item] then
            output[#output + 1] = item
            seen[item] = true
            if #output >= (limit or Observatory.MAX_REFS) then break end
        end
    end
    return output
end

local function scalarFields(source, keys)
    local output = {}
    source = type(source) == "table" and source or {}
    for _, key in ipairs(keys or {}) do
        local value = source[key]
        if type(value) ~= "table" and value ~= nil then
            output[key] = value
        end
    end
    return output
end

local function schedulerScene(runtime, id)
    local scheduler = runtime and runtime.scheduler or nil
    return scheduler and scheduler.scenes
        and scheduler.scenes[tostring(id or "")] or nil
end

local function participantRows(scene)
    local output = {}
    for _, id in ipairs(
        type(scene) == "table"
            and type(scene.participantOrder) == "table"
            and scene.participantOrder or {}
    ) do
        local row = scene.participants and scene.participants[id] or {}
        output[#output + 1] = {
            id = clean(id, 128),
            kind = clean(row.kind, 32) or (
                row.isPlayer == true and "player" or "npc"
            ),
            isPlayer = row.isPlayer == true,
        }
    end
    return output
end

local function historyRows(scene, limit)
    local source = type(scene) == "table"
        and type(scene.semanticHistory) == "table"
        and scene.semanticHistory or {}
    local output = {}
    local start = math.max(1, #source - limit + 1)
    for index = start, #source do
        local row = source[index]
        output[#output + 1] = {
            sequence = number(row.sequence),
            stimulusSourceID = clean(row.sourceActorID, 128),
            responderID = clean(row.targetActorID, 128),
            stimulusType = clean(row.sourceType, 64),
            intent = clean(row.intent, 64),
            speechAct = clean(row.speechAct, 64),
            topic = clean(row.topic, 96),
            factRefs = boundedList(
                row.factRefs or row.factID and { row.factID } or {},
                Observatory.MAX_REFS
            ),
            eventRefs = boundedList(
                row.eventRefs or row.eventID and { row.eventID } or {},
                Observatory.MAX_REFS
            ),
            behaviorID = clean(row.behaviorID, 128),
            behaviorAct = clean(row.behaviorAct, 64),
            beatID = clean(row.beatID, 128),
        }
    end
    return output
end

local function groundedRefs(history, key)
    local output = {}
    local seen = {}
    for _, row in ipairs(history) do
        for _, value in ipairs(row[key] or {}) do
            if not seen[value] then
                output[#output + 1] = value
                seen[value] = true
                if #output >= Observatory.MAX_REFS then return output end
            end
        end
    end
    return output
end

local function directorProjection(scene)
    local state = scene and scene.semanticState
        and type(scene.semanticState.GetDirectorState) == "function"
        and scene.semanticState:GetDirectorState() or {}
    local active = type(state.active) == "table" and state.active or nil
    local recent = {}
    for index = 1, math.min(
        #(type(state.recent) == "table" and state.recent or {}),
        Observatory.MAX_HISTORY
    ) do
        recent[#recent + 1] = scalarFields(state.recent[index], {
            "id", "group", "beatID", "behaviorID", "reason",
            "enteredAt", "exitedAt", "turn",
        })
    end
    return {
        revision = number(state.revision) or 0,
        active = active and scalarFields(active, {
            "id", "group", "beatID", "topic", "enteredAt",
            "turns", "maxTurns",
        }) or nil,
        recent = recent,
    }
end

local function continuationProjection(scene)
    local last = type(scene) == "table"
        and type(scene.lastContinuation) == "table"
        and scene.lastContinuation or {}
    local history = type(scene) == "table"
        and type(scene.continuationHistory) == "table"
        and scene.continuationHistory or {}
    return {
        mode = clean(last.mode, 32) or "none",
        reason = clean(last.reason, 128),
        sourceID = clean(last.sourceID, 128),
        targetID = clean(last.targetID, 128),
        intent = clean(last.intent, 64),
        speechAct = clean(last.speechAct, 64),
        expectedResponse = clean(last.expectedResponse, 64),
        emittedCount = math.min(#history, Observatory.MAX_HISTORY),
    }
end

local function tacticalSpatialProjection(scene)
    local world = type(scene) == "table"
        and type(scene.world) == "table" and scene.world or {}
    local danger = type(world.danger) == "table" and world.danger or {}
    local spatial = type(danger.spatial) == "table"
        and danger.spatial or nil
    if not spatial then
        return {
            available = false,
            presentationMode = "omitted",
            suppressionReason = "tactical_spatial_unavailable",
        }
    end
    return {
        available = true,
        targetKind = clean(spatial.targetKind, 64),
        targetRef = clean(spatial.targetRef, 128),
        targetPositionSource = clean(spatial.targetPositionSource, 64),
        headingSource = clean(spatial.headingSource, 64),
        clockToken = clean(spatial.clockToken, 16),
        relativeSector8 = clean(spatial.relativeSector8, 32),
        distanceBand = clean(spatial.distanceBand, 32),
        freshnessMs = number(spatial.freshnessMs),
        presentationMode = clean(spatial.presentationMode, 16) or "omitted",
        presentationReason = clean(spatial.presentationReason, 96),
        suppressionReason = (
            clean(spatial.presentationMode, 16) == "omitted"
        ) and clean(spatial.presentationReason, 96) or nil,
    }
end

local function currentTurn(history, continuation)
    local row = history[#history]
    if not row then return nil end
    local recipientID = row.stimulusSourceID
        or continuation.targetID
    return {
        sequence = row.sequence,
        stimulusSourceID = row.stimulusSourceID,
        speakerID = row.responderID,
        recipientID = recipientID,
        stimulusType = row.stimulusType,
        intent = row.intent,
        speechAct = row.speechAct,
        behaviorID = row.behaviorID,
        behaviorAct = row.behaviorAct,
        beatID = row.beatID,
    }
end

local function participantIsPlayer(participants, id)
    for _, row in ipairs(participants or {}) do
        if row.id == id then return row.isPlayer == true end
    end
    return false
end

local function lastAdmission(manager)
    local row = manager and manager.lastAdmission or nil
    if type(row) ~= "table" then return nil end
    local rejections = {}
    for index = 1, math.min(
        #(type(row.rejections) == "table" and row.rejections or {}),
        Observatory.MAX_REJECTIONS
    ) do
        local rejected = row.rejections[index]
        rejections[#rejections + 1] = scalarFields(rejected, {
            "providerID", "proposalID", "reason",
        })
    end
    local result = scalarFields(row, {
        "accepted", "reason", "providerID", "proposalID", "sceneID",
        "dedupeKey", "initialStimulusType", "continuationReason",
        "audienceCount", "delivered",
    })
    result.rejections = rejections
    return result
end

local function providersProjection()
    local output = {}
    for index, row in ipairs(Opportunity.ListProviders()) do
        if index > Observatory.MAX_PROVIDERS then break end
        output[#output + 1] = {
            id = clean(row.id, 128),
            order = number(row.order),
            stimuli = boundedList(row.stimuli, 16),
        }
    end
    return output
end

local function opportunityProjection(manager)
    if type(manager) ~= "table" then
        return {
            available = false,
            providers = providersProjection(),
        }
    end
    local activeCount = 0
    for _ in pairs(type(manager.activeByKey) == "table"
        and manager.activeByKey or {}) do
        activeCount = activeCount + 1
    end
    return {
        available = true,
        activeCount = activeCount,
        cooldownCount = #(
            type(manager.cooldownOrder) == "table"
                and manager.cooldownOrder or {}
        ),
        metrics = scalarFields(manager.metrics, {
            "events", "providerEvaluations", "proposals", "accepted",
            "rejected", "activeSuppressed", "cooldownSuppressed",
            "dispatchFailed", "transported",
        }),
        providers = providersProjection(),
        lastAdmission = lastAdmission(manager),
    }
end

local function closureProjection(runtime)
    local source = runtime and runtime.scheduler
        and runtime.scheduler.recentClosures or {}
    local output = {}
    local start = math.max(1, #source - Observatory.MAX_CLOSURES + 1)
    for index = start, #source do
        output[#output + 1] = scalarFields(source[index], {
            "id", "reason", "turnCount", "maxTurns",
            "lod", "participantCount",
        })
    end
    return output
end

local function closureFor(closures, sceneID)
    for index = #closures, 1, -1 do
        if closures[index].id == sceneID then return closures[index] end
    end
    return nil
end

local function sceneProjection(runtime, scene, historyLimit, admission)
    local scheduler = schedulerScene(runtime, scene.id) or {}
    local participants = participantRows(scene)
    local history = historyRows(scene, historyLimit)
    local continuation = continuationProjection(scene)
    local turn = currentTurn(history, continuation)
    local metadata = runtime.metadata and runtime.metadata[scene.id] or {}
    local admissionMatches = admission
        and admission.sceneID == scene.id
    local playerChoices = turn
        and participantIsPlayer(participants, turn.recipientID)
        and continuation.mode == "wait"
        and continuation.reason == "player_input_required"
    return {
        id = clean(scene.id, 128),
        status = clean(scene.status, 32),
        lod = clean(scheduler.lod, 32),
        topic = clean(scene.topic, 96),
        participantCount = #participants,
        participants = participants,
        turnCount = number(scheduler.turnCount) or #history,
        maxTurns = number(scheduler.maxTurns),
        sequence = number(scene.semanticState and scene.semanticState.sequence)
            or 0,
        providerID = clean(metadata.providerID, 128),
        currentTurn = turn,
        semanticHistory = history,
        semanticHistoryCount = math.min(
            #(scene.semanticHistory or {}),
            Observatory.MAX_HISTORY
        ),
        grounding = {
            factRefs = groundedRefs(history, "factRefs"),
            eventRefs = groundedRefs(history, "eventRefs"),
        },
        tacticalSpatial = tacticalSpatialProjection(scene),
        director = directorProjection(scene),
        continuation = continuation,
        audience = {
            observedFromLastAdmission = admissionMatches == true,
            count = admissionMatches
                and number(admission.audienceCount) or nil,
            delivered = admissionMatches
                and number(admission.delivered) or nil,
            observersMayRespond = false,
            addressedPlayerMayRespond = playerChoices == true,
        },
        transcriptStored = false,
    }
end

local function defaultManager()
    local adopters = PNC.Semantics.InteractionSceneAdopters
    if type(adopters) == "table"
        and type(adopters.Manager) == "function"
    then
        return adopters.Manager()
    end
    return nil
end

local function adopterProjection()
    local adopters = PNC.Semantics.InteractionSceneAdopters
    if type(adopters) ~= "table"
        or type(adopters.Snapshot) ~= "function"
    then
        return nil
    end
    local snapshot = adopters.Snapshot()
    return {
        metrics = scalarFields(snapshot and snapshot.metrics, {
            "actorQueries", "hordeEvents",
            "knowledgeEvents", "excursionEvents",
        }),
    }
end

function Observatory.Inspect(options)
    options = type(options) == "table" and options or {}
    local runtime = options.runtime or Runtime.Default()
    local manager = options.opportunityManager or defaultManager()
    local historyLimit = math.max(
        1,
        math.min(
            Observatory.MAX_HISTORY,
            math.floor(number(options.historyLimit)
                or Observatory.MAX_HISTORY)
        )
    )
    local sceneLimit = math.max(
        1,
        math.min(
            Observatory.MAX_SCENES,
            math.floor(number(options.sceneLimit)
                or Observatory.MAX_SCENES)
        )
    )
    local requestedID = clean(options.sceneID, 128)
    local admission = lastAdmission(manager)
    local scenes = {}
    for _, id in ipairs(
        type(runtime.order) == "table" and runtime.order or {}
    ) do
        local scene = runtime.scenes and runtime.scenes[id] or nil
        if scene and (not requestedID or requestedID == id) then
            scenes[#scenes + 1] = sceneProjection(
                runtime, scene, historyLimit, admission
            )
            if #scenes >= sceneLimit then break end
        end
    end

    local closures = closureProjection(runtime)
    local requestedClosure = requestedID
        and closureFor(closures, requestedID) or nil
    local schedulerMetrics = runtime.scheduler
        and runtime.scheduler.metrics or {}
    local runtimeMetrics = runtime.metrics or {}
    local explanation
    local focused = scenes[1]
    if focused then
        explanation = {
            outcome = "active",
            providerID = focused.providerID,
            continuationMode = focused.continuation.mode,
            continuationReason = focused.continuation.reason,
            playerChoices = focused.audience.addressedPlayerMayRespond
                and "addressed_player_wait"
                or "observer_or_non_player_recipient",
        }
    elseif requestedClosure then
        explanation = {
            outcome = "closed",
            terminationReason = requestedClosure.reason,
            playerChoices = "scene_closed",
        }
    else
        explanation = {
            outcome = requestedID and "scene_not_found" or "runtime_summary",
            admissionReason = admission and (
                admission.accepted == true and "accepted"
                    or admission.reason
            ) or nil,
        }
    end

    return {
        schema = Observatory.SCHEMA,
        schemaVersion = Observatory.VERSION,
        readOnly = true,
        transcriptStored = false,
        runtime = {
            activeSceneCount = #(
                type(runtime.order) == "table" and runtime.order or {}
            ),
            metrics = scalarFields(runtimeMetrics, {
                "admissionAttempts", "admissionAccepted",
                "admissionRejected", "ttlExpired",
                "actorUnavailableClosed", "explicitClosed",
                "maxActiveScenes",
            }),
            scheduler = {
                metrics = scalarFields(schedulerMetrics, {
                    "eventsSubmitted", "directorEvaluations",
                    "distantFlavorSkipped", "scenesOpened",
                    "scenesClosed", "maxActiveScenes",
                    "maxParticipants", "maxBeatCandidatesEvaluated",
                    "maxBehaviorCandidatesEvaluated",
                    "maxPredicateTraceRows",
                }),
            },
        },
        opportunity = opportunityProjection(manager),
        adopter = adopterProjection(),
        scenes = scenes,
        sceneCount = #scenes,
        recentClosures = closures,
        explanation = explanation,
        limits = {
            maxScenes = Observatory.MAX_SCENES,
            maxHistory = Observatory.MAX_HISTORY,
            maxProviders = Observatory.MAX_PROVIDERS,
            maxClosures = Observatory.MAX_CLOSURES,
        },
    }
end

return Observatory
