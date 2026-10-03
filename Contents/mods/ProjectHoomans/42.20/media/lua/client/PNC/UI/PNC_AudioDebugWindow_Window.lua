-- Audio debug window shell, public API, and reset lifecycle.
local AudioUI = PNC.AudioDebugUI
local Internal = AudioUI.Internal
local TEXT = Internal.TEXT
local Model = Internal.Model
local UI = Internal.UI
local Layout = Internal.Layout

ISPNCAudioDebugWindow = PsychopatzWindow:derive("ISPNCAudioDebugWindow")

function ISPNCAudioDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAudioDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tabPanel = ISTabPanel:new(0, self:titleBarHeight(), self.width,
        self.height - self:titleBarHeight() - self:resizeWidgetHeight())
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.dialoguesTab = ISPNCAudioDebugDialoguesTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.dialoguesTab:initialise()
    self.dialoguesTab:instantiate()
    self.tabPanel:addView(TEXT.dialogues, self.dialoguesTab)

    self.sfxTab = ISPNCAudioDebugSFXTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.sfxTab:initialise()
    self.sfxTab:instantiate()
    self.tabPanel:addView(TEXT.sfx, self.sfxTab)
    self:onResponsiveLayout()
end

function ISPNCAudioDebugWindow:onResponsiveLayout()
    if not self.tabPanel then return end
    local titleHeight = self:titleBarHeight()
    local resizeHeight = self:resizeWidgetHeight()
    local top = titleHeight + 8
    local panelHeight = math.max(1, self.height - top - resizeHeight - 8)
    local panelWidth = math.max(1, self.width - 20)
    Layout.SetBounds(self.tabPanel, 10, top, panelWidth, panelHeight)
    local viewHeight = math.max(1, panelHeight - self.tabPanel.tabHeight)
    for _, view in ipairs({ self.dialoguesTab, self.sfxTab }) do
        Layout.SetBounds(view, 0, self.tabPanel.tabHeight,
            panelWidth, viewHeight)
        view:onResponsiveLayout()
    end
end

function ISPNCAudioDebugWindow:close()
    Model.StopAll(Model.GetCurrentPlayer())
    self:setVisible(false)
    self:removeFromUIManager()
    AudioUI.instance = nil
end

function ISPNCAudioDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function AudioUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = AudioUI.instance
    if not window then
        window = UI.NewWindow(ISPNCAudioDebugWindow, {
            title = TEXT.title,
            persistenceKey = "pnc.audioDebug",
            responsiveSpec = {
                width = 900,
                height = 620,
                minWidth = 620,
                minHeight = 440,
                maxWidth = 1400,
                maxHeight = 960,
            },
        })
        window:initialise()
        window:instantiate()
        AudioUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestResponsiveLayout(true)
    return window
end

function AudioUI.Toggle()
    if AudioUI.instance and AudioUI.instance:getIsVisible() then
        AudioUI.instance:close()
        return false
    end
    return AudioUI.Open() ~= nil
end

function AudioUI.Reset()
    if AudioUI.instance then
        Model.StopAll(Model.GetCurrentPlayer())
        if AudioUI.instance.removeFromUIManager then
            AudioUI.instance:removeFromUIManager()
        end
    end
    AudioUI.instance = nil
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(AudioUI.Reset)
end

return AudioUI
