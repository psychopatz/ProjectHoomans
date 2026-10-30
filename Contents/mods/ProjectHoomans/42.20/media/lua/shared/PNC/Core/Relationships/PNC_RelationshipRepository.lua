-- Closed social schema and persistence projection; domain services retain authority.
local Repository = {}
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local RelationshipTypes = PNC.RelationshipTypes
local RelationshipMath = PNC.RelationshipMath

function Repository.Normalize(raw, identitySeed, archetypeID)
    local social
    local targetKey
    local relationship
    if RelationshipTypes and RelationshipTypes.NormalizeSocialState then
        social = RelationshipTypes.NormalizeSocialState(
            raw,
            identitySeed,
            archetypeID
        )
        if RelationshipMath
            and RelationshipMath.RecalculateRelationship
        then
            for targetKey, relationship in pairs(
                social.relationships
            ) do
                social.relationships[targetKey] =
                    RelationshipMath.RecalculateRelationship(
                        relationship,
                        targetKey,
                        relationship.lastEvaluatedAt
                    )
            end
        end
        return social
    end
    return {
        schemaVersion = 3,
        revision = 0,
        morale = 0,
        moraleBaseline = 0,
        relationships = {},
        recentEventIDs = {},
        lastEvaluatedAt = 0,
        personality = nil,
        personalityOverrides = {},
        conduct = PNC.ConductTypes
            and PNC.ConductTypes.NewConductRecord() or nil,
    }
end

function Repository.SerializeRecord(record)
    local social = Repository.Normalize(
        record and record.social,
        record and record.identitySeed,
        record and record.archetypeID
    )
    -- Conduct scores are a projection of baseline + evidence. Keep the
    -- evidence authoritative in the save and rebuild this view on load.
    if social and social.conduct then
        social.conduct.scores = nil
    end
    return social
end

function Repository.IsStaleGeneratedPersonality(raw)
    local social = type(raw.social) == "table" and raw.social or nil
    local personality = social and social.personality or nil
    local version = personality and tonumber(personality.generationVersion)
        or nil
    local currentVersion = PNC.SocialProfileConstants
        and tonumber(PNC.SocialProfileConstants.NPC_GENERATION_VERSION)
        or nil
    local generated = personality
        and (personality.generatedFromSeed == true
            or (personality.generatedFromSeed == nil
                and (version or 0) > 0))
    return generated and currentVersion ~= nil
        and math.max(0, math.floor(version or 0)) ~= math.max(
            1, math.floor(currentVersion))
end

function Repository.RestoreRecord(record, raw)
    record.social = Repository.Normalize(
        raw.social,
        record.identitySeed,
        record.archetypeID
    )
    if Repository.IsStaleGeneratedPersonality(raw)
        and PNC.Registry and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(record, "social_profile_regenerated")
    end
end

return Repository
