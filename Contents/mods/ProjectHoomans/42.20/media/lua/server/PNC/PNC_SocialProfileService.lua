-- Server-authoritative player profile resolution and NPC profile access.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.SocialProfiles = PNC.SocialProfiles or {}

local SocialProfiles = PNC.SocialProfiles
local Core = PNC.Core
local PlayerCharacters = PNC.PlayerCharacters
local PlayerTypes = PNC.PlayerCharacterTypes
local ProfileTypes = PNC.SocialProfileTypes
local Generator = PNC.SocialProfileGenerator
local ProfileMath = PNC.SocialProfileMath
local SocialTraits = PNC.SocialTraits
local RelationshipTypes = PNC.RelationshipTypes
local CoreTraits = PsychopatzCore and PsychopatzCore.Traits

SocialProfiles.RuntimePlayers = SocialProfiles.RuntimePlayers
    or setmetatable({}, { __mode = "k" })

local function isAuthority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function copy(value)
    if Core and Core.DeepCopy then
        return Core.DeepCopy(value)
    end
    local output = {}
    local key
    local item
    for key, item in pairs(value or {}) do
        output[key] = type(item) == "table" and copy(item) or item
    end
    return output
end

local function call(target, methodName)
    local method = target and target[methodName] or nil
    local ok
    local value
    if not method then
        return nil
    end
    ok, value = pcall(method, target)
    return ok and value or nil
end

local function finiteTimestamp(value)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return math.max(0, value)
end

local function worldAgeHours(value)
    value = finiteTimestamp(value)
    if value ~= nil then
        return value
    end
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(
            0,
            tonumber(gameTime:getWorldAgeHours()) or 0
        ) or 0
end

local function extractTraitID(trait)
    local value
    if type(trait) == "string" then
        return SocialTraits.NormalizeTraitID(trait)
    end
    value = call(trait, "toString")
    if value then
        value = SocialTraits.NormalizeTraitID(tostring(value))
        if value then
            return value
        end
    end
    value = call(trait, "getName")
    return value
        and SocialTraits.NormalizeTraitID(tostring(value)) or nil
end

local function extractTraitSet(player)
    if CoreTraits and CoreTraits.ReadPlayer then
        return CoreTraits.ReadPlayer(player, "ProjectHoomans.Social")
    end
    local characterTraits = call(player, "getCharacterTraits")
    local known = call(characterTraits, "getKnownTraits")
    local output = {}
    local size
    local index
    local trait
    local id
    if not known then
        return output, "ready"
    end
    size = call(known, "size")
    if size ~= nil and known.get then
        for index = 0, math.max(0, tonumber(size) or 0) - 1 do
            -- Kahlua method calls need their index argument; use pcall here.
            local ok
            ok, trait = pcall(known.get, known, index)
            if ok then
                id = extractTraitID(trait)
                if id then
                    output[id] = true
                end
            end
        end
        return output, "ready"
    end
    for _, trait in pairs(known) do
        id = extractTraitID(trait)
        if id then
            output[id] = true
        end
    end
    return output, "ready"
end

local function logProfile(kind, fields)
    if PNC.SocialProfileDebug
        and PNC.SocialProfileDebug.Log
    then
        fields = fields or {}
        fields.kind = kind
        PNC.SocialProfileDebug.Log(fields)
    end
end

local function hasEntries(value)
    local _
    if type(value) ~= "table" then
        return false
    end
    for _, _ in pairs(value) do
        return true
    end
    return false
end

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
    if not record then
        return nil, "character_not_found"
    end
    return ProfileTypes.NormalizePlayerSocialProfile(
        record.socialProfile
    ), "resolved"
end

function SocialProfiles.GetPlayerProfileForPlayer(player)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "identity_service_unavailable"
    end
    local context, reason = PNC.PlayerContext.Resolve(
        player, "social_profile_read"
    )
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
    if not isAuthority() then
        return nil, "not_authority"
    end
    if not player or not player.getModData then
        return nil, "invalid_player"
    end
    local context
    context, reason = PNC.PlayerContext.Resolve(player, "social_profile")
    if not context then return nil, reason end
    uuid = context.characterUUID
    record = PlayerCharacters.GetRegistryRecord(uuid)
    current = ProfileTypes.NormalizePlayerSocialProfile(
        record and record.socialProfile
    )
    local traitSet
    traitSet, reason = extractTraitSet(player)
    if not traitSet then return nil, reason or "traits_not_ready" end
    resolved, conflicts, fingerprint = SocialTraits.ResolveTraits(traitSet)
    if current.resolvedAt > 0
        and SocialTraits.Fingerprint(current.sourceTraits)
            == fingerprint
    then
        SocialProfiles.RuntimePlayers[player] = {
            uuid = uuid,
            fingerprint = fingerprint,
        }
        return copy(current), "unchanged"
    end
    resolved.resolvedAt = worldAgeHours(at)
    changed, reason, resolved =
        PlayerCharacters.ApplyResolvedSocialProfile(uuid, resolved)
    SocialProfiles.RuntimePlayers[player] = {
        uuid = uuid,
        fingerprint = fingerprint,
    }
    if #conflicts > 0 then
        local conflict
        for _, conflict in ipairs(conflicts) do
            logProfile("trait_conflict", {
                characterUUID = uuid,
                preferred = conflict.preferred,
                discarded = conflict.discarded,
            })
        end
    end
    logProfile("player_resolution", {
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
                record.socialProfile
            ), "cached"
        end
    end
    return SocialProfiles.ResolvePlayerProfile(player, at)
end

function SocialProfiles.ResetRuntimePlayers()
    SocialProfiles.RuntimePlayers =
        setmetatable({}, { __mode = "k" })
end

function SocialProfiles.GenerateNPCProfile(
    identitySeed,
    archetypeID,
    overrides
)
    local profile = ProfileTypes.NormalizeNPCPersonality(
        Generator.Generate(identitySeed, archetypeID, overrides),
        identitySeed,
        archetypeID
    )
    if hasEntries(
        ProfileTypes.NormalizeNPCPersonalityOverrides(overrides)
    ) then
        logProfile("authored_override", {
            identitySeed = identitySeed,
            archetypeID = archetypeID,
        })
    end
    return profile
end

function SocialProfiles.GetNPCProfile(npcID)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then
        return nil, "npc_not_found"
    end
    return ProfileTypes.NormalizeNPCPersonality(
        record.social and record.social.personality,
        record.identitySeed,
        record.archetypeID
    ), "resolved"
end

function SocialProfiles.EnsureNPCProfile(record)
    local normalizedSocial
    local changed
    if not isAuthority() then
        return nil, "not_authority"
    end
    if type(record) ~= "table" or record.id == nil then
        return nil, "invalid_npc_record"
    end
    normalizedSocial = RelationshipTypes.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    changed = not RelationshipTypes.AreEqual(
        record.social,
        normalizedSocial
    )
    if changed then
        normalizedSocial.revision = math.max(
            tonumber(record.social and record.social.revision) or 0,
            tonumber(normalizedSocial.revision) or 0
        ) + 1
        record.social = normalizedSocial
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "social_profile")
        end
        logProfile("npc_generation", {
            npcID = record.id,
            archetypeID = record.archetypeID,
            identitySeed = record.identitySeed,
        })
        if hasEntries(normalizedSocial.personalityOverrides) then
            logProfile("authored_override", {
                npcID = record.id,
                archetypeID = record.archetypeID,
                identitySeed = record.identitySeed,
            })
        end
    end
    return copy(normalizedSocial.personality),
        changed and "created" or "existing"
end

function SocialProfiles.IsGenderCompatible(...)
    return ProfileMath.IsGenderCompatible(...)
end

function SocialProfiles.AreMutuallyOrientationCompatible(...)
    return ProfileMath.AreMutuallyOrientationCompatible(...)
end

function SocialProfiles.ModifySocialEvent(...)
    return ProfileMath.ModifySocialEvent(...)
end

return SocialProfiles
