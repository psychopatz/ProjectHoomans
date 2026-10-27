if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local Network = PNC.Network
local socialContext = H.SocialContext
local socialContextConstants = H.SocialContextConstants
local callSpeechEventID = H.CallSpeechEventID
local updateSpeechEventID = H.UpdateSpeechEventID
local repeatSpeechEventID = H.RepeatSpeechEventID
local SocialReactions = PNC.Semantics
    and PNC.Semantics.SocialReactions or nil
if not SocialReactions then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticSocialReaction"
    )
    SocialReactions = ok and loaded or nil
end
local now = H.Now
local clean = H.Clean
local playerCanHear = H.PlayerCanHear
local recordAttackerName = H.RecordAttackerName
local buildInput = H.BuildInput
local lastCallByNPC = H.LastCallByNPC
local markCalled = H.MarkCalled
local HEAR_RADIUS = H.HEAR_RADIUS
local CALL_COOLDOWN_MS = H.CALL_COOLDOWN_MS
local UPDATE_COOLDOWN_MS = H.UPDATE_COOLDOWN_MS
local REPEAT_INTERVAL_MS = H.REPEAT_INTERVAL_MS

local function semanticEventTypeFor(speechEventID)
    if speechEventID == callSpeechEventID() then return "incapacitated_call" end
    if speechEventID == updateSpeechEventID() then return "incapacitated_update" end
    if speechEventID == repeatSpeechEventID() then return "incapacitated_repeat" end
    return "incapacitated_call"
end

local function eventFacts(eventRef, context, reason)
    local threat = context and context.downedThreat
    local attacker = context and context.downedAttackerName or nil
    local fact = {
        eventRef = eventRef,
        authoritative = true,
        disclosure = "player",
        summary = "the NPC was incapacitated",
        happened = "the NPC was incapacitated",
        healthState = "incapacitated",
        need = context and context.downedNeed or nil,
        needType = context and context.downedNeed or nil,
        attackerName = attacker,
        attacker = attacker,
        attackerKind = threat ~= "unknown" and threat or nil,
        reason = reason,
    }
    if not fact.attacker and fact.attackerKind then
        fact.attacker = fact.attackerKind
    end
    return { [tostring(eventRef)] = fact }
end

local function eventFactRefs(eventRef, context)
    local refs = { tostring(eventRef) }
    if context and context.downedNeed then
        refs[#refs + 1] = tostring(eventRef) .. ":need"
    end
    if context and (context.downedAttackerName or context.downedThreat)
        and context.downedThreat ~= "unknown"
    then
        refs[#refs + 1] = tostring(eventRef) .. ":attacker"
    end
    return refs
end

-- ---------------------------------------------------------------------------
-- Delivery
-- ---------------------------------------------------------------------------

local function emitDistress(record, speechEventID, needInputs, reason, cooldownMs)
    local npcID = clean(record and record.id, nil)
    local at = now()
    if not npcID then return 0, "invalid_subject" end
    if record.alive == false then return 0, "subject_dead" end
    local previous = lastCallByNPC[npcID]
    if previous and at - previous < cooldownMs then
        return 0, "debounced"
    end
    local resolver = socialContext()
    if not resolver or type(resolver.BuildContext) ~= "function" then
        return 0, "resolver_unavailable"
    end
    if not Network
        or type(Network.SendConversationRelationshipForNPC) ~= "function"
    then
        return 0, "transport_unavailable"
    end
    if not Core or type(Core.ForEachPlayer) ~= "function" then
        return 0, "player_enumerator_unavailable"
    end
    local radiusSq = HEAR_RADIUS * HEAR_RADIUS
    local emitted = 0
    local semanticUnavailable = false
    local eventID = "downed:" .. npcID .. ":" .. tostring(math.floor(at))
    local semanticEventType = semanticEventTypeFor(speechEventID)
    markCalled(npcID, at)
    Core.ForEachPlayer(function(player)
        if not player or not playerCanHear(player, record, radiusSq) then
            return
        end
        local input, threat = buildInput(record, player, needInputs)
        local context = resolver.BuildContext(input)
        local planningContext = {}
        local realization
        local key
        for key, value in pairs(input or {}) do
            planningContext[key] = value
        end
        for key, value in pairs(context or {}) do
            planningContext[key] = value
        end
        context.eventType = semanticEventType
        context.eventRef = eventID
        context.eventID = eventID
        context.downedAttackerName = recordAttackerName(threat)
        context.attackerKind = context.downedThreat
        context.downedReason = reason
        context.victimNPCID = npcID
        context.factRefs = eventFactRefs(eventID, context)
        context.semanticEventFacts = eventFacts(eventID, context, reason)
        planningContext.eventType = semanticEventType
        planningContext.eventRef = eventID
        planningContext.eventID = eventID
        planningContext.npcID = npcID
        planningContext.downedAttackerName = context.downedAttackerName
        planningContext.downedReason = reason
        planningContext.factRefs = context.factRefs
        planningContext.semanticEventFacts = context.semanticEventFacts
        if SocialReactions and type(SocialReactions.Resolve) == "function" then
            realization = SocialReactions.Resolve({
                eventType = semanticEventType,
                act = "REQUEST",
                topic = "medical_distress",
                context = planningContext,
                eventID = eventID,
                npcID = npcID,
            })
        end
        if not realization
            or type(realization.fallback) ~= "string"
            or realization.fallback == ""
        then
            semanticUnavailable = true
            return
        end
        context.offerIDs = realization.offerIDs or {}
        local result = {
            source = semanticEventType,
            eventID = eventID,
            npcID = npcID,
            ambientFlavor = {
                eventID = eventID,
                eventRef = eventID,
                speechEventID = speechEventID,
                text = realization.fallback,
                semanticOwned = true,
                eventType = semanticEventType,
                semanticEventFacts = context.semanticEventFacts,
                offerIDs = realization.offerIDs,
                act = realization.semanticAct or "REQUEST",
                topic = realization.topic or "medical_distress",
                responsePlanID = realization.responsePlanID,
                poolID = realization.realizationFamily,
                realizationFamily = realization.realizationFamily,
                realizationID = realization.realizationID,
                factRefs = realization.groundedFactRefs,
                family = (socialContextConstants().FAMILY or "incapacitated_distress"),
                priority = (socialContextConstants().PRIORITY or 70),
                weight = (socialContextConstants().WEIGHT or 3),
                llmEligible = false,
                memoryEligible = false,
                npcID = npcID,
                npcType = context.downedAudience,
                socialRole = context.downedAudience,
                relationshipState = input.relationshipState,
                relationshipTier = input.relationshipTier,
                -- One merge key per downed episode keeps "call" and "update"
                -- as a single visible line that updates in place.
                mergeKey = npcID .. ":" .. (socialContextConstants().FAMILY or "incapacitated_distress"),
                cooldowns = {
                    familyMs = (socialContextConstants().FAMILY_COOLDOWN_MS or 15000),
                    speakerMs = (socialContextConstants().SPEAKER_COOLDOWN_MS or 12000),
                    ambientMs = (socialContextConstants().AMBIENT_CADENCE_MS or 4500),
                    mergeWindowMs = (socialContextConstants().MERGE_WINDOW_MS or 8000),
                },
                ttlMs = (socialContextConstants().TTL_MS or 12000),
                holdMs = (socialContextConstants().HOLD_MS or 3200),
                context = context,
                source = {
                    kind = "semantic_speech",
                    channel = "health",
                    eventType = semanticEventType,
                    contextEligible = false,
                },
            },
        }
        local ok, sent = pcall(
            Network.SendConversationRelationshipForNPC,
            player,
            npcID,
            speechEventID,
            result
        )
        if ok and sent == true then
            emitted = emitted + 1
        end
    end)
    if emitted > 0 then return emitted, "emitted" end
    if semanticUnavailable then
        return 0, "semantic_realization_unavailable"
    end
    return 0, "no_audience"
end

-- ---------------------------------------------------------------------------
-- Wound picture -> resolver need inputs
-- ---------------------------------------------------------------------------

local function boundedPressure(value)
    value = tonumber(value)
    if value == nil or value ~= value then return 0 end
    return math.max(0, math.min(1, value))
end

local function needStateFor(record)
    local repository = PNC.NeedsRepository
    if repository and type(repository.Get) == "function" then
        local ok, state = pcall(repository.Get, record, false)
        if ok and type(state) == "table" then
            return type(state.needs) == "table" and state.needs or state
        end
    end
    return record and type(record.needs) == "table" and record.needs or {}
end

local function activeAilment(body, id)
    local ailments = body and body.wholeBodyAilments
    local value = ailments and ailments[id]
    if type(value) == "table" then
        return boundedPressure(value.severity or value.value) > 0
    end
    return value == true or boundedPressure(value) > 0
end

local function woundInputs(record)
    local wounds = PNC.NPCWounds
    local summary
    if wounds and type(wounds.BuildStatusSummary) == "function" then
        local ok, value = pcall(wounds.BuildStatusSummary, record)
        if ok then summary = value end
    end
    local treatable = {}
    if wounds and type(wounds.GetTreatableWounds) == "function" then
        local ok, value = pcall(wounds.GetTreatableWounds, record)
        if ok and type(value) == "table" then treatable = value end
    end
    local infected = false
    if wounds and type(wounds.HasActiveInfection) == "function" then
        local ok, value = pcall(wounds.HasActiveInfection, record)
        if ok then infected = value == true end
    end
    local health = record.health or {}
    local needs = needStateFor(record)
    local body = type(health.body) == "table" and health.body or {}
    local stamina = type(record.stamina) == "table" and record.stamina or {}
    local thirst = boundedPressure(needs.thirst)
    local hunger = boundedPressure(needs.hunger)
    local fatigue = boundedPressure(needs.fatigue)
    local staminaRatio = tonumber(stamina.ratio or record.staminaRatio)
    if staminaRatio == nil then
        local staminaCurrent = tonumber(stamina.current)
        local staminaMax = tonumber(stamina.max)
        if staminaCurrent ~= nil and staminaMax and staminaMax > 0 then
            staminaRatio = staminaCurrent / staminaMax
        end
    end
    local current = tonumber(health.current)
    local max = tonumber(health.max)
    local critical = current == nil or max == nil or max <= 0
        or (current / max) <= 0.25
    return {
        bleeding = summary and summary.bleeding == true or false,
        bleedingRate = summary and tonumber(summary.bleedingRate),
        openWoundCount = summary and summary.openWoundCount,
        treatableWoundCount = #treatable,
        infected = infected,
        critical = critical,
        thirst = thirst,
        hunger = hunger,
        fatigue = fatigue,
        dehydration = activeAilment(body, "dehydration"),
        starvation = activeAilment(body, "starvation"),
        staminaState = stamina.state or record.staminaState,
        staminaRatio = staminaRatio,
    }
end

-- ---------------------------------------------------------------------------
-- Public hooks
-- ---------------------------------------------------------------------------

-- Called from the health module the moment an NPC enters the downed state.
function Hooks.OnIncapacitated(record, reason)
    if not record or record.alive == false then
        return false, "invalid_subject"
    end
    local emitted, status = emitDistress(
        record,
        callSpeechEventID(),
        woundInputs(record),
        reason,
        CALL_COOLDOWN_MS
    )
    return emitted > 0, status
end

-- Called when the wound picture changes while the NPC is still down, so a
-- follower that starts bleeding out asks for a bandage specifically.
function Hooks.OnIncapacitatedStatusChanged(record, reason)
    if not record or record.alive == false then
        return false, "invalid_subject"
    end
    local health = record.health
    if not health or health.state ~= "incapacitated" then
        return false, "not_incapacitated"
    end
    local emitted, status = emitDistress(
        record,
        updateSpeechEventID(),
        woundInputs(record),
        reason,
        UPDATE_COOLDOWN_MS
    )
    return emitted > 0, status
end

-- Driven by the existing incapacitated behavior tick (PNC.BehaviorIncapacitated
-- .Tick), which already runs per-tick for exactly the downed NPCs.  No timer is
-- added: this only decides whether enough time has passed to ask again.
function Hooks.TickIncapacitatedDistress(record)
    local npcID
    local at
    local previous
    if not record or record.alive == false then return false end
    local health = record.health
    if not health or health.state ~= "incapacitated" then return false end
    npcID = clean(record.id, nil)
    if not npcID then return false end
    at = now()
    previous = lastCallByNPC[npcID]
    if not previous then
        -- The NPC went down through a path that did not emit the initial call
        -- (loaded save, desync).  Treat the first tick as the call instead of
        -- waiting a full interval in silence.
        return Hooks.OnIncapacitated(record, "tick_adopted")
    end
    if at - previous < REPEAT_INTERVAL_MS then return false end
    local emitted, status = emitDistress(
        record,
        repeatSpeechEventID(),
        woundInputs(record),
        "repeat",
        REPEAT_INTERVAL_MS
    )
    return emitted > 0, status
end

-- Test/debug support.
function H.IncapacitatedSpeechDebugReset()
    return H.ResetIncapacitatedSpeechState()
end

return Hooks
