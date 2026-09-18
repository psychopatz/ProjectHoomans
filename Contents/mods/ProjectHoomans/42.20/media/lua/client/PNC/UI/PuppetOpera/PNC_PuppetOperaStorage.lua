-- Local persistence for Puppet Opera definitions.
--
-- Draft files live below Hoomans/Opera Definitions.  The shared root index is
-- maintained by PNC_DefinitionDatabase so NPC and Opera editors share one
-- discoverable database without sharing a filename namespace.

require "PNC/Core/Definitions/PNC_DefinitionDatabase"
require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints"

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Storage = PNC.PuppetOpera.Storage or {}

local Storage = PNC.PuppetOpera.Storage
local Database = PNC.DefinitionDatabase
local Blueprints = PNC.PuppetOpera.Blueprints
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"

local KIND = "opera"
local ROOT = Database.ROOT
local INDEX = Database.INDEX_PATH
local DIRECTORY = Database.GetDirectory(KIND)
local LIMITS = { maxString = 65536, maxDepth = 16, maxCollection = 1024 }
local MAX_FILE_LINES = 16384

local function decode(content)
    if not content or content == "" then return nil, "file_empty" end
    local value = Json.Decode(content, LIMITS)
    if type(value) ~= "table" then return nil, "invalid_json" end
    return value
end

local function encode(value)
    return Json.Encode(value, LIMITS)
end

local function safeID(value)
    value = tostring(value or "")
    if value == "" or not string.match(value, "^[%w%._%-]+$") then
        return nil
    end
    return value
end

local function fileNameFor(definition)
    local id = safeID(definition and definition.id)
    if not id then return nil end
    local fileName = string.gsub(id, "[^%w%._%-]", "_") .. ".txt"
    return Database.SafeFileName(fileName)
end

local function readDefinition(fileName)
    local content, reason = Database.ReadFile(KIND, fileName)
    if not content then return nil, reason end
    if #content > MAX_FILE_LINES * 4096 then
        return nil, "definition_file_too_large"
    end
    local payload
    payload, reason = decode(content)
    if not payload then return nil, reason end
    local definition = payload.definition or payload
    if type(definition) ~= "table" then
        return nil, "definition_missing"
    end
    local id = safeID(definition.id)
    if not id then return nil, "definition_id_invalid" end
    local normalized, normalizeReason = Blueprints.Normalize(id, definition)
    if not normalized then return nil, normalizeReason end
    return normalized
end

function Storage.FileName(definition)
    return fileNameFor(definition)
end

function Storage.Save(definition)
    local id = safeID(definition and definition.id)
    if not id then return false, "definition_id_invalid" end
    local normalized, reason = Blueprints.Normalize(id, definition)
    if not normalized then return false, reason end
    local fileName = fileNameFor(normalized)
    if not fileName then return false, "definition_file_name_invalid" end
    local payload = {
        schemaVersion = 1,
        kind = "ProjectHoomans.OperaDefinition",
        definitionType = KIND,
        definition = normalized,
    }
    local written, writeReason = Database.WriteFile(
        KIND,
        fileName,
        encode(payload)
    )
    if not written then return false, writeReason end
    local indexed, indexReason = Database.Upsert(KIND, fileName, {
        definitionType = KIND,
        fileName = fileName,
        definitionId = normalized.id,
        displayName = normalized.label,
        schemaVersion = payload.schemaVersion,
    })
    if not indexed then return false, indexReason end
    return true, fileName, normalized
end

function Storage.LoadFile(fileName)
    fileName = Database.SafeFileName(fileName)
    if not fileName then return nil, "invalid_file_name" end
    return readDefinition(fileName)
end

function Storage.List()
    local result = {}
    for _, entry in ipairs(Database.List(KIND)) do
        local definition, reason = Storage.LoadFile(entry.fileName)
        if definition then
            result[#result + 1] = {
                id = definition.id,
                fileName = entry.fileName,
                label = definition.label,
                draft = definition,
            }
        elseif reason then
            result[#result + 1] = {
                id = entry.definitionId or entry.fileName,
                fileName = entry.fileName,
                label = entry.displayName or entry.fileName,
                error = reason,
            }
        end
    end
    table.sort(result, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return result
end

function Storage.LoadAll()
    local result = {}
    for _, entry in ipairs(Storage.List()) do
        if entry.draft then result[#result + 1] = entry.draft end
    end
    return result
end

Storage.ROOT = ROOT
Storage.INDEX = INDEX
Storage.DIRECTORY = DIRECTORY
Storage.KIND = KIND

return Storage
