-- Local canonical starter-preset persistence.
--
-- This store uses the Hoomans definition database's dedicated starter kind;
-- it never reads vanilla saved_builds.txt or the Unique NPC namespace.

require "PNC/Core/Definitions/PNC_DefinitionDatabase"
require "PNC/CharacterCreation/PNC_StartingCompanionPresets"

PNC = PNC or {}
PNC.StartingCompanionPresetStore = PNC.StartingCompanionPresetStore or {}

local Store = PNC.StartingCompanionPresetStore
local Database = PNC.DefinitionDatabase
local Presets = PNC.StartingCompanionPresets
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"

Store.SCHEMA_ID = "ProjectHoomans.StartingCompanionPresetFile"
Store.SCHEMA_VERSION = 1
Store.KIND = "starter"
Store.LIMITS = {
    maxString = 65536,
    maxDepth = 12,
    maxCollection = 512,
}

local function safeFileName(value)
    value = tostring(value or "StartingCompanion")
    value = string.gsub(value, "[^%w%._%-]+", "_")
    value = string.gsub(value, "^_+", "")
    value = string.gsub(value, "_+$", "")
    if value == "" then value = "StartingCompanion" end
    return string.sub(value, 1, 120) .. ".txt"
end

function Store.FileName(label)
    local candidate = safeFileName(label)
    return Database.SafeFileName(candidate)
end

function Store.Save(preset, label)
    local serialized, reason = Presets.Serialize(preset)
    local fileName
    local payload
    local encoded
    local ok
    if not serialized then return false, reason end
    fileName = Store.FileName(label or serialized.label)
    if not fileName then return false, "invalid_preset_file_name" end
    payload = {
        schemaId = Store.SCHEMA_ID,
        schemaVersion = Store.SCHEMA_VERSION,
        kind = "ProjectHoomans.StartingCompanionPreset",
        preset = serialized,
    }
    encoded = Json.Encode(payload, Store.LIMITS)
    ok, reason = Database.WriteFile(Store.KIND, fileName, encoded)
    if not ok then return false, reason end
    ok, reason = Database.Upsert(Store.KIND, fileName, {
        definitionType = Store.KIND,
        fileName = fileName,
        definitionId = Presets.Fingerprint(serialized),
        displayName = serialized.label or fileName,
        schemaVersion = Store.SCHEMA_VERSION,
    })
    if not ok then return false, reason end
    return true, fileName, serialized
end

function Store.Load(fileName)
    local content, reason = Database.ReadFile(Store.KIND, fileName)
    local payload
    local preset
    if not content then return nil, reason end
    payload = Json.Decode(content, Store.LIMITS)
    if type(payload) ~= "table"
        or tostring(payload.schemaId or "") ~= Store.SCHEMA_ID
        or tonumber(payload.schemaVersion) ~= Store.SCHEMA_VERSION
    then
        return nil, "unsupported_preset_file_schema"
    end
    preset, reason = Presets.Deserialize(payload.preset)
    if not preset then return nil, reason end
    return preset
end

function Store.List()
    local output = {}
    for _, entry in ipairs(Database.List(Store.KIND)) do
        output[#output + 1] = {
            fileName = entry.fileName,
            label = entry.displayName,
            schemaVersion = entry.schemaVersion,
        }
    end
    table.sort(output, function(left, right)
        return tostring(left.label) < tostring(right.label)
    end)
    return output
end

return Store
