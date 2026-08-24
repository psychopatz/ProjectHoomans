if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}
PNC.StartingCompanionServiceInternal =
    PNC.StartingCompanionServiceInternal or {}

local Starting = PNC.StartingCompanions
local H = PNC.StartingCompanionServiceInternal
local Traits = PNC.StartingCompanionTraits
local Identity = PNC.Identity
local Registry = PNC.Registry

function H.ResolveOrientation(characterUUID)
    local profile = PNC.SocialProfiles
        and PNC.SocialProfiles.GetPlayerProfile
        and PNC.SocialProfiles.GetPlayerProfile(characterUUID) or nil
    return profile and profile.orientation or "straight"
end

function H.SafeID(value)
    value = string.lower(tostring(value or "companion"))
    return string.gsub(value, "[^%w_%-]", "_")
end

function H.MakeNPCID(characterUUID, traitID)
    return "pnc_starting_" .. tostring(characterUUID)
        .. "_" .. H.SafeID(traitID)
end

function H.SharesSurname(spec)
    return spec and spec.sharesSurname == true
end

function H.BuildIdentity(player, npcID, spec, isFemale, seed)
    if not Identity.GenerateResolvedIdentity then return nil end
    local identity = Identity.GenerateResolvedIdentity({
        id = npcID,
        isFemale = isFemale,
        identitySeed = seed,
        archetypeID = "General",
    })
    local surname = H.SharesSurname(spec) and H.PlayerSurname(player) or nil
    if surname and identity then
        identity.survivor = identity.survivor or {}
        local forename = tostring(identity.survivor.forename or "")
        if forename == "" then
            forename = string.match(
                tostring(identity.displayName or ""), "^(%S+)"
            ) or "Alex"
        end
        identity.survivor.forename = forename
        identity.survivor.surname = surname
        identity.displayName = forename .. " " .. surname
    end
    return identity
end

function H.ApplySharedSurname(player, record, spec)
    local surname = H.SharesSurname(spec) and H.PlayerSurname(player) or nil
    local identity = record and record.identity or nil
    if not surname or not identity then return false end
    identity.survivor = identity.survivor or {}
    local forename = tostring(identity.survivor.forename or "")
    if forename == "" then
        forename = string.match(tostring(identity.displayName or ""), "^(%S+)")
            or "Alex"
    end
    if identity.survivor.surname == surname
        and identity.displayName == forename .. " " .. surname
    then
        return false
    end
    identity.survivor.forename = forename
    identity.survivor.surname = surname
    identity.displayName = forename .. " " .. surname
    record.name = identity.displayName
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "starting_companion_shared_name")
    end
    return true
end

return Starting

