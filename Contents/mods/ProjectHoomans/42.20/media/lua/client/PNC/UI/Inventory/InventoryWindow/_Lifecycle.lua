local InventoryWindow = PNC.InventoryWindow
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local QuantityModal = PNC.InventoryQuantityModal
local TransferEndpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr
local getTooltipHost = Helpers.getTooltipHost
local OPACITY_TARGET_ID = Helpers.OPACITY_TARGET_ID

function ISPNCInventoryWindow:close()
    if QuantityModal and QuantityModal.instance then
        QuantityModal.instance:close()
    end
    getTooltipHost().Hide(self)
    Options.UnregisterTarget(OPACITY_TARGET_ID)
    InventoryWindow.instance = nil
    UI.Window.close(self)
end

function ISPNCInventoryWindow:new(x, y, width, height, options)
    local o = UI.Window.new(self, x, y, width, height, options or {})
    o.resizable = true
    return o
end

local function getOrCreateWindow()
    local window = InventoryWindow.instance
    if not window then
        local spec = {
            width = 760, height = 520,
            minWidth = 600, minHeight = 360,
            maxWidth = 1100, maxHeight = 820,
            anchor = "center",
        }
        local bounds = Layout.ResolveWindow(spec)
        window = ISPNCInventoryWindow:new(bounds.x, bounds.y, bounds.width, bounds.height, {
            title = tr("UI_PNC_Inventory_Title", "Inventory"),
            responsiveSpec = spec,
            persistenceKey = "ProjectHoomans:InventoryWindow",
            resizable = true,
        })
        window:initialise()
        window:instantiate()
        window:addToUIManager()
        InventoryWindow.instance = window
    end
    Options.RegisterTarget(OPACITY_TARGET_ID, window)
    window:setVisible(true)
    return window
end

function InventoryWindow.Open(npcId, options)
    local window = getOrCreateWindow()
    window:setNPC(npcId)
    options = type(options) == "table" and options or {}
    window:setConversationMode(options.mode, options.token, options)
    window:bringToTop()
    return window
end

function InventoryWindow.OpenLocalDraft(draft, options)
    options = type(options) == "table" and options or {}
    local window = getOrCreateWindow()
    local endpoint = TransferEndpoint.LocalDraft(draft)
    endpoint.displayName = draft and draft.displayName or "Unique NPC Draft"
    window:setTransferEndpoint(endpoint)
    window:setConversationMode(nil, nil)
    window.statusText = tr("UI_PNC_UniqueNPCEditor_InventoryHint",
        "Editor copy: player inventory is unchanged")
    window:bringToTop()
    return window
end

function InventoryWindow.OpenStorage(storageID, options)
    options = type(options) == "table" and options or {}
    local window = getOrCreateWindow()
    local endpoint = TransferEndpoint.Storage(storageID)
    endpoint.displayName = options.displayName or "Colony Storage"
    endpoint.readOnly = options.readOnly == true
    window:setTransferEndpoint(endpoint)
    window:setConversationMode(nil, nil)
    window:bringToTop()
    return window
end

function InventoryWindow.OnResult(result)
    local window = InventoryWindow.instance
    local composer = PNC.Conversation
        and PNC.Conversation.Composer or nil
    if result and (result.gift == true or result.giftEffect ~= nil)
        and composer and type(composer.ReceiveGiftResult) == "function"
        and (not window or not window.giftMode
            or not window.transferEndpoint
            or window.transferEndpoint.kind ~= "npc"
            or tostring(result.npcId or "") ~= tostring(window.npcId or ""))
    then
        return composer.ReceiveGiftResult(result)
    end
    if window and window.transferEndpoint
        and window.transferEndpoint.kind ~= "npc"
    then return end
    if not window or not result or tostring(result.npcId or "") ~= tostring(window.npcId or "") then
        return
    end
    local reason = tostring(result.reason or "")
    local readable = reason:gsub("_", " ")
    window.statusText = result.success == true
        and tr("UI_PNC_Inventory_Complete", "Transfer complete")
        or (tr("UI_PNC_Inventory_Failed", "Inventory action failed") .. ": " .. readable)
    window.contextSignature = nil
    window.playerRowsDirty = true
    if window.giftMode and composer
        and composer.ReceiveGiftResult
    then
        composer.ReceiveGiftResult(result)
    end
end

function InventoryWindow.OnColonyStorageResult(result)
    local window = InventoryWindow.instance
    if not window or type(result) ~= "table" then return end
    if window.transferEndpoint and window.transferEndpoint.kind == "storage"
        and result.storageId
        and tostring(result.storageId) ~= tostring(window.transferEndpoint.id)
    then return end
    local reason = tostring(result.reason or "failed"):gsub("_", " ")
    local details = result.details or {}
    if result.ok == true and result.reason == "courier_returning_home" then
        window.statusText = tr("UI_PNC_Storage_CourierReturning",
            "Courier is returning home to deposit all items")
    elseif result.ok == true then
        window.statusText = tr(
            "UI_PNC_Storage_TransferComplete", "Storage transfer complete"
        )
    elseif result.reason == "storage_full" then
        window.statusText = string.format(
            "%s  %s: %.1f  %s: %.1f",
            tr("UI_PNC_Storage_Full", "Storage full"),
            tr("UI_PNC_Storage_Requires", "Requires"),
            tonumber(details.requiredWeight) or 0,
            tr("UI_PNC_Storage_Available", "Available"),
            tonumber(details.availableWeight) or 0
        )
    else
        window.statusText = tr(
            "UI_PNC_Storage_TransferFailed", "Storage transfer failed"
        ) .. ": " .. reason
    end
    window.contextSignature = nil
    window.playerRowsDirty = true
end

function InventoryWindow.Close()
    local window = InventoryWindow.instance
    if window then window:close() end
end

return InventoryWindow
