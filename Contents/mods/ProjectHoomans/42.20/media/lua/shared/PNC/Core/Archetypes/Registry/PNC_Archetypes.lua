--[[
    PNC Archetype Registry
    Owns self-registering archetype metadata, registration APIs, and module
    specs. Runtime systems read from this registry but do not define archetypes.
]]

PNC = PNC or {}
PNC.Archetypes = PNC.Archetypes or {}

local Archetypes = PNC.Archetypes
local Core = PNC.Core

Archetypes.Registry = Archetypes.Registry or {
    definitions = {},
    skills = {},
    loadouts = {},
    modules = {},
    moduleOrder = {},
    loadedModules = {},
    colonistDefaults = {},
    hostileDefaults = {},
}

local Registry = Archetypes.Registry
Registry.colonistDefaults = Registry.colonistDefaults or Registry.companionDefaults or {}
Registry.companionDefaults = Registry.colonistDefaults
PNC.PendingArchetypeBundles = PNC.PendingArchetypeBundles or {}

local function coreArchetypeID(id)
    local normalized = id
    if normalized == nil or normalized == "" then return nil end
    normalized = tostring(normalized)
    normalized = string.lower(normalized)
    normalized = string.gsub(normalized, "[^%w_%-]+", "-")
    return "projecthoomans." .. normalized
end

local function registerCoreArchetype(id, bundle)
    local core = PsychopatzCore
    local actors = core and core.Actors or nil
    local archetypes = actors and actors.Archetypes or nil
    local definition = type(bundle) == "table"
        and type(bundle.definition) == "table"
        and bundle.definition or {}
    local loadout = type(bundle) == "table"
        and type(bundle.loadout) == "table"
        and bundle.loadout or {}
    local coreID = coreArchetypeID(id)
    local registered
    local reason

    if not archetypes or type(archetypes.Register) ~= "function" then
        return true, "core_archetype_registry_unavailable"
    end
    registered, reason = archetypes:Register({
        id = coreID,
        aliases = { tostring(id) },
        label = definition.label or id,
        sourceMod = "ProjectHoomans",
        tags = definition.tags,
        appearance = Core.DeepCopy(bundle.appearance or {}),
        skillBias = bundle.skills,
        inventory = {
            bagChoices = loadout.bagChoices,
            attached = loadout.attached,
            supplies = loadout.supplies,
        },
        extensions = {
            ["projecthoomans.archetype"] = {
                type = definition.type,
                defaultForFaction = definition.defaultForFaction,
                allowedJobs = definition.allowedJobs,
            },
        },
    })
    if not registered and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn(
            "Core archetype registration failed for "
                .. tostring(id) .. ": " .. tostring(reason)
        )
    end
    return registered, reason
end

local function appendUnique(list, value)
    local i
    if type(list) ~= "table" or value == nil then
        return
    end
    for i = 1, #list do
        if list[i] == value then
            return
        end
    end
    list[#list + 1] = value
end

local function normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

local function normalizeDefaults(list)
    local output = {}
    local i
    if type(list) ~= "table" then
        return output
    end
    for i = 1, #list do
        if normalizeString(list[i]) then
            output[#output + 1] = tostring(list[i])
        end
    end
    return output
end

function PNC.RegisterArchetype(id, data)
    local entry
    id = normalizeString(id)
    if not id or type(data) ~= "table" then
        return false
    end
    entry = Core.DeepCopy(data)
    entry.id = id
    entry.label = normalizeString(entry.label or entry.name) or id
    entry.tags = type(entry.tags) == "table" and Core.DeepCopy(entry.tags) or {}
    entry.type = normalizeString(entry.type) or "survivor"
    entry.allowedJobs = type(entry.allowedJobs) == "table" and Core.DeepCopy(entry.allowedJobs) or {}
    Registry.definitions[id] = entry
    if entry.defaultForFaction == "colonist" or entry.defaultForFaction == "companion" or entry.defaultForFaction == "friendly" then
        entry.defaultForFaction = "colonist"
        appendUnique(Registry.colonistDefaults, id)
    elseif entry.defaultForFaction == "hostile" then
        appendUnique(Registry.hostileDefaults, id)
    end
    return true
end

function PNC.RegisterArchetypeModule(id, spec)
    local entry
    id = normalizeString(id)
    if not id then
        return false
    end
    entry = type(spec) == "table" and Core.DeepCopy(spec) or {}
    entry.id = id
    entry.modulePath = normalizeString(entry.modulePath) or ("PNC/ArchetypeDefinitions/" .. id .. "/PNC_" .. id)
    Registry.modules[id] = entry
    appendUnique(Registry.moduleOrder, id)
    return true
end

function Archetypes.GetModuleList()
    return normalizeDefaults(Registry.moduleOrder)
end

function Archetypes.GetModuleSpec(id)
    id = normalizeString(id)
    if not id then
        return nil
    end
    return Registry.modules[id] and Core.DeepCopy(Registry.modules[id]) or nil
end

function Archetypes.LoadModule(id)
    local spec
    local ok
    local err
    id = normalizeString(id)
    if not id then
        return false, "missing_id"
    end
    if Registry.loadedModules[id] == true then
        return true, "already_loaded"
    end
    spec = Registry.modules[id] or { id = id, modulePath = "PNC/ArchetypeDefinitions/" .. id .. "/PNC_" .. id }
    Registry.modules[id] = spec
    appendUnique(Registry.moduleOrder, id)
    ok, err = pcall(require, spec.modulePath)
    if not ok then
        return false, tostring(err)
    end
    Registry.loadedModules[id] = true
    return true, spec.modulePath
end

function Archetypes.LoadModules()
    local moduleIDs = Archetypes.GetModuleList()
    local totalLoaded = 0
    local errors = {}
    local i
    local ok
    local reason
    for i = 1, #moduleIDs do
        ok, reason = Archetypes.LoadModule(moduleIDs[i])
        if ok then
            if reason ~= "already_loaded" then
                totalLoaded = totalLoaded + 1
            end
        else
            errors[#errors + 1] = {
                id = moduleIDs[i],
                reason = reason,
            }
        end
    end
    return totalLoaded, errors
end

function PNC.LoadArchetypes()
    return Archetypes.LoadModules()
end

function PNC.RegisterArchetypeSkills(id, data)
    id = normalizeString(id)
    if not id or type(data) ~= "table" then
        return false
    end
    Registry.skills[id] = Core.DeepCopy(data)
    return true
end

function PNC.RegisterArchetypeLoadout(id, data)
    id = normalizeString(id)
    if not id or type(data) ~= "table" then
        return false
    end
    Registry.loadouts[id] = Core.DeepCopy(data)
    return true
end

function Archetypes.ApplyBundle(id, bundle)
    local applied = false
    id = normalizeString(id)
    if not id or type(bundle) ~= "table" then
        return false
    end
    if type(bundle.definition) == "table" then
        PNC.RegisterArchetype(id, bundle.definition)
        applied = true
    end
    if type(bundle.appearance) == "table" then
        applied = true
    end
    if type(bundle.skills) == "table" then
        PNC.RegisterArchetypeSkills(id, bundle.skills)
        applied = true
    end
    if type(bundle.loadout) == "table" then
        PNC.RegisterArchetypeLoadout(id, bundle.loadout)
        applied = true
    end
    return applied
end

function Archetypes.ApplyPendingBundles()
    local source = PNC.PendingArchetypeBundles or {}
    local id
    local bundle
    local applied = 0
    for id, bundle in pairs(source) do
        if Archetypes.ApplyBundle(id, bundle) then
            Registry.pendingBundles = Registry.pendingBundles or {}
            Registry.pendingBundles[id] = Core.DeepCopy(bundle)
            applied = applied + 1
        end
    end
    return applied
end

function PNC.RegisterArchetypeBundle(id, bundle)
    local applied
    id = normalizeString(id)
    if not id or type(bundle) ~= "table" then
        return false
    end
    PNC.PendingArchetypeBundles = PNC.PendingArchetypeBundles or {}
    PNC.PendingArchetypeBundles[id] = Core.DeepCopy(bundle)
    applied = Archetypes.ApplyBundle(id, bundle)
    registerCoreArchetype(id, bundle)
    return applied
end

local function coreDefinitionFor(key)
    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    local registry
    local ok
    local loaded
    local definition
    local extension
    local appearance
    local inventory

    if not actors then
        ok, loaded = pcall(require,
            "PsychopatzCore/Actors/PsychopatzActors")
        if ok then actors = loaded end
    end
    registry = actors and actors.Archetypes or nil
    if not registry or type(registry.Get) ~= "function" then return nil end
    definition = registry:Get(key)
    if not definition then return nil end

    extension = definition.extensions
        and definition.extensions["projecthoomans.archetype"] or {}
    appearance = type(definition.appearance) == "table"
        and definition.appearance or {}
    inventory = type(definition.inventory) == "table"
        and definition.inventory or {}
    return {
        id = key,
        label = definition.label or key,
        type = extension.type or "survivor",
        tags = Core.DeepCopy(definition.tags or {}),
        allowedJobs = Core.DeepCopy(extension.allowedJobs or {}),
        defaultForFaction = extension.defaultForFaction,
        appearance = Core.DeepCopy(appearance),
        skillBias = Core.DeepCopy(definition.skillBias or {}),
        loadout = {
            bagChoices = Core.DeepCopy(inventory.bagChoices or {}),
            attached = Core.DeepCopy(inventory.attached or {}),
            supplies = Core.DeepCopy(inventory.items or {}),
            equipment = Core.DeepCopy(inventory.equipment or {}),
        },
    }
end

function Archetypes.Get(id)
    local key = normalizeString(id) or "General"
    local coreDefinition = coreDefinitionFor(key)
    local definition = Registry.definitions[key] or Registry.definitions.General or {
        id = key,
        label = key,
        tags = {},
        allowedJobs = {},
    }
    if coreDefinition then return coreDefinition end
    return {
        id = definition.id,
        label = definition.label,
        type = definition.type,
        tags = Core.DeepCopy(definition.tags or {}),
        allowedJobs = Core.DeepCopy(definition.allowedJobs or {}),
        defaultForFaction = definition.defaultForFaction,
        skillBias = Core.DeepCopy(Registry.skills[key] or Registry.skills.General or {}),
        loadout = Core.DeepCopy(Registry.loadouts[key] or Registry.loadouts.General or {}),
    }
end

local function coreDefaultsFor(value)
    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    local registry = actors and actors.Archetypes or nil
    local output = {}
    local definitions
    local extension
    local aliases
    if not registry or type(registry.List) ~= "function" then
        return output
    end
    definitions = registry:List()
    for _, definition in ipairs(definitions) do
        extension = definition.extensions
            and definition.extensions["projecthoomans.archetype"] or nil
        if type(extension) == "table"
            and extension.defaultForFaction == value
        then
            aliases = definition.aliases or {}
            if aliases[1] then
                output[#output + 1] = tostring(aliases[1])
            end
        end
    end
    table.sort(output)
    return output
end

function Archetypes.GetColonistDefaults()
    local defaults = coreDefaultsFor("colonist")
    if #defaults <= 0 then
        defaults = normalizeDefaults(Registry.colonistDefaults)
    end
    if #defaults <= 0 then
        defaults[1] = "General"
    end
    return defaults
end

-- Compatibility for add-ons built against the former faction name.
function Archetypes.GetCompanionDefaults()
    return Archetypes.GetColonistDefaults()
end

function Archetypes.GetHostileDefaults()
    local defaults = coreDefaultsFor("hostile")
    if #defaults <= 0 then
        defaults = normalizeDefaults(Registry.hostileDefaults)
    end
    if #defaults <= 0 then
        defaults[1] = "Scavenger"
    end
    return defaults
end

function Archetypes.List()
    local output = {}
    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    local registry = actors and actors.Archetypes or nil
    local definitions
    local extension
    local alias
    local index
    local outputCount = 0
    if registry and type(registry.List) == "function" then
        definitions = registry:List()
        for _, definition in ipairs(definitions) do
            extension = definition.extensions
                and definition.extensions["projecthoomans.archetype"] or nil
            if type(extension) == "table" then
                if type(definition.aliases) == "table"
                    and #definition.aliases > 0
                then
                    for index = 1, #definition.aliases do
                        alias = tostring(definition.aliases[index])
                        output[alias] = Archetypes.Get(alias)
                        outputCount = outputCount + 1
                    end
                else
                    output[definition.id] = Archetypes.Get(definition.id)
                    outputCount = outputCount + 1
                end
            end
        end
        if outputCount > 0 then return output end
    end
    local id
    for id, _ in pairs(Registry.definitions) do
        output[id] = Archetypes.Get(id)
    end
    return output
end
