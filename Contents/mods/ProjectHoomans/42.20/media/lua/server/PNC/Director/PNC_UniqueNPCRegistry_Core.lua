-- Unique NPC registry shared authority and selection helpers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.UniqueNPCRegistry = PNC.UniqueNPCRegistry or {}

local Registry = PNC.UniqueNPCRegistry
local Catalog = PNC.UniqueNPCs
local Store = PNC.AbstractWorldStore
local Identity = PNC.Identity
local Config = PNC.DirectorConfig
local Core = PNC.Core

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function ensure()
    if not authority() then return nil, "not_authority" end
    if not Store or not Store.EnsureLoaded then
        return nil, "abstract_world_store_unavailable"
    end
    Store.EnsureLoaded()
    Store.Registry.uniqueNPCsByID = Store.Registry.uniqueNPCsByID or {}
    return Store.Registry.uniqueNPCsByID
end

local function now(context)
    return tonumber(context and context.worldAgeHours)
        or Store.WorldAgeHours()
end

local function getEntry(states, definitionID)
    return states[definitionID]
end

local function isAvailable(entry)
    return entry == nil or entry.status == "unseen"
end

local function selectionSeed(context)
    context = type(context) == "table" and context or {}
    return Identity.NormalizeSeed(
        context.selectionSeed or context.seed,
        "unique_pool:" .. tostring(context.generationId or "world")
    )
end

local function chooseWeighted(definitions, seed)
    local total = 0
    local roll
    local index
    local definition
    local weight
    for index = 1, #definitions do
        definition = definitions[index]
        weight = math.max(0, tonumber(definition.chanceWeight) or 1)
        total = total + weight
    end
    if total <= 0 then return nil end
    roll = Identity.Float(seed, "unique_pool:candidate") * total
    total = 0
    for index = 1, #definitions do
        definition = definitions[index]
        total = total + math.max(0, tonumber(definition.chanceWeight) or 1)
        if roll < total then return definition end
    end
    return definitions[#definitions]
end


Registry.Internal = Registry.Internal or {}
local Internal = Registry.Internal
Internal.Copy = copy
Internal.Authority = authority
Internal.Ensure = ensure
Internal.Now = now
Internal.GetEntry = getEntry
Internal.IsAvailable = isAvailable
Internal.SelectionSeed = selectionSeed
Internal.ChooseWeighted = chooseWeighted

return Registry
