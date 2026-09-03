-- Map toolbar button and modal for home-base tracking.

require "ISUI/ISPanel"
require "ISUI/ISButton"

PNC = PNC or {}
local Tracking = PNC.MapTracking
    or require "PNC/UI/Map/PNC_MapTracking"
local Toolbar = PNC.MapToolbar
    or require "PNC/UI/Map/PNC_MapToolbar"

local function text(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

ISPNCMapTrackingModal = ISPanel:derive("ISPNCMapTrackingModal")

function ISPNCMapTrackingModal:initialise()
    ISPanel.initialise(self)
end

local function addButton(panel, id, title, y)
    local button = ISButton:new(
        24, y, panel.width - 48, 30, title,
        panel, ISPNCMapTrackingModal.onButton
    )
    button.internal = id
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    panel:addChild(button)
    return button
end

function ISPNCMapTrackingModal:createChildren()
    ISPanel.createChildren(self)
    self.baseButton = addButton(
        self, "BASE", text("UI_PNC_MapTrack_BaseOff", "BASE: OFF"), 70
    )
    self.closeButton = addButton(
        self, "CLOSE", text("UI_Close", "Close"), 118
    )
    self:syncButtons()
end

function ISPNCMapTrackingModal:syncButtons()
    if not self.baseButton then return end
    local tracked = Tracking.IsBaseTracked()
    local hasBase = Tracking.HasBase()
    local atBase = hasBase and Tracking.IsAtBase()
    local available = hasBase and not atBase
    local title = text(
        tracked and "UI_PNC_MapTrack_BaseOn" or "UI_PNC_MapTrack_BaseOff",
        tracked and "BASE: ON" or "BASE: OFF"
    )
    if self.baseButton.setTitle then self.baseButton:setTitle(title)
    else self.baseButton.title = title end
    if self.baseButton.setEnable then self.baseButton:setEnable(available)
    else self.baseButton.enable = available end
    local helpKey = not hasBase and "UI_PNC_MapTrack_BaseMissing"
        or atBase and "UI_PNC_MapTrack_BaseArrived"
        or "UI_PNC_MapTrack_BaseHelp"
    local helpFallback = not hasBase
        and "Create a base zone before tracking your base."
        or atBase and "You are already at your base."
        or "Toggle the marker that guides you to your base."
    self.baseButton.tooltip = text(
        helpKey,
        helpFallback
    )
end

function ISPNCMapTrackingModal:onButton(button)
    local id = button and button.internal or ""
    if id == "BASE" then
        if not Tracking.CanTrackBase() then return false end
        local result = Tracking.ToggleBase()
        self:syncButtons()
        return result ~= false
    end
    if id == "CLOSE" then self:close() end
    return true
end

function ISPNCMapTrackingModal:prerender()
    ISPanel.prerender(self)
    self:syncButtons()
    self:drawRect(0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.96, 0.28, 0.65, 0.92)
    self:drawTextCentre(
        text("UI_PNC_MapTrack_Title", "Track"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium
    )
    self:drawTextCentre(
        text("UI_PNC_MapTrack_Hint", "Choose a location to track."),
        self.width / 2, 43, 0.72, 0.76, 0.82, 1, UIFont.Small
    )
end

function ISPNCMapTrackingModal:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if Tracking.instance == self then Tracking.instance = nil end
end

function ISPNCMapTrackingModal:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.moveWithMouse = true
    return object
end

function Tracking.Open()
    local client = PNC.ColonyManagementClient
    if client and type(client.RequestSnapshot) == "function" then
        client.RequestSnapshot()
    elseif PNC.Client and type(PNC.Client.RequestColonyManagement) == "function" then
        PNC.Client.RequestColonyManagement()
    end
    if Tracking.instance then
        Tracking.instance:syncButtons()
        Tracking.instance:bringToTop()
        return Tracking.instance
    end

    local width, height = 360, 190
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = ISPNCMapTrackingModal:new(
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
    Tracking.instance = modal
    return modal
end

function Tracking.Close()
    if Tracking.instance then Tracking.instance:close() end
end

if Toolbar and Toolbar.Register then
    Toolbar.Register("track", {
        order = 10,
        field = "pncTrackButton",
        width = 92,
        title = function()
            local value = getText and getText("UI_PNC_MapTrack_Button")
            return value and value ~= ""
                and value ~= "UI_PNC_MapTrack_Button" and value or "Track"
        end,
        tooltip = function()
            local value = getText and getText("UI_PNC_MapTrack_ButtonHelp")
            return value and value ~= ""
                and value ~= "UI_PNC_MapTrack_ButtonHelp"
                and value or "Open Hoomans tracking options."
        end,
        icon = "media/ui/MP/mp_ui_internet.png",
        iconSize = 22,
        onActivate = function() return Tracking.Open() ~= nil end,
        onMapClose = Tracking.Close,
    })
end

return Tracking
