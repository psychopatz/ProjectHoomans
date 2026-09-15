-- Shared configuration and helpers for the faction debug overlay.

PNC = PNC or {}
PNC.FactionDebugOverlay = PNC.FactionDebugOverlay or {}

local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal or {}
Overlay._Internal = Internal

Internal.WIDTH = 430
Internal.HEIGHT = 492
Internal.REQUEST_INTERVAL = 1000
Internal.RELATIONSHIP_CHANGE_VISIBLE_MS = 12000

Internal.COLORS = {
    background = { r = 0.025, g = 0.035, b = 0.045 },
    panel = { r = 0.065, g = 0.08, b = 0.095 },
    border = { r = 0.22, g = 0.66, b = 0.76 },
    text = { r = 0.90, g = 0.94, b = 0.96 },
    muted = { r = 0.56, g = 0.64, b = 0.69 },
    success = { r = 0.25, g = 0.78, b = 0.43 },
    warning = { r = 0.94, g = 0.67, b = 0.22 },
    danger = { r = 0.94, g = 0.25, b = 0.22 },
    neutral = { r = 0.35, g = 0.62, b = 0.80 },
}

Internal.Model = PNC.FactionDebugModel
Internal.ClientState = PNC.Network.ClientState

Internal.tr = function(key)
    return getText and PNC.Translation.GetKey(key) or key
end

Internal.shorten = function(value, maximum)
    return Internal.Model.ShortenID(value, maximum)
end

Internal.stateTone = function(relation, generatedAt)
    if relation.atWar then return Internal.COLORS.danger end
    if relation.allied then return Internal.COLORS.success end
    if relation.truceUntil > (tonumber(generatedAt) or 0) then
        return Internal.COLORS.warning
    end
    return Internal.COLORS.neutral
end

Internal.statusText = function(relation, generatedAt)
    if relation.atWar then
        return Internal.tr("UI_PNC_FactionOverlayWar")
    end
    if relation.allied then
        return Internal.tr("UI_PNC_FactionOverlayAllied")
    end
    local remaining = math.max(
        0,
        (tonumber(relation.truceUntil) or 0)
            - (tonumber(generatedAt) or 0)
    )
    if remaining > 0 then
        return Internal.tr("UI_PNC_FactionOverlayTruce")
            .. " " .. string.format("%.1fh", remaining)
    end
    return string.upper(tostring(relation.state or "unknown"))
end

return Internal
