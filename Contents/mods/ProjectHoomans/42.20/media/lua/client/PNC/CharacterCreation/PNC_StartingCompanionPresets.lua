-- Canonical starting-companion preset format.
--
-- Presets contain only sparse blueprint intent and generation state.  They do
-- not contain a resolved surname, relationship-derived sex, appearance,
-- runtime NPC ID, player identity, or authority fields.

require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PNC/Core/Identity/PNC_NPCAuthoring"

PNC = PNC or {}
PNC.StartingCompanionPresets = PNC.StartingCompanionPresets or {}

local Presets = PNC.StartingCompanionPresets
local StartingTraits = PNC.StartingCompanionTraits
local Authoring = PNC.NPCAuthoring
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint

Presets.SCHEMA_ID = "ProjectHoomans.StartingCompanionPreset"
Presets.SCHEMA_VERSION = 1
Presets.MAX_SLOTS = #StartingTraits.DEFINITIONS
Presets.MAX_LABEL_LENGTH = 128

local function copy(value)
    return Registry.Copy(value)
end

local function cleanLabel(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, Presets.MAX_LABEL_LENGTH)
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

local function addSerialized(output, traitID, payload)
    local id = normalizeTraitID(traitID)
    local blueprint, reason
    if not id then return nil, "unknown_companion_trait" end
    blueprint, reason = Blueprint.Deserialize(payload)
    if not blueprint then return nil, reason end
    blueprint.id = "starter:" .. tostring(id)
    output[id] = Blueprint.Serialize(blueprint)
    return true
end

function Presets.Normalize(payload)
    local output
    local slots
    local count = 0
    local id
    local serialized
    local reason
    if type(payload) ~= "table" then return nil, "preset_invalid" end
    if tostring(payload.schemaId or "") ~= Presets.SCHEMA_ID then
        return nil, "unsupported_preset_schema"
    end
    if tonumber(payload.schemaVersion) ~= Presets.SCHEMA_VERSION then
        return nil, "unsupported_preset_version"
    end
    if payload.kind ~= "whole" and payload.kind ~= "template" then
        return nil, "preset_kind_invalid"
    end
    output = {
        schemaId = Presets.SCHEMA_ID,
        schemaVersion = Presets.SCHEMA_VERSION,
        kind = payload.kind,
        label = cleanLabel(payload.label),
        companionTraitID = nil,
        slots = {},
    }
    slots = type(payload.slots) == "table" and payload.slots or {}
    for id, serialized in pairs(slots) do
        count = count + 1
        if count > Presets.MAX_SLOTS then return nil, "too_many_preset_slots" end
        local ok
        ok, reason = addSerialized(output.slots, id, serialized)
        if not ok then return nil, reason end
    end
    if payload.kind == "template" then
        output.companionTraitID = normalizeTraitID(payload.companionTraitID)
        if not output.companionTraitID then
            return nil, "template_trait_missing"
        end
        if not output.slots[output.companionTraitID] then
            return nil, "template_blueprint_missing"
        end
    end
    return output
end

function Presets.Fingerprint(payload)
    local normalized, reason = Presets.Normalize(payload)
    if not normalized then return nil, reason end
    return "preset:v" .. tostring(Presets.SCHEMA_VERSION) .. ":"
        .. Registry.Hash(normalized)
end

function Presets.Serialize(payload)
    local normalized, reason = Presets.Normalize(payload)
    if not normalized then return nil, reason end
    normalized.fingerprint = Presets.Fingerprint(normalized)
    return normalized
end

function Presets.Deserialize(payload)
    local candidate = copy(payload)
    local expected
    local normalized
    local reason
    if type(candidate) ~= "table" then return nil, "preset_payload_invalid" end
    expected = candidate.fingerprint
    candidate.fingerprint = nil
    normalized, reason = Presets.Normalize(candidate)
    if not normalized then return nil, reason end
    if expected and tostring(expected) ~= tostring(Presets.Fingerprint(normalized)) then
        return nil, "preset_fingerprint_mismatch"
    end
    return normalized
end

function Presets.FromSession(session, label)
    local payload = {
        schemaId = Presets.SCHEMA_ID,
        schemaVersion = Presets.SCHEMA_VERSION,
        kind = "whole",
        label = cleanLabel(label),
        slots = {},
    }
    if not session or type(session.FinalBlueprints) ~= "function" then
        return nil, "session_invalid"
    end
    for traitID, blueprint in pairs(session:FinalBlueprints()) do
        payload.slots[traitID] = Blueprint.Serialize(blueprint)
    end
    return Presets.Serialize(payload)
end

function Presets.TemplateFromSession(session, traitID, label)
    local id = normalizeTraitID(traitID)
    local blueprint = session and session.GetBlueprint
        and session:GetBlueprint(id)
    if not id then return nil, "unknown_companion_trait" end
    if not blueprint then return nil, "slot_not_found" end
    return Presets.Serialize({
        schemaId = Presets.SCHEMA_ID,
        schemaVersion = Presets.SCHEMA_VERSION,
        kind = "template",
        label = cleanLabel(label),
        companionTraitID = id,
        slots = { [id] = Blueprint.Serialize(blueprint) },
    })
end

local function applyBlueprint(session, traitID, blueprint)
    local slot = session.GetSlot and session:GetSlot(traitID, true) or nil
    if slot then
        return session:SetBlueprint(traitID, blueprint, {
            presetBaseline = true,
        })
    end
    session.pendingBlueprints = session.pendingBlueprints or {}
    session.pendingBlueprints[traitID] = Blueprint.Clone(blueprint)
    return true, "pending"
end

function Presets.ApplyToSession(session, payload)
    local normalized, reason = Presets.Deserialize(payload)
    local applied = {}
    local pending = {}
    local id
    local serialized
    local blueprint
    local ok
    if not normalized then return nil, reason end
    if not session or type(session.SetBlueprint) ~= "function" then
        return nil, "session_invalid"
    end
    for id, serialized in pairs(normalized.slots) do
        blueprint, reason = Blueprint.Deserialize(serialized)
        if not blueprint then return nil, reason end
        ok, reason = applyBlueprint(session, id, blueprint)
        if not ok then return nil, reason end
        if reason == "pending" then
            pending[#pending + 1] = id
        else
            applied[#applied + 1] = id
        end
    end
    table.sort(applied)
    table.sort(pending)
    return {
        preset = normalized,
        applied = applied,
        pending = pending,
        addedTraits = false,
    }
end

function Presets.Encode(payload)
    local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
    local serialized, reason = Presets.Serialize(payload)
    if not serialized then return nil, reason end
    return Json.Encode(serialized, {
        maxString = 65536,
        maxDepth = 12,
        maxCollection = 512,
    })
end

function Presets.Decode(text)
    local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
    local payload = Json.Decode(text, {
        maxString = 65536,
        maxDepth = 12,
        maxCollection = 512,
    })
    return Presets.Deserialize(payload)
end

return Presets
