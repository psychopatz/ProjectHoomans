-- Modal presentation for the Hoomans map menu.

local Menu = require "PNC/UI/Map/PNC_MapHoomansMenu_Registry"

require "ISUI/ISPanel"
require "ISUI/ISButton"

local function text(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

ISPNCHoomansSettingsModal = ISPanel:derive(
    "ISPNCHoomansSettingsModal"
)

function ISPNCHoomansSettingsModal:initialise()
    ISPanel.initialise(self)
end

local function addRow(panel, entry, y)
    local button = ISButton:new(
        18, y, panel.width - 36, 32, "", panel,
        ISPNCHoomansSettingsModal.onButton
    )
    button.internal = entry.id
    button.entry = entry
    local iconPath = Menu.Resolve(entry, "icon", nil)
    if iconPath and getTexture then
        local icon = type(iconPath) == "string"
            and getTexture(iconPath) or iconPath
        if icon then
            button.iconTexture = icon
            button.joypadTextureWH = tonumber(
                Menu.Resolve(entry, "iconSize", 20)
            ) or 20
        end
    end
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    panel:addChild(button)
    return button
end

function ISPNCHoomansSettingsModal:createChildren()
    ISPanel.createChildren(self)
    self.entryButtons = {}
    local y = 62
    for _, entry in ipairs(Menu.List()) do
        local button = addRow(self, entry, y)
        self.entryButtons[entry.id] = button
        y = y + 38
    end
    self.closeButton = ISButton:new(
        18, y, self.width - 36, 32,
        text("UI_Close", "Close"), self,
        ISPNCHoomansSettingsModal.onButton
    )
    self.closeButton.internal = "CLOSE"
    if self.closeButton.initialise then self.closeButton:initialise() end
    if self.closeButton.instantiate then self.closeButton:instantiate() end
    self:addChild(self.closeButton)
    self.closeY = y
    self:syncButtons()
end

function ISPNCHoomansSettingsModal:syncButtons()
    local y = 62
    for _, button in pairs(self.entryButtons or {}) do
        if button.setVisible then button:setVisible(false)
        else button.visible = false end
    end
    for _, entry in ipairs(Menu.List()) do
        local button = self.entryButtons and self.entryButtons[entry.id]
        if not button then
            button = addRow(self, entry, y)
            self.entryButtons[entry.id] = button
        end
        if button then
            local visible = Menu.IsEntryVisible(entry)
            if button.setVisible then button:setVisible(visible)
            else button.visible = visible end
            if visible then
                if button.setY then button:setY(y) else button.y = y end
                y = y + 38
                local title = tostring(Menu.Resolve(entry, "title", entry.id))
                if button.setTitle then button:setTitle(title)
                else button.title = title end
                local enabled = Menu.Resolve(entry, "enabled", true) ~= false
                if button.setEnable then button:setEnable(enabled)
                else button.enable = enabled end
                button.tooltip = Menu.Resolve(entry, "tooltip", nil)
            end
        end
    end
    if self.closeButton then
        if self.closeButton.setY then self.closeButton:setY(y)
        else self.closeButton.y = y end
        self.closeY = y
    end
    local desiredHeight = y + 32 + 8
    if self.setHeight then self:setHeight(desiredHeight)
    else self.height = math.max(self.height or 0, desiredHeight) end
end

function ISPNCHoomansSettingsModal:onButton(button)
    local id = button and button.internal or ""
    if id == "CLOSE" then
        self:close()
        return true
    end
    local entry = Menu.EntriesByID[id]
    if not entry or not Menu.IsEntryVisible(entry)
        or Menu.Resolve(entry, "enabled", true) == false
    then
        return false
    end
    local result = entry.onActivate(self.map)
    self:syncButtons()
    return result ~= false
end

function ISPNCHoomansSettingsModal:prerender()
    ISPanel.prerender(self)
    self:syncButtons()
    self:drawRect(0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.96, 0.28, 0.65, 0.92)
    self:drawTextCentre(
        text("UI_PNC_MapHoomans_Title", "Hoomans"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium
    )
    self:drawTextCentre(
        text("UI_PNC_MapHoomans_Hint", "Hoomans map tools"),
        self.width / 2, 39, 0.72, 0.76, 0.82, 1, UIFont.Small
    )
end

function ISPNCHoomansSettingsModal:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if Menu.instance == self then Menu.instance = nil end
end

function ISPNCHoomansSettingsModal:new(x, y, width, height, map)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.map = map
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.moveWithMouse = true
    return object
end

function Menu.Open(map)
    if Menu.instance then
        Menu.instance:syncButtons()
        Menu.instance:bringToTop()
        return Menu.instance
    end
    local width = 400
    local height = 82 + math.max(1, Menu.VisibleEntryCount()) * 38 + 32
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = ISPNCHoomansSettingsModal:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2),
        width, height, map
    )
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
    if modal.setCapture then modal:setCapture(true) end
    modal:bringToTop()
    Menu.instance = modal
    return modal
end

function Menu.Close()
    if Menu.instance then Menu.instance:close() end
end

return Menu
