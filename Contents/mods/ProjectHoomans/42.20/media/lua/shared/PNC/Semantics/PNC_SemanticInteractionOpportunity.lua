-- Event-driven Scene opportunity registry and bounded admission manager.
-- Providers consume caller-supplied authoritative event/context only.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Scheduler = require "PNC/Semantics/PNC_SemanticInteractionScheduler"
local Stimulus = require "PNC/Semantics/PNC_SemanticInteractionStimulus"
local Transport = require "PNC/Semantics/PNC_SemanticInteractionSceneTransport"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Opportunity = PNC.Semantics.InteractionOpportunity or {}
PNC.Semantics.InteractionOpportunity = Opportunity

Opportunity.VERSION = 1
Opportunity.MAX_PROVIDERS = 32
Opportunity.MAX_PROPOSALS = 8
Opportunity.MAX_PARTICIPANTS = Scheduler.MAX_PARTICIPANTS
Opportunity.MAX_AUDIENCE = Transport.MAX_AUDIENCE
Opportunity.MAX_FACT_REFS = 16
Opportunity.MAX_EVENT_REFS = 16
Opportunity.MAX_ACTIVE_KEYS = 64
Opportunity.DEFAULT_COOLDOWN_MS = 5000
Opportunity.MAX_COOLDOWN_MS = 120000

local providers = Opportunity._providers or {}
Opportunity._providers = providers

local function copy(value)
    return ValueBounds.Copy(value)
end

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

local function cleanID(value, maximum)
    value = clean(value, maximum or 128)
    if not value or string.find(value, "[^%w_%.:%-]") then return nil end
    return value
end

local function boundedToken(value)
    value = tostring(value or "")
    if value == "" or #value > 64
        or not string.match(value, "^[A-Z][A-Z0-9_]*$")
    then
        return nil
    end
    return value
end

local function boundedRefs(values, maximum)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local id = cleanID(value, 128)
        if id and not seen[id] then
            output[#output + 1] = id
            seen[id] = true
            if #output >= maximum then break end
        end
    end
    return output
end

local stimulusTypes = {}
for _, value in ipairs(Stimulus.Types()) do stimulusTypes[value] = true end

local function providerOrder(left, right)
    local leftOrder = tonumber(left.order) or 0
    local rightOrder = tonumber(right.order) or 0
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    return tostring(left.id) < tostring(right.id)
end

local function proposalOrder(left, right)
    local lp = tonumber(left.priority) or 0
    local rp = tonumber(right.priority) or 0
    if lp ~= rp then return lp > rp end
    if left.providerOrder ~= right.providerOrder then
        return left.providerOrder < right.providerOrder
    end
    return tostring(left.id) < tostring(right.id)
end

local function providerCount()
    local count = 0
    for _ in pairs(providers) do count = count + 1 end
    return count
end

local function normalizeStimuli(values)
    if values == nil then return {} end
    if type(values) ~= "table" then return nil end
    local output = {}
    local seen = {}
    for index = 1, math.min(#values, 16) do
        local value = boundedToken(values[index])
        if not value or not stimulusTypes[value] then return nil end
        if not seen[value] then
            output[#output + 1] = value
            seen[value] = true
        end
    end
    return output
end

function Opportunity.RegisterProvider(provider)
    if type(provider) ~= "table" then
        return false, "opportunity_provider_invalid"
    end
    local id = cleanID(provider.id, 128)
    if not id then return false, "opportunity_provider_id_invalid" end
    if type(provider.propose) ~= "function" then
        return false, "opportunity_provider_propose_required"
    end
    local stimuli = normalizeStimuli(provider.stimuli)
    if not stimuli then
        return false, "opportunity_provider_stimuli_invalid"
    end
    if providers[id] == nil
        and providerCount() >= Opportunity.MAX_PROVIDERS
    then
        return false, "opportunity_provider_limit"
    end
    provider.id = id
    provider.order = tonumber(provider.order) or 0
    provider.stimuli = stimuli
    providers[id] = provider
    return true, "registered"
end

function Opportunity.UnregisterProvider(id)
    id = cleanID(id, 128)
    if not id or not providers[id] then return false end
    providers[id] = nil
    return true
end

function Opportunity.ListProviders()
    local output = {}
    for _, provider in pairs(providers) do
        if provider.enabled ~= false then
            output[#output + 1] = {
                id = provider.id,
                order = tonumber(provider.order) or 0,
                stimuli = copy(provider.stimuli) or {},
            }
        end
    end
    table.sort(output, providerOrder)
    return output
end

local function providerAccepts(provider, stimulusType)
    if #provider.stimuli == 0 then return true end
    for _, value in ipairs(provider.stimuli) do
        if value == stimulusType then return true end
    end
    return false
end

local function normalizeParticipants(values)
    if type(values) ~= "table" then return nil, "participants_required" end
    local output = {}
    local seen = {}
    for index = 1, math.min(#values, Opportunity.MAX_PARTICIPANTS) do
        local source = values[index]
        if type(source) ~= "table" then
            return nil, "participant_invalid"
        end
        local id = cleanID(source.id, 128)
        if not id or seen[id] then
            return nil, id and "participant_duplicate" or "participant_id_invalid"
        end
        seen[id] = true
        output[#output + 1] = {
            id = id,
            actor = source.actor,
            projection = type(source.projection) == "table"
                and copy(source.projection) or nil,
            adapterContext = type(source.adapterContext) == "table"
                and copy(source.adapterContext) or nil,
            isPlayer = source.isPlayer == true,
            kind = source.isPlayer == true
                and "player" or tostring(source.kind or "npc"),
        }
    end
    if #output < 2 then return nil, "participant_minimum" end
    return output
end

local function participantSet(values)
    local output = {}
    for _, row in ipairs(values or {}) do output[row.id] = true end
    return output
end

local function normalizeAudience(values)
    local output = {}
    local seen = {}
    for index = 1, math.min(
        #(type(values) == "table" and values or {}),
        Opportunity.MAX_AUDIENCE
    ) do
        local row = values[index]
        if type(row) == "table" then
            local actorID = cleanID(row.actorID or row.playerID, 96)
            if actorID and row.player and not seen[actorID] then
                seen[actorID] = true
                output[#output + 1] = {
                    actorID = actorID,
                    player = row.player,
                    role = row.role == "recipient"
                        and "recipient" or "observer",
                }
            end
        end
    end
    return output
end

local function normalizeStimulus(value, participants, providerID)
    if type(value) ~= "table" then
        return nil, "initial_stimulus_required"
    end
    local stimulusType = boundedToken(value.type)
    if not stimulusType or not stimulusTypes[stimulusType] then
        return nil, "initial_stimulus_type_invalid"
    end
    local ids = participantSet(participants)
    local sourceID = cleanID(value.sourceID, 128)
    local responderID = cleanID(value.responderID, 128)
    if sourceID and not ids[sourceID] then
        return nil, "initial_source_not_participant"
    end
    if not responderID or not ids[responderID] then
        return nil, "initial_responder_not_participant"
    end
    if sourceID and sourceID == responderID then
        return nil, "initial_self_response_invalid"
    end
    local eventID = cleanID(value.eventID, 128)
    if (stimulusType == "WORLD_EVENT"
        or stimulusType == "DANGER_CHANGED")
        and not eventID
    then
        return nil, "initial_event_id_required"
    end
    return {
        type = stimulusType,
        sourceID = sourceID,
        responderID = responderID,
        providerID = providerID,
        intent = boundedToken(value.intent),
        speechAct = boundedToken(value.speechAct),
        subject = cleanID(value.subject, 96),
        topic = cleanID(value.topic, 96),
        confidence = tonumber(value.confidence) or 1,
        eventID = eventID,
        factRefs = boundedRefs(
            value.factRefs,
            Opportunity.MAX_FACT_REFS
        ),
        eventRefs = boundedRefs(
            value.eventRefs,
            Opportunity.MAX_EVENT_REFS
        ),
        modifiers = type(value.modifiers) == "table"
            and copy(value.modifiers) or {},
        worldPatch = type(value.worldPatch) == "table"
            and copy(value.worldPatch) or nil,
    }
end

function Opportunity.NormalizeProposal(value, providerID, providerOrderValue)
    if type(value) ~= "table" then
        return nil, "opportunity_proposal_invalid"
    end
    local participants, participantReason = normalizeParticipants(
        value.participants
    )
    if not participants then return nil, participantReason end
    local stimulus, stimulusReason = normalizeStimulus(
        value.stimulus, participants, providerID
    )
    if not stimulus then return nil, stimulusReason end

    local id = cleanID(value.id, 128)
        or cleanID(value.dedupeKey, 128)
        or table.concat({
            tostring(providerID),
            tostring(stimulus.type),
            tostring(stimulus.sourceID or "engine"),
            tostring(stimulus.responderID),
        }, ":")
    local dedupeKey = cleanID(value.dedupeKey, 128) or id
    local cooldownMs = math.max(
        0,
        math.min(
            Opportunity.MAX_COOLDOWN_MS,
            tonumber(value.cooldownMs)
                or Opportunity.DEFAULT_COOLDOWN_MS
        )
    )
    local worldEvents = boundedRefs(
        value.worldEvents,
        Opportunity.MAX_EVENT_REFS
    )
    if stimulus.eventID then
        local seen = false
        for _, eventID in ipairs(worldEvents) do
            if eventID == stimulus.eventID then seen = true break end
        end
        if not seen and #worldEvents < Opportunity.MAX_EVENT_REFS then
            table.insert(worldEvents, 1, stimulus.eventID)
        end
    end
    for _, eventID in ipairs(stimulus.eventRefs) do
        local seen = false
        for _, existing in ipairs(worldEvents) do
            if existing == eventID then seen = true break end
        end
        if not seen and #worldEvents < Opportunity.MAX_EVENT_REFS then
            worldEvents[#worldEvents + 1] = eventID
        end
    end

    return {
        schemaVersion = Opportunity.VERSION,
        id = id,
        dedupeKey = dedupeKey,
        providerID = providerID,
        providerOrder = tonumber(providerOrderValue) or 0,
        priority = tonumber(value.priority) or 0,
        participants = participants,
        playerParticipant = value.playerParticipant == true,
        topic = cleanID(value.topic or stimulus.topic, 96),
        ttlMs = tonumber(value.ttlMs),
        maxTurns = math.min(
            Scheduler.MAX_TURNS_PER_SCENE,
            math.max(1, math.floor(
                tonumber(value.maxTurns)
                    or Scheduler.MAX_TURNS_PER_SCENE
            ))
        ),
        perceived = value.perceived == true,
        distance = tonumber(value.distance),
        world = type(value.world) == "table" and copy(value.world) or nil,
        worldProviderID = cleanID(
            value.worldProviderID or providerID,
            128
        ),
        worldEvents = worldEvents,
        audience = normalizeAudience(value.audience),
        stimulus = stimulus,
        cooldownMs = cooldownMs,
        autoContinue = value.autoContinue ~= false,
        maxContinuationSteps = math.min(
            4,
            math.max(1, math.floor(
                tonumber(value.maxContinuationSteps) or 3
            ))
        ),
    }
end

function Opportunity.Evaluate(event, context, maximum)
    event = type(event) == "table" and event or {}
    context = type(context) == "table" and context or {}
    maximum = math.min(
        Opportunity.MAX_PROPOSALS,
        math.max(1, math.floor(tonumber(maximum)
            or Opportunity.MAX_PROPOSALS))
    )
    local eventType = boundedToken(event.type)
    if not eventType or not stimulusTypes[eventType] then
        return {}, {
            {
                providerID = "registry",
                reason = "opportunity_event_type_invalid",
            },
        }
    end

    local proposals = {}
    local diagnostics = {}
    local function retainProposal(proposal)
        proposals[#proposals + 1] = proposal
        table.sort(proposals, proposalOrder)
        while #proposals > maximum do
            table.remove(proposals)
        end
    end
    local function diagnostic(row)
        if #diagnostics < 16 then diagnostics[#diagnostics + 1] = row end
    end

    -- Evaluate all registered providers before applying the output cap.
    -- Capping raw provider order first would let many low-priority proposals
    -- starve a later urgent provider as the registry grows.
    for _, summary in ipairs(Opportunity.ListProviders()) do
        local provider = providers[summary.id]
        if provider and providerAccepts(provider, eventType) then
            -- Provider callbacks are the explicit external/adopter boundary.
            local ok, value = pcall(provider.propose, event, context)
            if not ok then
                diagnostic({
                    providerID = provider.id,
                    reason = "provider_error",
                })
            else
                local raw = type(value) == "table"
                    and value.proposals or value
                if type(raw) == "table"
                    and raw.participants ~= nil
                then
                    raw = { raw }
                end
                if type(raw) == "table" then
                    for index = 1, math.min(
                        #raw, Opportunity.MAX_PROPOSALS
                    ) do
                        local normalized, reason =
                            Opportunity.NormalizeProposal(
                                raw[index],
                                provider.id,
                                provider.order
                            )
                        if normalized then
                            retainProposal(normalized)
                        else
                            diagnostic({
                                providerID = provider.id,
                                proposalIndex = index,
                                reason = reason,
                            })
                        end
                    end
                end
            end
        end
    end
    table.sort(proposals, proposalOrder)
    return proposals, diagnostics
end

local function newMetrics()
    return {
        events = 0,
        providerEvaluations = 0,
        proposals = 0,
        accepted = 0,
        rejected = 0,
        activeSuppressed = 0,
        cooldownSuppressed = 0,
        dispatchFailed = 0,
        transported = 0,
    }
end

function Opportunity.New(runtime, options)
    runtime = runtime or Runtime.Default()
    options = type(options) == "table" and options or {}
    local instance = {
        runtime = runtime,
        activeByKey = {},
        cooldownUntil = {},
        cooldownOrder = {},
        metrics = newMetrics(),
        lastAdmission = nil,
    }
    local Methods = {}

    function Methods:Now()
        if self.runtime and type(self.runtime.Now) == "function" then
            return tonumber(self.runtime:Now()) or 0
        end
        return 0
    end

    function Methods:Prune()
        for key, sceneID in pairs(self.activeByKey) do
            local scene = self.runtime:Get(sceneID)
            if not scene then self.activeByKey[key] = nil end
        end
        local now = self:Now()
        for index = #self.cooldownOrder, 1, -1 do
            local key = self.cooldownOrder[index]
            if (tonumber(self.cooldownUntil[key]) or 0) <= now then
                self.cooldownUntil[key] = nil
                table.remove(self.cooldownOrder, index)
            end
        end
    end

    function Methods:RememberCooldown(key, untilAt)
        if self.cooldownUntil[key] == nil then
            self.cooldownOrder[#self.cooldownOrder + 1] = key
        end
        self.cooldownUntil[key] = untilAt
        while #self.cooldownOrder > Opportunity.MAX_ACTIVE_KEYS do
            local oldest = table.remove(self.cooldownOrder, 1)
            self.cooldownUntil[oldest] = nil
        end
    end

    function Methods:Advance(scene, result, proposal)
        local delivered = 0
        if result then
            local count = Transport.Deliver(
                scene, result, proposal.audience
            )
            delivered = delivered + (tonumber(count) or 0)
        end
        if proposal.autoContinue ~= true or not result then
            return result, delivered, "initial_only"
        end

        local current = result
        for _ = 1, proposal.maxContinuationSteps do
            local continuation = type(current.continuation) == "table"
                and current.continuation or {}
            if continuation.mode == "emit" then
                local advanced, reason = scene:Continue(current)
                if not advanced then return current, delivered, reason end
                if not advanced.emitted or not advanced.result then
                    return current, delivered,
                        advanced.decision and advanced.decision.reason
                            or "continuation_stopped"
                end
                current = advanced.result
                local count = Transport.Deliver(
                    scene, current, proposal.audience
                )
                delivered = delivered + (tonumber(count) or 0)
            elseif continuation.mode == "terminate" then
                scene:Continue(current)
                return current, delivered, "continuation_terminate"
            else
                return current, delivered,
                    continuation.reason or "continuation_stopped"
            end
        end
        return current, delivered, "continuation_step_limit"
    end

    function Methods:Admit(event, context)
        self:Prune()
        self.metrics.events = self.metrics.events + 1
        local proposals, diagnostics = Opportunity.Evaluate(event, context)
        self.metrics.providerEvaluations =
            self.metrics.providerEvaluations
            + #Opportunity.ListProviders()
        self.metrics.proposals = self.metrics.proposals + #proposals

        local now = self:Now()
        local rejections = {}
        for _, proposal in ipairs(proposals) do
            local key = proposal.dedupeKey
            local activeSceneID = self.activeByKey[key]
            if activeSceneID and self.runtime:Get(activeSceneID) then
                self.metrics.activeSuppressed =
                    self.metrics.activeSuppressed + 1
                rejections[#rejections + 1] = {
                    providerID = proposal.providerID,
                    proposalID = proposal.id,
                    reason = "opportunity_active",
                }
            elseif now < (tonumber(self.cooldownUntil[key]) or 0) then
                self.metrics.cooldownSuppressed =
                    self.metrics.cooldownSuppressed + 1
                rejections[#rejections + 1] = {
                    providerID = proposal.providerID,
                    proposalID = proposal.id,
                    reason = "opportunity_cooldown",
                }
            else
                local scene, sceneID = self.runtime:Open({
                    participants = proposal.participants,
                    playerParticipant = proposal.playerParticipant,
                    perceived = proposal.perceived,
                    distance = proposal.distance,
                    maxTurns = proposal.maxTurns,
                    ttlMs = proposal.ttlMs,
                    topic = proposal.topic,
                    world = proposal.world,
                    worldProviderID = proposal.worldProviderID,
                    worldEvents = proposal.worldEvents,
                    providerID = proposal.providerID,
                })
                if scene then
                    self.activeByKey[key] = sceneID
                    self:RememberCooldown(
                        key, now + proposal.cooldownMs
                    )
                    local result, dispatchReason =
                        scene:EmitStimulus(proposal.stimulus)
                    if not result then
                        self.activeByKey[key] = nil
                        self.runtime:Close(
                            sceneID, "opportunity_dispatch_failed"
                        )
                        self.metrics.dispatchFailed =
                            self.metrics.dispatchFailed + 1
                        rejections[#rejections + 1] = {
                            providerID = proposal.providerID,
                            proposalID = proposal.id,
                            reason = dispatchReason,
                        }
                    else
                        local final, delivered, advanceReason =
                            self:Advance(scene, result, proposal)
                        self.metrics.accepted =
                            self.metrics.accepted + 1
                        self.metrics.transported =
                            self.metrics.transported + delivered
                        self.lastAdmission = {
                            accepted = true,
                            providerID = proposal.providerID,
                            proposalID = proposal.id,
                            sceneID = sceneID,
                            dedupeKey = key,
                            initialStimulusType =
                                proposal.stimulus.type,
                            continuationReason = advanceReason,
                            audienceCount = #proposal.audience,
                            delivered = delivered,
                        }
                        return {
                            accepted = true,
                            scene = scene,
                            sceneID = sceneID,
                            proposal = proposal,
                            initialResult = result,
                            finalResult = final,
                            continuationReason = advanceReason,
                            diagnostics = diagnostics,
                            rejections = rejections,
                        }
                    end
                else
                    rejections[#rejections + 1] = {
                        providerID = proposal.providerID,
                        proposalID = proposal.id,
                        reason = sceneID,
                    }
                end
            end
        end

        self.metrics.rejected = self.metrics.rejected + 1
        self.lastAdmission = {
            accepted = false,
            reason = #proposals == 0
                and "no_opportunity" or "opportunity_rejected",
            diagnostics = copy(diagnostics),
            rejections = copy(rejections),
        }
        return {
            accepted = false,
            reason = self.lastAdmission.reason,
            diagnostics = diagnostics,
            rejections = rejections,
        }
    end

    function Methods:Snapshot()
        self:Prune()
        local active = {}
        for key, sceneID in pairs(self.activeByKey) do
            active[#active + 1] = {
                key = key,
                sceneID = sceneID,
            }
        end
        table.sort(active, function(left, right)
            return left.key < right.key
        end)
        return {
            schemaVersion = Opportunity.VERSION,
            providers = Opportunity.ListProviders(),
            active = active,
            activeCount = #active,
            cooldownCount = #self.cooldownOrder,
            metrics = copy(self.metrics),
            lastAdmission = copy(self.lastAdmission),
            limits = {
                maxProviders = Opportunity.MAX_PROVIDERS,
                maxProposals = Opportunity.MAX_PROPOSALS,
                maxParticipants = Opportunity.MAX_PARTICIPANTS,
                maxAudience = Opportunity.MAX_AUDIENCE,
            },
        }
    end

    return setmetatable(instance, { __index = Methods })
end

function Opportunity.ResetProvidersForTests()
    for key in pairs(providers) do providers[key] = nil end
end

return Opportunity
