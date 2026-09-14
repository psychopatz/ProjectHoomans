require "PNC/00_PNC_Init"

PNC = PNC or {}
PNC.InventoryTransferEndpoint = PNC.InventoryTransferEndpoint or {}

local Endpoint = PNC.InventoryTransferEndpoint
local Model = PNC.InventoryUIModel
    or require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local StorageModel = PNC.ColonyStorageViewModel
    or require "PNC/UI/Communities/PNC_ColonyStorageViewModel"
local Inventory = PNC.Inventory
local EditorModel

local ROOT_TEXTURE = getTexture
    and getTexture("media/ui/Icon_InventoryBasic.png") or nil

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function title(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

local function findNativeItem(container, wantedID, depth)
    local items
    local item
    local nested
    depth = tonumber(depth) or 0
    if not container or depth > 6 then return nil end
    items = container.getItems and container:getItems() or nil
    if not items or not items.size or not items.get then return nil end
    for index = 0, items:size() - 1 do
        item = items:get(index)
        if item and item.getID and tostring(item:getID()) == tostring(wantedID) then
            return item
        end
        nested = item and item.getItemContainer and item:getItemContainer()
            or item and item.getInventory and item:getInventory() or nil
        item = findNativeItem(nested, wantedID, depth + 1)
        if item then return item end
    end
    return nil
end

local function localPlayer()
    return getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
end

function Endpoint.LocalDraft(draft)
    local endpoint = {
        kind = "local_draft",
        role = "counterparty",
        id = "editor-draft",
        displayName = draft and draft.displayName or "Unique NPC Draft",
        draft = draft,
        selectedContainer = "root",
        expandedGroups = {},
    }
    local function record()
        if not EditorModel then
            EditorModel = require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"
        end
        return EditorModel.EnsureRuntimeRecord(draft)
    end
    function endpoint:payload()
        self.displayName = draft and draft.displayName or self.displayName
        local current = record()
        return current and {
            inventory = current.inventory,
            snapshot = { id = self.id, name = self.displayName },
        } or nil
    end
    function endpoint:inventory()
        local current = record()
        return current and current.inventory or nil
    end
    function endpoint:revision()
        local inventory = self:inventory()
        return inventory and tonumber(inventory.revision) or -1
    end
    function endpoint:containers()
        return Model.BuildNPCContainers(self:inventory())
    end
    function endpoint:rows()
        return Model.BuildNPCRows(
            self:inventory(), self.selectedContainer, self.expandedGroups
        )
    end
    function endpoint:weight()
        return Model.GetNPCContainerWeight(
            self:inventory(), self.selectedContainer
        )
    end
    function endpoint:requestSnapshot() end
    function endpoint:send(direction, selection, destination)
        local current = record()
        local player = localPlayer()
        local specs = {}
        local skipped = {}
        local skippedReasons = {}
        local item
        local spec
        local blockReason
        local ok
        local reason
        local addedIDs
        if not current or not selection then return false, "draft_unavailable" end
        if direction == "to_target" then
            for _, itemID in ipairs(selection.itemIDs or {}) do
                blockReason = nil
                item = findNativeItem(
                    player and player.getInventory and player:getInventory() or nil,
                    itemID
                )
                if not item then
                    blockReason = "player_item_missing"
                elseif Model.GetPlayerItemTransferBlockReason then
                    blockReason = Model.GetPlayerItemTransferBlockReason(
                        item, player)
                end
                if blockReason then
                    skipped[#skipped + 1] = tostring(itemID)
                    skippedReasons[blockReason] =
                        (skippedReasons[blockReason] or 0) + 1
                    blockReason = nil
                else
                    spec, reason = Inventory.CaptureNativeItem(item)
                    if spec then
                        spec.templateKey = "editor:" .. tostring(self.id) .. ":"
                            .. tostring(#specs + 1) .. ":" .. tostring(itemID)
                        specs[#specs + 1] = spec
                    else
                        skipped[#skipped + 1] = tostring(itemID)
                        skippedReasons[reason or "capture_failed"] =
                            (skippedReasons[reason or "capture_failed"] or 0) + 1
                    end
                end
            end
            if #specs < 1 then
                return false, "no_transferable_items", {
                    added = 0,
                    skipped = skipped,
                    skippedReasons = skippedReasons,
                }
            end
            ok, reason, addedIDs = Inventory.AddItems(
                current, specs, destination or self.selectedContainer,
                "editor_player_copy"
            )
        else
            ok, reason = Inventory.RemoveItems(
                current, selection.itemIDs or {}, "editor_remove"
            )
        end
        if ok and EditorModel then
            EditorModel.SyncFromRuntime(draft)
            draft._dirty = true
        end
        if direction == "to_target" then
            return ok, reason, {
                added = ok and #specs or 0,
                addedIDs = addedIDs,
                skipped = skipped,
                skippedReasons = skippedReasons,
            }
        end
        return ok, reason
    end
    function endpoint:action(actionID, itemID)
        local current = record()
        local Actions = PNC.InventoryActions
        local ok
        local reason
        if not current or not Actions or not Actions.Execute then
            return false, "actions_unavailable"
        end
        ok, reason = Actions.Execute(actionID, nil, current, itemID, {})
        if ok and EditorModel then
            EditorModel.SyncFromRuntime(draft)
            draft._dirty = true
        end
        return ok, reason
    end
    return endpoint
end

function Endpoint.NPC(npcID)
    local endpoint = {
        kind = "npc",
        role = "counterparty",
        id = npcID and tostring(npcID) or nil,
        selectedContainer = "root",
        expandedGroups = {},
    }
    function endpoint:payload()
        local state = clientState()
        return self.id and state.characterPayloads
            and state.characterPayloads[self.id] or nil
    end
    function endpoint:inventory()
        local payload = self:payload()
        return payload and payload.inventory or nil
    end
    function endpoint:revision()
        local inventory = self:inventory()
        return inventory and tonumber(inventory.revision) or -1
    end
    function endpoint:containers()
        return Model.BuildNPCContainers(self:inventory())
    end
    function endpoint:rows()
        return Model.BuildNPCRows(
            self:inventory(), self.selectedContainer, self.expandedGroups
        )
    end
    function endpoint:weight()
        return Model.GetNPCContainerWeight(
            self:inventory(), self.selectedContainer
        )
    end
    function endpoint:requestSnapshot(forceFull)
        if PNC.Client and PNC.Client.RequestCharacterPayload and self.id then
            -- Opening the detail window is an explicit cache validation
            -- boundary. A delta cannot repair a same-revision stale item
            -- state, while the full payload is cheap and infrequent here.
            return PNC.Client.RequestCharacterPayload(
                self.id, forceFull ~= false
            )
        end
        return false
    end
    function endpoint:send(direction, selection, destination, options)
        options = options or {}
        if not PNC.Client or not PNC.Client.SendInventoryTransfer then
            return false
        end
        local args = {
            id = self.id,
            direction = direction == "to_target"
                and "player_to_npc" or "npc_to_player",
            itemIDs = selection.itemIDs,
            quantity = selection.quantity,
            inventoryRevision = self:revision(),
            bulk = options.bulk == true,
            gift = options.gift == true,
            conversationToken = options.conversationToken,
        }
        if direction == "to_target" then
            args.npcContainer = destination or self.selectedContainer
        else
            args.playerContainer = destination or "root"
        end
        return PNC.Client.SendInventoryTransfer(args)
    end
    return endpoint
end

function Endpoint.Storage(storageID)
    local endpoint = {
        kind = "storage",
        role = "counterparty",
        id = storageID and tostring(storageID) or nil,
        selectedContainer = "root",
        expandedGroups = {},
    }
    function endpoint:snapshot()
        local snapshot = clientState().colonyManagement
        local storage = snapshot and snapshot.storage or nil
        if storage and (not self.id or tostring(storage.storageId) == self.id) then
            self.id = tostring(storage.storageId)
            return storage
        end
        return nil
    end
    function endpoint:revision()
        local storage = self:snapshot()
        return storage and tonumber(storage.inventoryRevision) or -1
    end
    function endpoint:containers()
        return {{
            id = "root",
            label = title(self.displayName, "Stockpile"),
            texture = ROOT_TEXTURE,
        }}
    end
    function endpoint:rows()
        return StorageModel.BuildInventoryRows(
            self:snapshot(), "", "name", self.expandedGroups
        )
    end
    function endpoint:weight()
        local storage = self:snapshot()
        return StorageModel.GetTotalWeight(storage),
            StorageModel.GetCapacity(storage)
    end
    function endpoint:requestSnapshot()
        if PNC.Client and PNC.Client.RequestColonyManagement then
            PNC.Client.RequestColonyManagement()
        end
    end
    function endpoint:send(direction, selection, destination, options)
        if self.readOnly == true then return false, "read_only" end
        if not PNC.Client or not PNC.Client.TransferPlayerStorage then
            return false
        end
        local args = {
            direction = direction == "to_target" and "player_to_storage"
                or "storage_to_player",
            storageId = self.id,
            inventoryRevision = self:revision(),
            playerContainer = destination or "root",
            bulk = options and options.bulk == true,
        }
        if direction == "to_target" then
            args.itemIDs = selection.itemIDs
        else
            args.records = selection.records or {{
                recordIndex = tonumber(selection.recordIndex),
                quantity = selection.quantity,
            }}
        end
        return PNC.Client.TransferPlayerStorage(args)
    end
    return endpoint
end

function Endpoint.SelectionForRow(endpoint, row, requestedQuantity)
    local selection, reason = Model.BuildTransferSelection(row, requestedQuantity)
    if not selection then return nil, reason end
    if endpoint and endpoint.kind == "storage" then
        selection.recordIndex = tonumber(row.recordIndex or row.id)
        selection.records = {{
            recordIndex = selection.recordIndex,
            quantity = selection.quantity,
        }}
        if not selection.recordIndex then return nil, "record_unavailable" end
    end
    return selection
end

function Endpoint.BulkSelection(endpoint, list)
    local selection = { itemIDs = {}, records = {}, quantity = 0 }
    local seen = {}
    for _, entry in ipairs(list and list.items or {}) do
        local row = entry and entry.item or nil
        if row and row.groupHeader ~= true and row.favorite ~= true
            and row.equipped ~= true and row.restricted ~= true
        then
            local quantity = Model.GetRowQuantity(row)
            if endpoint and endpoint.kind == "storage" then
                local recordIndex = tonumber(row.recordIndex or row.id)
                if recordIndex and not seen[recordIndex] then
                    seen[recordIndex] = true
                    selection.records[#selection.records + 1] = {
                        recordIndex = recordIndex,
                        quantity = quantity,
                    }
                    selection.quantity = selection.quantity + quantity
                end
            else
                local rowIDs = row.itemIDs or { row.id }
                for index = 1, #rowIDs do
                    local itemID = rowIDs[index]
                    if itemID and not seen[itemID] then
                        seen[itemID] = true
                        selection.itemIDs[#selection.itemIDs + 1] = itemID
                    end
                end
                selection.quantity = selection.quantity + quantity
            end
        end
    end
    return selection
end

return Endpoint
