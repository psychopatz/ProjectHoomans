-- Starter import sanitizer shared by preview and application.
--
-- The sanitizer converts a canonical Unique NPC definition into the same
-- sparse blueprint that a starter slot uses.  It never copies resolved
-- relationship bindings or runtime authority into the result.

require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PNC/Core/Identity/PNC_NPCAuthoring"

PNC = PNC or {}
PNC.StartingCompanionSanitizer = PNC.StartingCompanionSanitizer or {}

local Sanitizer = PNC.StartingCompanionSanitizer
local StartingTraits = PNC.StartingCompanionTraits
local Authoring = PNC.NPCAuthoring
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint
local Resolver = Authoring.Resolver

Sanitizer.VERSION = 1

local function copy(value)
    return Registry.Copy(value)
end

local function normalizeTraitID(value)
    local id = tostring(value or "")
    if PsychopatzCore and PsychopatzCore.Traits
        and PsychopatzCore.Traits.NormalizeID
    then
        id = PsychopatzCore.Traits.NormalizeID(
            id, StartingTraits.OWNER
        ) or id
    end
    return StartingTraits.GetDefinition(id) and id or nil
end

local function add(report, bucket, value)
    report[bucket][#report[bucket] + 1] = value
end

local function hasLegacyAlias(source)
    local identity = source and source.identity
    local survivor = identity and identity.survivor
    return source and (source.name ~= nil
            or source.alias ~= nil
            or source.forename ~= nil
            or source.surname ~= nil
            or source.nickname ~= nil
            or source.firstName ~= nil
            or source.lastName ~= nil
            or source.skillBaseLevels ~= nil
            or source.physiologicalTraits ~= nil
            or source.startingInventoryTemplate ~= nil)
        or identity and (identity.name ~= nil or identity.alias ~= nil)
        or survivor and (survivor.firstName ~= nil
            or survivor.lastName ~= nil or survivor.alias ~= nil)
end

local function sourceState(blueprint, fieldID)
    return Blueprint.Get(blueprint, fieldID)
end

local function preserveField(output, source, fieldID)
    local state, value = sourceState(source, fieldID)
    local nextBlueprint
    local reason
    if state == "value" then
        nextBlueprint, reason = Blueprint.Set(output, fieldID, value)
    elseif state == "clear" then
        nextBlueprint, reason = Blueprint.Clear(output, fieldID)
    else
        return output
    end
    if not nextBlueprint then return nil, reason end
    return nextBlueprint
end

function Sanitizer.SanitizeDefinition(definition, traitID, options)
    local id = normalizeTraitID(traitID)
    local spec
    local policy
    local source
    local output
    local report
    local reason
    local fieldID
    local field
    local state
    local nextBlueprint
    options = type(options) == "table" and options or {}
    if type(definition) ~= "table" then return nil, "definition_invalid" end
    if hasLegacyAlias(definition) then return nil, "unsupported_source_schema" end
    if not id then return nil, "unknown_companion_trait" end
    spec = StartingTraits.GetDefinition(id)
    policy = Resolver.PolicyForStartingCompanion(spec, options.context)
    source, reason = Blueprint.FromDefinition(definition, {
        id = "source:" .. tostring(definition.id or "unique"),
        generationSeed = options.generationSeed or definition.generationSeed,
    })
    if not source then return nil, reason end
    output = Blueprint.New({
        id = "starter:" .. tostring(id),
        generationSeed = source.generationSeed,
    })
    report = {
        version = Sanitizer.VERSION,
        companionTraitID = id,
        policy = policy.id,
        preserved = {},
        removed = {},
        rebound = {},
        regenerated = {},
    }

    -- Runtime/authority keys are described by the active policy.  They are
    -- reported for preview, but never enter the blueprint.
    for fieldID, _ in pairs(policy.serverControlledKeys or {}) do
        if definition[fieldID] ~= nil then add(report, "removed", fieldID) end
    end

    for _, field in ipairs(Registry.List()) do
        fieldID = field.id
        state = sourceState(source, fieldID)
        if state ~= "absent" then
            if policy.serverControlledFields
                and policy.serverControlledFields[fieldID]
            then
                add(report, "removed", fieldID)
            elseif policy.bindings
                and policy.bindings[fieldID]
                and policy.bindings[fieldID].mandatory
            then
                add(report, "rebound", fieldID)
            elseif fieldID == "identity.displayName" then
                add(report, "regenerated", fieldID)
            elseif not field.authorable or not field.persistable then
                add(report, "removed", fieldID)
            else
                nextBlueprint, reason = preserveField(output, source, fieldID)
                if not nextBlueprint then return nil, reason end
                output = nextBlueprint
                add(report, "preserved", fieldID)
            end
        elseif fieldID == "identity.displayName" then
            add(report, "regenerated", fieldID)
        elseif policy.bindings
            and policy.bindings[fieldID]
            and policy.bindings[fieldID].mandatory
        then
            -- A relationship binding will supply this value during resolve;
            -- include it in the report even when the source omitted it.
            add(report, "rebound", fieldID)
        elseif fieldID == "identity.forename" then
            add(report, "regenerated", fieldID)
        end
    end

    table.sort(report.preserved)
    table.sort(report.removed)
    table.sort(report.rebound)
    table.sort(report.regenerated)
    report.blueprintFingerprint = Blueprint.Fingerprint(output)
    return output, report
end

function Sanitizer.Preview(definition, traitID, options)
    local blueprint, report = Sanitizer.SanitizeDefinition(
        definition, traitID, options
    )
    if not blueprint then return nil, report end
    return {
        blueprint = blueprint,
        report = report,
    }
end

function Sanitizer.Apply(definition, traitID, options)
    return Sanitizer.SanitizeDefinition(definition, traitID, options)
end

return Sanitizer
