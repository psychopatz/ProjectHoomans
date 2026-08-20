local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

PNC = PNC or {}
PNC.SettlementLayoutOverlay = PNC.SettlementLayoutOverlay or {}

local Overlay = PNC.SettlementLayoutOverlay
Overlay.enabled = Overlay.enabled == true
Overlay.layers = Overlay.layers or {}
Overlay.markers = Overlay.markers or {}
Overlay.textureCache = Overlay.textureCache or {}

local COLORS = {
    -- Territory is context only. Keep it visible without washing out rooms,
    -- construction state, or point components above it.
    base = { r = 0.10, g = 0.70, b = 1.00, a = 0.06 },
    barracks = { r = 0.72, g = 0.38, b = 1.00, a = 0.38 },
    farm = { r = 0.22, g = 0.92, b = 0.28, a = 0.38 },
    research_facility = { r = 0.16, g = 0.72, b = 1.00, a = 0.38 },
    facility = { r = 1.00, g = 0.58, b = 0.15, a = 0.38 },
    anchor = { r = 1.00, g = 0.82, b = 0.25, a = 0.58 },
    stockpile = { r = 0.95, g = 0.82, b = 0.10, a = 0.58 },
    construction = { r = 1.00, g = 0.54, b = 0.08, a = 0.34 },
    deconstruction = { r = 1.00, g = 0.18, b = 0.12, a = 0.32 },
}

local function facilityColor(facility, color)
    local state = tostring(facility.constructionState
        or facility.cachedState or "BUILT")
    if state == "UNDER_CONSTRUCTION" or state == "RECONSTRUCTING" then
        return COLORS.construction
    end
    if state == "DECONSTRUCTING" then return COLORS.deconstruction end
    if state == "PLANNED" then
        return { r = color.r * 0.65, g = color.g * 0.65,
            b = color.b * 0.65, a = 0.13 }
    end
    -- Completed building/room areas stay deliberately dark so beds, stations,
    -- stockpile nodes, and other anchor components remain visually dominant.
    return { r = color.r * 0.45, g = color.g * 0.45,
        b = color.b * 0.45, a = 0.14 }
end

local ROOM_PLACEHOLDER = "media/ui/Facilities/BuildingMenu/livingRoom.png"
local COMPONENT_PLACEHOLDERS = {
    ["sleep.area"] = "media/ui/Facilities/Components/chair.png",
    ["sleep.bed"] = "media/ui/Facilities/Components/bed/barracks.png",
    ["farm.field"] = "media/ui/Facilities/Components/default.png",
    ["work.research"] =
        "media/ui/Facilities/Components/research_station/research_station.png",
    ["work.blueprint"] =
        "media/ui/Facilities/Components/research_station/architect_table.png",
    ["work.reverse"] =
        "media/ui/Facilities/Components/research_station/Lab_Station.png",
    ["work.craft"] =
        "media/ui/Facilities/Components/workshop/workbench.png",
    ["work.disassemble"] =
        "media/ui/Facilities/Components/workshop/recycling_bench.png",
    ["water.spigot"] =
        "media/ui/Facilities/Components/water_station/pump_spigot.png",
    ["water.tank"] = "media/ui/Facilities/Components/default.png",
    ["water.catcher"] = "media/ui/Facilities/Components/default.png",
    ["stockpile.access"] = "media/ui/Facilities/Components/storage/stockpile.png",
}

local function regionCenter(region)
    local count, sumX, sumY, sumZ = 0, 0, 0, 0
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            local index
            for index = 1, #spans, 2 do
                local first = tonumber(spans[index]) or 0
                local last = tonumber(spans[index + 1]) or first
                local width = math.max(0, last - first + 1)
                count = count + width
                sumX = sumX + ((first + last) * width / 2)
                sumY = sumY + (tonumber(y) or 0) * width
                sumZ = sumZ + (tonumber(z) or 0) * width
            end
        end
    end
    if count <= 0 then return nil end
    return { x = sumX / count + 0.5, y = sumY / count + 0.5,
        z = sumZ / count }
end

local function addMarker(markers, point, kind, id, role, texturePath, tileScale)
    if not point then return end
    markers[#markers + 1] = {
        x = point.x, y = point.y, z = point.z,
        kind = kind, id = id, role = role,
        texturePath = texturePath, tileScale = tileScale or 1,
    }
end

local function facilityIcon(facility)
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility.definitionId) or nil
    return definition and definition.iconPath or ROOM_PLACEHOLDER
end

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
        local sourceColor = COLORS[facility.definitionId] or COLORS.facility
        local color = facilityColor(facility, sourceColor)
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

function Overlay.BuildMarkers(settlement)
    local markers = {}
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local hasRoom = false
        local roomIcon = facilityIcon(facility)
        for _, component in ipairs(facility.components or {}) do
            if component.kind == "region" then
                hasRoom = true
                addMarker(markers, regionCenter(component.region), "room",
                    facility.id, component.role, roomIcon, 1)
            elseif component.kind == "anchor" then
                addMarker(markers, {
                    x = (tonumber(component.x) or 0) + 0.5,
                    y = (tonumber(component.y) or 0) + 0.5,
                    z = tonumber(component.z) or 0,
                }, "component", component.id, component.role,
                    COMPONENT_PLACEHOLDERS[component.role]
                        or "media/ui/Emotes/PNC_EmoteMenu.png", 1)
            end
        end
        if not hasRoom then
            addMarker(markers, regionCenter(facility.constructionRegion),
                "room", facility.id, "facility.footprint", roomIcon, 1)
        end
    end
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        addMarker(markers, {
            x = (tonumber(node.x) or 0) + 0.5,
            y = (tonumber(node.y) or 0) + 0.5,
            z = tonumber(node.z) or 0,
        }, "component", node.id, "stockpile.access",
            COMPONENT_PLACEHOLDERS["stockpile.access"], 1)
    end
    return markers
end

function Overlay.SetSettlement(settlement)
    Overlay.settlementId = settlement and settlement.id or nil
    Overlay.revision = settlement and settlement.revision or nil
    Overlay.layers = Overlay.BuildLayers(settlement, true)
    Overlay.markers = Overlay.BuildMarkers(settlement)
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

local function markerTexture(path)
    local cached = Overlay.textureCache[path]
    if cached ~= nil then return cached ~= false and cached or nil end
    cached = getTexture and getTexture(path) or nil
    Overlay.textureCache[path] = cached or false
    return cached
end

local function iconDrawer(playerNum)
    if not ISUIElement or not ISUIElement.new
        or not getPlayerScreenLeft or not getPlayerScreenTop
    then return nil end
    local x, y = getPlayerScreenLeft(playerNum), getPlayerScreenTop(playerNum)
    local width = getPlayerScreenWidth(playerNum)
    local height = getPlayerScreenHeight(playerNum)
    local drawer = Overlay.iconDrawer
    if not drawer then
        drawer = ISUIElement:new(x, y, width, height)
        if drawer.initialise then drawer:initialise() end
        drawer:setCapture(false)
        Overlay.iconDrawer = drawer
    else
        drawer:setX(x); drawer:setY(y)
        drawer:setWidth(width); drawer:setHeight(height)
    end
    return drawer
end

local function renderMarkers(playerNum)
    if not isoToScreenX or not isoToScreenY then return end
    local drawer = iconDrawer(playerNum)
    if not drawer or not drawer.drawTextureScaledAspect then return end
    for _, marker in ipairs(Overlay.markers or {}) do
        local texture = markerTexture(marker.texturePath)
        if texture then
            local screenX = isoToScreenX(playerNum,
                marker.x, marker.y, marker.z) - drawer.x
            local screenY = isoToScreenY(playerNum,
                marker.x, marker.y, marker.z) - drawer.y
            local xStep = math.abs(isoToScreenX(playerNum,
                marker.x + 1, marker.y, marker.z)
                - isoToScreenX(playerNum, marker.x, marker.y, marker.z))
            local yStep = math.abs(isoToScreenX(playerNum,
                marker.x, marker.y + 1, marker.z)
                - isoToScreenX(playerNum, marker.x, marker.y, marker.z))
            local tileWidth = math.max(16, 2 * math.max(xStep, yStep))
            local size = tileWidth * (tonumber(marker.tileScale) or 1)
            if screenX >= -size and screenY >= -size
                and screenX <= drawer.width + size
                and screenY <= drawer.height + size
            then
                drawer:drawTextureScaledAspect(texture,
                    screenX - size / 2, screenY - size / 2,
                    size, size, 0.92, 1, 1, 1)
            end
        end
    end
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
    renderMarkers(playerNum)
end

function Overlay.Reset()
    Overlay.enabled = false
    Overlay.layers = {}
    Overlay.markers = {}
    Overlay.settlementId = nil
    Overlay.revision = nil
end

if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Reset) end
    Overlay.eventsInstalled = true
end

return Overlay
