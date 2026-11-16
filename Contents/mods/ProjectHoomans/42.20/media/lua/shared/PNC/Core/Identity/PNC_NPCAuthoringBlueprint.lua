-- Sparse NPC authoring intent.
--
-- A blueprint stores only canonical authored field IDs, explicit clears, and
-- the stable generation seed.  Resolved player/context values never become
-- durable blueprint truth.

PNC = PNC or {}
PNC.NPCAuthoringBlueprint = PNC.NPCAuthoringBlueprint or {}

local Blueprint = PNC.NPCAuthoringBlueprint
local Registry = PNC.NPCAuthoringFieldRegistry

Blueprint.SCHEMA_ID = Registry.SCHEMA_ID
Blueprint.SCHEMA_VERSION = Registry.SCHEMA_VERSION

local function copy(value, seen)
    if Registry and Registry.Copy then return Registry.Copy(value, seen) end
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function seed(value, fallback)
    local Identity = PNC.Identity
    if Identity and Identity.NormalizeSeed then
        return Identity.NormalizeSeed(value, fallback)
    end
    local numeric = math.floor(tonumber(value) or 0)
    if numeric > 0 then return numeric % 2147483647 end
    return tonumber(Registry.Hash(tostring(fallback or "npc-authoring"))) or 1
end

local function fieldState(blueprint, fieldID)
    if blueprint.fields[fieldID] ~= nil then
        return "value", blueprint.fields[fieldID]
    end
    if blueprint.clears[fieldID] == true then
        return "clear", nil
    end
    return "absent", nil
end

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _, _ in pairs(value) do return true end
    return false
end

function Blueprint.New(options)
    options = type(options) == "table" and options or {}
    return {
        schemaId = Blueprint.SCHEMA_ID,
        schemaVersion = Blueprint.SCHEMA_VERSION,
        id = options.id,
        generationSeed = seed(
            options.generationSeed or options.seed,
            options.seedText or options.id or "npc-authoring"
        ),
        fields = {},
        clears = {},
    }
end

function Blueprint.Clone(blueprint)
    return copy(blueprint)
end

function Blueprint.Get(blueprint, fieldID)
    if type(blueprint) ~= "table"
        or type(blueprint.fields) ~= "table"
    then
        return nil, "blueprint_invalid"
    end
    return fieldState(blueprint, tostring(fieldID))
end

function Blueprint.Set(blueprint, fieldID, value)
    local output = copy(blueprint)
    local id = tostring(fieldID or "")
    local field = Registry.Get(id)
    local normalized
    local reason
    if type(blueprint) ~= "table" then return nil, "blueprint_invalid" end
    if not field then return nil, "unknown_field:" .. id end
    if not field.authorable then return nil, "field_not_authorable:" .. id end
    if value == nil then return nil, "explicit_clear_required:" .. id end
    normalized, reason = Registry.NormalizeValue(id, value)
    if normalized == nil then return nil, reason or "field_value_invalid:" .. id end
    output.fields = output.fields or {}
    output.clears = output.clears or {}
    output.fields[id] = normalized
    output.clears[id] = nil
    return output
end

function Blueprint.Clear(blueprint, fieldID, policy)
    local output = copy(blueprint)
    local id = tostring(fieldID or "")
    local field = Registry.Get(id)
    if type(blueprint) ~= "table" then return nil, "blueprint_invalid" end
    if not field then return nil, "unknown_field:" .. id end
    if not field.authorable or not field.clearable then
        return nil, "field_not_clearable:" .. id
    end
    if policy and policy.bindings and policy.bindings[id]
        and policy.bindings[id].mandatory
    then
        return nil, "mandatory_field_cannot_clear:" .. id
    end
    output.fields = output.fields or {}
    output.clears = output.clears or {}
    output.fields[id] = nil
    output.clears[id] = true
    return output
end

function Blueprint.Randomize(blueprint, generationSeed)
    local output = copy(blueprint)
    if type(blueprint) ~= "table" then return nil, "blueprint_invalid" end
    output.generationSeed = seed(
        generationSeed,
        "randomize:" .. tostring(output.generationSeed or "npc")
    )
    return output
end

function Blueprint.Normalize(blueprint)
    local output
    local fields
    local clears
    local normalized
    local reason
    local id
    local value
    local count = 0
    local clearCount = 0
    if type(blueprint) ~= "table" then return nil, "blueprint_invalid" end
    if tostring(blueprint.schemaId or "") ~= Blueprint.SCHEMA_ID then
        return nil, "unsupported_blueprint_schema"
    end
    if tonumber(blueprint.schemaVersion) ~= Blueprint.SCHEMA_VERSION then
        return nil, "unsupported_blueprint_version"
    end
    fields = type(blueprint.fields) == "table" and blueprint.fields or {}
    clears = type(blueprint.clears) == "table" and blueprint.clears or {}
    output = Blueprint.New({
        id = blueprint.id,
        generationSeed = blueprint.generationSeed,
    })
    for id, value in pairs(fields) do
        count = count + 1
        if count > Registry.MAX_FIELDS then return nil, "too_many_blueprint_fields" end
        if type(id) ~= "string" then return nil, "field_id_must_be_string" end
        output, reason = Blueprint.Set(output, id, value)
        if not output then return nil, reason end
    end
    for id, value in pairs(clears) do
        if value then
            clearCount = clearCount + 1
            if clearCount > Registry.MAX_CLEAR_FIELDS then
                return nil, "too_many_blueprint_clears"
            end
            output, reason = Blueprint.Clear(output, id)
            if not output then return nil, reason end
        end
    end
    return output
end

function Blueprint.Validate(blueprint, policy)
    local normalized, reason = Blueprint.Normalize(blueprint)
    local fieldID
    local field
    local state
    if not normalized then return false, reason end
    for fieldID, _ in pairs(normalized.fields) do
        field = Registry.Get(fieldID)
        if not field or not field.authorable then
            return false, "field_not_authorable:" .. tostring(fieldID)
        end
    end
    for fieldID, _ in pairs(normalized.clears) do
        field = Registry.Get(fieldID)
        if not field or not field.clearable then
            return false, "field_not_clearable:" .. tostring(fieldID)
        end
        if policy and policy.bindings and policy.bindings[fieldID]
            and policy.bindings[fieldID].mandatory
        then
            return false, "mandatory_field_cannot_clear:" .. tostring(fieldID)
        end
        state = Blueprint.Get(normalized, fieldID)
        if state ~= "clear" then return false, "clear_state_invalid" end
    end
    if policy and policy.required then
        for fieldID, _ in pairs(policy.required) do
            state = Blueprint.Get(normalized, fieldID)
            if state == "absent" then
                local binding = policy.bindings and policy.bindings[fieldID]
                if not binding or binding.mandatory ~= true then
                    return false, "required_field_missing:" .. tostring(fieldID)
                end
            end
        end
    end
    return true, normalized
end

function Blueprint.Fingerprint(blueprint)
    local normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return nil, reason end
    return "blueprint:v" .. tostring(Blueprint.SCHEMA_VERSION) .. ":"
        .. Registry.Hash({
            schemaId = normalized.schemaId,
            schemaVersion = normalized.schemaVersion,
            generationSeed = normalized.generationSeed,
            fields = normalized.fields,
            clears = normalized.clears,
        })
end

function Blueprint.Serialize(blueprint)
    local normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return nil, reason end
    return {
        schemaId = normalized.schemaId,
        schemaVersion = normalized.schemaVersion,
        id = normalized.id,
        generationSeed = normalized.generationSeed,
        fields = copy(normalized.fields),
        clears = copy(normalized.clears),
        fingerprint = Blueprint.Fingerprint(normalized),
    }
end

function Blueprint.Deserialize(payload)
    local normalized, reason
    if type(payload) ~= "table" then return nil, "blueprint_payload_invalid" end
    if payload.fingerprint then
        -- The payload fingerprint is diagnostic metadata.  Recompute it after
        -- validation; never trust it as an identity or authority token.
        local candidate = copy(payload)
        candidate.fingerprint = nil
        normalized, reason = Blueprint.Normalize(candidate)
        if not normalized then return nil, reason end
        if tostring(payload.fingerprint) ~= tostring(Blueprint.Fingerprint(normalized)) then
            return nil, "blueprint_fingerprint_mismatch"
        end
        return normalized
    end
    return Blueprint.Normalize(payload)
end

local function readDefinitionField(definition, field)
    local value
    if field.id == "identity.displayName" then
        value = definition.identity and definition.identity.displayName
            or definition.displayName
    elseif field.id == "identity.isFemale" then
        value = definition.identity and definition.identity.isFemale
        if value == nil then value = definition.isFemale end
    else
        value = Registry.Read(definition, field.id)
    end
    return value
end

function Blueprint.FromDefinition(definition, options)
    local output
    local field
    local value
    local reason
    local source
    options = type(options) == "table" and options or {}
    if type(definition) ~= "table" then return nil, "definition_invalid" end
    if definition.schemaId == Blueprint.SCHEMA_ID
        and type(definition.fields) == "table"
    then
        return Blueprint.Deserialize(definition)
    end
    if definition.blueprint and type(definition.blueprint) == "table" then
        return Blueprint.Deserialize(definition.blueprint)
    end
    output = Blueprint.New({
        id = options.id or definition.id or definition.uniqueDefinitionId,
        generationSeed = options.generationSeed or definition.generationSeed,
    })
    source = definition
    for _, field in ipairs(Registry.List()) do
        if field.authorable and field.persistable then
            value = readDefinitionField(source, field)
            if value ~= nil then
                output, reason = Blueprint.Set(output, field.id, value)
                if not output then return nil, reason end
            end
        end
    end
    return output
end

function Blueprint.FromDraft(draft, options)
    local output
    local field
    local value
    local reason
    local authored
    options = type(options) == "table" and options or {}
    if type(draft) ~= "table" then return nil, "draft_invalid" end
    output = Blueprint.New({
        id = options.id or draft.id or draft.uniqueDefinitionId,
        generationSeed = options.generationSeed or draft.previewSeed,
    })
    for _, field in ipairs(Registry.List()) do
        if field.authorable and field.persistable then
            authored = Registry.IsDraftAuthored(draft, field.id)
            value = Registry.ReadDraft(draft, field.id)
            if field.id == "identity.displayName"
                or field.id == "identity.isFemale"
            then
                authored = value ~= nil and value ~= ""
            end
            if field.id == "startingItems" and options.startingItems ~= nil then
                value = options.startingItems
                authored = type(value) == "table" and #value > 0
            end
            if authored and value ~= nil and value ~= "" then
                output, reason = Blueprint.Set(output, field.id, value)
                if not output then return nil, reason end
            end
        end
    end
    for fieldID, shouldClear in pairs(options.explicitClears or {}) do
        if shouldClear then
            output, reason = Blueprint.Clear(output, fieldID)
            if not output then return nil, reason end
        end
    end
    return output
end

function Blueprint.ToDefinition(blueprint, options)
    local normalized, reason = Blueprint.Normalize(blueprint)
    local definition
    local fieldID
    local field
    local identity
    local survivor
    local forename
    local surname
    local displayName
    local isFemale
    options = type(options) == "table" and options or {}
    if not normalized then return nil, reason end
    definition = {}
    definition.id = options.id or normalized.id
    definition.uniqueDefinitionId = definition.id
    definition.version = math.max(1, math.floor(tonumber(options.version) or 1))
    definition.generationSeed = normalized.generationSeed
    for fieldID, _ in pairs(normalized.fields) do
        field = Registry.Get(fieldID)
        if field then Registry.Write(definition, fieldID, normalized.fields[fieldID]) end
    end
    for fieldID, _ in pairs(normalized.clears) do
        field = Registry.Get(fieldID)
        if field then Registry.ClearRuntime(definition, fieldID) end
    end
    identity = definition.identity or {}
    survivor = identity.survivor or {}
    identity.survivor = survivor
    forename = survivor.forename
    surname = survivor.surname
    displayName = identity.displayName
    if not displayName and (forename or surname) then
        displayName = string.gsub(table.concat({
            tostring(forename or ""), tostring(surname or "")
        }, " "), "^%s+", "")
        displayName = string.gsub(displayName, "%s+$", "")
    end
    definition.displayName = displayName
    isFemale = identity.isFemale
    if isFemale ~= nil then definition.isFemale = isFemale == true end
    if hasEntries(identity) then definition.identity = identity end
    if definition.appearance and definition.appearance.schemaVersion then
        definition.appearanceVersion = definition.appearance.schemaVersion
    end
    return definition
end

return Blueprint
