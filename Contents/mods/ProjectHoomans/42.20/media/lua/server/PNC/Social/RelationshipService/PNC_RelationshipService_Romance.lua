-- Server-authoritative player proposal and NPC acceptance boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local EntityRef = PNC.EntityRef
local Profiles = PNC.SocialProfiles
local ProfileMath = PNC.SocialProfileMath
local ProfileTypes = PNC.SocialProfileTypes
local Policy = PNC.RelationshipProposalPolicy

local function methodValue(target, methodName)
    local method = target and target[methodName]
    local ok
    local value
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target)
    return ok and value or nil
end

local function playerIsFemale(player)
    local value = player and player.isFemale or nil
    if type(value) == "function" then
        value = methodValue(player, "isFemale")
    end
    return type(value) == "boolean" and value or nil
end

local function npcIsFemale(record)
    if type(record) ~= "table" then return nil end
    if type(record.isFemale) == "boolean" then
        return record.isFemale
    end
    if record.identity and type(record.identity.isFemale) == "boolean" then
        return record.identity.isFemale
    end
    return nil
end

local function playerIsAvailable(player)
    if not player then return false end
    if player.isDead == true then return false end
    if type(player.isDead) == "function"
        and methodValue(player, "isDead") == true
    then
        return false
    end
    return true
end

local function npcIsAvailable(record)
    return type(record) == "table"
        and record.alive ~= false
        and record.available ~= false
        and not (record.runtime and record.runtime.available == false)
end

local function worldAgeHours(value)
    value = tonumber(value)
    if value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
    then
        return math.max(0, value)
    end
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(0, tonumber(getGameTime():getWorldAgeHours()) or 0)
    end
    return 0
end

local function playerKey(player, at)
    if PNC.PlayerCharacters
        and type(PNC.PlayerCharacters.GetEntityKey) == "function"
    then
        return PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "relationship_proposal",
            worldAgeHours = at,
        })
    end
    return nil, "player_identity_service_unavailable"
end

local function resolvePlayerProfile(player, at)
    local profile
    local reason
    if not Profiles then return nil, "social_profile_service_unavailable" end
    if type(Profiles.EnsurePlayerProfile) == "function" then
        profile, reason = Profiles.EnsurePlayerProfile(player, at)
        if profile then return profile end
    end
    if type(Profiles.GetPlayerProfileForPlayer) == "function" then
        profile, reason = Profiles.GetPlayerProfileForPlayer(player)
        if profile then return profile end
    end
    return nil, reason or "player_social_profile_unavailable"
end

local function resolveNPCProfile(record)
    local profile
    if Profiles and type(Profiles.GetNPCProfile) == "function" then
        profile = Profiles.GetNPCProfile(record and record.id)
    end
    if profile then return profile end
    if not ProfileTypes then return nil end
    return ProfileTypes.NormalizeNPCPersonality(
        record and record.social and record.social.personality,
        record and record.identitySeed,
        record and record.archetypeID,
        record and record.social and record.social.personalityOverrides,
        record
    )
end

local function relationshipEvaluation(
    observerNPCID,
    targetKey,
    player,
    at
)
    local record
    local reason
    local relationship
    local bond
    local playerProfile
    local npcProfile
    local compatible = false
    local actualTargetKey
    local playerGender
    local npcGender
    local evaluation
    if not Internal.isAuthority() then return nil, "not_authority" end
    at = worldAgeHours(at)
    record, reason = Internal.resolveObserver(observerNPCID)
    if not record then return nil, reason end
    targetKey, reason = Internal.validateTarget(targetKey)
    if not targetKey or not EntityRef.IsPlayer(targetKey) then
        return nil, "player_target_required"
    end
    if not playerIsAvailable(player) then
        return nil, "player_unavailable"
    end
    actualTargetKey = playerKey(player, at)
    if not actualTargetKey or tostring(actualTargetKey) ~= tostring(targetKey) then
        return nil, "player_identity_mismatch"
    end
    relationship = Internal.getRelationship(record, targetKey)
    if not relationship then return nil, "relationship_not_found" end
    relationship = Types.NormalizeRelationship(relationship, targetKey)
    bond = Types.NormalizeBond(relationship.bond)
    playerProfile, reason = resolvePlayerProfile(player, at)
    if not playerProfile then return nil, reason end
    npcProfile = resolveNPCProfile(record)
    if not npcProfile then return nil, "npc_social_profile_unavailable" end
    playerGender = playerIsFemale(player)
    npcGender = npcIsFemale(record)
    if playerGender ~= nil and npcGender ~= nil
        and ProfileMath
        and type(ProfileMath.AreMutuallyOrientationCompatible) == "function"
    then
        compatible = ProfileMath.AreMutuallyOrientationCompatible(
            npcProfile,
            npcGender,
            playerProfile,
            playerGender
        ) == true
    end
    evaluation = Policy.EvaluateEligibility(
        relationship,
        bond,
        compatible,
        npcIsAvailable(record) and playerIsAvailable(player),
        at
    )
    evaluation.observerNPCID = tostring(observerNPCID)
    evaluation.targetKey = targetKey
    evaluation.bond = bond
    evaluation.relationship = relationship
    evaluation.npcProfile = npcProfile
    evaluation.playerProfile = playerProfile
    evaluation.playerGender = playerGender
    evaluation.npcGender = npcGender
    evaluation.at = at
    return evaluation
end

function Relationships.EvaluateProposal(
    observerNPCID,
    targetKey,
    player,
    at
)
    return relationshipEvaluation(observerNPCID, targetKey, player, at)
end

local function proposalMemory(record, targetKey, at, accepted, eventID)
    return Types.NewMemory({
        id = eventID,
        type = accepted
            and "relationship_proposal_accepted"
            or "relationship_proposal_rejected",
        aboutKey = targetKey,
        createdAt = at,
        lastEvaluatedAt = at,
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = accepted and 1 or 0.5,
        decayPerDay = accepted and 0 or 0.1,
        permanent = accepted,
        shareable = accepted,
        knowledgeSource = Constants.KNOWLEDGE_EXPERIENCED,
        sourceKey = targetKey,
        tags = {
            social_history = true,
            relationship_proposal = true,
            accepted = accepted,
        },
    })
end

function Relationships.Propose(
    observerNPCID,
    targetKey,
    player,
    at
)
    local evaluation, reason = relationshipEvaluation(
        observerNPCID,
        targetKey,
        player,
        at
    )
    local record
    local social
    local relationship
    local accepted
    local acceptance
    local eventID
    local memory
    local atValue
    local style
    if not evaluation then return false, reason end
    if not evaluation.eligible then
        return false, evaluation.reason, evaluation
    end
    record = Internal.resolveObserver(observerNPCID)
    atValue = evaluation.at
    style = evaluation.npcProfile and evaluation.npcProfile.romanceStyle
        or "neutral"
    acceptance = Policy.EvaluateAcceptance(
        record.identitySeed or record.id,
        targetKey .. ":" .. tostring(evaluation.relationship.revision)
            .. ":" .. Policy.ActionID(),
        evaluation.relationship,
        evaluation.npcProfile
    )
    accepted = acceptance.accepted == true
    eventID = "social:relationship_proposal_"
        .. (accepted and "accepted:" or "rejected:")
        .. tostring(record.id) .. ":" .. tostring(targetKey) .. ":"
        .. tostring(evaluation.relationship.revision + 1)
    memory = proposalMemory(record, targetKey, atValue, accepted, eventID)
    if not memory then return false, "proposal_memory_invalid" end
    social = Types.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    relationship = Types.NormalizeRelationship(
        Internal.getRelationship(record, targetKey),
        targetKey
    )
    relationship.memories[#relationship.memories + 1] = memory
    while #relationship.memories > Constants.MEMORY_LIMIT do
        table.remove(relationship.memories, 1)
    end
    if accepted then
        relationship.bond = {
            schemaVersion = Constants.DURABLE_BOND_SCHEMA_VERSION,
            class = "lover",
            kind = nil,
            establishedAt = atValue,
            source = "relationship_proposal",
        }
    else
        relationship.cooldowns[Policy.CooldownType()] = atValue
            + Policy.CooldownHours(style)
    end
    Internal.appendRecentEvent(social, eventID)
    social.relationships[targetKey] = relationship
    Internal.commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        atValue,
        {
            kind = accepted
                and "relationship_proposal_accepted"
                or "relationship_proposal_rejected",
            eventID = eventID,
            memoryID = eventID,
            action = Policy.ActionID(),
        }
    )
    evaluation.acceptance = acceptance
    evaluation.accepted = accepted
    evaluation.result = accepted and "accepted" or "rejected"
    evaluation.cooldownUntil = relationship.cooldowns[Policy.CooldownType()]
    evaluation.relationship = Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    )
    evaluation.bond = evaluation.relationship.bond
    return true, evaluation.result, evaluation
end

return Relationships
