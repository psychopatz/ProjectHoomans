local Helpers = {}
local TooltipHost
local TooltipOptions

Helpers.OPACITY_TARGET_ID = "ProjectHoomans.InventoryWindow"
Helpers.INVENTORY_REFRESH_COOLDOWN_MS = 750
Helpers.INVENTORY_REFRESH_TIMEOUT_MS = 4000
Helpers.INVENTORY_REFRESH_FEEDBACK_MS = 3000

function Helpers.inventoryNow()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function Helpers.getTooltipHost()
    TooltipHost = TooltipHost or require
        "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipHost"
    return TooltipHost
end

function Helpers.getTooltipOptions()
    TooltipOptions = TooltipOptions or require
        "PNC/UI/Inventory/PNC_InventoryUI_CoreTooltipOptions"
    return TooltipOptions
end

function Helpers.tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function Helpers.absoluteBounds(control)
    local x = control.getAbsoluteX and control:getAbsoluteX() or control:getX()
    local y = control.getAbsoluteY and control:getAbsoluteY() or control:getY()
    return x, y, control:getWidth(), control:getHeight()
end

function Helpers.mouseInside(control)
    local x, y, w, h = Helpers.absoluteBounds(control)
    local mx = getMouseX and getMouseX() or -1
    local my = getMouseY and getMouseY() or -1
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

return Helpers
