if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local SocialProfiles = PNC.SocialProfiles
local H = SocialProfiles.Internal
local ProfileTypes = PNC.SocialProfileTypes
local Generator = PNC.SocialProfileGenerator
local RelationshipTypes = PNC.RelationshipTypes

function SocialProfiles.GenerateNPCProfile(identitySeed, archetypeID, overrides)
    local profile = ProfileTypes.NormalizeNPCPersonality(
        Generator.Generate(identitySeed, archetypeID, overrides),
        identitySeed, archetypeID)
    if H.HasEntries(ProfileTypes.NormalizeNPCPersonalityOverrides(overrides)) then
        H.LogProfile("authored_override", {
            identitySeed = identitySeed,
            archetypeID = archetypeID,
        })
    end
    return profile
end

function SocialProfiles.GetNPCProfile(npcID)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end
    return ProfileTypes.NormalizeNPCPersonality(
        record.social and record.social.personality,
        record.identitySeed,
        record.archetypeID), "resolved"
end

function SocialProfiles.EnsureNPCProfile(record)
    local normalizedSocial
    local changed
    if not H.IsAuthority() then return nil, "not_authority" end
    if type(record) ~= "table" or record.id == nil then
        return nil, "invalid_npc_record"
    end
    normalizedSocial = RelationshipTypes.NormalizeSocialState(
        record.social, record.identitySeed, record.archetypeID)
    changed = not RelationshipTypes.AreEqual(record.social, normalizedSocial)
    if changed then
        normalizedSocial.revision = math.max(
            tonumber(record.social and record.social.revision) or 0,
            tonumber(normalizedSocial.revision) or 0) + 1
        record.social = normalizedSocial
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "social_profile")
        end
        H.LogProfile("npc_generation", {
            npcID = record.id,
            archetypeID = record.archetypeID,
            identitySeed = record.identitySeed,
        })
        if H.HasEntries(normalizedSocial.personalityOverrides) then
            H.LogProfile("authored_override", {
                npcID = record.id,
                archetypeID = record.archetypeID,
                identitySeed = record.identitySeed,
            })
        end
    end
    return H.Copy(normalizedSocial.personality),
        changed and "created" or "existing"
end

return SocialProfiles
