require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"
require "PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"

PNC.NPCMonitor = PNC.NPCMonitor or {}

local Monitor = PNC.NPCMonitor
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Support = PNC.NPCMonitorSupport
local TRACK_MARKER_PREFIX = "pnc_npc_track:"
local TRACK_MARKER_DURATION = 86400

local function markerHandler()
    return PNC.EventMarkers or (PsychopatzCore and PsychopatzCore.EventMarkers) or nil
end

local function markerID(npcID)
    return TRACK_MARKER_PREFIX .. tostring(npcID or "")
end

local function findDiagnostic(npcID)
    npcID = tostring(npcID or "")
    for _, item in ipairs(ClientState.debugRoster or {}) do
        if tostring(item.id or "") == npcID then return item end
    end
    return nil
end

local function markerStyle(item)
    local faction = tostring(item and item.faction or "")
    if faction == "hostile" then return "thief.png", { r = 1, g = 0.25, b = 0.2 } end
    if faction == "neutral" then return "crew.png", { r = 0.95, g = 0.75, b = 0.2 } end
    return "friend.png", { r = 0.15, g = 0.85, b = 1 }
end

function Monitor.ClearTrack()
    local trackedID = Monitor.trackedId
    local markers = markerHandler()
    local remove = markers and (markers.Remove or markers.remove) or nil
    if trackedID and remove then remove(markerID(trackedID)) end
    Monitor.trackedId = nil
    Monitor.trackSignature = nil
    Monitor.trackUpdatedAt = nil
    Monitor.lastTrackRosterRequestAt = nil
    if Monitor.instance then
        Monitor.instance.trackSignature = nil
        Monitor.instance.trackUpdatedAt = nil
    end
end

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

function ISPNCNPCMonitor:onPathOverlay()
    if not PNC.Nameplates or not PNC.Nameplates.TogglePathDebug then return end
    local enabled = PNC.Nameplates.TogglePathDebug()
    if self.pathOverlayButton then
        UI.SetButtonVariant(self.pathOverlayButton, enabled and "selected" or "quiet")
    end
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

function Monitor.UpdateTrackedMarker(force)
    local trackedID = Monitor.trackedId
    local markers = markerHandler()
    local setMarker = markers and (markers.Set or markers.set) or nil
    if not trackedID or not setMarker then return false end

    local existing = markers.markers and markers.markers[markerID(trackedID)] or nil
    if existing and existing.getDuration and existing:getDuration() <= 0 then
        Monitor.trackedId = nil
        Monitor.trackSignature = nil
        return false
    end

    local item = findDiagnostic(trackedID)
    if not item then return false end
    local body = Support.FindBody(item)
    local x = body and body.getX and body:getX() or tonumber(item.x)
    local y = body and body.getY and body:getY() or tonumber(item.y)
    if x == nil or y == nil then return false end

    local now = PNC.Core.Now()
    local signature = string.format("%s:%.2f:%.2f", trackedID, x, y)
    if force ~= true then
        if signature == Monitor.trackSignature then return true end
        if now - (tonumber(Monitor.trackUpdatedAt) or 0) < 250 then return true end
    end

    local icon, color = markerStyle(item)
    setMarker(markerID(trackedID), icon, TRACK_MARKER_DURATION, x, y, color,
        tostring(item.name or trackedID))
    Monitor.trackSignature = signature
    Monitor.trackUpdatedAt = now
    return true
end

function ISPNCNPCMonitor:updateTrackedMarker(force)
    return Monitor.UpdateTrackedMarker(force)
end

function ISPNCNPCMonitor:onTrack()
    local item = self:getSelectedDiagnostic()
    if not item then return end
    local selectedID = tostring(item.id)
    if Monitor.trackedId == selectedID then
        Monitor.ClearTrack()
    else
        Monitor.ClearTrack()
        Monitor.trackedId = selectedID
        self:updateTrackedMarker(true)
    end
    self:updateControlState()
end

local function updateTracking()
    if not Monitor.trackedId then return end
    local now = PNC.Core.Now()
    local lastRequest = math.max(
        tonumber(Monitor.lastTrackRosterRequestAt) or 0,
        tonumber(ClientState.lastDebugRosterRequestAt) or 0)
    if now - lastRequest >= 1000 and PNC.Client and PNC.Client.RequestDebugRoster then
        PNC.Client.RequestDebugRoster(false)
        Monitor.lastTrackRosterRequestAt = now
    end
    Monitor.UpdateTrackedMarker(false)
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
    if self.recordDebugButton then
        local recording = Support.IsRecording(item)
        self.recordDebugButton:setTitle(recording
            and Support.Tr("UI_PNC_MonitorStopRecordDebug", "Stop Recording")
            or Support.Tr("UI_PNC_MonitorRecordDebug", "Record Debug"))
        UI.SetButtonVariant(self.recordDebugButton, recording and "danger" or "default")
    end
    self.focus:setEnable(item ~= nil and Support.FindBody(item) ~= nil)
    self.track:setEnable(item ~= nil)
    UI.SetButtonVariant(self.track,
        item and Monitor.trackedId == tostring(item.id) and "selected" or "quiet")
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
    self:updateTrackedMarker(false)
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
    Monitor.ClearTrack()
end

if Events and Events.OnResetLua then Events.OnResetLua.Add(onResetLua) end
if Events and Events.OnTick and not Monitor.trackHookRegistered then
    Events.OnTick.Add(updateTracking)
    Monitor.trackHookRegistered = true
end
