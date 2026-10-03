
local Monitor = PNC.NPCMonitor
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Support = PNC.NPCMonitorSupport
local Tracking = PNC.NPCTracking

function Monitor.ClearTrack()
    Tracking.Clear()
    Monitor.trackedId = Tracking.trackedId
    Monitor.trackSignature = Tracking.trackSignature
    Monitor.trackUpdatedAt = Tracking.trackUpdatedAt
    Monitor.lastTrackRosterRequestAt = nil
    if Monitor.instance then
        Monitor.instance.trackSignature = nil
        Monitor.instance.trackUpdatedAt = nil
    end
end

function Monitor.TrackTarget(item)
    local tracked = Tracking.Track(item)
    Monitor.trackedId = Tracking.trackedId
    Monitor.trackSignature = Tracking.trackSignature
    Monitor.trackUpdatedAt = Tracking.trackUpdatedAt
    return tracked
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

function ISPNCNPCMonitor:onRelationships()
    local item = self:getSelectedDiagnostic()
    if item and item.deathMarker ~= true
        and PNC.RelationshipDebugUI
        and PNC.RelationshipDebugUI.Open
    then
        PNC.RelationshipDebugUI.Open(item.id)
    end
end

function ISPNCNPCMonitor:onProvisionDiagnostics()
    local item = self:getSelectedDiagnostic()
    if item and item.deathMarker ~= true
        and PNC.ProvisionDiagnosticsUI
        and PNC.ProvisionDiagnosticsUI.Open
    then
        PNC.ProvisionDiagnosticsUI.Open(item)
    end
end

function ISPNCNPCMonitor:onOverlay()
    if PNC.Nameplates and PNC.Nameplates.ToggleNameplateDebug then
        PNC.Nameplates.ToggleNameplateDebug()
    elseif PNC.Nameplates and PNC.Nameplates.ToggleDebug then
        PNC.Nameplates.ToggleDebug()
    end
end

function ISPNCNPCMonitor:onOverlayType(button)
    local internal = button and button.internal or ""
    local id = string.match(tostring(internal), "^overlay_(.+)$")
    if not id
        or not PNC.Nameplates
        or not PNC.Nameplates.ToggleOverlay
    then
        return
    end
    PNC.Nameplates.ToggleOverlay(id)
    if PNC.NPCMonitorView
        and PNC.NPCMonitorView.RefreshOverlayControls
    then
        PNC.NPCMonitorView.RefreshOverlayControls(self)
    end
end

function ISPNCNPCMonitor:onPathOverlay()
    if not PNC.Nameplates or not PNC.Nameplates.TogglePathDebug then return end
    local enabled = PNC.Nameplates.TogglePathDebug()
    if self.pathOverlayButton then
        UI.SetButtonVariant(self.pathOverlayButton, enabled and "selected" or "quiet")
    end
end

function ISPNCNPCMonitor:onCombatOverlay()
    if not PNC.Nameplates
        or not PNC.Nameplates.ToggleCombatDebug
    then
        return
    end
    local enabled = PNC.Nameplates.ToggleCombatDebug()
    if self.combatOverlayButton then
        UI.SetButtonVariant(
            self.combatOverlayButton,
            enabled and "selected" or "quiet"
        )
    end
end

function ISPNCNPCMonitor:onAnimationOverlay()
    if not PNC.Nameplates
        or not PNC.Nameplates.ToggleAnimationDebug
    then
        return
    end
    local enabled = PNC.Nameplates.ToggleAnimationDebug()
    if self.animationOverlayButton then
        UI.SetButtonVariant(
            self.animationOverlayButton,
            enabled and "selected" or "quiet"
        )
    end
end
