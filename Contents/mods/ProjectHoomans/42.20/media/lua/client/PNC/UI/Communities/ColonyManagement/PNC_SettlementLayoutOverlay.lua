local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

PNC = PNC or {}
PNC.SettlementLayoutOverlay = PNC.SettlementLayoutOverlay or {}

local Overlay = PNC.SettlementLayoutOverlay
Overlay.enabled = Overlay.enabled == true
Overlay.layers = Overlay.layers or {}

local COLORS = {
    base = { r = 0.10, g = 0.70, b = 1.00, a = 0.18 },
    barracks = { r = 0.72, g = 0.38, b = 1.00, a = 0.38 },
    farm = { r = 0.22, g = 0.92, b = 0.28, a = 0.38 },
    facility = { r = 1.00, g = 0.58, b = 0.15, a = 0.38 },
    anchor = { r = 1.00, g = 0.82, b = 0.25, a = 0.58 },
    stockpile = { r = 0.95, g = 0.82, b = 0.10, a = 0.58 },
}

local function pointRegion(x, y, z)
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    z = math.floor(tonumber(z) or 0)
    return GridRegion.normalize({ levels = {
        [z] = { rows = { [y] = { x, x } } },
    } })
end

local function addLayer(layers, region, color, kind, id, role, componentId)
    if region and GridRegion.countTiles(region) > 0 then
        layers[#layers + 1] = { region = GridRegion.normalize(region),
            color = color, kind = kind, id = id, role = role,
            componentId = componentId }
    end
end

function Overlay.BuildLayers(settlement, includeBase)
    local layers = {}
    if includeBase ~= false then
        addLayer(layers, settlement and settlement.geometry
            and settlement.geometry.region, COLORS.base, "base",
            settlement and settlement.id)
    end
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local color = COLORS[facility.definitionId] or COLORS.facility
        local hasRegion = false
        for _, component in ipairs(facility.components or {}) do
            if component.kind == "region" then hasRegion = true end
            local region = component.kind == "region" and component.region
                or pointRegion(component.x, component.y, component.z)
            addLayer(layers, region,
                component.kind == "anchor" and COLORS.anchor or color,
                "facility", facility.id, component.role, component.id)
        end
        if not hasRegion then
            addLayer(layers, facility.constructionRegion, color,
                "facility", facility.id, "facility.footprint",
                "footprint:" .. tostring(facility.id))
        end
    end
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        addLayer(layers, pointRegion(node.x, node.y, node.z),
            COLORS.stockpile, "stockpile", node.id, "stockpile.access")
    end
    return layers
end

function Overlay.SetSettlement(settlement)
    Overlay.settlementId = settlement and settlement.id or nil
    Overlay.revision = settlement and settlement.revision or nil
    Overlay.layers = Overlay.BuildLayers(settlement, true)
end

function Overlay.SetEnabled(enabled)
    Overlay.enabled = enabled == true
    return Overlay.enabled
end

function Overlay.Toggle(settlement)
    if settlement then Overlay.SetSettlement(settlement) end
    return Overlay.SetEnabled(not Overlay.enabled)
end

function Overlay.IsEnabled()
    return Overlay.enabled == true
end

function Overlay.Render()
    if not Overlay.enabled or not addAreaHighlightForPlayer then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return end
    local playerNum = player.getPlayerNum and player:getPlayerNum() or 0
    for _, layer in ipairs(Overlay.layers or {}) do
        for z, level in pairs(layer.region.levels or {}) do
            for y, spans in pairs(level.rows or {}) do
                local index
                for index = 1, #spans, 2 do
                    local color = layer.color
                    addAreaHighlightForPlayer(playerNum, spans[index], y,
                        spans[index + 1] + 1, y + 1, z,
                        color.r, color.g, color.b, color.a)
                end
            end
        end
    end
end

function Overlay.Reset()
    Overlay.enabled = false
    Overlay.layers = {}
    Overlay.settlementId = nil
    Overlay.revision = nil
end

if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Reset) end
    Overlay.eventsInstalled = true
end

return Overlay
