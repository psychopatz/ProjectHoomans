-- Read-only social-profile inspection and opt-in diagnostic logging.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.SocialProfileDebug = PNC.SocialProfileDebug or {}

local Debug = PNC.SocialProfileDebug

local function enabled()
    return PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugSocialProfiles == true
end

function Debug.Log(fields)
    local parts
    local keys
    local index
    local key
    if not enabled() then
        return false
    end
    parts = { "[PNC SocialProfile]" }
    keys = {
        "kind",
        "characterUUID",
        "npcID",
        "identitySeed",
        "archetypeID",
        "preferred",
        "discarded",
        "fingerprint",
        "result",
    }
    for index = 1, #keys do
        key = keys[index]
        if fields and fields[key] ~= nil then
            parts[#parts + 1] = key .. "="
                .. tostring(fields[key])
        end
    end
    if fields
        and fields.kind == "trait_conflict"
        and PNC.Core
        and PNC.Core.LogWarn
    then
        PNC.Core.LogWarn(table.concat(parts, " "))
    elseif PNC.Core and PNC.Core.LogDebug then
        PNC.Core.LogDebug(table.concat(parts, " "))
    elseif print then
        print(table.concat(parts, " "))
    end
    return true
end

local function appendCategorical(lines, profile)
    lines[#lines + 1] = "Orientation: "
        .. tostring(profile.orientation)
    lines[#lines + 1] = "Food preference: "
        .. tostring(profile.foodPreference)
    lines[#lines + 1] = "Romance style: "
        .. tostring(profile.romanceStyle)
    lines[#lines + 1] = "Jealousy style: "
        .. tostring(profile.jealousyStyle)
    lines[#lines + 1] = "Social style: "
        .. tostring(profile.socialStyle)
end

function Debug.FormatPlayer(characterUUID)
    local record = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
        and PNC.PlayerCharacters.GetRegistryRecord(characterUUID) or nil
    local profile
    local traits = {}
    local trait
    local lines
    if not record then
        return "Player Social Profile\nCharacter UUID: "
            .. tostring(characterUUID) .. "\nStatus: not found"
    end
    profile = PNC.SocialProfileTypes
        .NormalizePlayerSocialProfile(record.socialProfile)
    lines = {
        "Player Social Profile",
        "Account: " .. tostring(record.accountIdentity),
        "Character UUID: " .. tostring(record.uuid),
    }
    appendCategorical(lines, profile)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Source traits:"
    for trait, _ in pairs(profile.sourceTraits) do
        traits[#traits + 1] = trait
    end
    table.sort(traits)
    for _, trait in ipairs(traits) do
        lines[#lines + 1] = "  " .. trait
    end
    if #traits == 0 then
        lines[#lines + 1] = "  (none)"
    end
    return table.concat(lines, "\n")
end

function Debug.FormatNPC(npcID)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    local profile
    local lines
    if not record then
        return "NPC Social Profile\nNPC: "
            .. tostring(npcID) .. "\nStatus: not found"
    end
    profile = PNC.SocialProfileTypes.NormalizeNPCPersonality(
        record.social and record.social.personality,
        record.identitySeed,
        record.archetypeID
    )
    lines = {
        "NPC Social Profile",
        "NPC: " .. tostring(record.id),
        "Seed: " .. tostring(record.identitySeed),
        "Archetype: " .. tostring(record.archetypeID),
    }
    appendCategorical(lines, profile)
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format(
        "Compassion: %.2f",
        profile.compassion
    )
    lines[#lines + 1] = string.format(
        "Sociability: %.2f",
        profile.sociability
    )
    lines[#lines + 1] = string.format(
        "Forgiveness: %.2f",
        profile.forgiveness
    )
    lines[#lines + 1] = string.format(
        "Bravery: %.2f",
        profile.bravery
    )
    lines[#lines + 1] = string.format(
        "Materialism: %.2f",
        profile.materialism
    )
    lines[#lines + 1] = string.format(
        "Aggression: %.2f",
        profile.aggression
    )
    lines[#lines + 1] = string.format(
        "Loyalty: %.2f",
        profile.loyalty
    )
    return table.concat(lines, "\n")
end

return Debug
