-- NPC, diagnostics, and telemetry panel rendering for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local COLORS = Internal.COLORS
local tr = Internal.tr
local shorten = Internal.shorten

function ISPNCFactionDebugOverlay:renderNPCPanel(
    dashboard,
    contentX,
    contentWidth
)
    self:drawPanel(contentX, 312, contentWidth, 76)
    self:drawText(
        tr("UI_PNC_FactionOverlayNPC"),
        22, 320,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    if dashboard.npc then
        local affiliation = dashboard.npc.affiliation or {}
        self:drawLabel(
            tr("UI_PNC_FactionOverlaySelected"),
            shorten(dashboard.npc.name, 30),
            22, 341
        )
        self:drawLabel(
            tr("UI_PNC_FactionOverlayAffiliation"),
            tostring(affiliation.role or "none")
                .. " / "
                .. tostring(affiliation.rank or "none"),
            22, 360
        )
        self:drawTextRight(
            "r" .. tostring(dashboard.npc.recordRevision)
                .. " / p"
                .. tostring(dashboard.npc.presenceRevision),
            self.width - 22, 360,
            COLORS.muted.r,
            COLORS.muted.g,
            COLORS.muted.b,
            1,
            UIFont.Small
        )
    else
        self:drawText(
            tr("UI_PNC_FactionOverlayNoNPC"),
            22, 347,
            COLORS.muted.r,
            COLORS.muted.g,
            COLORS.muted.b,
            1,
            UIFont.Small
        )
    end
end

function ISPNCFactionDebugOverlay:renderDiagnosticsPanel(
    dashboard,
    contentX,
    contentWidth
)
    self:drawPanel(contentX, 396, contentWidth, 62)
    self:drawText(
        tr("UI_PNC_FactionOverlayDiagnostics"),
        22, 404,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    self:drawLabel(
        tr("UI_PNC_FactionOverlayEpisodes"),
        dashboard.activeEpisodeCount,
        22, 426,
        dashboard.activeEpisodeCount > 0
            and COLORS.warning or COLORS.success
    )
    self:drawLabel(
        tr("UI_PNC_FactionOverlayReconcile"),
        dashboard.reconciliationJobCount,
        190, 426,
        dashboard.reconciliationJobCount > 0
            and COLORS.warning or COLORS.success
    )
    local validationText =
        tr("UI_PNC_FactionOverlayNotRun")
    local validationTone = COLORS.muted
    if dashboard.validation then
        validationText = dashboard.validation.ok
            and "PASS" or "FAIL"
        validationTone = dashboard.validation.ok
            and COLORS.success or COLORS.danger
    end
    self:drawText(
        tr("UI_PNC_FactionOverlayInvariant")
            .. ": " .. validationText,
        22, 446,
        validationTone.r,
        validationTone.g,
        validationTone.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tr("UI_PNC_FactionOverlayTelemetry")
            .. " " .. tostring(dashboard.telemetry.count)
            .. "/" .. tostring(dashboard.telemetry.maximum),
        self.width - 22, 446,
        dashboard.telemetry.enabled
            and COLORS.success.r or COLORS.muted.r,
        dashboard.telemetry.enabled
            and COLORS.success.g or COLORS.muted.g,
        dashboard.telemetry.enabled
            and COLORS.success.b or COLORS.muted.b,
        1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:renderTelemetryFooter(
    dashboard,
    source,
    relation
)
    local latest = dashboard.telemetry.entries[
        #dashboard.telemetry.entries
    ]
    self:drawText(
        latest and (
            "#" .. tostring(latest.sequence)
                .. " " .. tostring(latest.category)
                .. " / " .. tostring(latest.result)
        ) or tr("UI_PNC_FactionOverlayNoTelemetry"),
        14, 470,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        "F" .. tostring(source.revision)
            .. " R" .. tostring(relation.revision)
            .. " G" .. tostring(dashboard.registryRevision),
        self.width - 14, 470,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
end

return Overlay
