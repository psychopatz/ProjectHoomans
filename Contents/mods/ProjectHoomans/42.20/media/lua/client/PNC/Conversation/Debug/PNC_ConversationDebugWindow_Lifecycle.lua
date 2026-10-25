-- Window rendering lifecycle and public open/toggle entry points.

local DebugUI = PNC.ConversationDebugUI
local Internal = DebugUI.Internal
local Model = Internal.Model
local UI = Internal.UI

function ISPNCConversationDebugWindow:prerender()
    local query = self.search and self.search:getText() or ""
    if query ~= self.lastQuery then
        self.lastQuery = query
        self:refreshBlocks()
    elseif self.blocks and self.blocks.selected ~= self.lastSelection then
        self.lastSelection = self.blocks.selected
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCConversationDebugWindow:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    DebugUI.instance = nil
end

function ISPNCConversationDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.Open(context)
    if PNC.Client and PNC.Client.CanUseDebug
        and not PNC.Client.CanUseDebug()
    then return nil end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCConversationDebugWindow, {
            title = Internal.tr("title"),
            resizable = true,
            responsiveSpec = {
                width = 1120, height = 720,
                minWidth = 760, minHeight = 500,
                maxWidth = 1600, maxHeight = 1000,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    if type(context) == "table" then
        window.context = Model.NormalizeContext(context)
    end
    window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    if window.setCapture then window:setCapture(true) end
    window:bringToTop()
    window:refreshBlocks()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end
