-- Window rendering, lifecycle, public API, and reset hook.
local WindowAPI = PNC.PlayerAnimationDebugUI
local Internal = WindowAPI.Internal
local TEXT = Internal.TEXT
local Debug = Internal.Debug
local UI = Internal.UI

function ISPNCPlayerAnimationDebugWindow:prerender()
    self:refreshDetails(false)
    self:refreshControls()
    PsychopatzWindow.prerender(self)
end

function ISPNCPlayerAnimationDebugWindow:render()
    PsychopatzWindow.render(self)
    local runtime = Debug.Runtime()
    local top = self:titleBarHeight() + 7
    self:drawText(TEXT.rawMode, 12, top,
        0.72, 0.78, 0.84, 1, UIFont.Small)
    self:drawTextRight(runtime.playerName or TEXT.noPlayer,
        self:getWidth() - 12, top,
        runtime.playerReady and 0.65 or 1.0,
        runtime.playerReady and 0.90 or 0.45,
        runtime.playerReady and 0.72 or 0.30,
        1, UIFont.Small)
end

function ISPNCPlayerAnimationDebugWindow:close()
    Debug.Stop("window_closed")
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function ISPNCPlayerAnimationDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function WindowAPI.Open()
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(ISPNCPlayerAnimationDebugWindow, {
            title = TEXT.title,
            resizable = true,
            responsiveSpec = {
                width = 1080,
                height = 720,
                minWidth = 740,
                minHeight = 520,
                maxWidth = 1500,
                maxHeight = 980,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestResponsiveLayout(true)
    return window
end

function WindowAPI.Toggle()
    if WindowAPI.instance and WindowAPI.instance:getIsVisible() then
        WindowAPI.instance:close()
        return nil
    end
    return WindowAPI.Open()
end

local function onResetLua()
    if WindowAPI.instance then WindowAPI.instance:close() end
end

if Events and Events.OnResetLua and Events.OnResetLua.Add
    and not WindowAPI._resetHook
then
    Events.OnResetLua.Add(onResetLua)
    WindowAPI._resetHook = true
end

return WindowAPI
