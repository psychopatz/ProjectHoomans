local Model = PNC.PlayerNeedsModel
local Internal = Model.Internal

local function ensureCurrentTraits(record)
    local currentVersion
    local generatedVersion
    if type(record) ~= "table" or record.vanillaTraits == nil
        or record.vanillaTraitsAuthored == true
        or not Model.EnsureTraits
    then
        return
    end
    currentVersion = math.max(1, math.floor(
        tonumber(Model.GENERATION_VERSION) or 1
    ))
    generatedVersion = math.max(0, math.floor(
        tonumber(record.vanillaTraitsGenerationVersion) or 0
    ))
    if generatedVersion ~= currentVersion then
        Model.EnsureTraits(record)
    end
end

function Model.GetTraitDefinitions()
    local output = {}
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local definition = Model.TRAIT_DEFINITIONS[index]
        output[index] = {
            id = definition.id,
            labelKey = definition.labelKey,
            descriptionKey = definition.descriptionKey,
        }
    end
    return output
end

function Model.GetActiveTraitIDs(source)
    ensureCurrentTraits(source)
    local traits = source and source.vanillaTraits or source
    traits = Model.NormalizeTraits(traits)
    local output = {}
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local id = Model.TRAIT_DEFINITIONS[index].id
        if traits[id] then output[#output + 1] = id end
    end
    return output
end

function Model.GetTraitLabelKey(id)
    id = Internal.TraitID(id)
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local definition = Model.TRAIT_DEFINITIONS[index]
        if definition.id == id then return definition.labelKey end
    end
    return nil
end

function Model.GetTraits(record)
    ensureCurrentTraits(record)
    return Model.NormalizeTraits(record and (
        record.vanillaTraits or record.physiologicalTraits or record.traits
    ))
end

function Model.SetTraits(record, source)
    if type(record) ~= "table" then return false, "npc_missing" end
    record.vanillaTraits = Model.NormalizeTraits(source)
    record.vanillaTraitsAuthored = true
    record.vanillaTraitsGenerationVersion = 0
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "vanilla_traits_changed")
    end
    return true, "updated", Model.NormalizeTraits(record.vanillaTraits)
end

function Model.EnsureTraits(record)
    if type(record) ~= "table" then return nil, false end
    local currentVersion = math.max(1, math.floor(
        tonumber(Model.GENERATION_VERSION) or 1
    ))
    local generatedVersion = math.max(0, math.floor(
        tonumber(record.vanillaTraitsGenerationVersion) or 0
    ))
    if record.vanillaTraitsAuthored == true then
        record.vanillaTraits = Model.NormalizeTraits(record.vanillaTraits)
        record.vanillaTraitsGenerationVersion = 0
        return record.vanillaTraits, false
    end
    if generatedVersion == currentVersion then
        record.vanillaTraits = Model.NormalizeTraits(record.vanillaTraits)
        return record.vanillaTraits, false
    end
    local existing = Model.NormalizeTraits(record.vanillaTraits)
    local hasExisting = false
    for _, enabled in pairs(existing) do
        if enabled == true then hasExisting = true break end
    end
    if generatedVersion == 0 and hasExisting then
        record.vanillaTraits = existing
        record.vanillaTraitsAuthored = true
        record.vanillaTraitsGenerationVersion = 0
    else
        record.vanillaTraits = Model.GenerateTraits(
            record.identitySeed,
            record.archetypeID
        )
        record.vanillaTraitsAuthored = false
        record.vanillaTraitsGenerationVersion = currentVersion
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, generatedVersion == 0 and hasExisting
            and "vanilla_traits_initialized"
            or "vanilla_traits_regenerated")
    end
    return record.vanillaTraits, true
end

function Model.HasTrait(record, id)
    id = Internal.TraitID(id)
    local traits = Model.GetTraits(record)
    return traits[id] == true
end

return Model
