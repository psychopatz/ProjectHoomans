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

function H.SharesAppearance(spec)
    return spec and spec.sharesAppearance == true
end

function H.ResolveSharedSkinTexture(texture, isFemale)
    local index = string.match(tostring(texture or ""), "Body(%d+)")
    if not index then
        return nil
    end
    return (isFemale and "FemaleBody" or "MaleBody") .. index
end

local function copyColor(color)
    if type(color) ~= "table" then return nil end
    return {
        r = tonumber(color.r) or 0.2,
        g = tonumber(color.g) or 0.1,
        b = tonumber(color.b) or 0.1,
    }
end

local function sameColor(left, right)
    return type(left) == "table"
        and type(right) == "table"
        and tonumber(left.r) == tonumber(right.r)
        and tonumber(left.g) == tonumber(right.g)
        and tonumber(left.b) == tonumber(right.b)
end

function H.ResolveSharedAppearance(player, spec)
    if not H.SharesAppearance(spec)
        or not Identity.GetCharacterAppearance
    then
        return nil
    end
    return Identity.GetCharacterAppearance(player)
end

function H.ApplySharedAppearanceToIdentity(identity, appearance, isFemale)
    local survivor
    local skinTexture
    local changed = false
    if type(identity) ~= "table" or type(appearance) ~= "table" then
        return false
    end
    survivor = identity.survivor or {}
    identity.survivor = survivor
    skinTexture = H.ResolveSharedSkinTexture(
        appearance.skinTexture, isFemale == true)
    if skinTexture and survivor.skinTexture ~= skinTexture then
        survivor.skinTexture = skinTexture
        changed = true
    end
    if appearance.skinColor and not sameColor(
        survivor.skinColor, appearance.skinColor
    ) then
        survivor.skinColor = copyColor(appearance.skinColor)
        changed = true
    end
    if appearance.hairColor and not sameColor(
        survivor.hairColor, appearance.hairColor
    ) then
        survivor.hairColor = copyColor(appearance.hairColor)
        changed = true
    end
    return changed
end

function H.ApplySharedAppearance(player, record, spec)
    local appearance
    local changed
    local isFemale
    if not record or not H.SharesAppearance(spec) then
        return false
    end
    appearance = H.ResolveSharedAppearance(player, spec)
    isFemale = record.isFemale
    if isFemale == nil then
        isFemale = record.identity and record.identity.isFemale
    end
    changed = H.ApplySharedAppearanceToIdentity(
        record.identity, appearance, isFemale == true)
    if not changed then return false end
    record.runtime = record.runtime or {}
    record.runtime.appearanceCache = nil
    record.runtime.appearanceCacheKey = nil
    record.runtime.portraitSummaryCache = nil
    record.runtime.portraitSummaryCacheKey = nil
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "starting_companion_shared_appearance")
    end
    return true
end

function H.BuildIdentity(player, npcID, spec, isFemale, seed)
    local appearance
    if not Identity.GenerateResolvedIdentity then return nil end
    appearance = H.ResolveSharedAppearance(player, spec)
    local identity = Identity.GenerateResolvedIdentity({
        id = npcID,
        isFemale = isFemale,
        identitySeed = seed,
        archetypeID = "General",
    })
    H.ApplySharedAppearanceToIdentity(identity, appearance, isFemale == true)
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
