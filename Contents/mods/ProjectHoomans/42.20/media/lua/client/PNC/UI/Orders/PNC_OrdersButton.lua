require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.OrdersButton = PNC.OrdersButton or {}

local ButtonAPI = PNC.OrdersButton
local Sidebar = PsychopatzCore.UI.Sidebar

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function ButtonAPI.onClick()
    if PNC.OrdersUI and PNC.OrdersUI.Toggle then
        PNC.OrdersUI.Toggle()
    end
end

if Sidebar and Sidebar.Register then
    ButtonAPI.registration = Sidebar.Register({
        id = "PNC.Orders",
        order = 850,
        title = tr("UI_PNC_Orders_WindowTitle", "ORDERS"),
        tooltip = function()
            return tr("UI_PNC_Orders_OpenHelp", "Open colony orders")
        end,
        variant = "primary",
        disabledVariant = "quiet",
        onClick = ButtonAPI.onClick,
    })
end

return ButtonAPI
