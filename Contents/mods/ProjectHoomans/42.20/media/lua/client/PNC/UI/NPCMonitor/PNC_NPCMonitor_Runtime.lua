local Monitor = PNC.NPCMonitor
local ClientState = PNC.Network.ClientState
local Support = PNC.NPCMonitorSupport
local Tracking = PNC.NPCTracking
local UI = PsychopatzCore.UI
local View = PNC.NPCMonitorView

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
    local result = Tracking.Update(force)
    Monitor.trackedId = Tracking.trackedId
    Monitor.trackSignature = Tracking.trackSignature
    Monitor.trackUpdatedAt = Tracking.trackUpdatedAt
    return result
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
        Monitor.TrackTarget(item)
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

function ISPNCNPCMonitor:onCommandMap()
    local item = self:getSelectedDiagnostic()
    if not item or not PNC.MapCommands
        or not PNC.MapCommands.OpenForNPC
    then
        return
    end
    PNC.MapCommands.OpenForNPC(item)
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
    local mutableRecord = item ~= nil and item.deathMarker ~= true
    for _, button in ipairs(self.selectionControls or {}) do
        button:setEnable(mutableRecord)
    end
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
    if self.commandMap then
        self.commandMap:setEnable(mutableRecord)
    end
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
