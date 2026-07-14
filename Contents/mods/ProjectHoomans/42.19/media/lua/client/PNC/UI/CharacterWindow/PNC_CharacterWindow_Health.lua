PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared

local bodyTextures = {}

local function bodyTexture(isFemale)
    local key = isFemale and "female" or "male"
    if bodyTextures[key] == nil then
        bodyTextures[key] = getTexture("media/ui/defense/" .. key .. "_base.png")
    end
    return bodyTextures[key]
end

function Tabs.RenderHealth(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local health = payload and payload.health or {}
    local stamina = payload and payload.stamina or {}
    local texture = bodyTexture(resolved.isFemale == true)
    local padding = 12
    local silhouetteWidth = Shared.Clamp(math.floor(view.width * 0.3), 105, 165)
    local silhouetteHeight = math.min(view.height - padding * 2, 302)
    local x = padding + silhouetteWidth + 18
    local width = math.max(130, view.width - x - padding)
    local y = topY
    local hpCurrent = tonumber(health.current or resolved.hpCurrent) or 0
    local hpMax = math.max(1, tonumber(health.max or resolved.hpMax) or 100)
    local staminaCurrent = tonumber(stamina.current or resolved.staminaCurrent) or 0
    local staminaMax = math.max(1, tonumber(stamina.max or resolved.staminaMax) or 100)
    local state = tostring(health.state or resolved.healthState or "normal")

    if texture then
        local tw = texture.getWidthOrig and texture:getWidthOrig() or texture:getWidth()
        local th = texture.getHeightOrig and texture:getHeightOrig() or texture:getHeight()
        local scale = math.min(silhouetteWidth / math.max(1, tw), silhouetteHeight / math.max(1, th))
        local drawWidth = tw * scale
        local drawHeight = th * scale
        view:drawTextureScaled(texture, padding + (silhouetteWidth - drawWidth) / 2, padding, drawWidth, drawHeight, 1, 0.88, 0.88, 0.88)
    end

    y = Shared.DrawSection(view, "Overall Body Status", x, y, width)
    y = Shared.DrawBar(view, "Health", hpCurrent, hpMax, x, y, width, { r = 0.72, g = 0.16, b = 0.16 })
    y = Shared.DrawBar(view, "Stamina", staminaCurrent, staminaMax, x, y, width, { r = 0.24, g = 0.62, b = 0.3 })
    y = y + 4
    y = Shared.DrawLabelValue(view, "Condition", state, x, y, 92)
    y = Shared.DrawLabelValue(view, "Stamina State", stamina.state or resolved.staminaState or "fresh", x, y, 92)
    y = Shared.DrawLabelValue(view, "Can Revive", resolved.canRevive == true and "Yes" or "No", x, y, 92)
    y = Shared.DrawLabelValue(view, "Recent Damage", (tonumber(health.recentDamageUntil or resolved.recentDamageUntil) or 0) > 0 and "Recorded" or "None", x, y, 92)

    y = y + 8
    y = Shared.DrawSection(view, "Medical Summary", x, y, width)
    if state == "incapacitated" then
        view:drawText("Incapacitated", x, y, 0.95, 0.36, 0.31, 1, UIFont.Medium)
        y = y + getTextManager():getFontHeight(UIFont.Medium) + 5
        view:drawText("Reason: " .. tostring(health.incapacitatedReason or "critical injury"), x, y, 0.82, 0.82, 0.82, 1, UIFont.Small)
        y = y + getTextManager():getFontHeight(UIFont.Small) + 6
        view:drawText("Use the Revive interaction while in range.", x, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + getTextManager():getFontHeight(UIFont.Small) + 6
    elseif state == "dead" then
        view:drawText("No vital signs", x, y, 0.95, 0.36, 0.31, 1, UIFont.Medium)
        y = y + getTextManager():getFontHeight(UIFont.Medium) + 8
    else
        view:drawText("No active incapacitation or critical wound state.", x, y, 0.75, 0.75, 0.75, 1, UIFont.Small)
        y = y + getTextManager():getFontHeight(UIFont.Small) + 8
    end

    return math.max(y, padding + silhouetteHeight) + 12
end

return Tabs
