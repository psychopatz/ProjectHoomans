-- Local, client-only persistence for editor drafts and produced definitions.
-- JSON keeps these files data-only and safe to share with other clients/mods.

require "PNC/Identity/PNC_UniqueNPCDraft"
require "PNC/Core/Definitions/PNC_DefinitionDatabase"

PNC = PNC or {}
PNC.UniqueNPCEditorStorage = PNC.UniqueNPCEditorStorage or {}

local Storage = PNC.UniqueNPCEditorStorage
local Model = PNC.UniqueNPCEditorModel
local Database = PNC.DefinitionDatabase
local Authoring = PNC.NPCAuthoring or require "PNC/Core/Identity/PNC_NPCAuthoring"
local Blueprint = Authoring.Blueprint
local File = require "PNC/Core/Definitions/PNC_NPCDefinitionFile"

local ROOT = Database.ROOT
local INDEX = Database.INDEX_PATH
local DIRECTORY = Database.GetDirectory("npc")
local FILE_SCHEMA_VERSION = 2

local function safeFileName(value)
    return Database.SafeFileName(value)
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

function Storage.Save(draft, produced, requestedFileName)
    local valid, normalized = Model.Validate(draft)
    local blueprint
    local blueprintReason
    local fileName
    if not valid then return false, normalized end
    Model.SyncFromRuntime(draft)
    normalized = Model.BuildDefinition(draft)
    if not normalized then return false, "definition_build_failed" end
    blueprint, blueprintReason = Model.BuildBlueprint(draft)
    if not blueprint then return false, blueprintReason end
    if requestedFileName then fileName = safeFileName(requestedFileName)
    else fileName = Storage.FileName(draft) end
    if not fileName then return false, "invalid_file_name" end
    local encoded, encodeReason = File.Encode(blueprint, produced)
    if not encoded then return false, encodeReason end
    local ok, reason = Database.WriteFile("npc", fileName, encoded)
    if not ok then return false, reason end
    local indexed, indexReason = Database.Upsert("npc", fileName, {
        definitionType = "npc",
        fileName = fileName,
        definitionId = normalized.id,
        displayName = normalized.displayName,
        schemaVersion = FILE_SCHEMA_VERSION,
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
    if not content then return nil, reason end
    local definition
    definition, reason = File.Decode(content)
    if not definition then return nil, reason end
    local draft, draftReason = Model.FromDefinition(definition, fileName)
    if not draft then return nil, draftReason end
    local valid, normalized = Model.Validate(draft)
    if not valid then return nil, normalized end
    return draft
end

function Storage.SaveCharacter(draft, fileName)
    local collection = require "PNC/Core/Definitions/PNC_LocalNPCCollection"
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not collection.CanPublish(player) then return false, "admin_required" end
    fileName = safeFileName(fileName)
    if not fileName then return false, "invalid_file_name" end
    local snapshot = Authoring.Registry.Copy(draft)
    snapshot.id = "user:" .. string.gsub(fileName, "%.txt$", "")
    snapshot.identityIDLocked = true
    local record, previewReason = Model.EnsureRuntimeRecord(snapshot)
    if not record then return false, previewReason end
    local portrait = Model.BuildPortraitSpec(snapshot)
    local look = portrait and portrait.appearance
    if not look then return false, "preview_unavailable" end
    for _, field in ipairs({ "skinTexture", "skinColor", "hairModel", "beardModel", "hairColor", "voice", "voicePrefix", "voiceType", "voicePitch" }) do
        snapshot.identity.survivor[field] = Authoring.Registry.Copy((record.identity.survivor or {})[field])
        if look[field] ~= nil then snapshot.identity.survivor[field] = Authoring.Registry.Copy(look[field]) end
        snapshot.appearanceAuthored[field] = true
        snapshot.authoringClears["appearance." .. field] = nil
    end
    snapshot.appearance.outfit = { mode = "none" }
    snapshot.appearance.slots = {}
    snapshot.authoringClears.appearance, snapshot.authoringClears.startingItems = nil, nil
    snapshot.startingItems = {}
    local ids = {}
    for id in pairs(record.inventory and record.inventory.items or {}) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return tostring(a) < tostring(b) end)
    for _, id in ipairs(ids) do
        local item = record.inventory.items[id]
        if item.wornSlot and not item.equipSlot and not item.maxWeight and not item.bagContainer then
            local spec = PNC.Identity.Appearance.CaptureItemSpec(item)
            if spec then PNC.Identity.Appearance.CaptureSlot(snapshot.appearance.slots, item.wornSlot, spec) end
        elseif string.find(tostring(item.templateKey or ""), "tmpl:identity_card:", 1, true) ~= 1 then
            local spec = PNC.Inventory.Queries.ToDefinitionSpec(item, "library:" .. tostring(#snapshot.startingItems + 1), item.container and item.container ~= "root" and "bag" or nil)
            if spec then snapshot.startingItems[#snapshot.startingItems + 1] = spec end
        end
    end
    snapshot.authoredFields.startingItems = true
    snapshot.equipmentSpawnMode = "none"
    snapshot.runtimeRecord = nil
    local ok, reason = Storage.Save(snapshot, true, fileName)
    if not ok then return false, reason end
    local blueprint = Model.BuildBlueprint(snapshot)
    if isClient and isClient() then
        if not player or not sendClientCommand then return false, "network_unavailable" end
        sendClientCommand(player, PNC.Const.MODULE, PNC.Const.CMD_DEBUG,
            { action = "register_unique_definition", fileName = fileName, blueprint = Blueprint.Serialize(blueprint) })
    elseif PNC.Core and PNC.Core.IsAuthority and PNC.Core.IsAuthority() then
        return collection.Register(blueprint, fileName)
    end
    return true, fileName
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
