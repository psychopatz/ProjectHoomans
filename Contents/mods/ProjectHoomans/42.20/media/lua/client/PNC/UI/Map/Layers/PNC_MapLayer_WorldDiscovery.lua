-- Player-authorized settlement and mobile-group markers.

require "ISUI/Maps/ISWorldMap"

PNC = PNC or {}
PNC.WorldDiscoveryMapLayer = PNC.WorldDiscoveryMapLayer or {}

local Layer = PNC.WorldDiscoveryMapLayer
local State = PNC.Network.ClientState
local Types = PNC.WorldDiscoveryTypes

Layer.RefreshMs = 10000
Layer.LastRefreshAt = Layer.LastRefreshAt or 0

local COLORS = {
    settlement = { r = 0.52, g = 0.38, b = 0.92 },
    mobile_group = { r = 0.18, g = 0.68, b = 0.92 },
    rumored = { r = 0.78, g = 0.69, b = 0.30 },
}

local function visible()
    local snapshot = State.worldDiscovery
    return snapshot and #(snapshot.entities or {}) > 0
        and (not PNC.MapDisplay
            or not PNC.MapDisplay.AreBasesVisible
            or PNC.MapDisplay.AreBasesVisible())
end

local function populationNPCVisible(snapshot)
    local discovery = type(snapshot and snapshot.worldDiscovery) == "table"
        and snapshot.worldDiscovery or nil
    local generation = type(snapshot and snapshot.generation) == "table"
        and snapshot.generation or nil
    local generated = discovery
        and discovery.populationGenerated == true
        or generation
            and string.find(tostring(generation.source or ""),
                "WORLD_POPULATION_", 1, true) == 1
        or false
    if not generated then
        return true
    end
    if snapshot.recruited == true or snapshot.colonist == true then
        return true
    end
    if PNC.WorldDiscoveryDebugMap
        and PNC.WorldDiscoveryDebugMap.ShowRawEntities == true
    then
        return true
    end
    local affiliation = discovery or (
        type(snapshot.affiliation) == "table"
            and snapshot.affiliation or {}
    )
    for _, entity in ipairs(State.worldDiscovery
        and State.worldDiscovery.entities or {})
    do
        if tonumber(entity.phase) >= Types.PHASE_CONTACTED then
            if entity.kind == Types.KIND_SETTLEMENT
                and tostring(affiliation.communityID or "")
                    == tostring(entity.entityID or "")
            then
                return true
            end
            if entity.kind == Types.KIND_MOBILE_GROUP
                and entity.factionID
                and tostring(affiliation.factionID or "")
                    == tostring(entity.factionID)
            then
                return true
            end
        end
    end
    return false
end

local function colorFor(entity)
    if tonumber(entity.phase) == Types.PHASE_RUMORED then
        return COLORS.rumored
    end
    return COLORS[entity.kind] or COLORS.mobile_group
end

local function labelFor(entity)
    local label = tostring(entity.name or getText("UI_PNC_UnknownSignal"))
    if tonumber(entity.phase) == Types.PHASE_RUMORED then
        return label .. " (?)"
    end
    return label
end

local function drawDiamond(map, x, y, size, color)
    if map.javaObject and map.javaObject.DrawLine then
        map.javaObject:DrawLine(nil, x, y - size, x + size, y,
            2, color.r, color.g, color.b, 1)
        map.javaObject:DrawLine(nil, x + size, y, x, y + size,
            2, color.r, color.g, color.b, 1)
        map.javaObject:DrawLine(nil, x, y + size, x - size, y,
            2, color.r, color.g, color.b, 1)
        map.javaObject:DrawLine(nil, x - size, y, x, y - size,
            2, color.r, color.g, color.b, 1)
    else
        map:drawRect(x - size / 2, y - size / 2,
            size, size, 1, color.r, color.g, color.b)
    end
end

local function drawHover(map, entity, x, y, color)
    local lines = {
        labelFor(entity),
        tostring(entity.phaseName or "DISCOVERED"),
        entity.kind == Types.KIND_SETTLEMENT
            and "Settlement signal" or "Mobile group signal",
    }
    if entity.population then
        lines[#lines + 1] = "Population: " .. tostring(entity.population)
    end
    if entity.approximate == true then
        lines[#lines + 1] = "Position is approximate; scan again to locate."
    end
    local width = 290
    local height = 14 + #lines * 17
    x = math.max(5, math.min((map.width or 0) - width - 5, x + 12))
    y = math.max(5, math.min((map.height or 0) - height - 5, y + 12))
    map:drawRect(x, y, width, height, 0.94, 0.04, 0.04, 0.04)
    map:drawRectBorder(x, y, width, height, 1,
        color.r, color.g, color.b)
    for index, line in ipairs(lines) do
        map:drawText(line, x + 8, y + 5 + (index - 1) * 17,
            index == 1 and color.r or 0.88,
            index == 1 and color.g or 0.88,
            index == 1 and color.b or 0.88, 1, UIFont.Small)
    end
end

function Layer.FindAt(map, mouseX, mouseY, padding)
    if not map or not map.mapAPI then return nil end
    local best
    local bestDistance = tonumber(padding) or 12
    for _, entity in ipairs(State.worldDiscovery
        and State.worldDiscovery.entities or {})
    do
        if entity.x and entity.y then
            local x = map.mapAPI:worldToUIX(entity.x, entity.y)
            local y = map.mapAPI:worldToUIY(entity.x, entity.y)
            local dx, dy = mouseX - x, mouseY - y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= bestDistance then
                best, bestDistance = entity, distance
            end
        end
    end
    return best
end

function Layer.Render(map)
    if not visible() or not map or not map.mapAPI then return end
    local now = PNC.Core.Now()
    if PNC.Client and PNC.Client.RequestWorldDiscovery
        and now - (tonumber(Layer.LastRefreshAt) or 0)
            >= Layer.RefreshMs
    then
        Layer.LastRefreshAt = now
        PNC.Client.RequestWorldDiscovery("snapshot")
    end
    local mouseX, mouseY = map:getMouseX(), map:getMouseY()
    local hovered
    local hoveredColor
    for _, entity in ipairs(State.worldDiscovery.entities or {}) do
        if entity.x and entity.y then
            local x = map.mapAPI:worldToUIX(entity.x, entity.y)
            local y = map.mapAPI:worldToUIY(entity.x, entity.y)
            local dx, dy = mouseX - x, mouseY - y
            local isHovered = dx * dx + dy * dy <= 121
            local color = colorFor(entity)
            drawDiamond(map, x, y, isHovered and 9 or 7, color)
            if isHovered or PNC.MapDisplay
                and PNC.MapDisplay.AreNamesVisible
                and PNC.MapDisplay.AreNamesVisible()
            then
                map:drawTextCentre(labelFor(entity), x, y + 11,
                    color.r, color.g, color.b, 1, UIFont.Small)
            end
            if isHovered then
                hovered, hoveredColor = entity, color
            end
        end
    end
    if hovered then
        drawHover(map, hovered, mouseX, mouseY, hoveredColor)
    end
end

if PNC.MapLayers and PNC.MapLayers.Register then
    PNC.MapLayers.Register("pnc_world_discovery", {
        order = 95,
        isVisible = visible,
        render = Layer.Render,
    })
end

if PNC.TravelDirectory and PNC.TravelDirectory.RegisterVisibilityFilter then
    PNC.TravelDirectory.RegisterVisibilityFilter(
        "pnc_world_discovery",
        populationNPCVisible
    )
end

return Layer
