-- Central server-authoritative social-event validation and processing.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}

local SocialEvents = PNC.SocialEvents
local Core = PNC.Core
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local RelationshipTypes = PNC.RelationshipTypes
local Relationships = PNC.Relationships
local Definitions = PNC.SocialEventDefinitions
local ProfileTypes = PNC.SocialProfileTypes
local ProfileMath = PNC.SocialProfileMath
local Conduct = PNC.Conduct
local ConductDefinitions = PNC.ConductDefinitions

local FACTION_INCIDENT_BY_SOCIAL_EVENT = {
    saved_from_incapacitation = "member_rescued",
    protected_from_attacker = "member_protected",
    survived_combat_together = "members_fought_together",
    abandoned_in_combat = "member_abandoned",
}

local function factionIDForEntityKey(key)
    local parsed = EntityRef.Parse(key)
    if not parsed or not PNC.Factions then return nil end
    if parsed.kind == "npc" then
        local record = Registry and Registry.Get
            and Registry.Get(parsed.npcID) or nil
        return record
            and PNC.Factions.GetOrganizationalFactionID(record)
            or nil
    end
    if parsed.kind == "player" then
        local faction =
            PNC.Factions.GetFactionForPlayerKey(key)
        return faction and faction.id or nil
    end
    return nil
end

local function result(ok, reason, fields)
    local output = fields or {}
    output.ok = ok == true
    if reason then
        output.reason = reason
    end
    return output
end

local function finiteNumber(value)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function validString(value)
    return type(value) == "string"
        and value ~= ""
        and #value <= 512
        and not string.find(value, "%c")
end

local function isSafe(value, seen, depth, budget)
    local valueType = type(value)
    local key
    local item
    if valueType == "nil"
        or valueType == "string"
        or valueType == "boolean"
    then
        return true
    end
    if valueType == "number" then
        return finiteNumber(value) ~= nil
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return false
    end
    depth = depth or 0
    if depth >= 8 then
        return false
    end
    seen = seen or {}
    budget = budget or { count = 0 }
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > 128
            or (type(key) ~= "string" and type(key) ~= "number")
            or not isSafe(key, seen, depth + 1, budget)
            or not isSafe(item, seen, depth + 1, budget)
        then
            seen[value] = nil
            return false
        end
    end
    seen[value] = nil
    return true
end

local function copySafe(value)
    local output
    local key
    local item
    if type(value) ~= "table" then
        return value
    end
    output = {}
    for key, item in pairs(value) do
        output[key] = copySafe(item)
    end
    return output
end

local function enabled()
    local configured = not PNC.Config
        or not PNC.Config.Relationships
        or PNC.Config.Relationships.EnableSocialEvents ~= false
    if PNC.Sandbox and PNC.Sandbox.GetBoolean then
        return PNC.Sandbox.GetBoolean(
            "EnableSocialEvents",
            configured
        )
    end
    return configured
end

local function isAuthority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function SocialEvents.GetDefinition(eventType)
    local definition = type(eventType) == "string"
        and Definitions[eventType] or nil
    return definition and copySafe(definition) or nil
end

function SocialEvents.Validate(eventSpec)
    local definition
    local occurredAt
    if type(eventSpec) ~= "table" or not isSafe(eventSpec) then
        return result(false, "unsafe_event")
    end
    if not validString(eventSpec.id) then
        return result(false, "invalid_event_id")
    end
    if string.sub(eventSpec.id, 1, 7) ~= "social:" then
        return result(false, "invalid_event_id")
    end
    if not validString(eventSpec.type) then
        return result(false, "invalid_event_type")
    end
    definition = Definitions[eventSpec.type]
    if not definition then
        return result(false, "unknown_event_type")
    end
    if not EntityRef.IsValid(eventSpec.actorKey) then
        return result(false, "invalid_actor_key")
    end
    if not EntityRef.IsValid(eventSpec.targetKey) then
        return result(false, "invalid_target_key")
    end
    if eventSpec.actorKey == eventSpec.targetKey
        and definition.allowSelf ~= true
    then
        return result(false, "identical_actor_target")
    end
    occurredAt = finiteNumber(eventSpec.occurredAt)
    if not occurredAt or occurredAt < 0 then
        return result(false, "invalid_timestamp")
    end
    if not validString(eventSpec.sourceSystem)
        or not definition.allowedSourceSystems[eventSpec.sourceSystem]
    then
        return result(false, "invalid_source_system")
    end
    if eventSpec.context ~= nil and type(eventSpec.context) ~= "table" then
        return result(false, "invalid_context")
    end
    if eventSpec.x ~= nil and finiteNumber(eventSpec.x) == nil then
        return result(false, "invalid_position")
    end
    if eventSpec.y ~= nil and finiteNumber(eventSpec.y) == nil then
        return result(false, "invalid_position")
    end
    if eventSpec.z ~= nil and finiteNumber(eventSpec.z) == nil then
        return result(false, "invalid_position")
    end
    return result(true, nil, {
        event = {
            id = eventSpec.id,
            type = eventSpec.type,
            actorKey = eventSpec.actorKey,
            targetKey = eventSpec.targetKey,
            occurredAt = occurredAt,
            sourceSystem = eventSpec.sourceSystem,
            x = finiteNumber(eventSpec.x),
            y = finiteNumber(eventSpec.y),
            z = finiteNumber(eventSpec.z),
            context = eventSpec.context and copySafe(eventSpec.context)
                or {},
        },
        definition = copySafe(definition),
    })
end

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
    relationship, reason = Relationships.Get(
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

function SocialEvents.Process(eventSpec)
    local validated
    local event
    local definition
    local observers
    local work = {}
    local skippedDuplicates = 0
    local index
    local observer
    local prepared
    local reason
    local applied
    local mutationResult
    local details = {}
    local conductPrepared
    local conductDetails
    local conductDefinition
    local conductApplied
    if not isAuthority() then
        return result(false, "not_authority")
    end
    if not enabled() then
        return result(false, "feature_disabled")
    end
    validated = SocialEvents.Validate(eventSpec)
    if not validated.ok then
        return validated
    end
    event = validated.event
    definition = validated.definition
    observers = observerSpecs(event, definition)
    if #observers == 0 then
        return result(false, "no_npc_observer")
    end
    for index = 1, #observers do
        observer = observers[index]
        prepared, reason = preflightObserver(
            event,
            definition,
            observer
        )
        if prepared then
            work[#work + 1] = prepared
        elseif reason == "duplicate_event" then
            skippedDuplicates = skippedDuplicates + 1
        else
            return result(false, reason, {
                eventID = event.id,
                memoriesCreated = 0,
                relationshipsChanged = 0,
            })
        end
    end
    if #work == 0 and skippedDuplicates > 0 then
        return result(false, "duplicate_event", {
            eventID = event.id,
            memoriesCreated = 0,
            relationshipsChanged = 0,
        })
    end
    conductDefinition = ConductDefinitions
        and ConductDefinitions[event.type] or nil
    if not conductDefinition or not Conduct
        or not Conduct.PrepareSocialEvent
    then
        return result(false, "conduct_definition_unavailable", {
            eventID = event.id,
            memoriesCreated = 0,
            relationshipsChanged = 0,
            conductEvidenceCreated = 0,
        })
    end
    conductPrepared, reason = Conduct.PrepareSocialEvent(
        event,
        conductDefinition
    )
    if not conductPrepared then
        return result(false, reason, {
            eventID = event.id,
            memoriesCreated = 0,
            relationshipsChanged = 0,
            conductEvidenceCreated = 0,
        })
    end
    for index = 1, #work do
        prepared = work[index]
        applied, reason, mutationResult =
            Relationships.ApplyEventMutation(
                prepared.observerNPCID,
                prepared.aboutKey,
                prepared.mutation
            )
        if not applied then
            return result(false, reason, {
                eventID = event.id,
                memoriesCreated = #details,
                relationshipsChanged = #details,
            })
        end
        details[#details + 1] = {
            observerNPCID = prepared.observerNPCID,
            aboutKey = prepared.aboutKey,
            memoryID = mutationResult.memoryID,
            relationshipBefore = prepared.relationshipBefore,
            relationshipAfter = mutationResult.relationship,
            moraleAfter = mutationResult.morale,
            saturationBefore = prepared.saturationBefore,
            saturationAfter = prepared.saturationAfter,
            modifierBreakdown = prepared.modifierBreakdown,
            baseEffects = prepared.baseEffects,
            modifiedEffects = prepared.modifiedEffects,
        }
    end
    conductApplied, reason, conductDetails =
        Conduct.CommitPrepared(conductPrepared)
    if not conductApplied then
        return result(false, reason, {
            eventID = event.id,
            memoriesCreated = #details,
            relationshipsChanged = #details,
            conductEvidenceCreated = 0,
            transactionInvariantFailed = true,
        })
    end
    local output = result(true, nil, {
        eventID = event.id,
        eventType = event.type,
        actorKey = event.actorKey,
        targetKey = event.targetKey,
        memoriesCreated = #details,
        relationshipsChanged = #details,
        details = details,
        conductEvidenceCreated = #(conductDetails or {}),
        conductDetails = conductDetails or {},
    })
    local factionIncidentType =
        FACTION_INCIDENT_BY_SOCIAL_EVENT[event.type]
    if factionIncidentType and PNC.FactionIncidentService then
        local actorFactionID =
            factionIDForEntityKey(event.actorKey)
        local targetFactionID =
            factionIDForEntityKey(event.targetKey)
        if actorFactionID and targetFactionID
            and actorFactionID ~= targetFactionID
        then
            local incidentOK, incidentReason, incidentDetails =
                PNC.FactionIncidentService.RecordPositiveEvent(
                    actorFactionID,
                    targetFactionID,
                    factionIncidentType,
                    {
                        worldAgeHours = event.occurredAt,
                        actorKey = event.actorKey,
                        subjectKey = event.targetKey,
                        externalID = "social-faction:"
                            .. event.id,
                        public = true,
                        witnessed = true,
                    }
                )
            output.factionIncident = {
                ok = incidentOK,
                reason = incidentReason,
                details = incidentDetails,
            }
            if event.type == "survived_combat_together" then
                PNC.FactionIncidentService.RecordPositiveEvent(
                    targetFactionID,
                    actorFactionID,
                    factionIncidentType,
                    {
                        worldAgeHours = event.occurredAt,
                        actorKey = event.targetKey,
                        subjectKey = event.actorKey,
                        externalID = "social-faction-reciprocal:"
                            .. event.id,
                        public = true,
                        witnessed = true,
                    }
                )
            end
        end
    end
    if PNC.SocialEventDebug and PNC.SocialEventDebug.LogProcessed then
        PNC.SocialEventDebug.LogProcessed(output, definition)
    end
    return output
end

function SocialEvents.Emit(eventSpec)
    return SocialEvents.Process(eventSpec)
end

return SocialEvents
