-- Local, client-only persistence for editor drafts and produced definitions.
-- JSON keeps these files data-only and safe to share with other clients/mods.

require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"

PNC = PNC or {}
PNC.UniqueNPCEditorStorage = PNC.UniqueNPCEditorStorage or {}

local Storage = PNC.UniqueNPCEditorStorage
local Model = PNC.UniqueNPCEditorModel
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"

local ROOT = "Hoomans"
local INDEX = ROOT .. "/UniqueNPCIndex.txt"
local LIMITS = { maxString = 65536, maxDepth = 12, maxCollection = 512 }
local MAX_FILE_LINES = 8192

local function safeFileName(value)
    value = tostring(value or "")
    if string.match(value, "^[%w%-_]+%.txt$") then return value end
    return nil
end

local function path(fileName)
    return ROOT .. "/" .. tostring(fileName)
end

local function read(fileName)
    local reader = getFileReader and getFileReader(path(fileName), false) or nil
    local lines = {}
    if not reader then return nil, "file_missing" end
    while #lines < MAX_FILE_LINES do
        local line = reader:readLine()
        if line == nil then break end
        lines[#lines + 1] = line
    end
    reader:close()
    return table.concat(lines, "\n")
end

local function write(fileName, content)
    local writer = getFileWriter and getFileWriter(path(fileName), true, false) or nil
    if not writer then return false, "file_unavailable" end
    writer:write(tostring(content or ""))
    writer:close()
    return true
end

local function decode(textValue)
    if not textValue or textValue == "" then return nil, "file_empty" end
    return Json.Decode(textValue, LIMITS)
end

local function encode(value)
    return Json.Encode(value, LIMITS)
end

local function indexPayload(files)
    return { schemaVersion = 1, kind = "ProjectHoomans.UniqueNPCIndex", files = files }
end

function Storage.LoadIndex()
    local content = read("UniqueNPCIndex.txt")
    local payload
    if not content then return {} end
    payload = decode(content)
    if type(payload) ~= "table" or type(payload.files) ~= "table" then return {} end
    local output = {}
    for _, fileName in ipairs(payload.files) do
        fileName = safeFileName(fileName)
        if fileName then output[#output + 1] = fileName end
    end
    table.sort(output)
    return output
end

function Storage.RebuildIndex(files)
    files = type(files) == "table" and files or Storage.LoadIndex()
    local seen = {}
    local output = {}
    for _, fileName in ipairs(files) do
        fileName = safeFileName(fileName)
        if fileName and not seen[fileName] then
            seen[fileName] = true
            output[#output + 1] = fileName
        end
    end
    table.sort(output)
    return write("UniqueNPCIndex.txt", encode(indexPayload(output)))
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
    local files
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
    local ok, reason = write(fileName, encode(payload))
    if not ok then return false, reason end
    draft.fileName = fileName
    draft.id = normalized.id
    draft.identityIDLocked = true
    files = Storage.LoadIndex()
    files[#files + 1] = fileName
    Storage.RebuildIndex(files)
    draft._dirty = false
    return true, fileName, normalized
end

function Storage.LoadFile(fileName)
    fileName = safeFileName(fileName)
    if not fileName then return nil, "invalid_file_name" end
    local content, reason = read(fileName)
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

return Storage
