require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Hub = PNC.CommandHub
local Sidebar = PsychopatzCore.UI.Sidebar

local function removeLegacyOrders()
    if Sidebar and Sidebar.Unregister then
        Sidebar.Unregister("PNC.Orders")
    end
    local legacy = PNC.OrdersUI
    local window = legacy and legacy.instance or nil
    if window and type(window.close) == "function" then
        pcall(window.close, window)
    end
    PNC.OrdersUI = nil
end

removeLegacyOrders()

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function Hub.ToggleFromSidebar()
    return Hub.Toggle()
end

if Sidebar and Sidebar.Register then
    Hub.registration = Sidebar.Register({
        id = "PNC.CommandHub",
        order = 780,
        title = tr("UI_PNC_CommandHub_Title", "COLONY"),
        tooltip = function()
            return tr("UI_PNC_CommandHub_OpenHelp",
                "Open colony command hub")
        end,
        variant = "primary",
        disabledVariant = "quiet",
        onClick = Hub.ToggleFromSidebar,
    })
end

return Hub
