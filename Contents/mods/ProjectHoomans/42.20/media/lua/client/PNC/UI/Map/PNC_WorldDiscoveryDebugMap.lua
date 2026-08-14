-- Stable debug controls for strategic discovery. These live behind a map
-- button instead of intercepting the vanilla right-click/teleport menu.

require "ISUI/Maps/ISWorldMap"
require "ISUI/ISPanel"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.WorldDiscoveryDebugMap = PNC.WorldDiscoveryDebugMap or {}

local DebugMap = PNC.WorldDiscoveryDebugMap
DebugMap.ShowRawEntities = DebugMap.ShowRawEntities == true

local function text(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

local function canDebug()
    return PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

local function request(action, args)
    if not PNC.Client or not PNC.Client.RequestWorldDiscovery then
        return false
    end
    return PNC.Client.RequestWorldDiscovery(action, args)
end

function DebugMap.SendDiscoveryAll(scope)
    return request("debug_discover_all", {
        scope = tostring(scope or "all"),
    })
end

function DebugMap.ResetDiscovery()
    return request("debug_reset")
end

function DebugMap.ToggleRawEntities()
    DebugMap.ShowRawEntities = not DebugMap.ShowRawEntities
    if DebugMap.ShowRawEntities and PNC.Client then
        if PNC.Client.RequestCommunityDebug then
            PNC.Client.RequestCommunityDebug()
        end
        if PNC.Client.RequestDirectorDebug then
            PNC.Client.RequestDirectorDebug()
        end
    end
    if PNC.MapTravelLayer and PNC.MapTravelLayer.InvalidateEntryCache then
        PNC.MapTravelLayer.InvalidateEntryCache()
    end
    if DebugMap.instance and DebugMap.instance.syncButtons then
        DebugMap.instance:syncButtons()
    end
    return DebugMap.ShowRawEntities
end

ISPNCWorldDiscoveryDebugModal = ISPanel:derive(
    "ISPNCWorldDiscoveryDebugModal"
)

function ISPNCWorldDiscoveryDebugModal:initialise()
    ISPanel.initialise(self)
end

local function addButton(panel, id, title, y)
    local button = ISButton:new(
        24, y, panel.width - 48, 30, title,
        panel, ISPNCWorldDiscoveryDebugModal.onButton
    )
    button.internal = id
    button:initialise()
    button:instantiate()
    panel:addChild(button)
    return button
end

function ISPNCWorldDiscoveryDebugModal:createChildren()
    ISPanel.createChildren(self)
    self.settlementsButton = addButton(
        self, "SETTLEMENTS",
        text("UI_PNC_DebugDiscoveryAllSettlements",
            "Discover all settlements"), 70
    )
    self.groupsButton = addButton(
        self, "GROUPS",
        text("UI_PNC_DebugDiscoveryAllGroups",
            "Discover all mobile groups"), 108
    )
    self.allButton = addButton(
        self, "ALL",
        text("UI_PNC_DebugDiscoveryAllSignals",
            "Discover all signals"), 146
    )
    self.rawButton = addButton(self, "RAW", "", 184)
    self.resetButton = addButton(
        self, "RESET",
        text("UI_PNC_DebugDiscoveryReset",
            "Reset this character's discoveries"), 222
    )
    self.closeButton = addButton(
        self, "CLOSE", text("UI_Close", "Close"), 270
    )
    self:syncButtons()
end

function ISPNCWorldDiscoveryDebugModal:syncButtons()
    if not self.rawButton then return end
    local title = text(
        DebugMap.ShowRawEntities
            and "UI_PNC_DebugDiscoveryHideRaw"
            or "UI_PNC_DebugDiscoveryShowRaw",
        DebugMap.ShowRawEntities
            and "Hide undiscovered entity overlays"
            or "Show undiscovered entity overlays"
    )
    if self.rawButton.setTitle then
        self.rawButton:setTitle(title)
    else
        self.rawButton.title = title
    end
end

function ISPNCWorldDiscoveryDebugModal:onButton(button)
    local id = button and button.internal or ""
    if id == "SETTLEMENTS" then
        return DebugMap.SendDiscoveryAll("settlements")
    end
    if id == "GROUPS" then
        return DebugMap.SendDiscoveryAll("mobile_groups")
    end
    if id == "ALL" then
        return DebugMap.SendDiscoveryAll("all")
    end
    if id == "RAW" then
        return DebugMap.ToggleRawEntities()
    end
    if id == "RESET" then
        return DebugMap.ResetDiscovery()
    end
    if id == "CLOSE" then self:close() end
end

function ISPNCWorldDiscoveryDebugModal:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.96, 0.28, 0.65, 0.92)
    self:drawTextCentre(
        text("UI_PNC_DebugDiscoveryTitle", "NPC World Debug"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium
    )
    self:drawTextCentre(
        text("UI_PNC_DebugDiscoveryHint",
            "Discovery tools no longer replace the map context menu."),
        self.width / 2, 43, 0.72, 0.76, 0.82, 1, UIFont.Small
    )
end

function ISPNCWorldDiscoveryDebugModal:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if DebugMap.instance == self then DebugMap.instance = nil end
end

function ISPNCWorldDiscoveryDebugModal:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.moveWithMouse = true
    return object
end

function DebugMap.Open()
    if not canDebug() then return nil end
    if DebugMap.instance then
        DebugMap.instance:bringToTop()
        return DebugMap.instance
    end
    local width, height = 430, 326
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = ISPNCWorldDiscoveryDebugModal:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2),
        width, height
    )
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
    if modal.setCapture then modal:setCapture(true) end
    modal:bringToTop()
    DebugMap.instance = modal
    return modal
end

local function numberFrom(object, field, method, fallback)
    local value = object and tonumber(object[field]) or nil
    if value == nil and object and type(object[method]) == "function" then
        value = tonumber(object[method](object))
    end
    return value or fallback
end

function DebugMap.LayoutButton(map)
    local button = map and map.pncDebugButton or nil
    local panel = map and map.buttonPanel or nil
    if not button or not panel then return false end
    local gap = 8
    local width = numberFrom(button, "width", "getWidth", 88)
    local height = math.max(24,
        numberFrom(panel, "height", "getHeight", 32))
    local anchor = map.pncBasesButton
    local x = anchor
        and numberFrom(anchor, "x", "getX", 0) - width - gap
        or numberFrom(panel, "x", "getX", 0) - width - gap
    local y = numberFrom(panel, "y", "getY", 0)
    if button.setX then button:setX(x) else button.x = x end
    if button.setY then button:setY(y) else button.y = y end
    if button.setHeight then button:setHeight(height)
    else button.height = height end
    if button.setVisible then button:setVisible(canDebug())
    else button.visible = canDebug() end
    return true
end

function DebugMap.EnsureButton(map)
    if not map or not map.buttonPanel or not canDebug() then return nil end
    if not map.pncDebugButton then
        local button = ISButton:new(
            0, 0, 88, 32,
            text("UI_PNC_DebugDiscoveryButton", "DEBUG"),
            map, function() DebugMap.Open() end
        )
        button:initialise()
        button:instantiate()
        button.anchorBottom = true
        button.anchorRight = true
        map:addChild(button)
        map.pncDebugButton = button
    end
    DebugMap.LayoutButton(map)
    return map.pncDebugButton
end

if ISWorldMap and not ISWorldMap._pncWorldDiscoveryDebugPatched then
    ISWorldMap._pncWorldDiscoveryDebugPatched = true
    local originalCreateChildren = ISWorldMap.createChildren
    local originalPrerender = ISWorldMap.prerender

    function ISWorldMap:createChildren()
        originalCreateChildren(self)
        DebugMap.EnsureButton(self)
    end

    function ISWorldMap:prerender()
        DebugMap.EnsureButton(self)
        if originalPrerender then originalPrerender(self) end
    end
end

return DebugMap
