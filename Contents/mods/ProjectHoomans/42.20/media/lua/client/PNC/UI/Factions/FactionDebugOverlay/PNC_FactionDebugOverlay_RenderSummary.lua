-- Summary panel rendering for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local COLORS = Internal.COLORS
local tr = Internal.tr

local shorten = Internal.shorten
local statusText = Internal.statusText

function ISPNCFactionDebugOverlay:renderFrame()
    self:drawRect(
        0, 0, self.width, self.height,
        0.94,
        COLORS.background.r,
        COLORS.background.g,
        COLORS.background.b
    )
    self:drawRectBorder(
        0, 0, self.width, self.height,
        0.95,
        COLORS.border.r,
        COLORS.border.g,
        COLORS.border.b
    )
    self:drawRect(
        0, 0, self.width, 30,
        0.98, 0.07, 0.18, 0.22
    )
    self:drawText(
        tr("UI_PNC_FactionOverlayTitle"),
        12, 7,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tr("UI_PNC_FactionOverlayReadOnly"),
        self.width - 12,
        7,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:renderFactionPanel(
    dashboard,
    source,
    target,
    relation,
    tone,
    contentX,
    contentWidth
)
    self:drawPanel(contentX, 40, contentWidth, 62)
    self:drawText(
        shorten(source.name, 28),
        22, 48,
        COLORS.success.r,
        COLORS.success.g,
        COLORS.success.b,
        1,
        UIFont.Medium
    )
    self:drawText(
        tr("UI_PNC_FactionOverlayVersus"),
        22, 72,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    self:drawText(
        target and shorten(target.name, 28)
            or tr("UI_PNC_FactionOverlayNoTarget"),
        48, 72,
        target and COLORS.warning.r or COLORS.muted.r,
        target and COLORS.warning.g or COLORS.muted.g,
        target and COLORS.warning.b or COLORS.muted.b,
        1,
        UIFont.Small
    )
    if target then
        self:drawBadge(
            statusText(relation, dashboard.generatedAt),
            self.width - 142, 56, 118, tone
        )
    end
end

function ISPNCFactionDebugOverlay:renderDiplomacyPanel(
    relation,
    contentX,
    contentWidth
)
    self:drawPanel(contentX, 110, contentWidth, 116)
    self:drawText(
        tr("UI_PNC_FactionOverlayDiplomacy"),
        22, 117,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    local half = math.floor((contentWidth - 34) / 2)
    self:drawMetric(
        tr("UI_PNC_FactionOverlayStanding"),
        relation.standing, -100, 100,
        22, 139, half,
        relation.standing < 0
            and COLORS.danger or COLORS.success
    )
    self:drawMetric(
        tr("UI_PNC_FactionOverlayTrust"),
        relation.trust, -100, 100,
        32 + half, 139, half,
        relation.trust < 0
            and COLORS.danger or COLORS.success
    )
    self:drawMetric(
        tr("UI_PNC_FactionOverlayFear"),
        relation.fear, 0, 100,
        22, 181, half,
        COLORS.warning
    )
    self:drawMetric(
        tr("UI_PNC_FactionOverlayGrievance"),
        relation.grievance, 0, 100,
        32 + half, 181, half,
        COLORS.danger
    )
end

function ISPNCFactionDebugOverlay:renderIntentPanel(
    dashboard,
    contentX,
    contentWidth
)
    self:drawPanel(contentX, 234, contentWidth, 70)
    self:drawText(
        tr("UI_PNC_FactionOverlayResolvedIntent"),
        22, 242,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    local intentTone = dashboard.intent.attackAllowed
        and COLORS.danger or COLORS.success
    self:drawBadge(
        string.upper(dashboard.intent.value),
        self.width - 142, 241, 118, intentTone
    )
    self:drawLabel(
        tr("UI_PNC_FactionOverlayRule"),
        shorten(dashboard.intent.rule, 34),
        22, 268
    )
    self:drawTextRight(
        "A=" .. tostring(dashboard.intent.attackAllowed)
            .. " P=" .. tostring(dashboard.intent.pursueAllowed)
            .. " C=" .. tostring(dashboard.intent.commandable),
        self.width - 22, 285,
        intentTone.r, intentTone.g, intentTone.b, 1,
        UIFont.Small
    )
end

return Overlay
