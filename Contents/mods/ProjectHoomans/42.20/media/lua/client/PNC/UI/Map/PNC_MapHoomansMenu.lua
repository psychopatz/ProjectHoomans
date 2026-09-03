-- Central map menu for Hoomans controls and future map tools.

local Menu = require "PNC/UI/Map/PNC_MapHoomansMenu_Registry"

require "PNC/UI/Map/PNC_MapHoomansMenu_UI"
local Toolbar = require "PNC/UI/Map/PNC_MapToolbar"

Toolbar.Register("hoomans", {
    order = 20,
    field = "pncHoomansButton",
    width = 112,
    title = function()
        local value = getText and getText("UI_PNC_MapHoomans_Button")
        return value and value ~= ""
            and value ~= "UI_PNC_MapHoomans_Button" and value or "Hoomans"
    end,
    tooltip = function()
        local value = getText and getText("UI_PNC_MapHoomans_ButtonHelp")
        return value and value ~= ""
            and value ~= "UI_PNC_MapHoomans_ButtonHelp"
            and value or "Open Hoomans map settings"
    end,
    icon = "media/ui/inventoryPanes/Button_Settings.png",
    iconSize = 22,
    onActivate = function(map) return Menu.Open(map) ~= nil end,
    onMapClose = Menu.Close,
})

return Menu
