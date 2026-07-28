-- Named, locally extrapolated NPC journey dots for the vanilla world map.

PNC = PNC or {}
PNC.MapTravelLayer = PNC.MapTravelLayer or {}

local TravelLayer = PNC.MapTravelLayer
local Directory = PNC.TravelDirectory
local Layers = PNC.MapLayers
local Display = PNC.MapDisplay
local Icons = PNC.MapMarkerIcons

TravelLayer.Enabled = TravelLayer.Enabled ~= false
TravelLayer.DotTexture = TravelLayer.DotTexture
    or getTexture("media/ui/circle.png")

local COLORS = {
    colonist = { r = 0.15, g = 0.90, b = 0.25 },
    companion = { r = 0.15, g = 0.90, b = 0.25 },
    neutral = { r = 0.95, g = 0.75, b = 0.20 },
    hostile = { r = 1.00, g = 0.25, b = 0.20 },
}

local function colorFor(entry)
    if entry and entry.recruited == true then return COLORS.companion end
    return COLORS[tostring(entry and entry.faction or "neutral")]
        or COLORS.neutral
end

local function etaText(entry)
    local remaining = tonumber(entry and entry.remainingWorldHours)
    if not remaining then return nil end
    local hours = math.floor(remaining)
    local minutes = math.floor((remaining - hours) * 60 + 0.5)
    if hours > 0 then
        return "ETA " .. tostring(hours) .. "h " .. tostring(minutes) .. "m"
    end
    return "ETA " .. tostring(minutes) .. "m"
end

local function displayLabel(entry)
    local name = tostring(entry and entry.name or entry and entry.id or "NPC")
    local roleTag = entry and entry.roleTag
    if roleTag ~= nil and tostring(roleTag) ~= "" then
        return name .. " [" .. tostring(roleTag) .. "]"
    end
    return name
end

local function drawMarkerIcon(map, entry, sx, sy, dotSize)
    local definition = Icons and Icons.Resolve
        and Icons.Resolve(entry and entry.iconID) or nil
    local color
    local size
    if not definition then return end
    color = definition.color or { r = 0.05, g = 0.05, b = 0.05, a = 1 }
    size = math.max(dotSize, tonumber(definition.size) or dotSize)
    if definition.texture and map.drawTextureScaledAspect then
        map:drawTextureScaledAspect(
            definition.texture,
            sx - size / 2,
            sy - size / 2,
            size,
            size,
            color.a or 1,
            color.r or 1,
            color.g or 1,
            color.b or 1
        )
    elseif definition.glyph then
        map:drawTextCentre(
            definition.glyph,
            sx,
            sy - 6,
            color.r or 0.05,
            color.g or 0.05,
            color.b or 0.05,
            color.a or 1,
            UIFont.Small
        )
    end
end

local function isInsideVisibleChild(child, x, y)
    if not child then return false end
    local visible = child.getIsVisible and child:getIsVisible()
    if visible == nil then visible = child.visible ~= false end
    if not visible then return false end
    local left = tonumber(child.x)
        or child.getX and child:getX() or 0
    local top = tonumber(child.y)
        or child.getY and child:getY() or 0
    local width = tonumber(child.width)
        or child.getWidth and child:getWidth() or 0
    local height = tonumber(child.height)
        or child.getHeight and child:getHeight() or 0
    return x >= left and y >= top
        and x <= left + width and y <= top + height
end

local function isOverControls(map, x, y)
    return isInsideVisibleChild(map.symbolsUI, x, y)
        or isInsideVisibleChild(map.keyUI, x, y)
        or isInsideVisibleChild(map.buttonPanel, x, y)
        or isInsideVisibleChild(map.pncNamesButton, x, y)
end

local function drawSelectedRoute(map, entry)
    local points = entry and entry.route and entry.route.points or nil
    local i
    local from
    local to
    local x1
    local y1
    local x2
    local y2
    if type(points) ~= "table" or #points < 2
        or not map.javaObject
        or not map.javaObject.DrawLine
    then
        return
    end
    for i = 1, #points - 1 do
        from = points[i]
        to = points[i + 1]
        x1 = map.mapAPI:worldToUIX(from.x, from.y)
        y1 = map.mapAPI:worldToUIY(from.x, from.y)
        x2 = map.mapAPI:worldToUIX(to.x, to.y)
        y2 = map.mapAPI:worldToUIY(to.x, to.y)
        map.javaObject:DrawLine(
            nil,
            x1,
            y1,
            x2,
            y2,
            2,
            0.2,
            0.85,
            1,
            0.8
        )
    end
end

function TravelLayer.SetEnabled(enabled)
    TravelLayer.Enabled = enabled == true
end

function TravelLayer.Render(map)
    if not TravelLayer.Enabled or not map or not map.mapAPI then return end
    if Display and Display.EnsureButton then Display.EnsureButton(map) end
    local entries = Directory.ListProjected()
    local zoom = tonumber(map.mapAPI:getZoomF()) or 0
    local showLabels = Display and Display.AreNamesVisible
        and Display.AreNamesVisible() or false
    local dotSize = math.max(7, math.min(13, 7 + (zoom - 10) * 0.8))
    local mouseX = map:getMouseX()
    local mouseY = map:getMouseY()
    local hovered
    local i
    local entry
    local sx
    local sy
    local color
    local selected
    local half = dotSize / 2
    for i = 1, #entries do
        entry = entries[i]
        if entry.x and entry.y then
            sx = map.mapAPI:worldToUIX(entry.x, entry.y)
            sy = map.mapAPI:worldToUIY(entry.x, entry.y)
            if sx >= -dotSize and sy >= -dotSize
                and sx <= map.width + dotSize
                and sy <= map.height + dotSize
                and not isOverControls(map, sx, sy)
            then
                color = colorFor(entry)
                selected = PNC.MapCommands
                    and PNC.MapCommands.IsSelected
                    and PNC.MapCommands.IsSelected(entry.id)
                    or false
                if selected then
                    drawSelectedRoute(map, entry)
                end
                if TravelLayer.DotTexture then
                    map:drawTextureScaledAspect(
                        TravelLayer.DotTexture,
                        sx - half,
                        sy - half,
                        dotSize,
                        dotSize,
                        1,
                        color.r,
                        color.g,
                        color.b
                    )
                else
                    map:drawRect(
                        sx - half,
                        sy - half,
                        dotSize,
                        dotSize,
                        1,
                        color.r,
                        color.g,
                        color.b
                    )
                end
                map:drawRectBorder(
                    sx - half - (selected and 2 or 0),
                    sy - half - (selected and 2 or 0),
                    dotSize + (selected and 4 or 0),
                    dotSize + (selected and 4 or 0),
                    0.9,
                    selected and 0.2 or 0.05,
                    selected and 1.0 or 0.05,
                    selected and 0.2 or 0.05
                )
                drawMarkerIcon(map, entry, sx, sy, dotSize)
                if showLabels or selected then
                    map:drawTextCentre(
                        displayLabel(entry),
                        sx,
                        sy + half + 2,
                        1,
                        1,
                        1,
                        1,
                        UIFont.Small
                    )
                end
                if math.abs(mouseX - sx) <= half + 3
                    and math.abs(mouseY - sy) <= half + 3
                then
                    hovered = {
                        entry = entry,
                        x = sx,
                        y = sy,
                    }
                end
            end
        end
    end

    if hovered then
        local label = displayLabel(hovered.entry)
        local eta = etaText(hovered.entry)
        if eta then label = label .. " — " .. eta end
        local width = getTextManager():MeasureStringX(UIFont.Small, label) + 12
        local height = getTextManager():getFontHeight(UIFont.Small) + 8
        local x = math.max(
            4,
            math.min(map.width - width - 4, hovered.x - width / 2)
        )
        local y = math.max(4, hovered.y - height - 10)
        map:drawRect(x, y, width, height, 0.88, 0.05, 0.05, 0.05)
        map:drawRectBorder(x, y, width, height, 1, 0.5, 0.5, 0.5)
        map:drawTextCentre(
            label,
            x + width / 2,
            y + 4,
            1,
            1,
            1,
            1,
            UIFont.Small
        )
    end
end

Layers.Register("pnc_travel", {
    order = 100,
    isVisible = function()
        return TravelLayer.Enabled
    end,
    render = TravelLayer.Render,
})

return TravelLayer
