-- Generic social/dramaturgy admission over the existing Interaction
-- Opportunity + Scene Runtime. Domains submit grounded social opportunities;
-- this module never scans the world or owns gameplay truth.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local Scheduler = require "PNC/Semantics/PNC_SemanticInteractionScheduler"
local Budget = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialBudget"

local Director = PNC.Semantics.SocialDirector or {}
PNC.Semantics.SocialDirector = Director

Director.VERSION = 1
Director.PROVIDER_ID = "projecthoomans.scene.social_director"
Director.MAX_PARTICIPANTS = Scheduler.MAX_PARTICIPANTS
Director.MAX_REFS = 16
Director.MIN_RELEVANCE = 0.20

Director.MOTIVES = {
    INFORM = true,
    WARN = true,
    REQUEST = true,
    CHECK = true,
    ACKNOWLEDGE = true,
    REACT = true,
    SOCIALIZE = true,
    DISPUTE = true,
    REPAIR = true,
    COORDINATE = true,
    SILENCE = true,
}

local DEFAULT_PRIORITY = {
    INFORM = 30,
    WARN = 70,
    REQUEST = 45,
    CHECK = 35,
    ACKNOWLEDGE = 25,
    REACT = 25,
    SOCIALIZE = 15,
    DISPUTE = 40,
    REPAIR = 42,
    COORDINATE = 50,
}

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

local function token(value)
    value = string.upper(tostring(value or ""))
    if value == "" or #value > 64
        or not string.match(value, "^[A-Z][A-Z0-9_]*$")
    then
        return nil
    end
    return value
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 32 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function refs(values)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local id = cleanID(value, 128)
        if id and not seen[id] then
            output[#output + 1] = id
            seen[id] = true
            if #output >= Director.MAX_REFS then break end
        end
    end
    return output
end

local function participants(values, speakerID, recipientID)
    if type(values) ~= "table" then
        return nil, "social_participants_required"
    end
    local map = {}
    local order = {}
    for index = 1, math.min(#values, Director.MAX_PARTICIPANTS) do
        local row = values[index]
        if type(row) ~= "table" then
            return nil, "social_participant_invalid"
        end
        local id = cleanID(row.id, 128)
        if not id then return nil, "social_participant_id_invalid" end
        if map[id] then return nil, "social_participant_duplicate" end
        map[id] = row
        order[#order + 1] = id
    end
    if #order < 2 then return nil, "social_participant_minimum" end
    if not map[speakerID] then return nil, "social_speaker_not_participant" end
    if not map[recipientID] then return nil, "social_recipient_not_participant" end
    if speakerID == recipientID then return nil, "social_self_recipient" end

    -- Existing Scene continuation target="other" is deterministic by
    -- participant order. Put the selected opening speaker first and intended
    -- recipient second, then preserve all other participants.
    local normalized = {}
    local used = {}
    local function add(id)
        local row = map[id]
        if row and not used[id] then
            normalized[#normalized + 1] = row
            used[id] = true
        end
    end
    add(speakerID)
    add(recipientID)
    for _, id in ipairs(order) do add(id) end
    return normalized
end

function Director.Normalize(spec)
    spec = type(spec) == "table" and spec or {}
    local motive = token(spec.motive)
    if not motive or not Director.MOTIVES[motive] then
        return nil, "social_motive_invalid"
    end
    if motive == "SILENCE" then return nil, "social_motive_silence" end

    local relevance = clamp(spec.relevance or 1, 0, 1)
    if relevance < Director.MIN_RELEVANCE then
        return nil, "social_relevance_low"
    end

    local speakerID = cleanID(spec.speakerID, 128)
    local recipientID = cleanID(spec.recipientID, 128)
    if not speakerID then return nil, "social_speaker_required" end
    if not recipientID then return nil, "social_recipient_required" end
    local participantRows, participantReason = participants(
        spec.participants, speakerID, recipientID
    )
    if not participantRows then return nil, participantReason end

    local eventType = token(spec.eventType)
        or "AMBIENT_SOCIAL_OPPORTUNITY"
    local intent = token(spec.intent)
    local speechAct = token(spec.speechAct)
    if not intent then return nil, "social_intent_required" end
    if not speechAct then return nil, "social_speech_act_required" end

    local topic = cleanID(spec.topic or motive, 96)
    local eventID = cleanID(spec.eventID or spec.id, 128)
    local id = cleanID(spec.id, 128)
        or eventID
        or table.concat({
            "social",
            string.lower(motive),
            speakerID,
            recipientID,
        }, ":")
    local priority = tonumber(spec.priority)
        or (DEFAULT_PRIORITY[motive] or 20)

    local recipientParticipant = participantRows[2]
    local recipientIsPlayer = type(recipientParticipant) == "table"
        and (recipientParticipant.isPlayer == true
            or tostring(recipientParticipant.kind or "") == "player")
    local normalized = {
        schemaVersion = Director.VERSION,
        id = id,
        eventType = eventType,
        eventID = eventID,
        motive = motive,
        relevance = relevance,
        priority = priority,
        speakerID = speakerID,
        recipientID = recipientID,
        participants = participantRows,
        audience = copy(spec.audience) or {},
        topic = topic,
        intent = intent,
        speechAct = speechAct,
        subject = cleanID(spec.subject, 96),
        factRefs = refs(spec.factRefs),
        eventRefs = refs(spec.eventRefs),
        modifiers = copy(spec.modifiers) or {},
        world = copy(spec.world),
        perceived = spec.perceived == true,
        distance = tonumber(spec.distance),
        ttlMs = tonumber(spec.ttlMs),
        maxTurns = math.min(
            Scheduler.MAX_TURNS_PER_SCENE,
            math.max(1, math.floor(tonumber(spec.maxTurns) or 4))
        ),
        autoContinue = spec.autoContinue == true
            or recipientIsPlayer,
        maxContinuationSteps = math.min(
            4, math.max(1, math.floor(
                tonumber(spec.maxContinuationSteps) or 2
            ))
        ),
        allowNpcAfterPlayer = spec.allowNpcAfterPlayer == true,
        silenceThreshold = tonumber(spec.silenceThreshold),
        allowedStrategies = copy(spec.allowedStrategies),
        forbiddenStrategies = copy(spec.forbiddenStrategies),
        cooldownMs = math.max(0, tonumber(spec.cooldownMs) or 5000),
        areaKey = cleanID(spec.areaKey, 96),
        actorCooldownMs = tonumber(spec.actorCooldownMs),
        pairCooldownMs = tonumber(spec.pairCooldownMs),
        topicCooldownMs = tonumber(spec.topicCooldownMs),
        areaWindowMs = tonumber(spec.areaWindowMs),
        areaMaxOpenings = tonumber(spec.areaMaxOpenings),
        bypassBudget = spec.bypassBudget == true,
    }
    if normalized.eventID
        and #normalized.eventRefs < Director.MAX_REFS
    then
        local found = false
        for _, ref in ipairs(normalized.eventRefs) do
            if ref == normalized.eventID then found = true break end
        end
        if not found then
            table.insert(normalized.eventRefs, 1, normalized.eventID)
        end
    end
    return normalized
end

function Director.RegisterProvider()
    local existing = Opportunity.ListProviders()
    for _, row in ipairs(existing) do
        if row.id == Director.PROVIDER_ID then
            return true, "already_registered"
        end
    end
    return Opportunity.RegisterProvider({
        id = Director.PROVIDER_ID,
        order = 25,
        -- Empty means any canonical semantic stimulus family. The submitting
        -- domain still supplies an authoritative eventType.
        stimuli = {},
        propose = function(event, context)
            local social = type(context) == "table"
                and context.socialOpportunity or nil
            if type(social) ~= "table" then return {} end
            if tostring(event.type or "") ~= tostring(social.eventType or "") then
                return {}
            end
            if social.eventID and event.id
                and tostring(event.id) ~= tostring(social.eventID)
            then
                return {}
            end
            return {
                id = social.id,
                dedupeKey = social.id,
                priority = social.priority,
                cooldownMs = social.cooldownMs,
                participants = social.participants,
                audience = social.audience,
                topic = social.topic,
                ttlMs = social.ttlMs,
                maxTurns = social.maxTurns,
                perceived = social.perceived,
                distance = social.distance,
                world = social.world,
                autoContinue = social.autoContinue,
                maxContinuationSteps = social.maxContinuationSteps,
                stimulus = {
                    type = social.eventType,
                    responderID = social.speakerID,
                    intent = social.intent,
                    speechAct = social.speechAct,
                    subject = social.subject,
                    topic = social.topic,
                    eventID = social.eventID,
                    factRefs = social.factRefs,
                    eventRefs = social.eventRefs,
                    modifiers = social.modifiers,
                },
            }
        end,
    })
end

function Director.New(manager, options)
    if type(manager) ~= "table"
        or type(manager.Admit) ~= "function"
    then
        return nil, "social_opportunity_manager_required"
    end
    options = type(options) == "table" and options or {}
    Director.RegisterProvider()
    local instance = {
        manager = manager,
        budget = options.budget or Budget.New({
            clock = options.clock,
        }),
        metrics = {
            submitted = 0,
            admitted = 0,
            rejected = 0,
            silent = 0,
            budgetRejected = 0,
        },
        lastDecision = nil,
    }
    local Methods = {}

    function Methods:Submit(spec)
        self.metrics.submitted = self.metrics.submitted + 1
        local social, reason = Director.Normalize(spec)
        if not social then
            if reason == "social_motive_silence"
                or reason == "social_relevance_low"
            then
                self.metrics.silent = self.metrics.silent + 1
            else
                self.metrics.rejected = self.metrics.rejected + 1
            end
            self.lastDecision = {
                accepted = false,
                reason = reason,
            }
            return {
                accepted = false,
                reason = reason,
            }
        end

        local budgetSpec = {
            actorID = social.speakerID,
            targetID = social.recipientID,
            topic = social.topic,
            areaKey = social.areaKey,
            priority = social.priority,
            actorCooldownMs = social.actorCooldownMs,
            pairCooldownMs = social.pairCooldownMs,
            topicCooldownMs = social.topicCooldownMs,
            areaWindowMs = social.areaWindowMs,
            areaMaxOpenings = social.areaMaxOpenings,
            bypassBudget = social.bypassBudget,
        }
        local available, budgetReason = self.budget:Check(budgetSpec)
        if not available then
            self.metrics.rejected = self.metrics.rejected + 1
            self.metrics.budgetRejected = self.metrics.budgetRejected + 1
            self.lastDecision = {
                accepted = false,
                reason = budgetReason,
                opportunity = copy(social),
            }
            return {
                accepted = false,
                reason = budgetReason,
                opportunity = social,
            }
        end

        -- Reserve only after the existing Opportunity manager admits the
        -- Scene, so failed SceneRuntime capacity/dispatch does not consume an
        -- ambient social budget slot.
        local result = self.manager:Admit({
            type = social.eventType,
            id = social.eventID or social.id,
        }, {
            authority = Director.PROVIDER_ID,
            socialOpportunity = social,
        })
        if result and result.accepted == true then
            self.budget:Reserve(budgetSpec)
            self.metrics.admitted = self.metrics.admitted + 1
            self.lastDecision = {
                accepted = true,
                reason = "social_scene_admitted",
                opportunity = copy(social),
                sceneID = result.sceneID,
            }
            result.socialOpportunity = social
            return result
        end

        self.metrics.rejected = self.metrics.rejected + 1
        local rejectedReason = result and result.reason
            or "social_scene_rejected"
        self.lastDecision = {
            accepted = false,
            reason = rejectedReason,
            opportunity = copy(social),
        }
        return result or {
            accepted = false,
            reason = rejectedReason,
            opportunity = social,
        }
    end

    function Methods:Snapshot()
        local decision = type(self.lastDecision) == "table"
            and self.lastDecision or nil
        local opportunity = decision
            and type(decision.opportunity) == "table"
            and decision.opportunity or nil
        local participantIDs = {}
        if opportunity and type(opportunity.participants) == "table" then
            for index = 1, math.min(
                #opportunity.participants, Director.MAX_PARTICIPANTS
            ) do
                local row = opportunity.participants[index]
                participantIDs[#participantIDs + 1] =
                    cleanID(type(row) == "table" and row.id or nil, 128)
            end
        end
        return {
            schemaVersion = Director.VERSION,
            providerID = Director.PROVIDER_ID,
            metrics = copy(self.metrics),
            budget = self.budget:Snapshot(),
            lastDecision = decision and {
                accepted = decision.accepted == true,
                reason = clean(decision.reason, 128),
                sceneID = cleanID(decision.sceneID, 128),
                opportunity = opportunity and {
                    id = cleanID(opportunity.id, 128),
                    motive = token(opportunity.motive),
                    relevance = tonumber(opportunity.relevance),
                    priority = tonumber(opportunity.priority),
                    eventType = token(opportunity.eventType),
                    eventID = cleanID(opportunity.eventID, 128),
                    topic = cleanID(opportunity.topic, 96),
                    speakerID = cleanID(opportunity.speakerID, 128),
                    recipientID = cleanID(opportunity.recipientID, 128),
                    participantIDs = participantIDs,
                    factRefs = refs(opportunity.factRefs),
                    eventRefs = refs(opportunity.eventRefs),
                } or nil,
            } or nil,
        }
    end

    return setmetatable(instance, { __index = Methods })
end

return Director
