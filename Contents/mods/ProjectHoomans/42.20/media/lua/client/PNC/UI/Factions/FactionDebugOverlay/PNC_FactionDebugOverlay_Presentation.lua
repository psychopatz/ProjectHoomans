-- Drawing primitives for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local COLORS = Internal.COLORS
local tr = Internal.tr
local shorten = Internal.shorten

function ISPNCFactionDebugOverlay:initialise()
    ISUIElement.initialise(self)
end

function ISPNCFactionDebugOverlay:drawLabel(
    label,
    value,
    x,
    y,
    valueColor
)
    local muted = COLORS.muted
    local color = valueColor or COLORS.text
    self:drawText(
        tostring(label), x, y,
        muted.r, muted.g, muted.b, 1,
        UIFont.Small
    )
    self:drawText(
        tostring(value), x + 122, y,
        color.r, color.g, color.b, 1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:drawBadge(
    label,
    x,
    y,
    width,
    color
)
    self:drawRect(
        x, y, width, 22,
        0.84, color.r, color.g, color.b
    )
    self:drawRectBorder(
        x, y, width, 22,
        1, color.r, color.g, color.b
    )
    self:drawTextCentre(
        tostring(label),
        x + width / 2,
        y + 4,
        1, 1, 1, 1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:drawMetric(
    label,
    value,
    minimum,
    maximum,
    x,
    y,
    width,
    color
)
    local number = tonumber(value) or 0
    local span = math.max(1, maximum - minimum)
    local ratio = math.max(
        0, math.min(1, (number - minimum) / span)
    )
    self:drawText(
        tostring(label),
        x, y,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tostring(math.floor(number * 10 + 0.5) / 10),
        x + width,
        y,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    local barY = y + 15
    self:drawRect(
        x, barY, width, 8,
        0.90, 0.08, 0.09, 0.10
    )
    self:drawRect(
        x + 1, barY + 1,
        math.max(0, (width - 2) * ratio), 6,
        0.94, color.r, color.g, color.b
    )
    self:drawRectBorder(
        x, barY, width, 8,
        0.80, 0.32, 0.38, 0.42
    )
end

function ISPNCFactionDebugOverlay:drawPanel(x, y, width, height)
    self:drawRect(
        x, y, width, height,
        0.90,
        COLORS.panel.r,
        COLORS.panel.g,
        COLORS.panel.b
    )
    self:drawRectBorder(
        x, y, width, height,
        0.70, 0.18, 0.25, 0.29
    )
end

function ISPNCFactionDebugOverlay:renderWaiting(dashboard)
    self:drawTextCentre(
        tr("UI_PNC_FactionOverlayWaiting"),
        self.width / 2,
        70,
        COLORS.warning.r,
        COLORS.warning.g,
        COLORS.warning.b,
        1,
        UIFont.Medium
    )
    self:drawTextCentre(
        tostring(dashboard.status or "waiting"),
        self.width / 2,
        98,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
end

return Overlay
