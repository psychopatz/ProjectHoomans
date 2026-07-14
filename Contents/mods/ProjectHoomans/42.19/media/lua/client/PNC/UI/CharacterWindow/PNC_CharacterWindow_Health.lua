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

local function drawBody(view, texture, x, y, width, height)
    if not texture then return { x = x, y = y, width = width, height = height } end
    local textureWidth = texture.getWidthOrig and texture:getWidthOrig() or texture:getWidth()
    local textureHeight = texture.getHeightOrig and texture:getHeightOrig() or texture:getHeight()
    local scale = math.min(width / math.max(1, textureWidth), height / math.max(1, textureHeight))
    local drawWidth = textureWidth * scale
    local drawHeight = textureHeight * scale
    local bounds = {
        x = x + (width - drawWidth) / 2,
        y = y,
        width = drawWidth,
        height = drawHeight,
    }
    view:drawTextureScaled(texture, bounds.x, bounds.y, drawWidth, drawHeight, 1, 0.88, 0.88, 0.88)
    return bounds
end

local function markerColor(wound)
    if wound.bandaged == true then return 0.26, 0.72, 0.34 end
    if wound.type == "bite" then return 0.88, 0.12, 0.12 end
    if wound.type == "laceration" then return 0.95, 0.43, 0.12 end
    return 0.92, 0.78, 0.18
end

local function drawWoundMarkers(view, bodyBounds, wounds)
    local parts = PNC.NPCWounds and PNC.NPCWounds.Parts or {}
    local partId
    local wound
    local part
    for partId, wound in pairs(wounds or {}) do
        part = parts[partId]
        if part then
            local r, g, b = markerColor(wound)
            local size = wound.type == "bite" and 10 or 8
            local x = bodyBounds.x + bodyBounds.width * part.x - size / 2
            local y = bodyBounds.y + bodyBounds.height * part.y - size / 2
            view:drawRect(x, y, size, size, 0.95, r, g, b)
            view:drawRectBorder(x, y, size, size, 1, 0.1, 0.1, 0.1)
        end
    end
end

local function sortedWounds(wounds)
    local rows = {}
    local parts = PNC.NPCWounds and PNC.NPCWounds.Parts or {}
    local partId
    local wound
    for partId, wound in pairs(wounds or {}) do
        rows[#rows + 1] = {
            partId = partId,
            label = parts[partId] and parts[partId].label or tostring(partId),
            wound = wound,
        }
    end
    table.sort(rows, function(left, right) return left.label < right.label end)
    return rows
end

function Tabs.RenderHealth(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local payloadHealth = payload and payload.health or {}
    local health = {
        current = resolved.hpCurrent or payloadHealth.current,
        max = resolved.hpMax or payloadHealth.max,
        state = resolved.healthState or payloadHealth.state,
        incapacitatedReason = payloadHealth.incapacitatedReason,
    }
    local stamina = payload and payload.stamina or {}
    local body = resolved.bodyHealth or payloadHealth.body or {}
    local wounds = body.wounds or {}
    local rows = sortedWounds(wounds)
    local texture = bodyTexture(resolved.isFemale == true)
    local padding = 12
    local silhouetteWidth = Shared.Clamp(math.floor(view.width * 0.31), 112, 170)
    local silhouetteHeight = math.min(315, math.max(220, view.height - padding * 2))
    local bodyBounds = drawBody(view, texture, padding, padding, silhouetteWidth, silhouetteHeight)
    local x = padding + silhouetteWidth + 18
    local width = math.max(150, view.width - x - padding)
    local y = topY
    local hpCurrent = tonumber(health.current) or 0
    local hpMax = math.max(1, tonumber(health.max) or 100)
    local state = tostring(health.state or "normal")
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local i

    drawWoundMarkers(view, bodyBounds, wounds)

    y = Shared.DrawSection(view, "Overall Body Status", x, y, width)
    y = Shared.DrawBar(view, "Health", hpCurrent, hpMax, x, y, width, { r = 0.72, g = 0.16, b = 0.16 })
    if stamina.current ~= nil then
        y = Shared.DrawBar(view, "Stamina", stamina.current, math.max(1, tonumber(stamina.max) or 100), x, y, width, { r = 0.24, g = 0.62, b = 0.3 })
    end
    y = Shared.DrawLabelValue(view, "Condition", state, x, y + 2, 92)
    y = Shared.DrawLabelValue(view, "Open Wounds", body.openWoundCount or 0, x, y, 92)
    y = Shared.DrawLabelValue(view, "Bandaged", body.bandagedWoundCount or 0, x, y, 92)
    y = Shared.DrawLabelValue(view, "Bleeding", (tonumber(body.bleedingRate) or 0) > 0 and "Active" or "Controlled", x, y, 92)

    if body.infection and (body.infection.active == true or body.infection.fatal == true) then
        y = y + 4
        view:drawText("Knox Infection", x, y, 0.92, 0.24, 0.2, 1, UIFont.Medium)
        y = y + getTextManager():getFontHeight(UIFont.Medium) + 5
        local source = PNC.NPCWounds and PNC.NPCWounds.Parts and body.infection.sourcePart
            and PNC.NPCWounds.Parts[body.infection.sourcePart] or nil
        y = Shared.DrawLabelValue(view, "Bite Location", source and source.label or body.infection.sourcePart or "Unknown", x, y, 92)
        y = Shared.DrawLabelValue(view, "Outcome", body.infection.fatal == true and "Reanimating" or "Terminal", x, y, 92)
    end

    y = y + 7
    y = Shared.DrawSection(view, "Injuries", x, y, width)
    if #rows == 0 then
        view:drawText("No body-part injuries.", x, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 8
    else
        for i = 1, #rows do
            local row = rows[i]
            local wound = row.wound
            local status = wound.bandaged == true and "Bandaged" or "Bleeding"
            local label = row.label .. " - " .. string.upper(string.sub(tostring(wound.type or "wound"), 1, 1))
                .. string.sub(tostring(wound.type or "wound"), 2)
            view:drawText(PsychopatzCore.UI.Layout.Ellipsize(label, UIFont.Small, width - 78), x, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
            view:drawTextRight(status, x + width, y, wound.bandaged and 0.35 or 0.92, wound.bandaged and 0.76 or 0.38, 0.35, 1, UIFont.Small)
            y = y + fontHeight + 5
        end
    end

    if state == "incapacitated" then
        y = y + 6
        view:drawText("Incapacitated - " .. tostring(health.incapacitatedReason or "critical injury"), x, y, 0.95, 0.36, 0.31, 1, UIFont.Small)
        y = y + fontHeight + 6
        view:drawText("Revival bandages all current bleeding wounds.", x, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 6
    end

    return math.max(y, padding + silhouetteHeight) + 12
end

return Tabs
