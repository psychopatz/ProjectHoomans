require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.BuildingPlacementUI = PNC.BuildingPlacementUI or {}

local PlacementUI = PNC.BuildingPlacementUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

ISPNCBuildingPlacementWindow = PsychopatzWindow:derive(
    "ISPNCBuildingPlacementWindow"
)

function ISPNCBuildingPlacementWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCBuildingPlacementWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.backButton = UI.CreateButton(self, {
        id = "back",
        title = tr("UI_PNC_BuildingPlacement_Back", "BACK"),
        target = self,
        onclick = ISPNCBuildingPlacementWindow.onAction,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
end

function ISPNCBuildingPlacementWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    Layout.SetBounds(self.backButton, rect.x, rect.y + rect.height
        - buttonHeight, rect.width, buttonHeight)
end

function ISPNCBuildingPlacementWindow:render()
    PsychopatzWindow.render(self)
    local colors = Theme.colors
    local text = tr("UI_PNC_BuildingPlacement_Rotate", "PRESS R TO ROTATE")
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    self:drawTextCentre(text, self.width / 2, rect.y + 18,
        colors.text.r, colors.text.g, colors.text.b, 1, UIFont.Medium)
end

function ISPNCBuildingPlacementWindow:onAction(button)
    if button.internal ~= "back" then return end
    self:close()
end

function ISPNCBuildingPlacementWindow:close(suppressBack)
    local callback = not suppressBack and self.onBack or nil
    self:setVisible(false)
    self:removeFromUIManager()
    if PlacementUI.instance == self then PlacementUI.instance = nil end
    if callback then callback() end
end

function ISPNCBuildingPlacementWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self); self.__index = self
    object.onBack = options.onBack
    return object
end

function PlacementUI.Close()
    if PlacementUI.instance then PlacementUI.instance:close(true) end
end

function PlacementUI.Open(options)
    options = type(options) == "table" and options or {}
    PlacementUI.Close()
    local core = getCore and getCore() or nil
    local screenWidth = core and core.getScreenWidth
        and core:getScreenWidth() or 1280
    local screenHeight = core and core.getScreenHeight
        and core:getScreenHeight() or 720
    local width = math.min(360, math.max(280, screenWidth - 40))
    local height = 128
    local window = ISPNCBuildingPlacementWindow:new(
        math.floor((screenWidth - width) / 2), 24, width, height, {
            title = tr("UI_PNC_BuildingPlacement_Title", "PLACEMENT"),
            resizable = false,
            onBack = options.onBack,
        })
    window:initialise(); window:instantiate(); window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop()
    PlacementUI.instance = window
    return window
end

return PlacementUI
