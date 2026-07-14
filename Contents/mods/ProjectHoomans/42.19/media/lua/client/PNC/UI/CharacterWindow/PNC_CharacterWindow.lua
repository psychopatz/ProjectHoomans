require "ISUI/ISPanel"
require "ISUI/ISTabPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CharacterWindow = PNC.CharacterWindow or {}

local CharacterWindow = PNC.CharacterWindow
local ClientState = PNC.Network.ClientState
local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local TAB_ORDER = {
    { id = "Info", label = "Info" },
    { id = "Skills", label = "Skills" },
    { id = "Health", label = "Health" },
    { id = "Protection", label = "Protection" },
    { id = "Temperature", label = "Temperature" },
}

ISPNCCharacterTab = ISPanel:derive("ISPNCCharacterTab")

function ISPNCCharacterTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCCharacterTab:createChildren()
    ISPanel.createChildren(self)
    local createHook = Tabs["Create" .. tostring(self.tabId) .. "Children"]
    if createHook then createHook(self) end
end

function ISPNCCharacterTab:setContext(npcId, snapshot, payload)
    self.npcId = npcId
    self.snapshot = snapshot or {}
    self.payload = payload or {}
    local contextHook = Tabs["Set" .. tostring(self.tabId) .. "Context"]
    if contextHook then contextHook(self, self.snapshot, self.payload) end
end

function ISPNCCharacterTab:onResize()
    local layoutHook = Tabs["Layout" .. tostring(self.tabId)]
    if layoutHook then layoutHook(self) end
end

function ISPNCCharacterTab:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
    local layoutHook = Tabs["Layout" .. tostring(self.tabId)]
    if layoutHook then layoutHook(self) end
end

function ISPNCCharacterTab:render()
    ISPanel.render(self)
    local renderer = Tabs["Render" .. tostring(self.tabId)]
    local top = 12 - (tonumber(self.scrollY) or 0)
    local bottom = renderer and renderer(self, self.snapshot or {}, self.payload or {}, top) or top
    self.contentHeight = math.max(self.height, (tonumber(bottom) or top) + (tonumber(self.scrollY) or 0) + 12)
    self.maxScroll = math.max(0, self.contentHeight - self.height)
    self.scrollY = Shared.Clamp(self.scrollY or 0, 0, self.maxScroll)
    self:clearStencilRect()
end

function ISPNCCharacterTab:onMouseWheel(del)
    self.scrollY = Shared.Clamp((self.scrollY or 0) - (del * 30), 0, self.maxScroll or 0)
    return true
end

function ISPNCCharacterTab:new(x, y, width, height, tabId)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.tabId = tabId
    o.scrollY = 0
    o.maxScroll = 0
    return o
end

ISPNCCharacterWindow = UI.Window:derive("ISPNCCharacterWindow")

function ISPNCCharacterWindow:initialise()
    UI.Window.initialise(self)
end

function ISPNCCharacterWindow:createChildren()
    local i
    local tab
    local view
    UI.Window.createChildren(self)

    self.tabPanel = ISTabPanel:new(0, self:titleBarHeight(), self.width, self.height - self:titleBarHeight() - self:resizeWidgetHeight())
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.tabViews = {}
    for i = 1, #TAB_ORDER do
        tab = TAB_ORDER[i]
        view = ISPNCCharacterTab:new(0, self.tabPanel.tabHeight, self.tabPanel.width, self.tabPanel.height - self.tabPanel.tabHeight, tab.id)
        view:initialise()
        view:instantiate()
        self.tabPanel:addView(tab.label, view)
        self.tabViews[tab.id] = view
    end
    self:onResponsiveLayout()
    self:refreshViews()
end

function ISPNCCharacterWindow:onResponsiveLayout()
    local titleHeight
    local resizeHeight
    local panelHeight
    local view
    if not self.tabPanel then return end
    titleHeight = self:titleBarHeight()
    resizeHeight = self:resizeWidgetHeight()
    panelHeight = math.max(1, self.height - titleHeight - resizeHeight)
    Layout.SetBounds(self.tabPanel, 0, titleHeight, self.width, panelHeight)
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    for _, view in pairs(self.tabViews or {}) do
        Layout.SetBounds(view, 0, self.tabPanel.tabHeight, self.tabPanel.width, math.max(1, panelHeight - self.tabPanel.tabHeight))
        view:onResize()
    end
end

function CharacterWindow.Reset()
    local window = CharacterWindow.instance
    if not window then return end
    if window.removeFromUIManager then window:removeFromUIManager() end
    CharacterWindow.instance = nil
end

local function onResetLua()
    CharacterWindow.Reset()
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

function ISPNCCharacterWindow:refreshViews()
    local view
    for _, view in pairs(self.tabViews or {}) do
        view:setContext(self.npcId, self.snapshot or {}, self.payload or {})
    end
end

function ISPNCCharacterWindow:setNPC(npcId)
    local summary
    self.npcId = npcId and tostring(npcId) or nil
    self.snapshot = ClientState.snapshots and ClientState.snapshots[self.npcId] or nil
    self.payload = ClientState.characterPayloads and ClientState.characterPayloads[self.npcId] or nil
    summary = Shared.GetCharacterData(self.snapshot, self.payload)
    self.title = tostring(summary.displayName or self.snapshot and self.snapshot.name or "NPC")
        .. " - " .. tostring(summary.archetypeLabel or self.snapshot and self.snapshot.archetypeLabel or "Survivor")
    if self.setTitle then self:setTitle(self.title) end
    self:refreshViews()
    if PNC.Client and PNC.Client.RequestCharacterPayload and self.npcId then
        PNC.Client.RequestCharacterPayload(self.npcId)
    end
end

function ISPNCCharacterWindow:updateSnapshot()
    local snapshot = self.npcId and ClientState.snapshots and ClientState.snapshots[self.npcId] or self.snapshot
    local payload = self.npcId and ClientState.characterPayloads and ClientState.characterPayloads[self.npcId] or self.payload
    local signature = table.concat({
        tostring(snapshot and snapshot.presenceRevision or 0),
        tostring(snapshot and snapshot.inventorySummary and snapshot.inventorySummary.revision or 0),
        tostring(payload and payload.revision or 0),
        tostring(payload and payload.inventory and payload.inventory.revision or 0),
    }, "|")
    self.snapshot = snapshot
    self.payload = payload
    if signature ~= self.contextSignature then
        self.contextSignature = signature
        self:refreshViews()
        local summary = Shared.GetCharacterData(snapshot, payload)
        if summary.displayName and self.setTitle then
            self:setTitle(tostring(summary.displayName) .. " - " .. tostring(summary.archetypeLabel or "Survivor"))
        end
    end
end

function ISPNCCharacterWindow:prerender()
    self:updateSnapshot()
    UI.Window.prerender(self)
end

function ISPNCCharacterWindow:close()
    CharacterWindow.instance = nil
    UI.Window.close(self)
end

function ISPNCCharacterWindow:new(x, y, width, height, options)
    options = options or {}
    local o = UI.Window.new(self, x, y, width, height, options)
    o.resizable = true
    return o
end

function CharacterWindow.Toggle(npcId)
    local window = CharacterWindow.instance
    if not window then
        local responsiveSpec = {
            width = 600,
            height = 540,
            minWidth = 470,
            minHeight = 390,
            maxWidth = 840,
            maxHeight = 760,
            anchor = "center",
        }
        local bounds = Layout.ResolveWindow(responsiveSpec)
        window = ISPNCCharacterWindow:new(bounds.x, bounds.y, bounds.width, bounds.height, {
            title = "NPC Character",
            responsiveSpec = responsiveSpec,
            persistenceKey = "ProjectHoomans:CharacterWindow",
            resizable = true,
        })
        window:initialise()
        window:instantiate()
        window:addToUIManager()
        CharacterWindow.instance = window
    end
    window:setVisible(true)
    window:setNPC(npcId)
    window:bringToTop()
    return window
end

return CharacterWindow
