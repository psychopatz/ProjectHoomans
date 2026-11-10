-- Disposable fixture orchestration for the production Interaction Scene
-- Observatory. All scene decisions and inspection come from production Lua.
local SceneObservatory = {}

local MAX_PARTICIPANTS = 4

local function requireProduction()
    local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
    local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"
    local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
    local Observatory = require
        "PNC/Semantics/PNC_SemanticInteractionSceneObservatory"
    return Providers, Opportunity, Runtime, Observatory
end

local function projection(Providers, row)
    row = type(row) == "table" and row or {}
    local id = tostring(row.id or "")
    if id == "" then return nil, "scene_observatory_participant_id_required" end
    local confidence = math.max(
        0, math.min(1, tonumber(row.confidence) or 0.5)
    )
    local sociability = math.max(
        0, math.min(1, tonumber(row.sociability) or 0.5)
    )
    return {
        id = id,
        kind = row.isPlayer == true and "player" or "npc",
        isPlayer = row.isPlayer == true,
        projection = {
            actor = Providers.NormalizeActor({
                id = id,
                capabilities = {
                    speech = row.speechDisabled ~= true,
                    emote = true,
                    movement = true,
                },
                disposition = {
                    aggression = 0.2,
                    confidence = confidence,
                    forgiveness = 0.5,
                    sociability = sociability,
                    empathy = 0.5,
                    riskTolerance = confidence,
                },
                condition = {
                    panic = 0,
                    stress = 0,
                },
                activity = {
                    currentTask = "fixture",
                    idle = false,
                },
            }, "scene.observatory.worker"),
            relationship = Providers.NormalizeRelationship({
                state = "neutral",
                familiarity = 2,
                approval = 0,
                respect = 0,
            }, "scene.observatory.worker"),
            knowledge = Providers.NormalizeKnowledge({
                available = true,
                factRefs = type(row.factRefs) == "table"
                    and row.factRefs or {},
            }, "scene.observatory.worker"),
            evidence = {
                schemaVersion = 1,
                rows = {},
                providers = {},
                truncated = false,
                matched = 0,
            },
            provenance = {
                actor = "scene.observatory.worker",
                relationship = "scene.observatory.worker",
                knowledge = "scene.observatory.worker",
            },
        },
    }
end

local function fixtureWorld(payload)
    local spatial = type(payload.tacticalSpatial) == "table"
        and payload.tacticalSpatial or nil
    if not spatial then return nil end
    return {
        danger = {
            kind = tostring(payload.dangerKind or "zombie_horde"),
            pressureBand = tostring(payload.pressureBand or "horde"),
            nearbyCount = tonumber(payload.nearbyCount) or 8,
            phase = tostring(payload.dangerPhase or "started"),
            spatial = spatial,
        },
    }
end

local function participants(Providers, values)
    values = type(values) == "table" and values or {}
    if #values < 2 or #values > MAX_PARTICIPANTS then
        return nil, "scene_observatory_participant_count_invalid"
    end
    local output = {}
    for index = 1, #values do
        local row, reason = projection(Providers, values[index])
        if not row then return nil, reason end
        output[#output + 1] = row
    end
    return output
end

function SceneObservatory.fixture(context, payload)
    payload = type(payload) == "table" and payload or {}
    local Providers, Opportunity, Runtime, Observatory =
        requireProduction()
    local rows, participantReason = participants(
        Providers, payload.participants
    )
    if not rows then return nil, participantReason end

    local stimulusType = tostring(payload.stimulusType or "TASK_EVENT")
    local intent = tostring(payload.intent or "EXCURSION_PREPARING")
    local speechAct = tostring(payload.speechAct or "INFORM")
    local eventID = tostring(payload.eventID or "scene:worker:event")
    local responderID = tostring(
        payload.responderID or rows[1].id
    )
    local topic = tostring(payload.topic or "EXCURSION")
    local world = fixtureWorld(payload)

    Opportunity.ResetProvidersForTests()

    if payload.social == true then
        local SocialDirector = require
            "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector"
        local SocialConversation = require
            "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation"
        local runtime = Runtime.ResetForTests({
            maxActiveScenes = 4,
            maxParticipants = 4,
            maxTurns = 8,
            clock = function()
                return tonumber(context.Runtime.now) or 1000
            end,
        })
        local manager = Opportunity.New(runtime)
        local director, directorReason = SocialDirector.New(manager, {
            clock = function()
                return tonumber(context.Runtime.now) or 1000
            end,
        })
        if not director then return nil, directorReason end
        local controller = SocialConversation.New()
        local recipientID = tostring(
            payload.recipientID or rows[2].id
        )
        local admission = director:Submit({
            id = "worker-social:" .. eventID,
            motive = tostring(payload.motive or "COORDINATE"),
            relevance = tonumber(payload.relevance) or 0.9,
            priority = tonumber(payload.priority) or 40,
            eventType = stimulusType,
            eventID = eventID,
            intent = intent,
            speechAct = speechAct,
            subject = payload.subject or "SCENE_SOCIAL_FIXTURE",
            topic = topic,
            speakerID = responderID,
            recipientID = recipientID,
            participants = rows,
            factRefs = type(payload.factRefs) == "table"
                and payload.factRefs or {},
            eventRefs = { eventID },
            perceived = payload.perceived ~= false,
            distance = tonumber(payload.distance) or 8,
            maxTurns = tonumber(payload.maxTurns) or 4,
            areaKey = tostring(payload.areaKey or "worker-social"),
            allowNpcAfterPlayer = payload.allowNpcAfterPlayer == true,
        })
        if admission.accepted ~= true then
            return nil, admission.reason or "scene_social_admission_failed"
        end
        controller:RegisterScene(
            admission.scene,
            admission.socialOpportunity,
            admission.proposal and admission.proposal.audience or {}
        )
        local step = controller:Advance(
            admission.scene,
            admission.initialResult,
            admission.socialOpportunity
        )

        PNC.Semantics.InteractionSceneAdopters = {
            _semanticHarnessSceneObservatory = true,
            Manager = function() return manager end,
            Snapshot = function()
                return {
                    metrics = {
                        actorQueries = 0,
                        hordeEvents = 0,
                        postCombatEvents = 0,
                        knowledgeEvents = 0,
                        excursionEvents = 0,
                        taskEvents = 0,
                    },
                    social = director:Snapshot(),
                    socialConversation = controller:Snapshot(),
                }
            end,
        }

        context.Runtime.sceneObservatoryRuntime = runtime
        context.Runtime.sceneObservatoryManager = manager
        context.Runtime.sceneObservatorySceneID = admission.sceneID

        local view = Observatory.Inspect({
            runtime = runtime,
            opportunityManager = manager,
            sceneID = admission.sceneID,
            sceneLimit = tonumber(payload.sceneLimit),
            historyLimit = tonumber(payload.historyLimit),
        })
        view.ok = true
        view.type = "scene_observatory_social_fixture"
        view.sourceKind = "FIXTURE"
        view.workerKind = "production_lua"
        view.socialStep = {
            mode = step and step.mode or nil,
            reason = step and step.reason or nil,
            selectedStrategy = step and step.selected
                and step.selected.strategy or nil,
        }
        return view
    end

    if PNC.Semantics
        and type(PNC.Semantics.InteractionSceneAdopters) == "table"
        and PNC.Semantics.InteractionSceneAdopters
            ._semanticHarnessSceneObservatory == true
    then
        PNC.Semantics.InteractionSceneAdopters = nil
    end

    local registered, registerReason = Opportunity.RegisterProvider({
        id = "semantic_harness.scene_observatory",
        order = 1,
        stimuli = { stimulusType },
        propose = function(event, fixtureContext)
            return {
                id = "worker:" .. tostring(event.id),
                dedupeKey = "worker:" .. tostring(event.id),
                priority = 10,
                participants = fixtureContext.participants,
                topic = topic,
                ttlMs = 15000,
                maxTurns = 4,
                perceived = payload.perceived ~= false,
                distance = tonumber(payload.distance) or 8,
                autoContinue = payload.autoContinue == true,
                maxContinuationSteps = math.max(
                    1, math.min(
                        4,
                        math.floor(
                            tonumber(payload.maxContinuationSteps) or 2
                        )
                    )
                ),
                world = world,
                worldEvents = { eventID },
                stimulus = {
                    type = stimulusType,
                    responderID = responderID,
                    intent = intent,
                    speechAct = speechAct,
                    subject = payload.subject or "SCENE_FIXTURE",
                    topic = topic,
                    eventID = eventID,
                    eventRefs = { eventID },
                    worldPatch = world,
                },
            }
        end,
    })
    if not registered then return nil, registerReason end

    local runtime = Runtime.ResetForTests({
        maxActiveScenes = 4,
        maxParticipants = 4,
        maxTurns = 8,
        clock = function()
            return tonumber(context.Runtime.now) or 1000
        end,
    })
    local manager = Opportunity.New(runtime)
    local admission = manager:Admit({
        type = stimulusType,
        id = eventID,
    }, {
        participants = rows,
    })
    if admission.accepted ~= true then
        return nil, admission.reason or "scene_observatory_admission_failed"
    end

    context.Runtime.sceneObservatoryRuntime = runtime
    context.Runtime.sceneObservatoryManager = manager
    context.Runtime.sceneObservatorySceneID = admission.sceneID

    local view = Observatory.Inspect({
        runtime = runtime,
        opportunityManager = manager,
        sceneID = admission.sceneID,
        sceneLimit = tonumber(payload.sceneLimit),
        historyLimit = tonumber(payload.historyLimit),
    })
    view.ok = true
    view.type = "scene_observatory_fixture"
    view.sourceKind = "FIXTURE"
    view.workerKind = "production_lua"
    return view
end

function SceneObservatory.inspect(context, payload)
    payload = type(payload) == "table" and payload or {}
    local _, _, Runtime, Observatory = requireProduction()
    local runtime = context.Runtime.sceneObservatoryRuntime
        or Runtime.Default()
    local manager = context.Runtime.sceneObservatoryManager
    local view = Observatory.Inspect({
        runtime = runtime,
        opportunityManager = manager,
        sceneID = payload.sceneID
            or context.Runtime.sceneObservatorySceneID,
        sceneLimit = tonumber(payload.sceneLimit),
        historyLimit = tonumber(payload.historyLimit),
    })
    view.ok = true
    view.type = "scene_observatory_inspection"
    view.sourceKind = context.Runtime.sceneObservatoryRuntime
        and "FIXTURE_RUNTIME" or "PRODUCTION_RUNTIME"
    view.workerKind = "production_lua"
    return view
end

return SceneObservatory
