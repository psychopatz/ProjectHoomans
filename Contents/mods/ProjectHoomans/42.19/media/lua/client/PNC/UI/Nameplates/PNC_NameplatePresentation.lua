PNC = PNC or {}
PNC.NameplatePresentation = PNC.NameplatePresentation or {}

local Presentation = PNC.NameplatePresentation

Presentation.Layout = {
    barWidth = 60,
    barHeight = 6,
    padding = 2,
    maxDrawDistance = 22,
    floorTolerance = 1,
    heartIconSize = 16,
    heartIconGap = 2,
    nameYOffset = 152,
    barYOffset = 130,
    hpTextTopGap = 12,
    debugTextGap = 14,
    nameDebugGap = 16,
}

Presentation.Fonts = {
    name = UIFont.Small,
    hp = UIFont.Medium,
    debug = UIFont.Small,
}

local NAME_COLORS = {
    hostile = { r = 1.0, g = 0.28, b = 0.28, a = 1.0 },
    controlled = { r = 0.3, g = 1.0, b = 0.3, a = 1.0 },
    friendly = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
}

local HEALTH_COLORS = {
    healthy = { r = 0.1, g = 0.75, b = 0.15, a = 1.0 },
    injured = { r = 0.95, g = 0.8, b = 0.1, a = 1.0 },
    critical = { r = 0.8, g = 0.15, b = 0.15, a = 1.0 },
}

local heartTexture

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function ratio(current, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or 1)
    return clamp((tonumber(current) or 0) / safeMax, 0, 1)
end

function Presentation.Distance(a, b)
    if not a or not b then return 9999 end
    local dx = a:getX() - b:getX()
    local dy = a:getY() - b:getY()
    return math.sqrt((dx * dx) + (dy * dy))
end

function Presentation.HealthRatio(snapshot)
    return ratio(snapshot and snapshot.hpCurrent, snapshot and snapshot.hpMax)
end

function Presentation.StaminaRatio(snapshot)
    return ratio(snapshot and snapshot.staminaCurrent, snapshot and snapshot.staminaMax)
end

function Presentation.NameColor(snapshot)
    if snapshot and snapshot.faction == "hostile" then
        return NAME_COLORS.hostile
    end
    if snapshot and (snapshot.recruited == true or snapshot.faction == "companion") then
        return NAME_COLORS.controlled
    end
    return NAME_COLORS.friendly
end

function Presentation.HealthColor(healthRatio)
    if healthRatio >= 0.7 then return HEALTH_COLORS.healthy end
    if healthRatio >= 0.35 then return HEALTH_COLORS.injured end
    return HEALTH_COLORS.critical
end

function Presentation.IncapacitatedColor(currentTime)
    local pulse = (math.sin(currentTime / 140) + 1) * 0.5
    return {
        r = 0.35 + (0.2 * pulse),
        g = 0.03 + (0.04 * pulse),
        b = 0.03 + (0.04 * pulse),
        a = 0.8 + (0.2 * pulse),
    }
end

function Presentation.StaminaColor(staminaRatio)
    local value = 0.28 + (0.72 * clamp(tonumber(staminaRatio) or 0, 0, 1))
    return { r = value, g = value, b = value, a = 1.0 }
end

function Presentation.ShouldShowHealth(snapshot, currentTime)
    if not snapshot then return false end
    if tostring(snapshot.healthState or "") == "incapacitated" then return true end
    if snapshot.inCombat == true then return true end
    return (tonumber(snapshot.recentDamageUntil) or 0) > currentTime
end

function Presentation.ShouldShowStamina(snapshot, currentTime)
    if not snapshot then return false end
    if tostring(snapshot.healthState or "") == "incapacitated" then return true end
    if snapshot.inCombat == true then return true end
    if (tonumber(snapshot.staminaVisibleUntil) or 0) > currentTime then return true end
    return Presentation.StaminaRatio(snapshot) < 0.999
end

function Presentation.GetHeartTexture()
    if heartTexture ~= nil then return heartTexture or nil end
    heartTexture = getTexture("media/ui/Moodle_internal_plus_red.png") or getTexture("heart_on") or false
    return heartTexture or nil
end

function Presentation.ScaleFor(playerIndex)
    local zoom = getCore():getZoom(playerIndex)
    if zoom <= 0 then zoom = 1 end
    local divisor = zoom > 1 and (zoom * 1.15) or 1
    return {
        zoom = zoom,
        barWidth = Presentation.Layout.barWidth / divisor,
        barHeight = Presentation.Layout.barHeight / divisor,
        heartIconSize = Presentation.Layout.heartIconSize / divisor,
        heartIconGap = Presentation.Layout.heartIconGap / divisor,
        nameYOffset = Presentation.Layout.nameYOffset / zoom,
        barYOffset = Presentation.Layout.barYOffset / zoom,
    }
end

function Presentation.CacheTextMetric(entry, key, text, font)
    local widthKey = key .. "Width"
    if entry[key] ~= text or not entry[widthKey] then
        entry[key] = text
        entry[widthKey] = getTextManager():MeasureStringX(font, text)
    end
end

function Presentation.DrawOutlinedText(manager, text, x, y, color, alpha, font)
    if not text or text == "" then return end
    local outlineAlpha = math.min(1, (alpha or 1) * 0.95)
    manager:drawText(text, x - 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x + 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y - 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y + 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y, color.r, color.g, color.b, alpha, font)
end

return Presentation
