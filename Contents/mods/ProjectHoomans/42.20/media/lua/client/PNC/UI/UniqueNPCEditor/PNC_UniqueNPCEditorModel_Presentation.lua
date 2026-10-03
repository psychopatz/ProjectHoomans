-- Portrait, authored inventory, and parser operations for the editor model.
PNC = PNC or {}
PNC.UniqueNPCEditorModel = PNC.UniqueNPCEditorModel or {}

local Model = PNC.UniqueNPCEditorModel
local Internal = Model.Internal or {}
local Inventory = PNC.Inventory
local copy = Internal.copy
local hasEntries = Internal.hasEntries
local generatedItem = Internal.generatedItem
local exportItems = Internal.exportItems

function Model.BuildPortraitSpec(draft)
    local record = Model.EnsureRuntimeRecord(draft)
    local runtime = record and record.runtime or {}
    local snapshot = runtime.previewVisualSnapshot or {}
    local appearance = snapshot.appearance
        or record and runtime.appearanceCache or {}
    local equipment = snapshot.equipment or record and record.equipment or {}
    local revision = runtime.previewVisualRevision or 0
    return {
        key = tostring(draft.id or Model.BuildID(draft))
            .. ":preview:" .. tostring(revision),
        id = tostring(draft.id or "editor"),
        identitySeed = record and record.identitySeed or draft.previewSeed or 1,
        isFemale = draft.isFemale == true,
        preferDescriptor = true,
        appearance = copy(appearance),
        equipment = copy(equipment),
    }
end

function Model.ExportItems(draft)
    return exportItems(draft)
end

function Model.ListAuthoredItems(draft)
    local output = {}
    local inventory = draft and draft.runtimeRecord
        and draft.runtimeRecord.inventory or nil
    if not inventory then return output end
    for id, item in pairs(inventory.items or {}) do
        if item and not generatedItem(item) then
            output[#output + 1] = {
                runtimeID = id,
                type = item.type,
                stack = item.stack,
                container = item.container,
            }
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.runtimeID) < tostring(right.runtimeID)
    end)
    return output
end

function Model.RemoveInventoryItem(draft, runtimeID)
    local inventory = draft and draft.runtimeRecord
        and draft.runtimeRecord.inventory or nil
    local item
    local index
    if not inventory or runtimeID == nil then return false end
    item = inventory.items and inventory.items[runtimeID]
    if not item then return false end
    inventory.items[runtimeID] = nil
    for _, containerData in pairs(inventory.containers or {}) do
        local itemIDs = containerData and containerData.items or nil
        if type(itemIDs) == "table" then
            for index = #itemIDs, 1, -1 do
                if tostring(itemIDs[index]) == tostring(runtimeID) then
                    table.remove(itemIDs, index)
                end
            end
        end
    end
    inventory.revision = (tonumber(inventory.revision) or 0) + 1
    if Inventory and Inventory.SyncEquipmentFromInventory then
        Inventory.SyncEquipmentFromInventory(draft.runtimeRecord)
    end
    draft._dirty = true
    return true
end

function Model.ParseList(value)
    local output = {}
    for token in string.gmatch(tostring(value or ""), "[^,%s]+") do
        output[#output + 1] = token
    end
    return #output > 0 and output or nil
end

function Model.ParseMap(value)
    local output = {}
    for token in string.gmatch(tostring(value or ""), "[^,]+") do
        local key, number = string.match(token, "^%s*([^=]+)%s*=%s*(%-?[%d%.]+)%s*$")
        if key and number then output[tostring(key)] = tonumber(number) end
    end
    return hasEntries(output) and output or nil
end

return Model
