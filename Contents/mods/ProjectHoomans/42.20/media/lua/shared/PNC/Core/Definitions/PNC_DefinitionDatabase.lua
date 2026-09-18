-- Shared local definition index for Project Hoomans authoring tools.
--
-- The index intentionally stays at Hoomans/UniqueNPCIndex.txt for backwards
-- compatibility.  Individual definitions are separated by kind so the
-- Unique NPC and Puppet Opera editors can never collide on filenames.

PNC = PNC or {}
PNC.DefinitionDatabase = PNC.DefinitionDatabase or {}

local Database = PNC.DefinitionDatabase
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"

local ROOT = "Hoomans"
local INDEX_NAME = "UniqueNPCIndex.txt"
local INDEX_PATH = ROOT .. "/" .. INDEX_NAME
local LIMITS = { maxString = 65536, maxDepth = 12, maxCollection = 1024 }
local MAX_FILE_LINES = 16384

local DIRECTORIES = {
    npc = "NPC Definitions",
    opera = "Opera Definitions",
}

local function cleanText(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    if maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function validKind(kind)
    kind = cleanText(kind, 16)
    return DIRECTORIES[kind] and kind or nil
end

local function validFileName(fileName)
    fileName = cleanText(fileName, 160)
    if fileName == "" or fileName == INDEX_NAME then return nil end
    if not string.match(fileName, "^[%w%._%-]+%.txt$") then return nil end
    return fileName
end

local function relativePath(kind, fileName)
    kind = validKind(kind)
    fileName = validFileName(fileName)
    if not kind or not fileName then return nil end
    return ROOT .. "/" .. DIRECTORIES[kind] .. "/" .. fileName
end

local function readText(path)
    if type(getFileReader) ~= "function" then
        return nil, "file_reader_unavailable"
    end
    local reader = getFileReader(path, false)
    if not reader then return nil, "file_missing" end
    local lines = {}
    while #lines < MAX_FILE_LINES do
        local line = reader:readLine()
        if line == nil then break end
        lines[#lines + 1] = line
    end
    reader:close()
    return table.concat(lines, "\n")
end

local function writeText(path, content)
    if type(getFileWriter) ~= "function" then
        return false, "file_writer_unavailable"
    end
    local writer = getFileWriter(path, true, false)
    if not writer then return false, "file_unavailable" end
    writer:write(tostring(content or ""))
    writer:close()
    return true
end

local function decode(content)
    if not content or content == "" then return nil end
    local value = Json.Decode(content, LIMITS)
    return type(value) == "table" and value or nil
end

local function encode(value)
    return Json.Encode(value, LIMITS)
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth > 8 then return nil end
    local result = {}
    for key, child in pairs(value) do
        if type(child) ~= "function"
            and type(child) ~= "userdata"
            and type(child) ~= "thread"
        then
            result[key] = type(child) == "table"
                and copy(child, depth + 1) or child
        end
    end
    return result
end

local function entryKey(kind, fileName)
    return tostring(kind) .. ":" .. tostring(fileName)
end

local function normalizeEntry(raw, fallbackKind)
    if type(raw) ~= "table" then return nil end
    local kind = validKind(raw.definitionType or raw.kind or fallbackKind)
    local fileName = validFileName(raw.fileName or raw.file)
    if not kind or not fileName then return nil end
    local entry = {
        definitionType = kind,
        fileName = fileName,
        path = relativePath(kind, fileName),
        definitionId = cleanText(
            raw.definitionId or raw.id,
            160
        ),
        displayName = cleanText(raw.displayName or raw.label, 160),
        schemaVersion = tonumber(raw.schemaVersion) or 1,
    }
    return entry
end

local function emptyIndex()
    return {
        schemaVersion = 2,
        kind = "ProjectHoomans.DefinitionIndex",
        entries = {},
        -- Keep the old field as a compatibility view for older tools. It
        -- contains only NPC basenames and is never the source of truth.
        files = {},
    }
end

local function loadIndex()
    local content = readText(INDEX_PATH)
    local payload = decode(content)
    local index = emptyIndex()
    local seen = {}
    local rawEntry
    local entry

    if type(payload) == "table" and type(payload.entries) == "table" then
        for _, rawEntry in ipairs(payload.entries) do
            entry = normalizeEntry(rawEntry)
            if entry and not seen[entryKey(entry.definitionType, entry.fileName)] then
                seen[entryKey(entry.definitionType, entry.fileName)] = true
                index.entries[#index.entries + 1] = entry
            end
        end
    end

    -- Old UniqueNPCIndex files only listed flat NPC files. Keep them readable
    -- and migrate their records into the new NPC Definitions namespace on the
    -- next write.
    if type(payload) == "table" and type(payload.files) == "table" then
        for _, fileName in ipairs(payload.files) do
            entry = normalizeEntry({
                definitionType = "npc",
                fileName = fileName,
            })
            if entry and not seen[entryKey(entry.definitionType, entry.fileName)] then
                seen[entryKey(entry.definitionType, entry.fileName)] = true
                index.entries[#index.entries + 1] = entry
            end
        end
    end

    table.sort(index.entries, function(left, right)
        local leftKey = entryKey(left.definitionType, left.fileName)
        local rightKey = entryKey(right.definitionType, right.fileName)
        return leftKey < rightKey
    end)
    for _, item in ipairs(index.entries) do
        if item.definitionType == "npc" then
            index.files[#index.files + 1] = item.fileName
        end
    end
    return index
end

local function saveIndex(index)
    local payload = emptyIndex()
    payload.entries = index.entries or {}
    for _, entry in ipairs(payload.entries) do
        if entry.definitionType == "npc" then
            payload.files[#payload.files + 1] = entry.fileName
        end
    end
    return writeText(INDEX_PATH, encode(payload))
end

function Database.GetDirectory(kind)
    kind = validKind(kind)
    return kind and DIRECTORIES[kind] or nil
end

function Database.GetPath(kind, fileName)
    return relativePath(kind, fileName)
end

function Database.SafeFileName(fileName)
    return validFileName(fileName)
end

function Database.ReadIndex()
    return loadIndex()
end

function Database.List(kind)
    kind = validKind(kind)
    if not kind then return {} end
    local result = {}
    for _, entry in ipairs(loadIndex().entries) do
        if entry.definitionType == kind then
            result[#result + 1] = copy(entry)
        end
    end
    return result
end

function Database.ReadFile(kind, fileName)
    local path = relativePath(kind, fileName)
    if not path then return nil, "invalid_definition_path" end
    local content, reason = readText(path)
    if content then return content, path end

    -- Existing NPC drafts were written directly under Hoomans. Read them as
    -- a migration fallback, but never write new definitions there.
    if validKind(kind) == "npc" then
        local legacyPath = ROOT .. "/" .. tostring(fileName)
        content, reason = readText(legacyPath)
        if content then return content, legacyPath end
    end
    return nil, reason or "file_missing"
end

function Database.WriteFile(kind, fileName, content)
    local path = relativePath(kind, fileName)
    if not path then return false, "invalid_definition_path" end
    local written, reason = writeText(path, content)
    if not written then return false, reason end
    return true, path
end

function Database.Upsert(kind, fileName, metadata)
    kind = validKind(kind)
    fileName = validFileName(fileName)
    if not kind or not fileName then return false, "invalid_definition_entry" end
    local index = loadIndex()
    local replacement = normalizeEntry(metadata or {}, kind)
    replacement.definitionType = kind
    replacement.fileName = fileName
    replacement.path = relativePath(kind, fileName)
    local key = entryKey(kind, fileName)
    local found = false
    for indexValue, entry in ipairs(index.entries) do
        if entryKey(entry.definitionType, entry.fileName) == key then
            index.entries[indexValue] = replacement
            found = true
            break
        end
    end
    if not found then index.entries[#index.entries + 1] = replacement end
    table.sort(index.entries, function(left, right)
        return entryKey(left.definitionType, left.fileName)
            < entryKey(right.definitionType, right.fileName)
    end)
    return saveIndex(index)
end

function Database.ReplaceKind(kind, fileNames)
    kind = validKind(kind)
    if not kind then return false, "invalid_definition_type" end
    local index = loadIndex()
    local retained = {}
    local seen = {}
    for _, entry in ipairs(index.entries) do
        if entry.definitionType ~= kind then retained[#retained + 1] = entry end
    end
    for _, fileName in ipairs(fileNames or {}) do
        fileName = validFileName(fileName)
        if fileName and not seen[fileName] then
            seen[fileName] = true
            retained[#retained + 1] = normalizeEntry({
                definitionType = kind,
                fileName = fileName,
            })
        end
    end
    index.entries = retained
    table.sort(index.entries, function(left, right)
        return entryKey(left.definitionType, left.fileName)
            < entryKey(right.definitionType, right.fileName)
    end)
    return saveIndex(index)
end

Database.ROOT = ROOT
Database.INDEX_NAME = INDEX_NAME
Database.INDEX_PATH = INDEX_PATH
Database.DIRECTORIES = DIRECTORIES

return Database
