-- Shared map toolbar for labeled Hoomans controls.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.MapToolbar = PNC.MapToolbar or {}

local Toolbar = PNC.MapToolbar
Toolbar.EntriesByID = Toolbar.EntriesByID or {}

local function resolve(entry, field, fallback)
    local value = entry and entry[field]
    if type(value) == "function" then value = value(entry) end
    if value == nil then return fallback end
    return value
end

function Toolbar.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.onActivate) ~= "function"
    then
        return false
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    definition.field = definition.field or ("pnc" .. id .. "Button")
    Toolbar.EntriesByID[id] = definition
    return true
end

function Toolbar.List()
    local entries = {}
    for _, entry in pairs(Toolbar.EntriesByID) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(left, right)
        if left.order ~= right.order then return left.order < right.order end
        return tostring(left.id) < tostring(right.id)
    end)
    return entries
end

local function numberFrom(object, field, method, fallback)
    local value = object and tonumber(object[field]) or nil
    if value == nil and object and type(object[method]) == "function" then
        value = tonumber(object[method](object))
    end
    return value or fallback
end

local function setButtonPosition(button, x, y, height)
    if button.setX then button:setX(x) else button.x = x end
    if button.setY then button:setY(y) else button.y = y end
    if button.setHeight then button:setHeight(height)
    else button.height = height end
end

local function setButtonVisible(button, visible)
    if button.setVisible then button:setVisible(visible)
    else button.visible = visible end
end

local function activate(target, entry)
    if resolve(entry, "visible", true) == false
        or resolve(entry, "enabled", true) == false
    then
        return false
    end
    return entry.onActivate(target) ~= false
end

local function addButton(map, entry)
    local width = tonumber(resolve(entry, "width", 100)) or 100
    local button = ISButton:new(
        0, 0, width, 32,
        tostring(resolve(entry, "title", entry.id)), map,
        function() return activate(map, entry) end
    )
    button.internal = entry.id
    button.toolbarEntry = entry
    local iconPath = resolve(entry, "icon", nil)
    if iconPath and getTexture then
        local icon = type(iconPath) == "string"
            and getTexture(iconPath) or iconPath
        if icon then
            button.iconTexture = icon
            button.joypadTextureWH = tonumber(
                resolve(entry, "iconSize", 22)
            ) or 22
        end
    end
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    if map.addChild then map:addChild(button) end
    map[entry.field] = button
    return button
end

function Toolbar.LayoutButtons(map)
    local panel = map and map.buttonPanel or nil
    if not panel then return false end
    local entries = Toolbar.List()
    local panelX = numberFrom(panel, "x", "getX", 0)
    local panelY = numberFrom(panel, "y", "getY", 0)
    local height = math.max(24, numberFrom(panel, "height", "getHeight", 32))
    local right = panelX
    local gap = 8

    for index = #entries, 1, -1 do
        local entry = entries[index]
        local button = map[entry.field]
        local visible = resolve(entry, "visible", true) ~= false
        if button then setButtonVisible(button, visible) end
        if button and visible then
            local width = numberFrom(button, "width", "getWidth", 100)
            right = right - width
            setButtonPosition(button, right, panelY, height)
            local title = tostring(resolve(entry, "title", entry.id))
            if button.setTitle then button:setTitle(title)
            else button.title = title end
            local enabled = resolve(entry, "enabled", true) ~= false
            if button.setEnable then button:setEnable(enabled)
            else button.enable = enabled end
            button.tooltip = resolve(entry, "tooltip", nil)
            right = right - gap
        end
    end
    return true
end

function Toolbar.EnsureButtons(map)
    if not map or not map.buttonPanel or not ISButton
        or not ISButton.new
    then
        return nil
    end
    for _, entry in ipairs(Toolbar.List()) do
        if not map[entry.field] then addButton(map, entry) end
    end
    Toolbar.LayoutButtons(map)
    return true
end

function Toolbar.Close()
    for _, entry in ipairs(Toolbar.List()) do
        if type(entry.onMapClose) == "function" then entry.onMapClose() end
    end
end

if ISWorldMap and not ISWorldMap._pncMapToolbarPatched then
    ISWorldMap._pncMapToolbarPatched = true
    local originalCreateChildren = ISWorldMap.createChildren
    local originalPrerender = ISWorldMap.prerender
    local originalClose = ISWorldMap.close

    function ISWorldMap:createChildren()
        if originalCreateChildren then originalCreateChildren(self) end
        Toolbar.EnsureButtons(self)
    end

    function ISWorldMap:prerender()
        if originalPrerender then originalPrerender(self) end
        Toolbar.EnsureButtons(self)
    end

    function ISWorldMap:close()
        Toolbar.Close()
        if originalClose then return originalClose(self) end
        return false
    end
end

return Toolbar
