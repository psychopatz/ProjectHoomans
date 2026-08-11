local Internal = PNC.ColonyStorageService.Internal
local CoreInventory = Internal.CoreInventory
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

local function nativeID(item)
    return item and item.getID and tostring(item:getID()) or nil
end

function Internal.SelectedPlayerItems(player, ids)
    local wanted = {}
    for index = 1, #(ids or {}) do wanted[tostring(ids[index])] = true end
    local found = {}
    local function visit(container)
        local items = container and container.getItems and container:getItems() or nil
        if not items or not items.size or not items.get then return end
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if wanted[nativeID(item)] then found[#found + 1] = item end
            local nested = item and item.getItemContainer
                and item:getItemContainer() or nil
            if nested then visit(nested) end
        end
    end
    visit(player and player.getInventory and player:getInventory() or nil)
    if #found ~= #(ids or {}) then return nil, "item_not_found" end
    return found
end

function Internal.ResolvePlayerContainer(player, containerItemID)
    local root = player and player.getInventory and player:getInventory() or nil
    containerItemID = tostring(containerItemID or "root")
    if containerItemID == "" or containerItemID == "root" then return root end
    local function visit(container, depth)
        if not container or depth > 4 then return nil end
        local items = container.getItems and container:getItems() or nil
        if not items or not items.size or not items.get then return nil end
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if item and item.getID
                and tostring(item:getID()) == containerItemID
            then
                return item.getItemContainer and item:getItemContainer()
                    or item.getInventory and item:getInventory() or nil
            end
            local nested = item and item.getItemContainer
                and item:getItemContainer() or nil
            local found = nested and visit(nested, depth + 1) or nil
            if found then return found end
        end
        return nil
    end
    return visit(root, 1)
end

function Internal.PlayerDestination(player, containerItemID)
    local container = Internal.ResolvePlayerContainer(player, containerItemID)
    if not container then return nil, "player_container_not_found" end
    return CoreInventory.wrapPhysicalInventory(container)
end

function Internal.StorageSelectionSource(storage, selections, owner)
    local source = { revision = storage.inventory.revision, tokens = {} }
    local total = 0
    for index = 1, #(selections or {}) do
        local selection = selections[index]
        local record = storage.inventory.records[
            math.floor(tonumber(selection.recordIndex) or 0)
        ]
        local quantity = math.max(1,
            math.floor(tonumber(selection.quantity) or 1))
        if not record then
            for tokenIndex = 1, #source.tokens do
                storage.inventory:releaseReservation(source.tokens[tokenIndex])
            end
            return nil, "record_not_found"
        end
        local selectedRecord = record
        local token, reason = storage.inventory:reserve({
            typeId = selectedRecord[Internal.Constants.TYPE_ID],
            predicate = function(candidate) return candidate == selectedRecord end,
        }, quantity, owner)
        if not token then
            for tokenIndex = 1, #source.tokens do
                storage.inventory:releaseReservation(source.tokens[tokenIndex])
            end
            return nil, reason or "reservation_failed"
        end
        source.tokens[#source.tokens + 1] = token
        total = total + quantity
    end
    source.quantity = total
    function source:remove(_, quantity)
        if quantity ~= self.quantity then return false, "quantity_mismatch" end
        local removed = {}
        for index = 1, #self.tokens do
            local ok, records = storage.inventory:commitReservation(
                self.tokens[index]
            )
            if not ok then
                for pending = index + 1, #self.tokens do
                    storage.inventory:releaseReservation(self.tokens[pending])
                end
                self:restoreRemoved(removed)
                return false, records
            end
            for recordIndex = 1, #records do
                removed[#removed + 1] = records[recordIndex]
            end
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        for index = 1, #(removed or {}) do
            local ok = storage.inventory:add(removed[index])
            if not ok then return false end
        end
        return true
    end
    function source:release()
        for index = 1, #self.tokens do
            storage.inventory:releaseReservation(self.tokens[index])
        end
    end
    return source
end

function Internal.PhysicalSelectionSource(items)
    local source = { revision = 0, items = items }
    function source:preview()
        local records = {}
        for index = 1, #self.items do
            local encoded, reason = CoreInventory.encodeItem(self.items[index], 1)
            if not encoded then return nil, reason end
            records[#records + 1] = encoded
        end
        return records
    end
    function source:remove(_, quantity)
        quantity = math.max(1, math.floor(tonumber(quantity) or #self.items))
        if quantity ~= #self.items then return false, "quantity_mismatch" end
        local records, reason = self:preview()
        if not records then return false, reason end
        local removed = { physicalItems = {}, physicalAdapters = {} }
        for index = 1, #self.items do
            local item = self.items[index]
            local container = item and item.getContainer and item:getContainer() or nil
            local adapter
            adapter, reason = CoreInventory.wrapPhysicalInventory(container)
            if not adapter then self:restoreRemoved(removed); return false, reason end
            if not adapter:_nativeRemove(item) then
                self:restoreRemoved(removed)
                return false, "physical_remove_failed"
            end
            removed[#removed + 1] = records[index]
            removed.physicalItems[#removed.physicalItems + 1] = item
            removed.physicalAdapters[#removed.physicalAdapters + 1] = adapter
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        for index = #(removed and removed.physicalItems or {}), 1, -1 do
            if not removed.physicalAdapters[index]:_nativeAdd(
                removed.physicalItems[index]
            ) then return false end
        end
        return true
    end
    return source
end

local function compactPreview(item, quantity)
    return CoreInventory.encodeItem(StateCodec.pseudoItem(item), quantity)
end

local function mutateCompactRemoval(record, item, quantity, reason)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    if quantity >= stack then
        return PNC.Inventory.RemoveItems(record, { item.id }, reason)
    end
    return PNC.Inventory.ApplyDelta(record, {{
        op = "update", itemID = item.id, stack = stack - quantity,
    }}, reason)
end

function Internal.AbstractNPCSource(record, item, quantity)
    local source = { revision = record.inventory.revision }
    function source:preview()
        local encoded, reason = compactPreview(item, quantity)
        return encoded and { encoded } or nil, reason
    end
    function source:remove()
        local records, reason = self:preview()
        if not records then return false, reason end
        self.undo = PNC.Core.DeepCopy(record.inventory)
        local ok
        ok, reason = mutateCompactRemoval(
            record, item, quantity, "npc_to_colony_storage"
        )
        if not ok then self.undo = nil; return false, reason end
        return true, records
    end
    function source:restoreRemoved()
        if not self.undo then return false end
        record.inventory = self.undo
        PNC.Inventory.RebuildCaches(record)
        return true
    end
    return source
end

function Internal.LiveNPCSource(record, item, quantity, body)
    local container = body and body.getInventory and body:getInventory() or nil
    local physical = container and CoreInventory.wrapPhysicalInventory(container) or nil
    if not physical then return nil, "physical_inventory_unavailable" end
    local expected, reason = compactPreview(item, 1)
    if not expected then return nil, reason end
    local key = ItemRecord.stackKey(expected)
    local typeQuery = { fullType = tostring(item.type or "") }
    local source = { revision = record.inventory.revision }

    local function chooseCandidates()
        local exact = {}
        local compatible = {}
        for _, nativeItem in ipairs(physical:query(typeQuery)) do
            local encoded = CoreInventory.encodeItem(nativeItem, 1)
            if key and encoded and ItemRecord.stackKey(encoded) == key then
                exact[#exact + 1] = nativeItem
            else
                compatible[#compatible + 1] = nativeItem
            end
        end
        for _, nativeItem in ipairs(compatible) do
            exact[#exact + 1] = nativeItem
        end
        return exact
    end

    function source:preview()
        local records = {}
        for index = 1, quantity do
            records[index] = ItemRecord.clone(expected, 1)
        end
        return records
    end
    function source:remove()
        local candidates = chooseCandidates()
        local physicalQuantity = math.min(#candidates, quantity)
        local selected = {}
        for index = 1, physicalQuantity do
            selected[candidates[index]] = true
        end
        local query = { predicate = function(nativeItem)
            return selected[nativeItem] == true
        end }
        self.undo = PNC.Core.DeepCopy(record.inventory)
        local removed = { physicalItems = {} }
        if physicalQuantity > 0 then
            local ok
            ok, removed = physical:remove(query, physicalQuantity)
            if not ok then self.undo = nil; return false, removed end
        end
        local shortfall = quantity - physicalQuantity
        for index = 1, shortfall do
            removed[#removed + 1] = ItemRecord.clone(expected, 1)
        end
        if shortfall > 0 then self.mirrorShortfall = shortfall end
        local mutated, why = mutateCompactRemoval(
            record, item, quantity, "live_npc_to_colony_storage"
        )
        if not mutated then
            if physicalQuantity > 0 then physical:restoreRemoved(removed) end
            self.undo = nil
            return false, why
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        local physicalOK = physical:restoreRemoved(removed)
        if self.undo then
            record.inventory = self.undo
            PNC.Inventory.RebuildCaches(record)
        end
        return physicalOK
    end
    return source
end

return Internal
