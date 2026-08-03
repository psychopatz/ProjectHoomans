-- Per-client world-map presentation controls.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.MapDisplay = PNC.MapDisplay or {}

local Display = PNC.MapDisplay

Display.NamesVisible = Display.NamesVisible == true
if Display.BasesVisible == nil then Display.BasesVisible = true end

local function numberFrom(object, field, method, fallback)
    local value = object and tonumber(object[field]) or nil
    if value == nil and object and type(object[method]) == "function" then
        value = tonumber(object[method](object))
    end
    return value or fallback
end

local function syncNamesButton(button)
    if not button then return end
    local title = Display.NamesVisible
        and "NPC NAMES: ON" or "NPC NAMES: OFF"
    if button.setTitle then button:setTitle(title) else button.title = title end
    button.tooltip = Display.NamesVisible
        and "Hide ordinary NPC names (selected and hovered names remain visible)"
        or "Show NPC names on the world map"
end

local function syncBasesButton(button)
    if not button then return end
    local title = Display.BasesVisible
        and "NPC WORLD: ON" or "NPC WORLD: OFF"
    if button.setTitle then button:setTitle(title) else button.title = title end
    button.tooltip = Display.BasesVisible
        and "Hide generated settlements and abstract survivor groups"
        or "Show generated settlements and abstract survivor groups"
end

function Display.AreNamesVisible()
    return Display.NamesVisible == true
end

function Display.SetNamesVisible(visible)
    Display.NamesVisible = visible == true
    syncNamesButton(Display.LastNamesButton)
    return Display.NamesVisible
end

function Display.AreBasesVisible()
    return Display.BasesVisible == true
end

function Display.SetBasesVisible(visible)
    Display.BasesVisible = visible == true
    syncBasesButton(Display.LastBasesButton)
    if Display.BasesVisible
        and PNC.CommunityDebugOverlay
        and PNC.CommunityDebugOverlay.Update
    then
        PNC.CommunityDebugOverlay.Update(true)
    end
    if Display.BasesVisible
        and PNC.AbstractGroupMapLayer
        and PNC.AbstractGroupMapLayer.Update
    then
        PNC.AbstractGroupMapLayer.Update(true)
    end
    return Display.BasesVisible
end

function Display.ToggleBases()
    return Display.SetBasesVisible(
        not Display.BasesVisible
    )
end

function Display.ToggleNames()
    return Display.SetNamesVisible(not Display.NamesVisible)
end

function Display.LayoutButton(map)
    local button = map and map.pncNamesButton or nil
    local basesButton = map and map.pncBasesButton or nil
    local panel = map and map.buttonPanel or nil
    if not button or not basesButton or not panel then
        return false
    end
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
    local basesWidth = numberFrom(
        basesButton,
        "width",
        "getWidth",
        116
    )
    local namesX = panelX - width - gap
    if basesButton.setX then
        basesButton:setX(namesX - basesWidth - gap)
    else
        basesButton.x = namesX - basesWidth - gap
    end
    if basesButton.setY then basesButton:setY(panelY)
    else basesButton.y = panelY end
    if basesButton.setHeight then
        basesButton:setHeight(height)
    else
        basesButton.height = height
    end
    syncNamesButton(button)
    syncBasesButton(basesButton)
    return true
end

function Display.EnsureButton(map)
    if not map then return nil end
    if not map.buttonPanel or not ISButton or not ISButton.new then
        return nil
    end
    if not map.pncNamesButton then
        local button = ISButton:new(
            0, 0, 116, 32, "", map,
            function() Display.ToggleNames() end
        )
        if button.initialise then button:initialise() end
        if button.instantiate then button:instantiate() end
        button.anchorBottom = true
        button.anchorRight = true
        if map.addChild then map:addChild(button) end
        map.pncNamesButton = button
    end
    if not map.pncBasesButton then
        local button = ISButton:new(
            0, 0, 116, 32, "", map,
            function() Display.ToggleBases() end
        )
        if button.initialise then button:initialise() end
        if button.instantiate then button:instantiate() end
        button.anchorBottom = true
        button.anchorRight = true
        if map.addChild then map:addChild(button) end
        map.pncBasesButton = button
    end
    Display.LastNamesButton = map.pncNamesButton
    Display.LastBasesButton = map.pncBasesButton
    Display.LayoutButton(map)
    return map.pncNamesButton
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
