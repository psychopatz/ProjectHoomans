-- Unified Animation Studio window for Project Hoomans.
-- Replaces the 4 fragmented debug windows (NPC Presentation Lab, Player
-- Animation Lab, NPC Scene Lab, Multi-Actor Animation) with one 3-tab studio:
--   1. Clips (Selected NPC + Local Player)
--   2. Scenes (Single-NPC 42 scenes + Multi-Actor choreography builder)
--   3. Props & Anchors (Hold Item + Firearm Anchor)

require "ISUI/ISTabPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_AnimationDebugPlayer"
require "PNC/UI/Nameplates/PNC_NameplateFirearmAnchor"
require "PNC/UI/AnimationStudio/PNC_AnimationStudio_ClipsTab"
require "PNC/UI/AnimationStudio/PNC_AnimationStudio_ScenesTab"
require "PNC/UI/AnimationStudio/PNC_AnimationStudio_PropsTab"

PNC = PNC or {}
PNC.AnimationStudio = PNC.AnimationStudio or {}

local Studio = PNC.AnimationStudio
local DebugPlayer = PNC.AnimationDebugPlayer
local Anchor = PNC.NameplateFirearmAnchor
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

ISPNCAnimationStudioWindow = PsychopatzWindow:derive("ISPNCAnimationStudioWindow")

function ISPNCAnimationStudioWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAnimationStudioWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    self.tabPanel = ISTabPanel:new(10, self:titleBarHeight() + 26,
        self.width - 20,
        self.height - self:titleBarHeight() - self:resizeWidgetHeight() - 34)
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(12, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.clipsTab = ISPNCAnimationStudioClipsTab:new(0, 0, 1, 1)
    self.clipsTab:initialise()
    self.clipsTab:instantiate()
    self.tabPanel:addView(tr("UI_PNC_AnimationStudio_TabClips", "Clips"), self.clipsTab)

    self.scenesTab = ISPNCAnimationStudioScenesTab:new(0, 0, 1, 1)
    self.scenesTab:initialise()
    self.scenesTab:instantiate()
    self.tabPanel:addView(tr("UI_PNC_AnimationStudio_TabScenes", "Scenes"), self.scenesTab)

    self.propsTab = ISPNCAnimationStudioPropsTab:new(0, 0, 1, 1)
    self.propsTab:initialise()
    self.propsTab:instantiate()
    self.tabPanel:addView(tr("UI_PNC_AnimationStudio_TabProps", "Props & Anchors"), self.propsTab)

    self:onResponsiveLayout()
end

function ISPNCAnimationStudioWindow:onResponsiveLayout()
    if not self.tabPanel then return end
    local top = self:titleBarHeight() + 26
    local resizeH = self:resizeWidgetHeight()
    local panelW = math.max(1, self.width - 20)
    local panelH = math.max(1, self.height - top - resizeH - 8)
    Layout.SetBounds(self.tabPanel, 10, top, panelW, panelH)
    local viewH = math.max(1, panelH - self.tabPanel.tabHeight)
    for _, view in ipairs({ self.clipsTab, self.scenesTab, self.propsTab }) do
        if view then
            Layout.SetBounds(view, 0, self.tabPanel.tabHeight, panelW, viewH)
            if view.onResponsiveLayout then view:onResponsiveLayout() end
        end
    end
end

function ISPNCAnimationStudioWindow:resolveBody()
    if DebugPlayer and DebugPlayer.ResolveBody then
        self.body = DebugPlayer.ResolveBody(self.npcId, self.body)
    end
    return self.body
end

-- Called by embedded NPC AnimationTab's "SCENE LAB" button to jump straight
-- to the Single-NPC Scenes view inside this same window.
function ISPNCAnimationStudioWindow:onSceneLabClicked()
    self:selectTab("scenes", "single")
end

function ISPNCAnimationStudioWindow:selectTab(tabKey, subMode)
    if not self.tabPanel or not self.tabPanel.activateView then return end
    if tabKey == "clips" then
        self.tabPanel:activateView(tr("UI_PNC_AnimationStudio_TabClips", "Clips"))
        if subMode and self.clipsTab and self.clipsTab.setMode then
            self.clipsTab:setMode(subMode)
        end
    elseif tabKey == "scenes" then
        self.tabPanel:activateView(tr("UI_PNC_AnimationStudio_TabScenes", "Scenes"))
        if subMode and self.scenesTab and self.scenesTab.setScope then
            self.scenesTab:setScope(subMode)
        end
    elseif tabKey == "props" then
        self.tabPanel:activateView(tr("UI_PNC_AnimationStudio_TabProps", "Props & Anchors"))
        if subMode and self.propsTab and self.propsTab.setTool then
            self.propsTab:setTool(subMode)
        end
    end
end

function ISPNCAnimationStudioWindow:setTarget(contextEntry)
    contextEntry = type(contextEntry) == "table" and contextEntry or {}
    self.contextEntry = contextEntry
    local nextID = tostring(contextEntry.id or "")
    local nextBody = DebugPlayer and DebugPlayer.ResolveBody
        and DebugPlayer.ResolveBody(nextID, contextEntry.zombie)
        or contextEntry.zombie
    if (self.body ~= nextBody or tostring(self.npcId or "") ~= nextID)
        and DebugPlayer and DebugPlayer.active
    then
        DebugPlayer.Stop("animation_studio_target_changed")
    end
    self.npcId = nextID
    self.body = nextBody
    self.npcName = tostring(
        contextEntry.name
            or (contextEntry.snapshot and contextEntry.snapshot.name)
            or (nextID ~= "" and nextID or "Local Player")
    )
    local title = tr("UI_PNC_AnimationStudio_Title", "Animation Studio")
        .. " - " .. self.npcName
    if self.setTitle then self:setTitle(title) else self.title = title end
    for _, view in ipairs({ self.clipsTab, self.scenesTab, self.propsTab }) do
        if view and view.setContext then view:setContext(self) end
    end
end

function ISPNCAnimationStudioWindow:prerender()
    PsychopatzWindow.prerender(self)
    local y = self:titleBarHeight() + 6
    local status = "Target: " .. tostring(self.npcName or "Local Player")
        .. (self.npcId ~= "" and (" [" .. tostring(self.npcId) .. "]") or "")
    self:drawText(status, 14, y, 0.78, 0.86, 0.94, 1, UIFont.Small)
end

function ISPNCAnimationStudioWindow:close()
    if DebugPlayer and DebugPlayer.active then
        DebugPlayer.Stop("animation_studio_closed")
    end
    if PNC.PlayerAnimationDebug and PNC.PlayerAnimationDebug.Stop then
        PNC.PlayerAnimationDebug.Stop("animation_studio_closed")
    end
    if Anchor and Anchor.ClearTarget then Anchor.ClearTarget() end
    local operaClient = PNC.Choreography and PNC.Choreography.Client or nil
    if operaClient and operaClient.StopPlacementPreview then
        operaClient.StopPlacementPreview()
    end
    if operaClient and operaClient.StopPreview then
        operaClient.StopPreview()
    end
    self:setVisible(false)
    self:removeFromUIManager()
    Studio.instance = nil
end

function Studio.Open(contextEntry, initialTab, subMode)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = Studio.instance
    if not window then
        window = UI.NewWindow(ISPNCAnimationStudioWindow, {
            title = tr("UI_PNC_AnimationStudio_Title", "Animation Studio"),
            width = 1040,
            height = 680,
            minWidth = 760,
            minHeight = 520,
            resizable = true,
        })
        Studio.instance = window
    end
    window:setTarget(contextEntry)
    if initialTab then
        window:selectTab(initialTab, subMode)
    end
    window:setVisible(true)
    window:bringToTop()
    return window
end

function Studio.Toggle(contextEntry, initialTab, subMode)
    if Studio.instance and Studio.instance:getIsVisible() then
        Studio.instance:close()
        return nil
    end
    return Studio.Open(contextEntry, initialTab, subMode)
end

return Studio
