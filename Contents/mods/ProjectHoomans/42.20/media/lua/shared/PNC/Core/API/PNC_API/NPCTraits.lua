-- Public data-only NPC trait registration API.

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.NPCTraits = PNC.API.NPCTraits or {}

local API = PNC.API.NPCTraits
local Registry = PNC.NPCTraits

function API.Register(definition, options)
    return Registry.Register(definition, options)
end

function API.RegisterGenerationGroup(definition, options)
    return Registry.RegisterGenerationGroup(definition, options)
end

function API.Get(id)
    return Registry.GetDefinition(id)
end

function API.List()
    return Registry.GetDefinitions()
end

function API.ListGenerationGroups()
    return Registry.GetGenerationGroups()
end

function API.Set(record, traits)
    return Registry.Set(record, traits)
end

function API.GetActive(record)
    return Registry.GetActiveTraitIDs(record)
end

function API.GetEffects(record)
    return PNC.NPCTraitEffects
        and PNC.NPCTraitEffects.GetTraitSet(record) or {}
end

function API.GetFirearmModifiers(record)
    return PNC.NPCTraitEffects
        and PNC.NPCTraitEffects.ResolveFirearmModifiers
        and PNC.NPCTraitEffects.ResolveFirearmModifiers(record) or {}
end

function API.GetMeleeModifiers(record)
    return PNC.NPCTraitEffects
        and PNC.NPCTraitEffects.ResolveMeleeModifiers
        and PNC.NPCTraitEffects.ResolveMeleeModifiers(record) or {}
end

return API
