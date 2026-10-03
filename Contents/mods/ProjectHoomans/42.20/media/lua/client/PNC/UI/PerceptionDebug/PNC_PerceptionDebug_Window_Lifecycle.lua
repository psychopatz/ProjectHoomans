require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}
PNC.PerceptionDebug.UI = PNC.PerceptionDebug.UI or {}

local DebugUI = PNC.PerceptionDebug.UI
local Internal = DebugUI.Internal or {}
DebugUI.Internal = Internal
local Settings = PNC.PerceptionDebug.Settings
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings"
local Model = PNC.PerceptionDebug.Model
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
local Overlay = PNC.PerceptionDebug.Overlay
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Overlay"
local Perception = PNC.Perception and PNC.Perception.WorldObjects
    or require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local SLEEP_COLOR = Internal.SleepColor
local OPTION_LABELS = Internal.OptionLabels

local tr = Internal.Tr
local trf = Internal.Trf

function ISPNCPerceptionDebugWindow:prerender()
    if self.objects.selected ~= self.lastSelection then
        self.lastSelection = self.objects.selected
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCPerceptionDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local summary = Model.Summary(self.snapshot)
    local suffix = trf("UI_PNC_PerceptionDebug_Summary",
        "%1 | %2 objects | %3 inspected", summary.status,
        summary.objects, summary.inspected)
    if summary.serverRequests ~= 0 then
        suffix = suffix .. trf("UI_PNC_PerceptionDebug_ServerRequests",
            " | server requests %1", summary.serverRequests)
    end
    UI.DrawSectionTitle(self,
        tr("UI_PNC_PerceptionDebug_Objects", "OBSERVED OBJECTS"),
        self.layout.objects.x, self.layout.objects.y - Layout.Pixels(20,
            self.uiScale), self.layout.objects.width, suffix)
    local current = self:getSelected()
    UI.DrawSectionTitle(self,
        tr("UI_PNC_PerceptionDebug_Details", "OBJECT DETAILS"),
        self.layout.details.x, self.layout.details.y - Layout.Pixels(20,
            self.uiScale), self.layout.details.width,
        current and current.label or "")
    UI.DrawSectionTitle(self,
        tr("UI_PNC_PerceptionDebug_CampPreview", "CAMP PREVIEW"),
        self.layout.campPreview.x,
        self.layout.campPreview.y - Layout.Pixels(20, self.uiScale),
        self.layout.campPreview.width)
end

function ISPNCPerceptionDebugWindow:close()
    -- Overlay activation is a session/runtime concern. Closing the debug hub
    -- releases the dashboard only; an explicitly active overlay remains
    -- visible and uses its last frozen snapshot. This also stops all future
    -- scans because the window's refresh loop is no longer running.
    if not Overlay.IsEnabled() then Overlay.Clear(true) end
    self:setVisible(false)
    self:removeFromUIManager()
    if DebugUI.instance == self then DebugUI.instance = nil end
end

function ISPNCPerceptionDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.Open()
    if PNC.Client and PNC.Client.CanUseDebug
        and not PNC.Client.CanUseDebug()
    then return nil end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCPerceptionDebugWindow, {
            title = tr("UI_PNC_PerceptionDebug_Title",
                "HOOMANS PERCEPTION DEBUG"),
            resizable = true,
            collapsible = false,
            responsiveSpec = {
                width = 1120,
                height = 720,
                minWidth = 780,
                minHeight = 480,
                maxWidth = 1600,
                maxHeight = 1100,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    -- Older sessions could have persisted this hub in its collapsed title-bar
    -- state. The perception controls must always be reachable when the hub is
    -- opened, even after the window switches to the fixed presentation.
    window.isCollapsed = false
    if window.clearMaxDrawHeight then window:clearMaxDrawHeight() end
    if window.syncWindowControls then window:syncWindowControls() end
    if window.requestResponsiveLayout then
        window:requestResponsiveLayout(true)
    end
    window:bringToTop()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

DebugUI.OpenWindow = DebugUI.Open


return DebugUI
