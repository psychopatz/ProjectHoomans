-- Persistent in-world fishing-zone visualization. This is intentionally
-- separate from the settlement layout overlay because a fishing zone may be
-- outside the base territory and is valid only after shoreline validation.

PNC = PNC or {}
PNC.FishingZoneOverlay = PNC.FishingZoneOverlay or {}

local Overlay = PNC.FishingZoneOverlay
Overlay.enabled = Overlay.enabled == true
Overlay.zone = Overlay.zone or nil
Overlay.owner = Overlay.owner or nil

local ZONE_COLOR = { r = 0.12, g = 0.95, b = 0.35, a = 0.13 }
local SPOT_COLOR = { r = 0.30, g = 1.00, b = 0.55, a = 0.52 }

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then return PNC.Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
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

function Overlay.SetZone(zone, owner)
    if type(zone) ~= "table" or zone.valid ~= true
        or type(zone.geometry) ~= "table"
    then
        return false
    end
    Overlay.zone = copy(zone)
    Overlay.enabled = true
    Overlay.owner = owner or "external"
    return true
end

function Overlay.Clear(owner)
    if owner ~= nil and Overlay.owner ~= nil and Overlay.owner ~= owner then
        return false
    end
    Overlay.zone = nil
    Overlay.enabled = false
    Overlay.owner = nil
    return true
end

function Overlay.IsEnabled()
    return Overlay.enabled == true and Overlay.zone ~= nil
end

function Overlay.Render()
    if not Overlay.IsEnabled() or not addAreaHighlightForPlayer then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return end
    local playerNum = player.getPlayerNum and player:getPlayerNum() or 0
    renderRegion(playerNum, Overlay.zone.geometry, ZONE_COLOR)
    for _, spot in ipairs(Overlay.zone.fishingSpots or {}) do
        local x, y, z = math.floor(tonumber(spot.standX) or 0),
            math.floor(tonumber(spot.standY) or 0), tonumber(spot.standZ) or 0
        addAreaHighlightForPlayer(playerNum, x, y, x + 1, y + 1, z,
            SPOT_COLOR.r, SPOT_COLOR.g, SPOT_COLOR.b, SPOT_COLOR.a)
    end
end

if Overlay.eventsInstalled ~= true then
    if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(Overlay.Render) end
    if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(Overlay.Clear) end
    Overlay.eventsInstalled = true
end

return Overlay
