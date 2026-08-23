local Model = PNC.PlayerNeedsModel
local Internal = Model.Internal

function Model.GetTraitDefinitions()
    local output = {}
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local definition = Model.TRAIT_DEFINITIONS[index]
        output[index] = { id = definition.id, labelKey = definition.labelKey }
    end
    return output
end

function Model.GetActiveTraitIDs(source)
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
    local generatedVersion = math.max(0, math.floor(
        tonumber(record.vanillaTraitsGenerationVersion) or 0
    ))
    if record.vanillaTraitsAuthored == true or generatedVersion > 0 then
        record.vanillaTraits = Model.NormalizeTraits(record.vanillaTraits)
        return record.vanillaTraits, false
    end
    local existing = Model.NormalizeTraits(record.vanillaTraits)
    local hasExisting = false
    for _, enabled in pairs(existing) do
        if enabled == true then hasExisting = true break end
    end
    if hasExisting then
        record.vanillaTraits = existing
        record.vanillaTraitsAuthored = true
        record.vanillaTraitsGenerationVersion = 0
    else
        record.vanillaTraits = Model.GenerateTraits(
            record.identitySeed,
            record.archetypeID
        )
        record.vanillaTraitsAuthored = false
        record.vanillaTraitsGenerationVersion = Model.GENERATION_VERSION
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "vanilla_traits_initialized")
    end
    return record.vanillaTraits, true
end

function Model.HasTrait(record, id)
    id = Internal.TraitID(id)
    local traits = Model.GetTraits(record)
    return traits[id] == true
end

return Model
