-- Unified Animation Studio window for Project Hoomans.
-- Replaces the 4 fragmented debug windows (NPC Presentation Lab, Player
-- Animation Lab, NPC Scene Lab, Multi-Actor Animation) with one 3-tab studio:
--   1. Clips (Selected NPC + Local Player)
--   2. Scenes (Single-NPC 42 scenes + Multi-Actor choreography builder)
--   3. Props & Anchors (Hold Item + Firearm Anchor)

require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_AnimationDebugPlayer"
require "PNC/Choreography/PNC_Choreography_Client"
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

local function getNearbyLiveNPCs()
    local client = PNC.Choreography and PNC.Choreography.Client or nil
    if client and type(client.GetNearbyNPCs) == "function" then
        return client.GetNearbyNPCs(32) or {}
    end
    return {}
end

ISPNCAnimationStudioWindow = PsychopatzWindow:derive("ISPNCAnimationStudioWindow")

function ISPNCAnimationStudioWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAnimationStudioWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    self.targetCombo = ISComboBox:new(0, 0, 260, 24, self,
        ISPNCAnimationStudioWindow.onTargetComboChanged)
    self.targetCombo:initialise()
    self.targetCombo:instantiate()
    self:addChild(self.targetCombo)

    self.refreshTargetBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_RefreshTargets", "Refresh NPCs"),
        target = self,
        onclick = UI.ButtonCallback(function() self:refreshNearbyTargets(false) end),
        variant = "quiet",
    })

    self.tabPanel = ISTabPanel:new(10, self:titleBarHeight() + 34,
        self.width - 20,
        self.height - self:titleBarHeight() - self:resizeWidgetHeight() - 42)
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

function ISPNCAnimationStudioWindow:refreshNearbyTargets(autoSelectFirst)
    if not self.targetCombo then return end
    local currentId = tostring(self.npcId or "")
    local nearby = getNearbyLiveNPCs()
    self.targetCombo:clear()
    if #nearby == 0 then
        self.targetCombo:addOptionWithData("No nearby live NPCs", { id = "", name = "No NPC" })
        self.targetCombo.selected = 1
        if currentId ~= "" then
            self:setTarget({})
        end
        return
    end
    local selectedIdx = nil
    for i, entry in ipairs(nearby) do
        local dist = entry.distSq and math.sqrt(tonumber(entry.distSq) or 0) or nil
        local distText = dist and string.format(" (%.1f tiles)", dist) or ""
        self.targetCombo:addOptionWithData(
            tostring(entry.name or entry.id) .. distText,
            entry
        )
        if currentId ~= "" and tostring(entry.id) == currentId then
            selectedIdx = i
        end
    end
    if selectedIdx then
        self.targetCombo.selected = selectedIdx
    elseif autoSelectFirst or currentId == "" then
        self.targetCombo.selected = 1
        self:setTarget(nearby[1])
    else
        self.targetCombo.selected = 1
        self:setTarget(nearby[1])
    end
end

function ISPNCAnimationStudioWindow:onTargetComboChanged()
    if not self.targetCombo or not self.targetCombo.getOptionData then return end
    local entry = self.targetCombo:getOptionData(self.targetCombo.selected)
    if type(entry) == "table" then
        self:setTarget(entry)
    end
end

function ISPNCAnimationStudioWindow:onResponsiveLayout()
    if not self.tabPanel then return end
    local titleH = self:titleBarHeight()
    local headerY = titleH + 5
    local headerH = 24
    local refreshW = 104
    local comboX = 96
    local comboW = math.min(340, math.max(160, self.width - comboX - refreshW - 22))
    if self.targetCombo then
        Layout.SetBounds(self.targetCombo, comboX, headerY, comboW, headerH)
    end
    if self.refreshTargetBtn then
        Layout.SetBounds(self.refreshTargetBtn, comboX + comboW + 6, headerY, refreshW, headerH)
    end
    local top = headerY + headerH + 6
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

function ISPNCAnimationStudioWindow:resolveRecord()
    if self.npcId and self.npcId ~= "" and PNC.Registry and PNC.Registry.Get then
        return PNC.Registry.Get(self.npcId)
    end
    return nil
end

function ISPNCAnimationStudioWindow:playXML(entry)
    local body = self:resolveBody()
    if not entry or not body or not DebugPlayer or not DebugPlayer.PlayXML then return end
    DebugPlayer.PlayXML(entry, self.npcId, body, self:resolveRecord())
end

function ISPNCAnimationStudioWindow:playPipeline(entry)
    local body = self:resolveBody()
    if not entry or not body or not DebugPlayer or not DebugPlayer.PlayPipeline then return end
    DebugPlayer.PlayPipeline(entry, self.npcId, body, self:resolveRecord())
end

function ISPNCAnimationStudioWindow:playRaw(entry)
    local body = self:resolveBody()
    if not entry or not body or not DebugPlayer or not DebugPlayer.PlayRaw then return end
    DebugPlayer.PlayRaw(entry, self.npcId, body, self:resolveRecord())
end

function ISPNCAnimationStudioWindow:openScenes()
    self:selectTab("scenes", "single")
end

function ISPNCAnimationStudioWindow:onSceneLabClicked()
    self:openScenes()
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
    if (self.body ~= nextBody or tostring(self.npcId or "") ~= nextID) then
        if DebugPlayer and DebugPlayer.active then
            DebugPlayer.Stop("animation_studio_target_changed")
        end
        if Anchor and Anchor.ClearTarget then
            Anchor.ClearTarget()
        end
    end
    self.npcId = nextID
    self.body = nextBody
    self.playerIndex = tonumber(contextEntry.playerNum or contextEntry.playerIndex) or 0
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
    local y = self:titleBarHeight() + 9
    self:drawText("Target NPC:", 14, y, 0.78, 0.86, 0.94, 1, UIFont.Small)
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
            resizable = true,
            responsiveSpec = {
                width = 1120,
                height = 740,
                minWidth = 760,
                minHeight = 520,
                maxWidth = 1600,
                maxHeight = 1080,
            },
        })
        window:initialise()
        window:instantiate()
        Studio.instance = window
    end
    window:addToUIManager()
    if type(contextEntry) == "table" and tostring(contextEntry.id or "") ~= "" then
        window:setTarget(contextEntry)
        window:refreshNearbyTargets(false)
    else
        window:setTarget(contextEntry)
        window:refreshNearbyTargets(true)
    end
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
