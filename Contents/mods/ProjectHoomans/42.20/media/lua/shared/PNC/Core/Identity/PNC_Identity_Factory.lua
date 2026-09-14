PNC = PNC or {}
PNC.Identity = PNC.Identity or {}

local Identity = PNC.Identity
local Names = PNC.IdentityNames

local function normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

local function colorToTable(color)
    if not color then
        return nil
    end
    if color.getRedFloat and color.getGreenFloat and color.getBlueFloat then
        return {
            r = tonumber(color:getRedFloat()) or 0.2,
            g = tonumber(color:getGreenFloat()) or 0.1,
            b = tonumber(color:getBlueFloat()) or 0.1,
        }
    end
    return {
        r = tonumber(color.r) or 0.2,
        g = tonumber(color.g) or 0.1,
        b = tonumber(color.b) or 0.1,
    }
end

local function readVisualColor(humanVisual, methodName)
    local getter
    local ok
    local color
    if not humanVisual then
        return nil
    end
    getter = humanVisual[methodName]
    if not getter then
        return nil
    end
    ok, color = pcall(getter, humanVisual)
    return ok and colorToTable(color) or nil
end

local function readVisualString(humanVisual, methodName)
    local getter
    local ok
    local value
    if not humanVisual then
        return nil
    end
    getter = humanVisual[methodName]
    if not getter then
        return nil
    end
    ok, value = pcall(getter, humanVisual)
    return ok and normalizeString(value) or nil
end

function Identity.GetCharacterAppearance(character)
    local humanVisual
    if not character or not character.getHumanVisual then
        return nil
    end
    local ok
    ok, humanVisual = pcall(character.getHumanVisual, character)
    if not ok or not humanVisual then
        return nil
    end
    return {
        skinTexture = readVisualString(humanVisual, "getSkinTexture"),
        skinColor = readVisualColor(humanVisual, "getSkinColor"),
        hairColor = readVisualColor(humanVisual, "getHairColor"),
    }
end

local function tryCreateSurvivor()
    local ok
    local desc
    if not SurvivorFactory or not SurvivorFactory.CreateSurvivor then
        return nil
    end
    if SurvivorType and SurvivorType.Neutral then
        ok, desc = pcall(SurvivorFactory.CreateSurvivor, SurvivorType.Neutral, false)
        if ok and desc then
            return desc
        end
    end
    ok, desc = pcall(SurvivorFactory.CreateSurvivor)
    if ok and desc then
        return desc
    end
    return nil
end

function Identity.GenerateResolvedIdentity(source)
    local identityOverride = source and source.identity
    local survivorOverride = type(identityOverride) == "table"
        and type(identityOverride.survivor) == "table"
        and identityOverride.survivor or {}
    local seed = Identity.NormalizeSeed(source and source.identitySeed or nil, tostring(source and source.id or "npc"))
    local desc = tryCreateSurvivor()
    local humanVisual = desc and desc.getHumanVisual and desc:getHumanVisual() or nil
    local explicitName = normalizeString(
        source and (source.displayName or source.name) or nil
    ) or normalizeString(identityOverride and identityOverride.displayName)
    local explicitFemale = source and source.isFemale
    if explicitFemale == nil and identityOverride then
        explicitFemale = identityOverride.isFemale
    end
    local resolvedFemale = explicitFemale
    local forename
    local surname
    local displayName
    local appearance
    local voicePrefix
    local voiceType
    local voicePitch
    if resolvedFemale == nil and desc and desc.isFemale then
        resolvedFemale = desc:isFemale()
    end
    if resolvedFemale == nil then
        resolvedFemale = Identity.Index(seed, "gender:fallback", 2) == 1
    else
        resolvedFemale = resolvedFemale == true
    end
    if desc and desc.setFemale then
        pcall(function()
            desc:setFemale(resolvedFemale)
        end)
    end
    forename = normalizeString(source and source.forename)
        or normalizeString(survivorOverride.forename)
        or (desc and desc.getForename and normalizeString(desc:getForename()) or nil)
    surname = normalizeString(source and source.surname)
        or normalizeString(survivorOverride.surname)
        or (desc and desc.getSurname and normalizeString(desc:getSurname()) or nil)
    if explicitName and not (source and source.forename)
        and not survivorOverride.forename
    then
        forename = string.match(explicitName, "^(%S+)") or forename
    end
    if explicitName and not (source and source.surname)
        and not survivorOverride.surname
    then
        surname = string.match(explicitName, "%s+(%S+)%s*$") or surname
    end
    appearance = Identity.GetCharacterAppearance(desc)
    voicePrefix = normalizeString(survivorOverride.voicePrefix)
        or normalizeString(survivorOverride.voice)
        or (desc and desc.getVoicePrefix
            and normalizeString(desc:getVoicePrefix()) or nil)
    voiceType = tonumber(survivorOverride.voiceType)
        or (desc and desc.getVoiceType
            and tonumber(desc:getVoiceType()) or nil)
    voicePitch = tonumber(survivorOverride.voicePitch)
        or (desc and desc.getVoicePitch
            and tonumber(desc:getVoicePitch()) or nil)
    displayName = explicitName
    if not displayName then
        if forename or surname then
            displayName = table.concat({
                tostring(forename or ""),
                tostring(surname or ""),
            }, " ")
            displayName = string.gsub(displayName, "^%s+", "")
            displayName = string.gsub(displayName, "%s+$", "")
        end
    end
    if not displayName or displayName == "" then
        displayName = Names and Names.Generate and Names.Generate(seed, resolvedFemale, source and source.archetypeID or nil) or "Survivor"
    end
    return {
        seed = seed,
        archetypeID = normalizeString(source and source.archetypeID or nil),
        archetypeLabel = normalizeString(source and source.archetypeLabel or nil),
        displayName = displayName,
        isFemale = resolvedFemale,
        survivor = {
            forename = forename,
            surname = surname,
            hairModel = survivorOverride.hairModel ~= nil
                and tostring(survivorOverride.hairModel)
                or (humanVisual and humanVisual.getHairModel
                    and normalizeString(humanVisual:getHairModel()) or nil),
            beardModel = survivorOverride.beardModel ~= nil
                and tostring(survivorOverride.beardModel)
                or (humanVisual and humanVisual.getBeardModel
                    and normalizeString(humanVisual:getBeardModel()) or nil),
            skinColor = survivorOverride.skinColor
                or (appearance and appearance.skinColor or nil),
            hairColor = survivorOverride.hairColor
                or (appearance and appearance.hairColor or nil),
            skinTexture = normalizeString(survivorOverride.skinTexture)
                or (appearance and appearance.skinTexture or nil),
            -- `voice` remains the legacy prefix field. The explicit fields
            -- mirror SurvivorDesc and allow the creator to preserve the
            -- complete factory voice profile.
            voice = voicePrefix,
            voicePrefix = voicePrefix,
            voiceType = voiceType,
            voicePitch = voicePitch,
        },
    }
end
