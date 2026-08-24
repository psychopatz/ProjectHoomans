if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Internal = Debug.Internal
local Math = PNC.RelationshipMath
local copy = Internal.copy

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

local function factionSnapshot(record)
    if not record then
        return {
            organizationalFaction = false,
            label = "No organizational faction",
        }
    end
    local affiliation = PNC.Factions
        and PNC.Factions.GetNPCAffiliation
        and PNC.Factions.GetNPCAffiliation(record.id)
        or nil
    local faction = affiliation
        and affiliation.factionID
        and PNC.Factions.Get(affiliation.factionID)
        or nil
    local community = affiliation
        and affiliation.communityID
        and PNC.Communities
        and PNC.Communities.Get
        and PNC.Communities.Get(affiliation.communityID)
        or nil
    return {
        organizationalFaction = faction ~= nil,
        label = faction and faction.name
            or "No organizational faction",
        factionID = faction and faction.id or nil,
        archetypeID = faction and faction.archetypeID or nil,
        policy = faction and copy(faction.policy) or nil,
        membershipStatus = affiliation
            and affiliation.membershipStatus
            or "unaffiliated",
        role = affiliation and affiliation.role or "civilian",
        rank = affiliation and affiliation.rank or "member",
        affiliationRevision = affiliation
            and affiliation.revision or 0,
        communityID = community and community.id or nil,
        communityName = community and community.name or nil,
        communityRole = affiliation
            and affiliation.communityRole or nil,
        insideCommunityHome = community
            and PNC.CommunityMath
            and PNC.CommunityMath.IsInsideHomeArea(
                community,
                record.x,
                record.y,
                record.z
            ) or false,
    }
end

local function playerFactionSnapshot(targetKey)
    local faction = PNC.Factions
        and PNC.Factions.GetDiplomacyFactionForPlayerKey
        and PNC.Factions
            .GetDiplomacyFactionForPlayerKey(targetKey)
        or nil
    if not faction then return factionSnapshot(nil) end
    return {
        organizationalFaction = true,
        label = faction.name,
        factionID = faction.id,
        archetypeID = faction.archetypeID,
        membershipStatus = "player_member",
        role = faction.ownerPlayerKey == targetKey
            and "owner" or "member",
        rank = faction.ownerPlayerKey == targetKey
            and "leader" or "member",
        affiliationRevision = faction.revision or 0,
    }
end

local function actionSnapshot(value)
    if type(value) ~= "table" then return nil end
    local details = {}
    local conductDetails = {}
    for _, item in ipairs(value.details or {}) do
        details[#details + 1] = {
            observerNPCID = item.observerNPCID,
            aboutKey = item.aboutKey,
            memoryID = item.memoryID,
            saturationBefore = copy(item.saturationBefore),
            saturationAfter = copy(item.saturationAfter),
            modifierBreakdown = copy(item.modifierBreakdown),
            baseEffects = copy(item.baseEffects),
            modifiedEffects = copy(item.modifiedEffects),
        }
    end
    for _, item in ipairs(value.conductDetails or {}) do
        conductDetails[#conductDetails + 1] = {
            entityKey = item.entityKey,
            evidenceID = item.evidenceID,
            evidence = copy(item.evidence),
            conductRevision = item.conduct
                and item.conduct.revision or nil,
        }
    end
    return {
        ok = value.ok == true,
        reason = value.reason,
        eventID = value.eventID,
        eventType = value.eventType,
        memoriesCreated = value.memoriesCreated or 0,
        relationshipsChanged = value.relationshipsChanged or 0,
        conductEvidenceCreated =
            value.conductEvidenceCreated or 0,
        details = details,
        conductDetails = conductDetails,
    }
end

Internal.summarizeRelationship = summarizeRelationship
Internal.memorySnapshot = memorySnapshot
Internal.personalitySnapshot = personalitySnapshot
Internal.factionSnapshot = factionSnapshot
Internal.playerFactionSnapshot = playerFactionSnapshot
Internal.actionSnapshot = actionSnapshot
