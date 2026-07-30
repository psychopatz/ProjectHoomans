-- Developer snapshots plus guarded named-event dispatch for relationships.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}

local Debug = PNC.RelationshipDebug
local Relationships = PNC.Relationships
local Math = PNC.RelationshipMath
local Types = PNC.RelationshipTypes
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Core = PNC.Core

local DEBUG_EVENTS = {
    treated_wound = "health",
    saved_from_incapacitation = "health",
    protected_from_attacker = "combat",
    survived_combat_together = "combat",
    abandoned_in_combat = "combat",
}

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    local value = gameTime
        and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
    if value ~= value or value == math.huge or value == -math.huge then
        return 0
    end
    return math.max(0, value)
end

local function displayName(record)
    local summary = record and record.identitySummary or nil
    local character = record and record.characterWindow or nil
    return tostring(
        summary and summary.displayName
        or character and character.displayName
        or record and record.name
        or record and record.id
        or "Unknown NPC"
    )
end

local function resolveTarget(player, args, at)
    local targetKind = tostring(args and args.targetKind or "")
    local targetID
    local record
    local key
    if targetKind == "current_player" then
        if not PNC.PlayerCharacters
            or not PNC.PlayerCharacters.GetEntityKey
        then
            return nil, nil, "player_identity_unavailable"
        end
        key, targetID = PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "relationship_debug",
            worldAgeHours = at,
        })
        if not key then
            return nil, nil, targetID
        end
        return key, {
            kind = "player",
            key = key,
            label = player and player.getDisplayName
                and tostring(player:getDisplayName())
                or player and player.getUsername
                and tostring(player:getUsername())
                or "Current player",
        }
    end
    if targetKind ~= "npc" then
        return nil, nil, "invalid_target_kind"
    end
    targetID = args and args.targetNPCID
    if type(targetID) ~= "string"
        and type(targetID) ~= "number"
    then
        return nil, nil, "invalid_target_npc_id"
    end
    targetID = tostring(targetID)
    record = Registry and Registry.Get and Registry.Get(targetID) or nil
    if not record or record.alive == false then
        return nil, nil, "target_npc_not_found"
    end
    key = EntityRef.ForNPC(targetID)
    if not key then
        return nil, nil, "invalid_target_key"
    end
    return key, {
        kind = "npc",
        key = key,
        npcID = targetID,
        label = displayName(record),
    }
end

local function summarizeRelationship(relationship, exists)
    return {
        exists = exists == true,
        targetKind = relationship.targetKind,
        targetID = relationship.targetID,
        baselineApproval = relationship.baselineApproval,
        baselineRespect = relationship.baselineRespect,
        approval = relationship.approval,
        respect = relationship.respect,
        familiarity = relationship.familiarity,
        state = relationship.state,
        previousState = relationship.previousState,
        revision = relationship.revision,
        lastInteractionAt = relationship.lastInteractionAt,
        lastEvaluatedAt = relationship.lastEvaluatedAt,
        memoryCount = #(relationship.memories or {}),
    }
end

local function memorySnapshot(memory, at)
    return {
        id = memory.id,
        type = memory.type,
        aboutKey = memory.aboutKey,
        createdAt = memory.createdAt,
        lastEvaluatedAt = memory.lastEvaluatedAt,
        approvalEffect = memory.approvalEffect,
        respectEffect = memory.respectEffect,
        moraleEffect = memory.moraleEffect,
        strength = memory.strength,
        currentStrength =
            Math.CalculateMemoryStrengthAtTime(memory, at),
        decayPerDay = memory.decayPerDay,
        permanent = memory.permanent == true,
        shareable = memory.shareable == true,
        knowledgeSource = memory.knowledgeSource,
        sourceKey = memory.sourceKey,
        tags = copy(memory.tags or {}),
    }
end

local function personalitySnapshot(record)
    local profile = record
        and record.social
        and record.social.personality or nil
    if not profile then
        return nil
    end
    return {
        orientation = profile.orientation,
        foodPreference = profile.foodPreference,
        romanceStyle = profile.romanceStyle,
        jealousyStyle = profile.jealousyStyle,
        socialStyle = profile.socialStyle,
        compassion = profile.compassion,
        sociability = profile.sociability,
        forgiveness = profile.forgiveness,
        bravery = profile.bravery,
        materialism = profile.materialism,
        aggression = profile.aggression,
        loyalty = profile.loyalty,
    }
end

function Debug.BuildSnapshot(
    observerNPCID,
    targetKey,
    target,
    at,
    actionResult
)
    local observer = Registry and Registry.Get
        and Registry.Get(tostring(observerNPCID or "")) or nil
    local relationship
    local exists
    local reverse
    local reverseExists
    local reverseKey
    local memories = {}
    local index
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    if not EntityRef.IsValid(targetKey) then
        return nil, "invalid_target_key"
    end
    at = tonumber(at)
    if at == nil
        or at ~= at
        or at == math.huge
        or at == -math.huge
    then
        at = worldAgeHours()
    end
    at = math.max(0, at)
    relationship = Relationships.Get(observer.id, targetKey)
    exists = relationship ~= nil
    relationship = relationship or Types.NewRelationship(targetKey)
    if not relationship then
        return nil, "invalid_relationship"
    end
    for index = 1, #(relationship.memories or {}) do
        memories[#memories + 1] =
            memorySnapshot(relationship.memories[index], at)
    end
    table.sort(memories, function(left, right)
        if left.createdAt ~= right.createdAt then
            return left.createdAt > right.createdAt
        end
        return tostring(left.id) < tostring(right.id)
    end)
    if target and target.kind == "npc" then
        reverseKey = EntityRef.ForNPC(observer.id)
        reverse = Relationships.Get(target.npcID, reverseKey)
        reverseExists = reverse ~= nil
        reverse = reverse or Types.NewRelationship(reverseKey)
    end
    return {
        generatedAt = at,
        observer = {
            npcID = observer.id,
            key = EntityRef.ForNPC(observer.id),
            label = displayName(observer),
            morale = observer.social
                and observer.social.morale or 0,
            moraleBaseline = observer.social
                and observer.social.moraleBaseline or 0,
            recordRevision = observer.recordRevision or 0,
            presenceRevision = observer.presenceRevision or 0,
            socialRevision = observer.social
                and observer.social.revision or 0,
            personality = personalitySnapshot(observer),
        },
        target = copy(target),
        relationship = summarizeRelationship(
            relationship,
            exists
        ),
        memories = memories,
        saturation = copy(relationship.saturation or {}),
        cooldowns = copy(relationship.cooldowns or {}),
        reverse = reverse and summarizeRelationship(
            reverse,
            reverseExists
        ) or nil,
        actionResult = copy(actionResult),
    }
end

function Debug.BuildSnapshotForRequest(player, args, actionResult)
    local at = worldAgeHours()
    local observerNPCID = args and args.observerNPCID
    local observer = Registry and Registry.Get
        and Registry.Get(tostring(observerNPCID or "")) or nil
    local targetKey
    local target
    local reason
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    targetKey, target, reason = resolveTarget(player, args, at)
    if not targetKey then
        return nil, reason
    end
    if targetKey == EntityRef.ForNPC(observer.id) then
        return nil, "identical_observer_target"
    end
    return Debug.BuildSnapshot(
        observer.id,
        targetKey,
        target,
        at,
        actionResult
    )
end

function Debug.TriggerSocialEvent(player, args)
    local eventType = tostring(args and args.eventType or "")
    local sourceSystem = DEBUG_EVENTS[eventType]
    local at = worldAgeHours()
    local observerNPCID = args and args.observerNPCID
    local observer = Registry and Registry.Get
        and Registry.Get(tostring(observerNPCID or "")) or nil
    local targetKey
    local target
    local reason
    local processed
    if not sourceSystem then
        return nil, "unsupported_debug_event"
    end
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    targetKey, target, reason = resolveTarget(player, args, at)
    if not targetKey then
        return nil, reason
    end
    if targetKey == EntityRef.ForNPC(observer.id) then
        return nil, "identical_observer_target"
    end
    if not PNC.SocialEvents or not PNC.SocialEvents.Process then
        return nil, "social_event_service_unavailable"
    end
    processed = PNC.SocialEvents.Process({
        id = "social:" .. tostring(
            Core.GenerateID("debug_relationship")
        ),
        type = eventType,
        actorKey = targetKey,
        targetKey = EntityRef.ForNPC(observer.id),
        occurredAt = at,
        sourceSystem = sourceSystem,
        context = {
            debug = true,
            requestedBy = player and player.getUsername
                and tostring(player:getUsername()) or nil,
        },
    })
    return Debug.BuildSnapshot(
        observer.id,
        targetKey,
        target,
        at,
        processed
    )
end

local function signed(value)
    return string.format("%+.2f", tonumber(value) or 0)
end

function Debug.FormatRelationship(
    observerNPCID,
    targetKey,
    relationship,
    worldAgeHours
)
    worldAgeHours = tonumber(worldAgeHours)
        or tonumber(relationship.lastEvaluatedAt)
        or 0
    local lines = {
        "Relationship Debug",
        "Observer: " .. tostring(observerNPCID),
        "Target: " .. tostring(targetKey),
        "",
        "Approval: " .. tostring(relationship.approval),
        "Respect: " .. tostring(relationship.respect),
        "Familiarity: " .. tostring(relationship.familiarity),
        "State: " .. tostring(relationship.state),
        "Previous State: " .. tostring(relationship.previousState),
        "",
        "Baseline Approval: " ..
            tostring(relationship.baselineApproval),
        "Baseline Respect: " ..
            tostring(relationship.baselineRespect),
        "",
        "Active memories:",
    }
    local _
    local memory
    local strength
    if #(relationship.memories or {}) == 0 then
        lines[#lines + 1] = "(none)"
    end
    for _, memory in pairs(relationship.memories or {}) do
        strength = Math.CalculateMemoryStrengthAtTime(
            memory,
            worldAgeHours
        )
        if memory.permanent or strength > 0 then
            lines[#lines + 1] = "+ " .. tostring(memory.type)
            lines[#lines + 1] =
                "  approval: " .. signed(memory.approvalEffect)
            lines[#lines + 1] =
                "  respect: " .. signed(memory.respectEffect)
            lines[#lines + 1] =
                "  current strength: " ..
                string.format("%.4f", strength)
            lines[#lines + 1] =
                "  source: " .. tostring(memory.knowledgeSource)
        end
    end
    return table.concat(lines, "\n")
end

function Debug.Inspect(observerNPCID, targetKey, worldAgeHours)
    local relationship
    local reason
    if not Relationships or not Relationships.Get then
        return nil, "relationship_service_unavailable"
    end
    relationship, reason = Relationships.Get(observerNPCID, targetKey)
    if not relationship then
        return nil, reason
    end
    return Debug.FormatRelationship(
        observerNPCID,
        targetKey,
        relationship,
        worldAgeHours
    )
end

return Debug
