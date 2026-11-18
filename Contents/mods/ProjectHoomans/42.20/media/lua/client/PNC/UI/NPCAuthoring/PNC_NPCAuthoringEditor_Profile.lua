-- Player-facing presentation metadata for canonical NPC authoring fields.
--
-- The registry owns storage, normalization, persistence, and wire semantics.
-- This profile owns only the reusable editor's human presentation: grouping,
-- ordering, labels, and control families. Relationship policies may further
-- restrict a profile entry at runtime.

PNC = PNC or {}
PNC.NPCAuthoringEditorProfile = PNC.NPCAuthoringEditorProfile or {}

local Profile = PNC.NPCAuthoringEditorProfile

local function tr(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        return PNC.Translation.GetKey(key, fallback or key)
    end
    return fallback or key
end

Profile.VERSION = 1
Profile.PRESENTATIONS = { normal = true, advanced = true, diagnostic = true }
Profile.FIELDS = {
    { id = "identity.forename", labelKey = "UI_PNC_UniqueNPCEditor_Forename",
        fallback = "First name", group = "general", control = "text",
        order = 10, normal = true, debug = true, companion = true },
    { id = "identity.nickname", labelKey = "UI_PNC_NPCAuthoring_Nickname",
        fallback = "Nickname", group = "general", control = "text",
        helpKey = "UI_PNC_NPCAuthoring_NicknameHelp",
        order = 20, normal = true, debug = true, companion = true },
    { id = "identity.surname", labelKey = "UI_PNC_UniqueNPCEditor_Surname",
        fallback = "Surname", helpKey = "UI_PNC_NPCAuthoring_SurnameHelp",
        group = "general", control = "text",
        order = 30, normal = true, debug = true, companion = true },
    { id = "identity.isFemale", labelKey = "UI_PNC_UniqueNPCEditor_Gender",
        fallback = "Gender", helpKey = "UI_PNC_NPCAuthoring_GenderHelp",
        group = "general", control = "gender",
        order = 40, normal = true, debug = true, companion = true },
    { id = "archetypeID", labelKey = "UI_PNC_UniqueNPCEditor_Archetype",
        fallback = "Archetype", group = "general", control = "archetype",
        order = 50, normal = true, debug = true, companion = true,
        provider = "archetypes" },
    { id = "factionID", labelKey = "UI_PNC_UniqueNPCEditor_Faction",
        fallback = "Faction", group = "general", control = "text",
        order = 60, normal = false, debug = true, companion = false,
        presentation = "advanced" },
    { id = "appearance.hairModel", labelKey = "UI_PNC_UniqueNPCEditor_Hair",
        fallback = "Hair style", group = "appearance", control = "hair",
        order = 110, normal = true, debug = true, companion = true,
        provider = "appearanceOptions" },
    { id = "appearance.beardModel", labelKey = "UI_PNC_UniqueNPCEditor_Beard",
        fallback = "Beard", group = "appearance", control = "beard",
        order = 120, normal = true, debug = true, companion = true,
        provider = "beardOptions" },
    { id = "appearance.skinTexture", labelKey = "UI_PNC_UniqueNPCEditor_SkinColor",
        fallback = "Skin", group = "appearance", control = "skin",
        order = 130, normal = true, debug = true, companion = true },
    { id = "appearance.skinColor", labelKey = "UI_PNC_UniqueNPCEditor_SkinColor",
        fallback = "Skin color", group = "appearance", control = "skin",
        order = 131, normal = false, debug = true, companion = true,
        presentation = "advanced" },
    { id = "appearance.hairColor", labelKey = "UI_PNC_NPCAuthoring_HairColor",
        fallback = "Hair color", group = "appearance", control = "color",
        order = 140, normal = false, debug = true, companion = true,
        presentation = "advanced" },
    { id = "appearance", labelKey = "UI_PNC_UniqueNPCEditor_Outfit",
        fallback = "Clothing and outfit", group = "appearance",
        control = "appearance", order = 150, normal = true,
        debug = true, companion = true, provider = "appearanceEditor" },
    { id = "appearance.voice", labelKey = "UI_PNC_UniqueNPCEditor_VoiceStyle",
        fallback = "Voice style", group = "appearance", control = "voice",
        order = 160, normal = true, debug = true, companion = true,
        provider = "appearanceEditor" },
    { id = "appearance.voicePrefix", labelKey = "UI_PNC_UniqueNPCEditor_VoiceStyle",
        fallback = "Voice style", group = "appearance", control = "voice",
        order = 161, normal = false, debug = true, companion = true,
        presentation = "advanced", provider = "appearanceEditor" },
    { id = "appearance.voiceType", labelKey = "UI_PNC_UniqueNPCEditor_VoiceType",
        fallback = "Voice type", group = "appearance", control = "voice",
        order = 162, normal = false, debug = true, companion = true,
        presentation = "advanced", provider = "appearanceEditor" },
    { id = "appearance.voicePitch", labelKey = "UI_PNC_UniqueNPCEditor_VoicePitch",
        fallback = "Voice pitch", group = "appearance", control = "voice",
        order = 163, normal = false, debug = true, companion = true,
        presentation = "advanced", provider = "appearanceEditor" },
    { id = "equipmentSpawnMode",
        labelKey = "UI_PNC_UniqueNPCEditor_EquipmentMode",
        fallback = "Equipment mode", group = "general",
        control = "equipment", order = 170, normal = true,
        debug = true, companion = true, provider = "equipmentOptions" },
    { id = "startingItems", labelKey = "UI_PNC_Authoring_Carried",
        fallback = "Carried items and bags", group = "loadout", control = "items",
        order = 180, normal = true, debug = true, companion = true },
    { id = "skills.baseLevels", labelKey = "UI_PNC_UniqueNPCEditor_AddSkill",
        fallback = "Skills", group = "traits", control = "skills",
        order = 210, normal = true, debug = true, companion = true,
        provider = "skillOptions" },
    { id = "traits.npc", labelKey = "UI_PNC_UniqueNPCEditor_AddNPCTrait",
        fallback = "NPC traits", group = "traits", control = "npcTraits",
        order = 220, normal = true, debug = true, companion = true,
        provider = "npcTraitOptions" },
    { id = "traits.physiological",
        labelKey = "UI_PNC_UniqueNPCEditor_AddVanillaTrait",
        fallback = "Vanilla traits", group = "traits",
        control = "vanillaTraits", order = 230, normal = true,
        debug = true, companion = true, provider = "vanillaTraitOptions" },
    { id = "traits.dynamic",
        labelKey = "UI_PNC_UniqueNPCEditor_AddDynamicTrait",
        fallback = "Dynamic traits", group = "traits",
        control = "dynamicTraits", order = 240, normal = true,
        debug = true, companion = true, provider = "dynamicTraitOptions" },
}

local byID = {}
for _, field in ipairs(Profile.FIELDS) do byID[field.id] = field end

function Profile.Get(fieldID)
    return byID[tostring(fieldID or "")]
end

function Profile.Label(fieldID)
    local field = Profile.Get(fieldID)
    return field and tr(field.labelKey, field.fallback)
        or tostring(fieldID or "Field")
end

function Profile.Help(fieldID)
    local field = Profile.Get(fieldID)
    return field and field.helpKey and tr(field.helpKey, nil) or nil
end

function Profile.List(mode, options)
    mode = mode == "companion" and "companion" or "debug"
    options = type(options) == "table" and options or {}
    local output = {}
    for _, field in ipairs(Profile.FIELDS) do
        local visible = mode == "companion" and field.companion
            or mode == "debug" and field.debug
        local presentation = field.presentation or "normal"
        if visible and (options.normal ~= true or field.normal == true)
            and (not options.presentation
                or options.presentation == presentation)
        then
            output[#output + 1] = field
        end
    end
    table.sort(output, function(left, right)
        if left.order == right.order then return left.id < right.id end
        return left.order < right.order
    end)
    return output
end

function Profile.IsVisible(mode, fieldID)
    local field = Profile.Get(fieldID)
    if not field then return false end
    return mode == "companion" and field.companion == true
        or mode ~= "companion" and field.debug == true
end

function Profile.EditableFieldIDs(mode)
    local output = {}
    for _, field in ipairs(Profile.List(mode)) do
        output[#output + 1] = field.id
    end
    return output
end

function Profile.SourceHelp(source)
    if source == "inherited" then
        return tr("UI_PNC_NPCAuthoring_Inherited", "Inherited from Player")
    end
    if source == "derived" then
        return tr("UI_PNC_NPCAuthoring_Derived", "Relationship Rule")
    end
    if source == "authoritative" then
        return tr("UI_PNC_NPCAuthoring_Authoritative", "Server Controlled")
    end
    if source == "generated" then
        return tr("UI_PNC_NPCAuthoring_Generated", "Generated")
    end
    return tr("UI_PNC_NPCAuthoring_Custom", "Custom")
end

return Profile
