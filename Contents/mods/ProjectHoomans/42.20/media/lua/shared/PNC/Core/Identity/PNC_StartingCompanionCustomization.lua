-- Shared starter customization envelope.
--
-- The envelope is a transport representation of the canonical NPC blueprint;
-- it is not a companion-specific authoring schema.  Durable intent remains in
-- string-keyed blueprints while MP uses the registry's explicit wire codes.

require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PNC/Core/Identity/PNC_NPCAuthoring"

PNC = PNC or {}
PNC.StartingCompanionCustomization =
    PNC.StartingCompanionCustomization or {}

local Customization = PNC.StartingCompanionCustomization
local StartingTraits = PNC.StartingCompanionTraits
local Authoring = PNC.NPCAuthoring
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint

Customization.SCHEMA_ID = "ProjectHoomans.StartingCompanionCustomization"
Customization.SCHEMA_VERSION = 1
Customization.PROTOCOL_VERSION = 1
Customization.MAX_SLOTS = #StartingTraits.DEFINITIONS
Customization.MAX_FIELDS_PER_SLOT = 48
Customization.MAX_TOTAL_FIELDS = 96
Customization.LocalEnvelope = Customization.LocalEnvelope or nil

local function copy(value)
    return Registry.Copy(value)
end

local function validText(value)
    return type(value) == "string" and value ~= ""
end

local function allowedKeys(value, allowed, label)
    local key
    if type(value) ~= "table" then
        return false, tostring(label or "value") .. "_invalid"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return false, tostring(label or "value") .. "_key_invalid:"
                .. tostring(key)
        end
    end
    return true
end

local function isArray(value, maximum, label)
    local count
    local key
    if type(value) ~= "table" then
        return false, tostring(label or "array") .. "_invalid"
    end
    count = #value
    if count > (maximum or Customization.MAX_SLOTS) then
        return false, tostring(label or "array") .. "_too_large"
    end
    for key in pairs(value) do
        if type(key) ~= "number"
            or key < 1
            or key > count
            or key ~= math.floor(key)
        then
            return false, tostring(label or "array") .. "_not_dense"
        end
    end
    return true
end

local function normalizeTraitIDs(values)
    local found = {}
    local output = {}
    local value
    local id
    if type(values) ~= "table" then return nil, "trait_ids_invalid" end
    if #values > Customization.MAX_SLOTS then
        return nil, "too_many_companion_slots"
    end
    for index = 1, #values do
        value = values[index]
        id = tostring(value or "")
        if not validText(id) or not StartingTraits.GetDefinition(id) then
            return nil, "unknown_companion_trait"
        end
        if found[id] then return nil, "duplicate_companion_trait" end
        found[id] = true
    end
    for index = 1, #StartingTraits.DEFINITIONS do
        id = StartingTraits.DEFINITIONS[index].id
        if found[id] then output[#output + 1] = id end
    end
    return output
end

local function sameList(left, right)
    if #left ~= #right then return false end
    for index = 1, #left do
        if left[index] ~= right[index] then return false end
    end
    return true
end

local function compactFingerprintInput(envelope)
    return {
        protocolVersion = envelope.protocolVersion,
        registryFingerprint = envelope.registryFingerprint,
        schemaId = envelope.schemaId,
        schemaVersion = envelope.schemaVersion,
        selectedTraitIDs = copy(envelope.selectedTraitIDs),
        slots = copy(envelope.slots),
    }
end

function Customization.Fingerprint(envelope)
    if type(envelope) ~= "table" then return nil end
    return "starter-envelope:v" .. tostring(Customization.SCHEMA_VERSION)
        .. ":" .. Registry.Hash(compactFingerprintInput(envelope))
end

function Customization.NormalizeTraitIDs(values)
    return normalizeTraitIDs(values)
end

local function sourceBlueprints(source)
    if source and type(source.FinalBlueprints) == "function" then
        return source:FinalBlueprints()
    end
    return source
end

function Customization.BuildEnvelope(source, selectedTraitIDs)
    local blueprints = sourceBlueprints(source)
    local selected
    local envelope
    local blueprint
    local compact
    local reason
    local totalFields = 0
    if type(blueprints) ~= "table" then
        return nil, "blueprints_invalid"
    end
    if selectedTraitIDs == nil and source and source.selectedOrder then
        selectedTraitIDs = source.selectedOrder
    end
    selected, reason = normalizeTraitIDs(selectedTraitIDs or {})
    if not selected then return nil, reason end
    envelope = {
        protocolVersion = Customization.PROTOCOL_VERSION,
        registryFingerprint = Registry.Fingerprint(),
        schemaId = Customization.SCHEMA_ID,
        schemaVersion = Customization.SCHEMA_VERSION,
        selectedTraitIDs = copy(selected),
        slots = {},
    }
    for index = 1, #selected do
        local traitID = selected[index]
        blueprint = blueprints[traitID]
        if type(blueprint) ~= "table" then
            return nil, "slot_blueprint_missing:" .. tostring(traitID)
        end
        compact, reason = Registry.EncodeCompact(blueprint)
        if not compact then return nil, reason end
        local fieldCount = 0
        for _ in pairs(compact.values or {}) do fieldCount = fieldCount + 1 end
        for _, enabled in pairs(compact.clears or {}) do
            if enabled then fieldCount = fieldCount + 1 end
        end
        if fieldCount > Customization.MAX_FIELDS_PER_SLOT then
            return nil, "slot_compact_fields_too_large:" .. tostring(traitID)
        end
        totalFields = totalFields + fieldCount
        if totalFields > Customization.MAX_TOTAL_FIELDS then
            return nil, "compact_envelope_too_large"
        end
        envelope.slots[#envelope.slots + 1] = {
            traitID = traitID,
            blueprint = compact,
        }
    end
    envelope.fingerprint = Customization.Fingerprint(envelope)
    return envelope
end

local function validateCompactShape(compact, label)
    local ok
    local reason
    local values
    local clears
    local count
    if type(compact) ~= "table" then
        return false, tostring(label) .. "_invalid"
    end
    ok, reason = allowedKeys(compact, {
        protocolVersion = true,
        registryFingerprint = true,
        schemaId = true,
        schemaVersion = true,
        generationSeed = true,
        values = true,
        clears = true,
    }, label)
    if not ok then return false, reason end
    values = compact.values
    clears = compact.clears
    if type(values) ~= "table" or type(clears) ~= "table" then
        return false, tostring(label) .. "_fields_invalid"
    end
    count = 0
    for _ in pairs(values) do
        count = count + 1
        if count > Customization.MAX_FIELDS_PER_SLOT then
            return false, tostring(label) .. "_fields_too_large"
        end
    end
    for _, enabled in pairs(clears) do
        if enabled ~= true then
            return false, tostring(label) .. "_clear_value_invalid"
        end
    end
    return true
end

function Customization.DecodeEnvelope(envelope)
    local ok
    local reason
    local selected
    local slots
    local decoded = {}
    local order = {}
    local seen = {}
    local totalFields = 0
    local slot
    local compact
    local blueprint
    local traitID
    if type(envelope) ~= "table" then
        return nil, "customization_envelope_invalid"
    end
    ok, reason = allowedKeys(envelope, {
        protocolVersion = true,
        registryFingerprint = true,
        schemaId = true,
        schemaVersion = true,
        selectedTraitIDs = true,
        slots = true,
        fingerprint = true,
    }, "customization_envelope")
    if not ok then return nil, reason end
    if tonumber(envelope.protocolVersion) ~= Customization.PROTOCOL_VERSION
        or tonumber(envelope.protocolVersion) ~= Registry.PROTOCOL_VERSION
    then
        return nil, "customization_protocol_version_mismatch"
    end
    if tostring(envelope.registryFingerprint or "")
        ~= Registry.Fingerprint()
    then
        return nil, "customization_registry_fingerprint_mismatch"
    end
    if tostring(envelope.schemaId or "") ~= Customization.SCHEMA_ID
        or tonumber(envelope.schemaVersion) ~= Customization.SCHEMA_VERSION
    then
        return nil, "customization_schema_version_mismatch"
    end
    if envelope.fingerprint
        and tostring(envelope.fingerprint)
            ~= tostring(Customization.Fingerprint(envelope))
    then
        return nil, "customization_fingerprint_mismatch"
    end
    selected, reason = normalizeTraitIDs(envelope.selectedTraitIDs)
    if not selected then return nil, reason end
    slots = envelope.slots
    ok, reason = isArray(slots, Customization.MAX_SLOTS, "customization_slots")
    if not ok then return nil, reason end
    if #slots ~= #selected then
        return nil, "customization_slot_selection_mismatch"
    end
    for index = 1, #slots do
        slot = slots[index]
        ok, reason = allowedKeys(slot, {
            traitID = true,
            blueprint = true,
        }, "customization_slot")
        if not ok then return nil, reason end
        traitID = tostring(slot.traitID or "")
        if traitID ~= selected[index] then
            return nil, "customization_slot_order_mismatch"
        end
        if seen[traitID] then return nil, "duplicate_companion_trait" end
        seen[traitID] = true
        compact = slot.blueprint
        ok, reason = validateCompactShape(compact, "compact_blueprint")
        if not ok then return nil, reason end
        totalFields = totalFields + 0
        for _ in pairs(compact.values or {}) do totalFields = totalFields + 1 end
        for _, enabled in pairs(compact.clears or {}) do
            if enabled then totalFields = totalFields + 1 end
        end
        if totalFields > Customization.MAX_TOTAL_FIELDS then
            return nil, "compact_envelope_too_large"
        end
        -- Decode into a temporary map only.  No caller receives a partial
        -- result if a later slot has an incompatible schema or bad field.
        blueprint, reason = Registry.DecodeCompact(compact)
        if not blueprint then return nil, reason end
        blueprint.id = "starter:" .. traitID
        decoded[traitID] = blueprint
        order[#order + 1] = traitID
    end
    return {
        selectedTraitIDs = order,
        blueprints = decoded,
        fingerprint = envelope.fingerprint
            or Customization.Fingerprint(envelope),
    }
end

local function removeField(blueprint, fieldID)
    local output = Blueprint.Clone(blueprint)
    output.fields = output.fields or {}
    output.clears = output.clears or {}
    output.fields[fieldID] = nil
    output.clears[fieldID] = nil
    return output
end

function Customization.SanitizeBlueprint(blueprint, spec)
    local normalized
    local reason
    local policy
    local report = {
        rebound = {},
        removed = {},
    }
    local fieldID
    local state
    if not spec then return nil, "companion_spec_missing" end
    normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return nil, reason end
    policy = PNC.NPCAuthoringResolver.PolicyForStartingCompanion(spec)
    for fieldID, binding in pairs(policy.bindings or {}) do
        -- Orientation is unavailable at wire sanitization. Retain partner sex
        -- intent here; final resolution enforces the actual player's policy.
        if binding.mandatory and not (fieldID == "identity.isFemale" and spec.sex == "orientation") then
            state = Blueprint.Get(normalized, fieldID)
            if state ~= "absent" then
                normalized = removeField(normalized, fieldID)
                report.rebound[#report.rebound + 1] = fieldID
            end
        end
    end
    for fieldID, _ in pairs(policy.serverControlledFields or {}) do
        state = Blueprint.Get(normalized, fieldID)
        if state ~= "absent" then
            normalized = removeField(normalized, fieldID)
            report.removed[#report.removed + 1] = fieldID
        end
    end
    -- Family policy binds the human skin and hair fields. The outfit,
    -- makeup and other worn item visuals are editable for every companion.
    normalized.id = "starter:" .. tostring(spec.id)
    table.sort(report.rebound)
    table.sort(report.removed)
    return normalized, report
end

function Customization.SetLocalEnvelope(envelope)
    local decoded
    local reason
    decoded, reason = Customization.DecodeEnvelope(envelope)
    if not decoded then return false, reason end
    Customization.LocalEnvelope = copy(envelope)
    return true, decoded
end

function Customization.TakeLocalEnvelope()
    local envelope = Customization.LocalEnvelope
    Customization.LocalEnvelope = nil
    return envelope
end

function Customization.ClearLocalEnvelope()
    Customization.LocalEnvelope = nil
end

return Customization
