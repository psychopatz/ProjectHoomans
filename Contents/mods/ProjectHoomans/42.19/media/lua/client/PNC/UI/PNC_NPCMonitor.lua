require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"

PNC.NPCMonitor = PNC.NPCMonitor or {}

local Monitor = PNC.NPCMonitor
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Support = PNC.NPCMonitorSupport

ISPNCNPCMonitor = PsychopatzWindow:derive("ISPNCNPCMonitor")

require "PNC/UI/NPCMonitor/PNC_NPCMonitorView"

local View = PNC.NPCMonitorView

function ISPNCNPCMonitor:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCNPCMonitor:createChildren()
    PsychopatzWindow.createChildren(self)
    View.CreateChildren(self)
    self:requestResponsiveLayout(true)
    self:requestRoster(false)
end

function ISPNCNPCMonitor:onResponsiveLayout()
    View.Layout(self)
end

function ISPNCNPCMonitor:onFilter(button)
    self.filter = button and button.internal or "All"
    for filter, filterButton in pairs(self.filterButtons) do
        UI.SetButtonVariant(filterButton, filter == self.filter and "selected" or "quiet")
    end
    self:refreshList()
end

function ISPNCNPCMonitor:getSelectedDiagnostic()
    local entry = self.list and self.list:getItem() or nil
    return entry and entry.item or nil
end

function ISPNCNPCMonitor:onAction(button)
    local item = self:getSelectedDiagnostic()
    if not item or not PNC.Client then return end
    PNC.Client.SendDebug(button.internal, {
        id = item.id,
        amount = button.internal == "damage" and 25 or nil,
    })
    self:requestRoster(false)
end

function ISPNCNPCMonitor:onAudit()
    self:requestRoster(true)
end

function ISPNCNPCMonitor:onRefresh()
    self:requestRoster(false)
end

function ISPNCNPCMonitor:onOverlay()
    if PNC.Nameplates and PNC.Nameplates.ToggleDebug then PNC.Nameplates.ToggleDebug() end
end

function ISPNCNPCMonitor:onFocus()
    local item = self:getSelectedDiagnostic()
    local body = Support.FindBody(item)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not body then return end
    Support.SetOutlined(body, true)
    self.outlinedBody = body
    self.outlinedId = tostring(item.id)
    if player and player.faceThisObject then player:faceThisObject(body) end
end

function ISPNCNPCMonitor:onTeleport()
    local item = self:getSelectedDiagnostic()
    if item and PNC.Client then PNC.Client.SendDebug("teleport_to_npc", { id = item.id }) end
end

function ISPNCNPCMonitor:requestRoster(forceAudit)
    if PNC.Client and PNC.Client.RequestDebugRoster then
        PNC.Client.RequestDebugRoster(forceAudit == true)
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCNPCMonitor:refreshList()
    local selected = self:getSelectedDiagnostic()
    local selectedId = selected and tostring(selected.id) or self.selectedId
    local roster = ClientState.debugRoster or {}
    self.list:clear()
    self.visibleRosterCount = 0
    for _, item in ipairs(roster) do
        if Support.MatchesFilter(item, self.filter) then
            self.list:addItem(tostring(item.name or item.id), item)
            self.visibleRosterCount = self.visibleRosterCount + 1
            if selectedId and tostring(item.id) == selectedId then
                self.list.selected = #self.list.items
            end
        end
    end
    self.selectedId = selectedId
    self.lastRosterReceiveAt = tonumber(ClientState.lastDebugRosterReceiveAt)
        or tonumber(ClientState.lastDebugRosterRequestAt)
        or PNC.Core.Now()
    self:refreshDetails(true)
end

function ISPNCNPCMonitor:refreshDetails(force)
    local item = self:getSelectedDiagnostic()
    local id = item and tostring(item.id) or nil
    if not force and id == self.detailId then return end
    self.detailId = id
    Support.PopulateDetails(self.details, item, ClientState.debugAuthorized, ClientState.debugAudit)
end

function ISPNCNPCMonitor:updateOutline()
    local item = self:getSelectedDiagnostic()
    local id = item and tostring(item.id) or nil
    local body = Support.FindBody(item)
    if self.outlinedBody and self.outlinedBody ~= body then
        Support.SetOutlined(self.outlinedBody, false)
        self.outlinedBody = nil
    end
    if body and id ~= self.outlinedId then
        Support.SetOutlined(body, true)
        self.outlinedBody = body
        self.outlinedId = id
    elseif not body then
        self.outlinedId = nil
    end
    self.selectedId = id or self.selectedId
end

function ISPNCNPCMonitor:updateControlState()
    local item = self:getSelectedDiagnostic()
    for _, button in ipairs(self.selectionControls or {}) do button:setEnable(item ~= nil) end
    self.focus:setEnable(item ~= nil and Support.FindBody(item) ~= nil)
    self.teleport:setEnable(item ~= nil)
end

function ISPNCNPCMonitor:prerender()
    local now = PNC.Core.Now()
    local receiveAt = tonumber(ClientState.lastDebugRosterReceiveAt)
        or tonumber(ClientState.lastDebugRosterRequestAt)
        or 0
    if (now - (tonumber(self.lastRequestAt) or 0)) >= 1000 then self:requestRoster(false) end
    if receiveAt > (tonumber(self.lastRosterReceiveAt) or 0) then self:refreshList() end
    self:refreshDetails(false)
    self:updateOutline()
    self:updateControlState()
    PsychopatzWindow.prerender(self)
end

function ISPNCNPCMonitor:render()
    PsychopatzWindow.render(self)
    View.Render(self, ClientState.debugRoster, self:getSelectedDiagnostic())
end

function ISPNCNPCMonitor:close()
    if self.outlinedBody then Support.SetOutlined(self.outlinedBody, false) end
    self.outlinedBody = nil
    self:setVisible(false)
    self:removeFromUIManager()
    Monitor.instance = nil
end

function ISPNCNPCMonitor:new(x, y, width, height, options)
    local o = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(o, self)
    self.__index = self
    o.filter = "All"
    return o
end

function Monitor.Toggle()
    local window = Monitor.instance
    if not PNC.Client or not PNC.Client.CanUseDebug or not PNC.Client.CanUseDebug() then return nil end
    if not window then
        window = UI.NewWindow(ISPNCNPCMonitor, {
            title = Support.Tr("UI_PNC_MonitorTitle", "PNC NPC Monitor"),
            resizable = true,
            responsiveSpec = {
                width = 1160,
                height = 740,
                minWidth = 640,
                minHeight = 480,
                maxWidth = 1240,
                maxHeight = 820,
            },
        })
        window:initialise()
        window:instantiate()
        Monitor.instance = window
    elseif window:getIsVisible() then
        window:close()
        return nil
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestRoster(false)
    return window
end

local function onResetLua()
    if Monitor.instance then Monitor.instance:close() end
end

if Events and Events.OnResetLua then Events.OnResetLua.Add(onResetLua) end
