require "ISUI/ISInventoryPane"

PNC = PNC or {}
PNC.InventoryDragBridge = PNC.InventoryDragBridge or {}

local Bridge = PNC.InventoryDragBridge

local function inside(control)
    if not control or not control.getAbsoluteX then return false end
    local x = control:getAbsoluteX()
    local y = control:getAbsoluteY()
    local mx = getMouseX and getMouseX() or -1
    local my = getMouseY and getMouseY() or -1
    return mx >= x and mx <= x + control:getWidth()
        and my >= y and my <= y + control:getHeight()
end

local function appendNativeItems(output, value)
    if not value then return end
    if value.getID then
        output[#output + 1] = value
        return
    end
    if type(value) == "table" and value.items ~= nil then
        if value.items.size and value.items.get then
            for index = 0, value.items:size() - 1 do
                appendNativeItems(output, value.items:get(index))
            end
        else
            for _, nested in ipairs(value.items) do appendNativeItems(output, nested) end
        end
    end
end

function Bridge.GetDraggedItems(pane)
    local raw = ISInventoryPane and ISInventoryPane.draggedItems or nil
    if type(raw) ~= "table" or #raw < 1 then
        raw = pane and pane.dragging or nil
    end
    local output = {}
    if type(raw) == "table" then
        for _, value in ipairs(raw) do appendNativeItems(output, value) end
    end
    return output
end

function Bridge.ResolveVanillaDestinationAtMouse()
    local page = getPlayerInventory and getPlayerInventory(0) or nil
    local pane = page and (page.inventoryPane or page.inventory) or nil
    if not pane or not inside(pane) then return nil end
    local container = pane.inventory
    local containingItem = container and container.getContainingItem
        and container:getContainingItem()
        or nil
    return containingItem and containingItem.getID
        and tostring(containingItem:getID())
        or "root"
end

local function handoffToCompanion(pane)
    local window = PNC.InventoryWindow and PNC.InventoryWindow.instance or nil
    local overItems = window and window.npcList and inside(window.npcList)
    local overContainers = window and window.npcContainerList
        and inside(window.npcContainerList)
    if not window or (not overItems and not overContainers) then
        return false
    end
    local items = Bridge.GetDraggedItems(pane)
    if #items < 1 or not window.acceptVanillaItems then return false end
    if not window:acceptVanillaItems(items) then return false end
    ISInventoryPane.draggedItems = {}
    if pane then pane.dragging = nil end
    return true
end

if ISInventoryPane and not ISInventoryPane._pncInventoryDragPatched then
    ISInventoryPane._pncInventoryDragPatched = true
    local originalMouseUpOutside = ISInventoryPane.onMouseUpOutside
    local originalMouseUp = ISInventoryPane.onMouseUp

    function ISInventoryPane:onMouseUpOutside(x, y)
        if handoffToCompanion(self) then return true end
        if originalMouseUpOutside then
            return originalMouseUpOutside(self, x, y)
        end
        return false
    end

    function ISInventoryPane:onMouseUp(x, y)
        if handoffToCompanion(self) then return true end
        if originalMouseUp then return originalMouseUp(self, x, y) end
        return false
    end
end

return Bridge
