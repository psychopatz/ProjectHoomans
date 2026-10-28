-- Event-driven bounded interaction-scene scheduler.
-- No tick hook lives here: callers explicitly open scenes and submit stimuli.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Director = require "PNC/Semantics/PNC_SemanticInteractionDirector"
local Stimulus = require "PNC/Semantics/PNC_SemanticInteractionStimulus"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Scheduler = PNC.Semantics.InteractionScheduler or {}
PNC.Semantics.InteractionScheduler = Scheduler

Scheduler.VERSION = 1
Scheduler.MAX_ACTIVE_SCENES = 16
Scheduler.MAX_PARTICIPANTS = 4
Scheduler.MAX_TURNS_PER_SCENE = 8
Scheduler.MAX_RECENT_EVENTS = 8
Scheduler.NEARBY_DISTANCE = 60

local function copy(value)
    return ValueBounds.Copy(value)
end

local function boundedID(value)
    value = tostring(value or "")
    if value == "" or #value > 128 then return nil end
    if string.find(value, "[^%w_%.:%-]") then return nil end
    return value
end

local function participantIDs(value)
    if type(value) ~= "table"
        or #value < 1
        or #value > Scheduler.MAX_PARTICIPANTS
    then
        return nil, "scene_participant_count_invalid"
    end
    local output = {}
    local seen = {}
    for index = 1, #value do
        local raw = type(value[index]) == "table"
            and value[index].id or value[index]
        local id = boundedID(raw)
        if not id then return nil, "scene_participant_id_invalid" end
        if seen[id] then return nil, "scene_participant_duplicate:" .. id end
        seen[id] = true
        output[#output + 1] = id
    end
    return output
end

function Scheduler.ClassifyLOD(spec)
    spec = type(spec) == "table" and spec or {}
    if spec.playerParticipant == true then return "player_full" end
    if spec.perceived == true then return "nearby_perceived" end
    local distance = tonumber(spec.distance)
    if distance ~= nil and distance <= Scheduler.NEARBY_DISTANCE then
        return "nearby_unperceived"
    end
    return "distant"
end

function Scheduler.RealizationPolicy(lod)
    if lod == "player_full" or lod == "nearby_perceived" then
        return {
            speech = true,
            emote = true,
            flavor = true,
            semanticOnly = false,
        }
    end
    return {
        speech = false,
        emote = false,
        flavor = false,
        semanticOnly = true,
    }
end

function Scheduler.New(options)
    options = type(options) == "table" and options or {}
    local instance = {
        schemaVersion = Scheduler.VERSION,
        scenes = {},
        order = {},
        metrics = {
            eventsSubmitted = 0,
            directorEvaluations = 0,
            distantFlavorSkipped = 0,
            scenesOpened = 0,
            scenesClosed = 0,
            maxActiveScenes = 0,
            maxParticipants = 0,
            maxBeatCandidatesEvaluated = 0,
            maxBehaviorCandidatesEvaluated = 0,
            maxPredicateTraceRows = 0,
        },
        maxActiveScenes = math.min(
            Scheduler.MAX_ACTIVE_SCENES,
            math.max(1, tonumber(options.maxActiveScenes)
                or Scheduler.MAX_ACTIVE_SCENES)
        ),
        maxParticipants = math.min(
            Scheduler.MAX_PARTICIPANTS,
            math.max(1, tonumber(options.maxParticipants)
                or Scheduler.MAX_PARTICIPANTS)
        ),
        maxTurns = math.min(
            Scheduler.MAX_TURNS_PER_SCENE,
            math.max(1, tonumber(options.maxTurns)
                or Scheduler.MAX_TURNS_PER_SCENE)
        ),
    }

    local Methods = {}

    function Methods:OpenScene(spec)
        spec = type(spec) == "table" and spec or {}
        local id = boundedID(spec.id)
        if not id then return nil, "scene_id_invalid" end
        if self.scenes[id] then return nil, "scene_duplicate:" .. id end
        if #self.order >= self.maxActiveScenes then
            return nil, "scene_active_limit"
        end
        local participants, reason = participantIDs(spec.participants)
        if not participants then return nil, reason end
        if #participants > self.maxParticipants then
            return nil, "scene_participant_limit"
        end
        local scene = {
            id = id,
            participants = participants,
            lod = Scheduler.ClassifyLOD(spec),
            playerParticipant = spec.playerParticipant == true,
            perceived = spec.perceived == true,
            distance = tonumber(spec.distance),
            turnCount = 0,
            status = "active",
            recentEvents = {},
        }
        self.scenes[id] = scene
        self.order[#self.order + 1] = id
        self.metrics.scenesOpened = self.metrics.scenesOpened + 1
        self.metrics.maxActiveScenes = math.max(
            self.metrics.maxActiveScenes, #self.order
        )
        self.metrics.maxParticipants = math.max(
            self.metrics.maxParticipants, #participants
        )
        return copy(scene)
    end

    function Methods:CloseScene(id, reason)
        id = tostring(id or "")
        local scene = self.scenes[id]
        if not scene then return nil, "scene_unknown" end
        scene.status = "closed"
        scene.closeReason = tostring(reason or "closed")
        self.scenes[id] = nil
        for index = #self.order, 1, -1 do
            if self.order[index] == id then
                table.remove(self.order, index)
                break
            end
        end
        self.metrics.scenesClosed = self.metrics.scenesClosed + 1
        return copy(scene)
    end

    function Methods:UpdateVisibility(id, spec)
        local scene = self.scenes[tostring(id or "")]
        if not scene then return nil, "scene_unknown" end
        spec = type(spec) == "table" and spec or {}
        if spec.playerParticipant ~= nil then
            scene.playerParticipant = spec.playerParticipant == true
        end
        if spec.perceived ~= nil then
            scene.perceived = spec.perceived == true
        end
        if spec.distance ~= nil then scene.distance = tonumber(spec.distance) end
        scene.lod = Scheduler.ClassifyLOD(scene)
        return copy(scene)
    end

    local function recordEvent(scene, stimulusType, result)
        scene.recentEvents[#scene.recentEvents + 1] = {
            stimulusType = stimulusType,
            behaviorID = result
                and result.interactionPlan
                and result.interactionPlan.behaviorID
                or nil,
            beatID = result
                and result.selectedBeat
                and result.selectedBeat.id
                or nil,
        }
        while #scene.recentEvents > Scheduler.MAX_RECENT_EVENTS do
            table.remove(scene.recentEvents, 1)
        end
    end

    function Methods:HandleStimulus(
        sceneID, stimulus, state, context, eventOptions
    )
        local scene = self.scenes[tostring(sceneID or "")]
        if not scene then return nil, "scene_unknown" end
        if scene.turnCount >= self.maxTurns then
            self:CloseScene(scene.id, "turn_limit")
            return nil, "scene_turn_limit"
        end
        local normalized, reason = Stimulus.Normalize(stimulus)
        if not normalized then return nil, reason end
        eventOptions = type(eventOptions) == "table"
            and eventOptions or {}
        self.metrics.eventsSubmitted = self.metrics.eventsSubmitted + 1

        local realization = Scheduler.RealizationPolicy(scene.lod)
        if scene.lod == "distant"
            and eventOptions.meaningfulOutcome ~= true
        then
            self.metrics.distantFlavorSkipped =
                self.metrics.distantFlavorSkipped + 1
            return {
                schemaVersion = Scheduler.VERSION,
                sceneID = scene.id,
                lod = scene.lod,
                skipped = true,
                reason = "distant_flavor_suppressed",
                realization = realization,
                directorEvaluated = false,
            }
        end

        local preview, previewReason = Director.PreviewStimulus(
            normalized, state, context, eventOptions
        )
        if not preview then return nil, previewReason end
        if eventOptions.commitBeatState == true then
            local committed, commitReason = Director.Commit(
                preview, context
            )
            if not committed then return nil, commitReason end
            preview = committed
        end
        scene.turnCount = scene.turnCount + 1
        self.metrics.directorEvaluations =
            self.metrics.directorEvaluations + 1
        local metrics = type(preview.metrics) == "table"
            and preview.metrics or {}
        self.metrics.maxBeatCandidatesEvaluated = math.max(
            self.metrics.maxBeatCandidatesEvaluated,
            tonumber(metrics.beatCandidatesEvaluated) or 0
        )
        self.metrics.maxBehaviorCandidatesEvaluated = math.max(
            self.metrics.maxBehaviorCandidatesEvaluated,
            (tonumber(metrics.beatBehaviorCandidatesEvaluated) or 0)
                + (tonumber(metrics.oneShotBehaviorCandidatesEvaluated) or 0)
        )
        self.metrics.maxPredicateTraceRows = math.max(
            self.metrics.maxPredicateTraceRows,
            tonumber(metrics.predicateTraceRows) or 0
        )
        recordEvent(scene, normalized.type, preview)

        return {
            schemaVersion = Scheduler.VERSION,
            sceneID = scene.id,
            lod = scene.lod,
            skipped = false,
            directorEvaluated = true,
            realization = realization,
            preview = preview,
            sceneTurn = scene.turnCount,
        }
    end

    function Methods:Snapshot()
        local scenes = {}
        for index = 1, #self.order do
            local scene = self.scenes[self.order[index]]
            if scene then scenes[#scenes + 1] = copy(scene) end
        end
        return {
            schemaVersion = Scheduler.VERSION,
            activeSceneCount = #scenes,
            scenes = scenes,
            metrics = copy(self.metrics),
            limits = {
                maxActiveScenes = self.maxActiveScenes,
                maxParticipants = self.maxParticipants,
                maxTurns = self.maxTurns,
            },
        }
    end

    function Methods:Metrics()
        return copy(self.metrics)
    end

    return setmetatable(instance, { __index = Methods })
end

return Scheduler
