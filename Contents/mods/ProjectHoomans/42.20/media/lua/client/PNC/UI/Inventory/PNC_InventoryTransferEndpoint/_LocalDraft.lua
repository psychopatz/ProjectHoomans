local Endpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"
local Model = Helpers.Model
local Inventory = Helpers.Inventory
local findNativeItem = Helpers.findNativeItem
local localPlayer = Helpers.localPlayer
local EditorModel

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

return Endpoint
