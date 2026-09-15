-- Faction debug window public lifecycle API.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local UI = Internal.UI
local text = Internal.Text
function ISPNCFactionDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    FactionUI.instance = nil
end

function ISPNCFactionDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(
        x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function FactionUI.Open()
    local window = FactionUI.instance
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if not window then
        local screenWidth = getCore and getCore()
            and getCore():getScreenWidth() or 1280
        local screenHeight = getCore and getCore()
            and getCore():getScreenHeight() or 800
        window = UI.NewWindow(ISPNCFactionDebugWindow, {
            title = PNC.Translation.GetKey("UI_PNC_FactionInspectorTitle"),
            resizable = true,
            responsiveSpec = {
                width = math.min(1280, screenWidth - 24),
                height = math.min(800, screenHeight - 40),
                minWidth = 820,
                minHeight = 540,
                maxWidth = 1500,
                maxHeight = 960,
            },
        })
        window:initialise()
        window:instantiate()
        FactionUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function FactionUI.Toggle()
    local window = FactionUI.instance
    if window and window:getIsVisible() then
        window:close()
        return nil
    end
    return FactionUI.Open()
end

local function onResetLua()
    if FactionUI.instance then FactionUI.instance:close() end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
