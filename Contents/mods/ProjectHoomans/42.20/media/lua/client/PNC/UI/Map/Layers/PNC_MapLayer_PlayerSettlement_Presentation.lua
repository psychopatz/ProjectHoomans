-- Presentation helpers for the player settlement map layer.

PNC = PNC or {}
PNC.PlayerSettlementMapPresentation =
    PNC.PlayerSettlementMapPresentation or {}

local Presentation = PNC.PlayerSettlementMapPresentation
local EmblemRenderer = PNC.FactionEmblemRenderer

local function text(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

local function numericBounds(bounds)
    if type(bounds) ~= "table" then return nil end
    local minX, minY = tonumber(bounds.minX), tonumber(bounds.minY)
    local maxX, maxY = tonumber(bounds.maxX), tonumber(bounds.maxY)
    if not minX or not minY or not maxX or not maxY
        or minX > maxX or minY > maxY
    then
        return nil
    end
    return minX, minY, maxX, maxY
end

function Presentation.Name(snapshot, settlement)
    local colony = snapshot and snapshot.colony or nil
    local faction = snapshot and snapshot.faction or nil
    return tostring(settlement and settlement.name
        or colony and colony.name
        or faction and faction.name
        or text("UI_PNC_MapPlayerSettlement_Label", "Home Base"))
end

local function details(snapshot, settlement)
    local colony = snapshot and snapshot.colony or {}
    local faction = snapshot and snapshot.faction or {}
    local territory = settlement and settlement.territory or {}
    local geometry = settlement and settlement.geometry or {}
    local bounds = geometry.bounds or {}
    local minX, minY, maxX, maxY = numericBounds(bounds)
    local population = colony.currentPopulation
        or snapshot and snapshot.people and #snapshot.people or 0
    local coordinates = minX and tostring(minX) .. ", " .. tostring(minY)
        .. " - " .. tostring(maxX) .. ", " .. tostring(maxY)
        or text("UI_PNC_MapPlayerSettlement_Unknown", "Unknown")
    return {
        Presentation.Name(snapshot, settlement),
        text("UI_PNC_MapPlayerSettlement_Status", "YOUR SETTLEMENT"),
        text("UI_PNC_MapPlayerSettlement_HQ", "HQ LEVEL") .. ": "
            .. tostring(settlement and settlement.hqLevel or 1),
        text("UI_PNC_MapPlayerSettlement_Coverage", "COVERAGE") .. ": "
            .. tostring(territory.claimedArea or geometry.tileCount or 0)
            .. " / " .. tostring(territory.territoryCapacity or 0),
        text("UI_PNC_MapPlayerSettlement_Population", "POPULATION") .. ": "
            .. tostring(population),
        text("UI_PNC_MapPlayerSettlement_Facilities", "FACILITIES") .. ": "
            .. tostring(#(settlement and settlement.facilities or {})),
        text("UI_PNC_MapPlayerSettlement_Stockpile", "STOCKPILE NODES") .. ": "
            .. tostring(#(settlement and settlement.stockpileNodes or {})),
        text("UI_PNC_MapPlayerSettlement_Coordinates", "COORDINATES") .. ": "
            .. coordinates,
        faction.name and text("UI_PNC_MapPlayerSettlement_Faction", "FACTION")
            .. ": " .. tostring(faction.name) or nil,
    }
end

function Presentation.DrawHover(map, snapshot, settlement, mouseX, mouseY, color)
    local sourceLines = details(snapshot, settlement)
    local lines = {}
    local index
    for index = 1, #sourceLines do
        if sourceLines[index] then lines[#lines + 1] = sourceLines[index] end
    end
    local emblem = snapshot and snapshot.faction
        and snapshot.faction.emblem or nil
    local manager = getTextManager and getTextManager() or nil
    local lineHeight = manager and manager.getFontHeight
        and manager:getFontHeight(UIFont.Small) or 14
    local padding, emblemSize = 9, 52
    local infoWidth = 170
    for index = 1, #lines do
        local measured = manager and manager.MeasureStringX
            and manager:MeasureStringX(UIFont.Small, lines[index])
            or #lines[index] * 7
        infoWidth = math.max(infoWidth, measured + padding * 2)
    end
    local height = math.max(lineHeight * #lines + 14, emblemSize + 12)
    local width = emblemSize + 12 + infoWidth
    local x = math.min((map.width or 0) - width - 5, mouseX + 12)
    local y = math.min((map.height or 0) - height - 5, mouseY + 12)
    x, y = math.max(5, x), math.max(5, y)
    map:drawRect(x, y, width, height, 0.94, 0.04, 0.04, 0.04)
    map:drawRectBorder(x, y, width, height, 1,
        color.r, color.g, color.b)
    map:drawRect(x + emblemSize + 12, y + 1, 1, height - 2,
        0.72, color.r, color.g, color.b)
    if emblem and EmblemRenderer and EmblemRenderer.Draw then
        EmblemRenderer.Draw(map, emblem, x + 6,
            y + (height - emblemSize) / 2, emblemSize, { border = true })
    end
    local infoX = x + emblemSize + 12 + padding
    for index = 1, #lines do
        local shade = index == 1 and 1 or 0.82
        map:drawText(lines[index], infoX,
            y + 5 + (index - 1) * lineHeight,
            shade, shade, shade, 1, UIFont.Small)
    end
end

return Presentation
