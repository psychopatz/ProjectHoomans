PNC = PNC or {}
PNC.NPCPresentationDebug = PNC.NPCPresentationDebug or {}

require "ISUI/ISTabPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_AnimationDebugPlayer"
require "PNC/Debug/NPCPresentationDebug/PNC_NPCPresentationDebug_HeldItem"
require "PNC/UI/Nameplates/PNC_NameplateFirearmAnchor"
require "PNC/UI/NPCPresentationDebug/PNC_NPCPresentationDebug_AnimationTab"
require "PNC/UI/NPCPresentationDebug/PNC_NPCPresentationDebug_AnchorTab"
require "PNC/UI/NPCPresentationDebug/PNC_NPCPresentationDebug_HoldItemTab"

local WindowAPI = PNC.NPCPresentationDebug
local DebugPlayer = PNC.AnimationDebugPlayer
local Holder = PNC.NPCPresentationHeldItem
local Anchor = PNC.NameplateFirearmAnchor
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function firearmEffects()
    if not PNC.ClientFirearmEffects and require then
        pcall(require, "PNC/PNC_ClientFirearmEffects")
    end
    return PNC.ClientFirearmEffects
end

ISPNCNPCPresentationDebugWindow = PsychopatzWindow:derive(
    "ISPNCNPCPresentationDebugWindow")

function ISPNCNPCPresentationDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCNPCPresentationDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tabPanel = ISTabPanel:new(10, self:titleBarHeight() + 30,
        self.width - 20,
        self.height - self:titleBarHeight() - self:resizeWidgetHeight() - 38)
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.animationTab = ISPNCNPCPresentationDebugAnimationTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.animationTab:initialise()
    self.animationTab:instantiate()
    self.tabPanel:addView("Animation", self.animationTab)

    self.anchorTab = ISPNCNPCPresentationDebugAnchorTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.anchorTab:initialise()
    self.anchorTab:instantiate()
    self.tabPanel:addView("Firearm Anchor", self.anchorTab)

    self.holdItemTab = ISPNCNPCPresentationDebugHoldItemTab:new(
        0, self.tabPanel.tabHeight, self.tabPanel.width,
        self.tabPanel.height - self.tabPanel.tabHeight)
    self.holdItemTab:initialise()
    self.holdItemTab:instantiate()
    self.tabPanel:addView("Hold Item", self.holdItemTab)
    self:onResponsiveLayout()
end

function ISPNCNPCPresentationDebugWindow:onResponsiveLayout()
    if not self.tabPanel then return end
    local titleHeight = self:titleBarHeight()
    local resizeHeight = self:resizeWidgetHeight()
    local top = titleHeight + 30
    local panelWidth = math.max(1, self.width - 20)
    local panelHeight = math.max(1,
        self.height - top - resizeHeight - 8)
    Layout.SetBounds(self.tabPanel, 10, top, panelWidth, panelHeight)
    local viewHeight = math.max(1, panelHeight - self.tabPanel.tabHeight)
    for _, view in ipairs({
        self.animationTab,
        self.anchorTab,
        self.holdItemTab,
    }) do
        Layout.SetBounds(view, 0, self.tabPanel.tabHeight,
            panelWidth, viewHeight)
        if view.onResponsiveLayout then view:onResponsiveLayout() end
    end
end

function ISPNCNPCPresentationDebugWindow:resolveBody()
    self.body = DebugPlayer.ResolveBody(self.npcId, self.body)
    return self.body
end

function ISPNCNPCPresentationDebugWindow:refreshTabs()
    for _, view in ipairs({
        self.animationTab,
        self.anchorTab,
        self.holdItemTab,
    }) do
        if view and view.setContext then view:setContext(self) end
    end
end

function ISPNCNPCPresentationDebugWindow:setTarget(contextEntry)
    contextEntry = contextEntry or {}
    local nextID = tostring(contextEntry.id or "")
    local previousBody = self.body
    local previousID = self.npcId
    local nextBody = DebugPlayer.ResolveBody(nextID, contextEntry.zombie)
    local changed = previousBody ~= nextBody
        or tostring(previousID or "") ~= nextID
    if changed then
        if DebugPlayer.active then DebugPlayer.Stop("target_changed") end
        local effects = firearmEffects()
        if effects and effects.StopSimulation then effects.StopSimulation() end
        if Anchor and Anchor.ClearTarget then Anchor.ClearTarget() end
    end
    self.npcId = nextID
    self.playerIndex = tonumber(contextEntry.playerIndex) or 0
    self.npcName = tostring(contextEntry.name
        or contextEntry.record and contextEntry.record.name
        or self.npcId)
    self.body = nextBody
    self.record = contextEntry.record
        or contextEntry.snapshot
        or {
            id = self.npcId,
            name = self.npcName,
            runtime = { debug = true },
        }
    Holder.SetTarget(self.body, self.npcId, self.playerIndex)
    if self.setTitle then
        self:setTitle("NPC Presentation Lab — " .. self.npcName)
    else
        self.title = "NPC Presentation Lab — " .. self.npcName
    end
    self:refreshTabs()
end

function ISPNCNPCPresentationDebugWindow:playXML(entry)
    DebugPlayer.PlayXML(entry, self.npcId, self:resolveBody(), self.record)
end

function ISPNCNPCPresentationDebugWindow:playPipeline(entry)
    DebugPlayer.PlayPipeline(entry, self.npcId, self:resolveBody(), self.record)
end

function ISPNCNPCPresentationDebugWindow:playRaw(entry)
    DebugPlayer.PlayRaw(entry, self.npcId, self:resolveBody(), self.record)
end

function ISPNCNPCPresentationDebugWindow:openScenes()
    if not PNC.AnimationSceneDebugWindow then
        require "PNC/UI/PNC_AnimationSceneDebugWindow"
    end
    if PNC.AnimationSceneDebugWindow
        and PNC.AnimationSceneDebugWindow.Open
    then
        PNC.AnimationSceneDebugWindow.Open({
            id = self.npcId,
            name = self.npcName,
            zombie = self:resolveBody(),
            record = self.record,
        })
    end
end

function ISPNCNPCPresentationDebugWindow:prerender()
    local body = self:resolveBody()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if DebugPlayer.active then DebugPlayer.Maintain(body, now) end
    -- Reapply after animation maintenance so an arbitrary held item remains
    -- the visible presentation while clips are replaced or pose-held.
    Holder.Maintain(body, self.npcId)
    if self.animationTab then self.animationTab:refreshDetails(false) end
    if self.anchorTab then self.anchorTab:refreshDetails(false) end
    if self.holdItemTab then self.holdItemTab:refreshDetails(false) end
    PsychopatzWindow.prerender(self)
end

function ISPNCNPCPresentationDebugWindow:render()
    PsychopatzWindow.render(self)
    local body = self:resolveBody()
    local top = self:titleBarHeight() + 7
    self:drawText(
        "Target: " .. tostring(self.npcName or self.npcId or "?")
            .. " [" .. tostring(self.npcId or "?") .. "]"
            .. (body and " — local body bound" or " — NO LOCAL BODY"),
        12, top,
        body and 0.65 or 1.0,
        body and 0.90 or 0.45,
        body and 0.72 or 0.30,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        "Pose / Firearm Anchor / Held Item",
        self:getWidth() - 12,
        top,
        0.72, 0.78, 0.84, 1, UIFont.Small
    )
end

function ISPNCNPCPresentationDebugWindow:close()
    DebugPlayer.Stop("window_closed")
    local effects = firearmEffects()
    if effects and effects.StopSimulation then effects.StopSimulation() end
    Holder.Reset()
    if Anchor and Anchor.ClearTarget then Anchor.ClearTarget() end
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function ISPNCNPCPresentationDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function WindowAPI.Open(contextEntry)
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(ISPNCNPCPresentationDebugWindow, {
            title = "NPC Presentation Lab",
            resizable = true,
            responsiveSpec = {
                width = 1180,
                height = 760,
                minWidth = 760,
                minHeight = 560,
                maxWidth = 1500,
                maxHeight = 980,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    window:setTarget(contextEntry)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestResponsiveLayout(true)
    return window
end

local function onResetLua()
    if WindowAPI.instance then WindowAPI.instance:close() end
    Holder.Reset()
    DebugPlayer.Stop("lua_reset")
end

if Events and Events.OnResetLua then Events.OnResetLua.Add(onResetLua) end

return WindowAPI
