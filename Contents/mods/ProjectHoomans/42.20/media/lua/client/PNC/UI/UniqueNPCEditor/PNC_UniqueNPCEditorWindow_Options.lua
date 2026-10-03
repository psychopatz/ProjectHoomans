local EditorUI = PNC.UniqueNPCEditorUI
local Internal = EditorUI.Internal or {}
local Archetypes = Internal.Archetypes
local tr = Internal.tr
local clearCombo = Internal.clearCombo

local function archetypeOptions()
    local output = {}
    local seen = {}
    local registered = Archetypes and Archetypes.List
        and Archetypes.List() or {}
    for id, definition in pairs(registered) do
        id = tostring(id)
        if not seen[id] then
            output[#output + 1] = {
                id = id,
                label = tostring(definition and definition.label or id),
            }
            seen[id] = true
        end
    end
    if not seen.General then
        output[#output + 1] = { id = "General", label = "General" }
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function skillOptions()
    local output = {}
    local groups = PNC.SkillCatalog and PNC.SkillCatalog.GetGroups
        and PNC.SkillCatalog.GetGroups() or {}
    for _, group in ipairs(groups) do
        for _, skill in ipairs(group.skills or {}) do
            output[#output + 1] = {
                id = tostring(skill.id),
                label = tostring(skill.display or skill.id),
            }
        end
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function npcTraitOptions()
    local output = {}
    local definitions = PNC.NPCTraits and PNC.NPCTraits.GetDefinitions
        and PNC.NPCTraits.GetDefinitions() or {}
    for _, definition in ipairs(definitions) do
        output[#output + 1] = {
            id = tostring(definition.id),
            label = tr(definition.labelKey, definition.label or definition.id),
        }
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function vanillaTraitOptions()
    local output = {}
    if not CharacterTraitDefinition
        or not CharacterTraitDefinition.getTraits
    then
        return output
    end
    local traitList = CharacterTraitDefinition.getTraits()
    if not traitList then return output end
    for index = 0, traitList:size() - 1 do
        local trait = traitList:get(index)
        local traitType
        local traitID
        local label
        if trait then
            traitType = trait:getType()
            if traitType and traitType.getName then
                traitID = traitType:getName()
            end
            label = trait:getLabel()
            if traitID and label then
                output[#output + 1] = {
                    id = tostring(traitID), label = tostring(label),
                }
            end
        end
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function appearanceOptions(isFemale)
    local output = {
        { id = "__random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
    }
    if type(getAllHairStyles) ~= "function" then return output end
    local styles = getAllHairStyles(isFemale == true)
    if not styles then return output end
    for index = 0, styles:size() - 1 do
        local id = tostring(styles:get(index))
        if id == "" then
            -- The empty native style is represented by the explicit None
            -- option above so it cannot be confused with Random.
            id = nil
        end
        local allowed = true
        if id and getHairStylesInstance then
            local instance = getHairStylesInstance()
            local style = isFemale and instance:FindFemaleStyle(id)
                or instance:FindMaleStyle(id)
            allowed = style and not style:isNoChoose()
        end
        if id and allowed then
            output[#output + 1] = {
                id = id,
                label = id == "" and tr("IGUI_Hair_Bald", "Bald")
                    or tr("IGUI_Hair_" .. id, id),
            }
        end
    end
    return output
end

local function beardOptions(isFemale)
    if isFemale then
        return { { id = "", label = tr("IGUI_Beard_None", "None") } }
    end
    local output = {
        { id = "__random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
    }
    if type(getAllBeardStyles) ~= "function" then return output end
    local styles = getAllBeardStyles()
    if not styles then return output end
    for index = 0, styles:size() - 1 do
        local id = tostring(styles:get(index))
        if id ~= "" then
            output[#output + 1] = {
                id = id,
                label = tr("IGUI_Beard_" .. id, id),
            }
        end
    end
    return output
end

local function outfitOptions(isFemale)
    local output = {
        { id = nil, label = tr("UI_characreation_clothing_none", "None") },
    }
    if type(getAllOutfits) ~= "function" then return output end
    local ok, outfits = pcall(getAllOutfits, isFemale == true)
    if not ok or not outfits then return output end
    for index = 0, outfits:size() - 1 do
        local id = tostring(outfits:get(index))
        output[#output + 1] = { id = id, label = id }
    end
    return output
end

local function addOptions(combo, options)
    clearCombo(combo)
    for _, option in ipairs(options or {}) do
        combo:addOptionWithData(option.label, option.id)
    end
end

local function collectionIDs(source, valueEntries)
    local output = {}
    local seen = {}
    if type(source) ~= "table" then return output end
    if #source > 0 then
        for _, id in ipairs(source) do
            id = tostring(id)
            if id ~= "" and not seen[id] then
                output[#output + 1] = id
                seen[id] = true
            end
        end
    else
        for id, enabled in pairs(source) do
            if (enabled == true
                or valueEntries and tonumber(enabled) ~= nil)
                and not seen[tostring(id)]
            then
                output[#output + 1] = tostring(id)
                seen[tostring(id)] = true
            end
        end
    end
    table.sort(output)
    return output
end

local function addCollection(source, id)
    local output = {}
    for _, value in ipairs(collectionIDs(source)) do output[value] = true end
    if id and id ~= "" then output[tostring(id)] = true end
    return output
end

local function removeCollection(source, id)
    local output = {}
    for _, value in ipairs(collectionIDs(source)) do
        if tostring(value) ~= tostring(id) then output[value] = true end
    end
    for _, _ in pairs(output) do return output end
    return nil
end


Internal.addOptions = addOptions
Internal.archetypeOptions = archetypeOptions
Internal.skillOptions = skillOptions
Internal.npcTraitOptions = npcTraitOptions
Internal.vanillaTraitOptions = vanillaTraitOptions
Internal.appearanceOptions = appearanceOptions
Internal.beardOptions = beardOptions
Internal.collectionIDs = collectionIDs
Internal.addCollection = addCollection
Internal.removeCollection = removeCollection
EditorUI.Internal = Internal
