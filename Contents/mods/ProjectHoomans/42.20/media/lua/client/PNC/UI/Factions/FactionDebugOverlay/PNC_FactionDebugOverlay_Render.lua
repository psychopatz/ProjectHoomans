-- Render entry point for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local Model = Internal.Model
local ClientState = Internal.ClientState
local stateTone = Internal.stateTone

require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_RenderSummary"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_RenderDetails"

function ISPNCFactionDebugOverlay:render()
    ISUIElement.render(self)
    local dashboard = Model.BuildDashboard(
        ClientState.factionDebug,
        ClientState.factionDebugAuthorized,
        ClientState.factionDebugReason
    )
    self:renderFrame()
    if dashboard.status ~= "ready" then
        self:renderWaiting(dashboard)
        return
    end

    local source = dashboard.source
    local target = dashboard.target
    local relation = dashboard.forward
    local tone = stateTone(relation, dashboard.generatedAt)
    local contentX = 12
    local contentWidth = self.width - 24

    self:renderFactionPanel(
        dashboard,
        source,
        target,
        relation,
        tone,
        contentX,
        contentWidth
    )
    self:renderDiplomacyPanel(
        relation,
        contentX,
        contentWidth
    )
    self:renderIntentPanel(dashboard, contentX, contentWidth)
    self:renderNPCPanel(dashboard, contentX, contentWidth)
    self:renderDiagnosticsPanel(dashboard, contentX, contentWidth)
    self:renderTelemetryFooter(dashboard, source, relation)
end

return Overlay
