-- Owns the world highlights shown by the command-hub zone editor.
--
-- The selector is a temporary input overlay. This manager is the persistent
-- display layer for the currently opened zone child, so switching lumber,
-- corpse haul, and fishing cannot leave stale highlights behind.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.ZoneOverlay = PNC.CommandHub.ZoneOverlay or {}

local Overlay = PNC.CommandHub.ZoneOverlay
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Overlay.activeDefinitionID = Overlay.activeDefinitionID or nil
Overlay.zone = Overlay.zone or nil
Overlay.OWNER = Overlay.OWNER or "ProjectHoomans.CommandHub.Zone"

local LUMBER_COLOR = { r = 0.20, g = 1.00, b = 0.28, a = 0.24 }
local CORPSE_SOURCE_COLOR = { r = 1.00, g = 0.62, b = 0.12, a = 0.28 }
local CORPSE_DESTINATION_COLOR = { r = 0.18, g = 0.82, b = 1.00, a = 0.28 }
local CORPSE_CONFLICT_COLOR = { r = 1.00, g = 0.12, b = 0.08, a = 0.62 }

local function fishingOverlay()
    -- Resolve lazily so providers can load this manager before the fishing
    -- renderer without creating a permanent load-order dependency.
    return PNC.FishingZoneOverlay
end

local function selectorOwnsWorldInput()
    local ui = PsychopatzCore and PsychopatzCore.UI or nil
    local selector = ui and ui.GridRegionSelector or nil
    if not selector then return false end
    if selector.IsWorldInputOwned then
        return selector.IsWorldInputOwned() == true
    end
    return selector.instance ~= nil
end

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then return PNC.Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function renderRegion(playerNum, region, color)
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                addAreaHighlightForPlayer(playerNum, spans[index], y,
                    spans[index + 1] + 1, y + 1, z,
                    color.r, color.g, color.b, color.a)
            end
        end
    end
end

function Overlay.SetActive(definitionID, zone)
    Overlay.activeDefinitionID = tostring(definitionID or "")
    Overlay.zone = type(zone) == "table" and copy(zone) or nil
    Overlay.corpseOverlap = nil
    if Overlay.activeDefinitionID == "corpse_haul" and Overlay.zone
        and Overlay.zone.sourceRegion and Overlay.zone.destinationRegion
        and type(GridRegion.intersection) == "function"
        and type(GridRegion.countTiles) == "function"
    then
        local overlap = GridRegion.intersection(
            Overlay.zone.sourceRegion, Overlay.zone.destinationRegion)
        if GridRegion.countTiles(overlap) > 0 then
            Overlay.corpseOverlap = overlap
        end
    end
    local fishing = fishingOverlay()

    if Overlay.activeDefinitionID == "fishing" then
        if fishing and fishing.SetZone and Overlay.zone then
            return fishing.SetZone(Overlay.zone, Overlay.OWNER)
        end
        if fishing and fishing.Clear then
            fishing.Clear(Overlay.OWNER)
        end
        return false
    end

    -- Fishing has its own renderer because it also draws shoreline spots.
    -- Clear only the instance owned by this manager; another map command may
    -- be using the shared fishing overlay at the same time.
    if fishing and fishing.Clear then
        fishing.Clear(Overlay.OWNER)
    end
    return Overlay.zone ~= nil
end

function Overlay.Clear()
    Overlay.activeDefinitionID = nil
    Overlay.zone = nil
    Overlay.corpseOverlap = nil
    local fishing = fishingOverlay()
    if fishing and fishing.Clear then
        fishing.Clear(Overlay.OWNER)
    end
end

function Overlay.IsActive(definitionID)
    return Overlay.activeDefinitionID == tostring(definitionID or "")
end

function Overlay.Render()
    if selectorOwnsWorldInput()
        or not Overlay.zone or not addAreaHighlightForPlayer
    then return end
    if Overlay.activeDefinitionID == "fishing" then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return end
    local playerNum = player.getPlayerNum and player:getPlayerNum() or 0

    if Overlay.activeDefinitionID == "lumber" then
        renderRegion(playerNum, Overlay.zone.geometry, LUMBER_COLOR)
    elseif Overlay.activeDefinitionID == "corpse_haul" then
        local sourceRegion = Overlay.zone.sourceRegion
        local destinationRegion = Overlay.zone.destinationRegion
        if Overlay.corpseOverlap and type(GridRegion.subtract) == "function" then
            renderRegion(playerNum,
                GridRegion.subtract(sourceRegion, Overlay.corpseOverlap),
                CORPSE_SOURCE_COLOR)
            renderRegion(playerNum,
                GridRegion.subtract(destinationRegion, Overlay.corpseOverlap),
                CORPSE_DESTINATION_COLOR)
            renderRegion(playerNum, Overlay.corpseOverlap,
                CORPSE_CONFLICT_COLOR)
        else
            renderRegion(playerNum, sourceRegion, CORPSE_SOURCE_COLOR)
            renderRegion(playerNum, destinationRegion,
                CORPSE_DESTINATION_COLOR)
        end
    end
end

if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Clear) end
    Overlay.eventsInstalled = true
end

return Overlay
