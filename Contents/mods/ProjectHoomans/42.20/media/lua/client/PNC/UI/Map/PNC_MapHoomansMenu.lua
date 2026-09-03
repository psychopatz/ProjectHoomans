-- Central map menu for Hoomans controls and future map tools.

local Menu = require "PNC/UI/Map/PNC_MapHoomansMenu_Registry"

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISButton"
require "PNC/UI/Map/PNC_MapHoomansMenu_UI"

Menu.ButtonTexturePath = "media/ui/inventoryPanes/Button_Settings.png"

local function numberFrom(object, field, method, fallback)
    local value = object and tonumber(object[field]) or nil
    if value == nil and object and type(object[method]) == "function" then
        value = tonumber(object[method](object))
    end
    return value or fallback
end

function Menu.LayoutButton(map)
    local button = map and map.pncHoomansButton or nil
    local panel = map and map.buttonPanel or nil
    if not button or not panel then return false end
    local width = numberFrom(button, "width", "getWidth", 48)
    local height = math.max(24, numberFrom(panel, "height", "getHeight", 32))
    local panelX = numberFrom(panel, "x", "getX", 0)
    local panelY = numberFrom(panel, "y", "getY", 0)
    local gap = 8
    if button.setX then button:setX(panelX - width - gap)
    else button.x = panelX - width - gap end
    if button.setY then button:setY(panelY)
    else button.y = panelY end
    if button.setHeight then button:setHeight(height)
    else button.height = height end
    local buttonHelp = getText and getText("UI_PNC_MapHoomans_ButtonHelp")
    button.tooltip = buttonHelp and buttonHelp ~= ""
        and buttonHelp or "Open Hoomans map settings"
    return true
end

function Menu.EnsureButton(map)
    if not map or not map.buttonPanel or not ISButton
        or not ISButton.new
    then
        return nil
    end
    if not map.pncHoomansButton then
        local button = ISButton:new(
            0, 0, 48, 32, "", map,
            function() Menu.Open(map) end
        )
        if getTexture and button.setImage then
            button:setImage(getTexture(Menu.ButtonTexturePath))
            if button.forceImageSize then button:forceImageSize(30, 30) end
        end
        if button.initialise then button:initialise() end
        if button.instantiate then button:instantiate() end
        button.anchorBottom = true
        button.anchorRight = true
        if map.addChild then map:addChild(button) end
        map.pncHoomansButton = button
    end
    Menu.LayoutButton(map)
    return map.pncHoomansButton
end

if ISWorldMap and not ISWorldMap._pncHoomansMenuPatched then
    ISWorldMap._pncHoomansMenuPatched = true
    local originalCreateChildren = ISWorldMap.createChildren
    local originalPrerender = ISWorldMap.prerender
    local originalClose = ISWorldMap.close

    function ISWorldMap:createChildren()
        if originalCreateChildren then originalCreateChildren(self) end
        Menu.EnsureButton(self)
    end

    function ISWorldMap:prerender()
        Menu.EnsureButton(self)
        if originalPrerender then originalPrerender(self) end
    end

    function ISWorldMap:close()
        Menu.Close()
        if originalClose then return originalClose(self) end
        return false
    end
end

return Menu
