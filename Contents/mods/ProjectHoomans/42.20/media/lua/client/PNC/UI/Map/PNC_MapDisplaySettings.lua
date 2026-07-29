-- Per-client world-map presentation controls.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.MapDisplay = PNC.MapDisplay or {}

local Display = PNC.MapDisplay

Display.NamesVisible = Display.NamesVisible == true

local function numberFrom(object, field, method, fallback)
    local value = object and tonumber(object[field]) or nil
    if value == nil and object and type(object[method]) == "function" then
        value = tonumber(object[method](object))
    end
    return value or fallback
end

local function syncButton(button)
    if not button then return end
    local title = Display.NamesVisible
        and "NPC NAMES: ON" or "NPC NAMES: OFF"
    if button.setTitle then button:setTitle(title) else button.title = title end
    button.tooltip = Display.NamesVisible
        and "Hide ordinary NPC names (selected and hovered names remain visible)"
        or "Show NPC names on the world map"
end

function Display.AreNamesVisible()
    return Display.NamesVisible == true
end

function Display.SetNamesVisible(visible)
    Display.NamesVisible = visible == true
    syncButton(Display.LastButton)
    return Display.NamesVisible
end

function Display.ToggleNames()
    return Display.SetNamesVisible(not Display.NamesVisible)
end

function Display.LayoutButton(map)
    local button = map and map.pncNamesButton or nil
    local panel = map and map.buttonPanel or nil
    if not button or not panel then return false end
    local gap = 8
    local panelX = numberFrom(panel, "x", "getX", 0)
    local panelY = numberFrom(panel, "y", "getY", 0)
    local panelHeight = numberFrom(panel, "height", "getHeight", 32)
    local width = numberFrom(button, "width", "getWidth", 116)
    local height = math.max(24, panelHeight)
    if button.setX then button:setX(panelX - width - gap)
    else button.x = panelX - width - gap end
    if button.setY then button:setY(panelY)
    else button.y = panelY end
    if button.setHeight then button:setHeight(height)
    else button.height = height end
    syncButton(button)
    return true
end

function Display.EnsureButton(map)
    if not map or map.pncNamesButton then
        if map then Display.LayoutButton(map) end
        return map and map.pncNamesButton or nil
    end
    if not map.buttonPanel or not ISButton or not ISButton.new then
        return nil
    end
    local button = ISButton:new(
        0,
        0,
        116,
        32,
        "",
        map,
        function()
            Display.ToggleNames()
        end
    )
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    button.anchorBottom = true
    button.anchorRight = true
    if map.addChild then map:addChild(button) end
    map.pncNamesButton = button
    Display.LastButton = button
    Display.LayoutButton(map)
    return button
end

if ISWorldMap and not ISWorldMap._pncMapDisplayPatched then
    ISWorldMap._pncMapDisplayPatched = true
    local originalCreateChildren = ISWorldMap.createChildren
    local originalPrerender = ISWorldMap.prerender

    function ISWorldMap:createChildren()
        originalCreateChildren(self)
        Display.EnsureButton(self)
    end

    function ISWorldMap:prerender()
        Display.EnsureButton(self)
        if originalPrerender then originalPrerender(self) end
    end
end

return Display
