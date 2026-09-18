-- Local, client-only persistence for editor drafts and produced definitions.
-- JSON keeps these files data-only and safe to share with other clients/mods.

require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"
require "PNC/Core/Definitions/PNC_DefinitionDatabase"

PNC = PNC or {}
PNC.UniqueNPCEditorStorage = PNC.UniqueNPCEditorStorage or {}

local Storage = PNC.UniqueNPCEditorStorage
local Model = PNC.UniqueNPCEditorModel
local Database = PNC.DefinitionDatabase
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"

local ROOT = Database.ROOT
local INDEX = Database.INDEX_PATH
local DIRECTORY = Database.GetDirectory("npc")
local LIMITS = { maxString = 65536, maxDepth = 12, maxCollection = 512 }

local function safeFileName(value)
    return Database.SafeFileName(value)
end

local function decode(textValue)
    if not textValue or textValue == "" then return nil, "file_empty" end
    return Json.Decode(textValue, LIMITS)
end

local function encode(value)
    return Json.Encode(value, LIMITS)
end

function Storage.LoadIndex()
    local output = {}
    for _, entry in ipairs(Database.List("npc")) do
        local fileName = safeFileName(entry.fileName)
        if fileName then output[#output + 1] = fileName end
    end
    table.sort(output)
    return output
end

function Storage.RebuildIndex(files)
    files = type(files) == "table" and files or Storage.LoadIndex()
    return Database.ReplaceKind("npc", files)
end

function Storage.FileName(draft)
    local fileName = safeFileName(draft and draft.fileName)
    if fileName and tostring(draft.originalDisplayName or "")
        == tostring(draft.displayName or "")
    then
        return fileName
    end
    return Model.FileName(draft)
end

function Storage.Save(draft, produced)
    local valid, normalized = Model.Validate(draft)
    local fileName
    local payload
    if not valid then return false, normalized end
    Model.SyncFromRuntime(draft)
    normalized = Model.BuildDefinition(draft)
    fileName = Storage.FileName(draft)
    payload = {
        schemaVersion = 2,
        kind = "ProjectHoomans.UniqueNPC",
        produced = produced == true,
        definition = normalized,
    }
    local ok, reason = Database.WriteFile("npc", fileName, encode(payload))
    if not ok then return false, reason end
    local indexed, indexReason = Database.Upsert("npc", fileName, {
        definitionType = "npc",
        fileName = fileName,
        definitionId = normalized.id,
        displayName = normalized.displayName,
        schemaVersion = payload.schemaVersion,
    })
    if not indexed then return false, indexReason end
    draft.fileName = fileName
    draft.id = normalized.id
    draft.identityIDLocked = true
    draft._dirty = false
    return true, fileName, normalized
end

function Storage.LoadFile(fileName)
    fileName = safeFileName(fileName)
    if not fileName then return nil, "invalid_file_name" end
    local content, reason = Database.ReadFile("npc", fileName)
    local payload
    if not content then return nil, reason end
    payload, reason = decode(content)
    if type(payload) ~= "table" then return nil, reason or "invalid_file" end
    local definition = payload.definition or payload
    if type(definition) ~= "table" then return nil, "definition_missing" end
    local valid, normalized = Model.Validate(Model.FromDefinition(definition, fileName))
    if not valid then return nil, normalized end
    return Model.FromDefinition(normalized, fileName)
end

function Storage.List()
    local output = {}
    for _, fileName in ipairs(Storage.LoadIndex()) do
        local draft = Storage.LoadFile(fileName)
        if draft then
            output[#output + 1] = {
                fileName = fileName,
                label = draft.displayName,
                draft = draft,
            }
        end
    end
    table.sort(output, function(left, right)
        return string.lower(tostring(left.label)) < string.lower(tostring(right.label))
    end)
    return output
end

Storage.ROOT = ROOT
Storage.INDEX = INDEX
Storage.DIRECTORY = DIRECTORY

return Storage
