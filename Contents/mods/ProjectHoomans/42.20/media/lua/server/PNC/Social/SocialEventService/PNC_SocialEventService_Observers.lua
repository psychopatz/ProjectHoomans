-- Observer discovery, cooldowns, saturation, and mutation preflight.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents
local Internal = SocialEvents.Internal
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local RelationshipTypes = PNC.RelationshipTypes
local ProfileTypes = PNC.SocialProfileTypes
local ProfileMath = PNC.SocialProfileMath
local personalRelationshipQueries = Internal.PersonalRelationshipQueries
local finiteNumber = Internal.FiniteNumber

local function hasRecentEvent(record, eventID)
    local social = RelationshipTypes.NormalizeSocialState(
        record and record.social,
        record and record.identitySeed,
        record and record.archetypeID
    )
    local index
    for index = 1, #social.recentEventIDs do
        if social.recentEventIDs[index] == eventID then
            return true
        end
    end
    return false
end

local function currentSaturation(relationship, eventType)
    local entry = relationship
        and relationship.saturation
        and relationship.saturation[eventType] or nil
    if type(entry) ~= "table" then
        return 0, 0
    end
    return finiteNumber(entry.approval) or 0,
        finiteNumber(entry.respect) or 0
end

local function cappedContribution(proposed, current, cap)
    proposed = finiteNumber(proposed) or 0
    current = finiteNumber(current) or 0
    cap = finiteNumber(cap)
    if cap == nil then
        return proposed, current + proposed
    end
    if proposed > 0 and cap >= 0 then
        proposed = math.min(proposed, math.max(0, cap - current))
    elseif proposed < 0 and cap <= 0 then
        proposed = math.max(proposed, math.min(0, cap - current))
    end
    return proposed, current + proposed
end

local function observerSpecs(event, definition)
    local output = {}
    local actor = EntityRef.Parse(event.actorKey)
    local target = EntityRef.Parse(event.targetKey)
    if target and target.kind == "npc" then
        output[#output + 1] = {
            observerNPCID = target.npcID,
            aboutKey = event.actorKey,
            role = "target",
        }
    end
    if definition.reciprocalNPCObservers == true
        and actor
        and actor.kind == "npc"
    then
        output[#output + 1] = {
            observerNPCID = actor.npcID,
            aboutKey = event.targetKey,
            role = "actor",
        }
    end
    return output
end

local function preflightObserver(event, definition, observer)
    local record = Registry and Registry.Get
        and Registry.Get(observer.observerNPCID) or nil
    local relationship
    local reason
    local memoryDefinition = definition.targetMemory
    local approvalCurrent
    local respectCurrent
    local approvalEffect
    local respectEffect
    local approvalTotal
    local respectTotal
    local cap = definition.contributionCaps or {}
    local cooldownUntil
    local evaluationAt
    local observerProfile
    local modifiedEffects
    local modifierBreakdown
    if not record or record.alive == false then
        return nil, "observer_not_found"
    end
    if hasRecentEvent(record, event.id) then
        return nil, "duplicate_event"
    end
    relationship, reason = personalRelationshipQueries().Get(
        observer.observerNPCID,
        observer.aboutKey
    )
    if not relationship then
        relationship = PNC.RelationshipTypes.NewRelationship(
            observer.aboutKey
        )
    end
    cooldownUntil = relationship.cooldowns
        and finiteNumber(relationship.cooldowns[event.type]) or nil
    if cooldownUntil and event.occurredAt < cooldownUntil then
        return nil, "cooldown_active"
    end
    approvalCurrent, respectCurrent = currentSaturation(
        relationship,
        event.type
    )
    observerProfile = ProfileTypes.NormalizeNPCPersonality(
        record.social and record.social.personality,
        record.identitySeed,
        record.archetypeID
    )
    modifiedEffects, modifierBreakdown =
        ProfileMath.ModifySocialEvent(
            observerProfile,
            definition,
            event,
            memoryDefinition
        )
    approvalEffect, approvalTotal = cappedContribution(
        modifiedEffects.approvalEffect,
        approvalCurrent,
        cap.approval
    )
    respectEffect, respectTotal = cappedContribution(
        modifiedEffects.respectEffect,
        respectCurrent,
        cap.respect
    )
    if approvalEffect == 0 and respectEffect == 0 then
        return nil, "contribution_saturated"
    end
    evaluationAt = math.max(
        event.occurredAt,
        tonumber(relationship.lastEvaluatedAt) or 0,
        tonumber(record.social and record.social.lastEvaluatedAt) or 0
    )
    return {
        record = record,
        observerNPCID = observer.observerNPCID,
        aboutKey = observer.aboutKey,
        role = observer.role,
        relationshipBefore = relationship,
        mutation = {
            eventID = event.id,
            sourceSystem = event.sourceSystem,
            interactionType = event.type,
            worldAgeHours = evaluationAt,
            familiarityDelta = modifiedEffects.familiarityGain,
            moraleDelta = modifiedEffects.moraleEffect,
            cooldownType = definition.cooldownHours
                and event.type or nil,
            cooldownUntil = definition.cooldownHours
                and (event.occurredAt + definition.cooldownHours) or nil,
            saturationType = event.type,
            saturation = {
                approval = approvalTotal,
                respect = respectTotal,
            },
            memory = {
                id = "memory:" .. event.id .. ":"
                    .. observer.observerNPCID .. ":" .. observer.role,
                type = memoryDefinition.type,
                aboutKey = observer.aboutKey,
                createdAt = event.occurredAt,
                lastEvaluatedAt = evaluationAt,
                approvalEffect = approvalEffect,
                respectEffect = respectEffect,
                moraleEffect = modifiedEffects.moraleEffect,
                strength = memoryDefinition.strength,
                decayPerDay = memoryDefinition.decayPerDay,
                permanent = memoryDefinition.permanent,
                shareable = memoryDefinition.shareable,
                knowledgeSource = memoryDefinition.knowledgeSource,
                sourceKey = nil,
                tags = memoryDefinition.tags,
            },
            interaction = {
                kind = event.type,
                source = event.sourceSystem,
                interactionType = event.type,
                at = event.occurredAt,
                worldAgeHours = evaluationAt,
                applied = true,
            },
        },
        saturationBefore = {
            approval = approvalCurrent,
            respect = respectCurrent,
        },
        saturationAfter = {
            approval = approvalTotal,
            respect = respectTotal,
        },
        modifierBreakdown = modifierBreakdown,
        baseEffects = {
            approvalEffect = memoryDefinition.approvalEffect,
            respectEffect = memoryDefinition.respectEffect,
            moraleEffect = memoryDefinition.moraleEffect,
            familiarityGain = memoryDefinition.familiarityGain,
        },
        modifiedEffects = modifiedEffects,
    }
end

Internal.HasRecentEvent = hasRecentEvent
Internal.CurrentSaturation = currentSaturation
Internal.CappedContribution = cappedContribution
Internal.ObserverSpecs = observerSpecs
Internal.PreflightObserver = preflightObserver

return Internal
