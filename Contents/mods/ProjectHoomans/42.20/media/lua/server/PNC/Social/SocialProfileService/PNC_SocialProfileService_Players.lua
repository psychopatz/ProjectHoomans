if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local SocialProfiles = PNC.SocialProfiles
local H = SocialProfiles.Internal
local PlayerCharacters = PNC.PlayerCharacters
local ProfileTypes = PNC.SocialProfileTypes
local SocialTraits = PNC.SocialTraits

function SocialProfiles.NormalizePlayerProfile(value)
    return ProfileTypes.NormalizePlayerSocialProfile(value)
end

function SocialProfiles.ResolveTraits(traitSet)
    return SocialTraits.ResolveTraits(traitSet)
end

function SocialProfiles.GetPlayerProfile(characterUUID)
    local record = PlayerCharacters
        and PlayerCharacters.GetRegistryRecord
        and PlayerCharacters.GetRegistryRecord(characterUUID) or nil
    if not record then return nil, "character_not_found" end
    return ProfileTypes.NormalizePlayerSocialProfile(record.socialProfile),
        "resolved"
end

function SocialProfiles.GetPlayerProfileForPlayer(player)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "identity_service_unavailable"
    end
    local context, reason = PNC.PlayerContext.Resolve(
        player, "social_profile_read")
    if not context then return nil, reason end
    return SocialProfiles.GetPlayerProfile(context.characterUUID)
end

function SocialProfiles.ResolvePlayerProfile(player, at)
    local uuid
    local reason
    local record
    local current
    local resolved
    local conflicts
    local fingerprint
    local changed
    if not H.IsAuthority() then return nil, "not_authority" end
    if not player or not player.getModData then
        return nil, "invalid_player"
    end
    local context
    context, reason = PNC.PlayerContext.Resolve(player, "social_profile")
    if not context then return nil, reason end
    uuid = context.characterUUID
    record = PlayerCharacters.GetRegistryRecord(uuid)
    current = ProfileTypes.NormalizePlayerSocialProfile(
        record and record.socialProfile)
    local traitSet
    traitSet, reason = H.ExtractTraitSet(player)
    if not traitSet then return nil, reason or "traits_not_ready" end
    resolved, conflicts, fingerprint = SocialTraits.ResolveTraits(traitSet)
    if current.resolvedAt > 0
        and SocialTraits.Fingerprint(current.sourceTraits) == fingerprint
    then
        SocialProfiles.RuntimePlayers[player] = {
            uuid = uuid,
            fingerprint = fingerprint,
        }
        return H.Copy(current), "unchanged"
    end
    resolved.resolvedAt = H.WorldAgeHours(at)
    changed, reason, resolved =
        PlayerCharacters.ApplyResolvedSocialProfile(uuid, resolved)
    SocialProfiles.RuntimePlayers[player] = {
        uuid = uuid,
        fingerprint = fingerprint,
    }
    if #conflicts > 0 then
        local conflict
        for _, conflict in ipairs(conflicts) do
            H.LogProfile("trait_conflict", {
                characterUUID = uuid,
                preferred = conflict.preferred,
                discarded = conflict.discarded,
            })
        end
    end
    H.LogProfile("player_resolution", {
        characterUUID = uuid,
        result = changed and "updated" or "unchanged",
        fingerprint = fingerprint,
    })
    return resolved, reason
end

function SocialProfiles.RefreshPlayerProfile(player, at)
    SocialProfiles.RuntimePlayers[player] = nil
    return SocialProfiles.ResolvePlayerProfile(player, at)
end

function SocialProfiles.EnsurePlayerProfile(player, at)
    local uuid
    local cached
    local record
    local context = PNC.PlayerContext and PNC.PlayerContext.Peek
        and PNC.PlayerContext.Peek(player) or nil
    uuid = context and context.characterUUID or nil
    cached = SocialProfiles.RuntimePlayers[player]
    if uuid and cached and cached.uuid == uuid then
        record = PlayerCharacters.GetRegistryRecord(uuid)
        if record and record.socialProfile then
            return ProfileTypes.NormalizePlayerSocialProfile(
                record.socialProfile), "cached"
        end
    end
    return SocialProfiles.ResolvePlayerProfile(player, at)
end

function SocialProfiles.ResetRuntimePlayers()
    SocialProfiles.RuntimePlayers = setmetatable({}, { __mode = "k" })
end

return SocialProfiles
