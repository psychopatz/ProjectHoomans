-- Ephemeral, session-local world town & modded-map discovery catalog.
-- Lazily discovers all loaded towns/districts from:
--   1) IsoMetaGrid named zones (vanilla + any modded map TownZone/named zones)
--   2) getWorld():getMap() active map folder list (catches modded maps whose
--      zones have generic/empty names, e.g. RavenCreek -> "Raven Creek")
--   3) Vanilla Knox County coordinate bounds as a lightweight fallback.
-- Zero ModData persistence, zero per-tick cost, O(1) lookup after first scan.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.WorldMapTownCatalog or {}
PNC.ConvoEngine.WorldMapTownCatalog = Catalog

Catalog.VERSION = 1

local VANILLA_TOWNS = {
    { id = "louisville",     name = "Louisville",     x1 = 11900, y1 = 1100,  x2 = 14800, y2 = 4200 },
    { id = "west_point",     name = "West Point",     x1 = 10700, y1 = 6500,  x2 = 12300, y2 = 7500 },
    { id = "valley_station", name = "Valley Station", x1 = 12300, y1 = 4200,  x2 = 14600, y2 = 6500 },
    { id = "muldraugh",      name = "Muldraugh",      x1 = 10400, y1 = 8700,  x2 = 11100, y2 = 10700 },
    { id = "march_ridge",    name = "March Ridge",    x1 = 9700,  y1 = 12500, x2 = 10500, y2 = 13400 },
    { id = "rosewood",       name = "Rosewood",       x1 = 7900,  y1 = 11100, x2 = 8600,  y2 = 12000 },
    { id = "riverside",      name = "Riverside",      x1 = 5900,  y1 = 5100,  x2 = 6900,  y2 = 5800 },
    { id = "fall_lake",      name = "Fall Lake",      x1 = 7000,  y1 = 8100,  x2 = 7600,  y2 = 8600 },
    { id = "brandenburg",    name = "Brandenburg",    x1 = 1800,  y1 = 5600,  x2 = 3400,  y2 = 6800 },
    { id = "ekron",          name = "Ekron",          x1 = 400,   y1 = 9200,  x2 = 1400,  y2 = 10300 },
    { id = "echo_creek",     name = "Echo Creek",     x1 = 3300,  y1 = 10700, x2 = 4000,  y2 = 11500 },
    { id = "irvington",      name = "Irvington",      x1 = 1600,  y1 = 13200, x2 = 3000,  y2 = 14900 },
}

local GENERIC_ZONE_NAMES = {
    [""] = true, none = true, unnamed = true, nav = true, road = true,
    townzone = true, trailerpark = true, farm = true, farmland = true,
    forest = true, deepforest = true, vegitation = true, vegetation = true,
    parkingstall = true, ranch = true, campground = true, zombie = true,
    zombies = true, foraging = true, water = true,
}

local discovered = nil
local discoveredByID = nil

local function normalizeID(name)
    local s = string.lower(tostring(name or ""))
    s = string.gsub(s, "[^%w]+", "_")
    s = string.gsub(s, "^_+", "")
    s = string.gsub(s, "_+$", "")
    return s
end

local function humanizeMapName(raw)
    local s = tostring(raw or "")
    -- Strip trailing ", KY" or similar state suffixes from PZ map folder names.
    s = string.gsub(s, ",%s*[A-Za-z]+%s*$", "")
    s = string.gsub(s, "_", " ")
    s = string.gsub(s, "(%l)(%u)", "%1 %2")
    s = string.gsub(s, "%s+", " ")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function isGeneric(name)
    return GENERIC_ZONE_NAMES[string.lower(tostring(name or ""))] == true
end

local function addTown(list, byID, name, bounds, source)
    local clean = humanizeMapName(name)
    if clean == "" or isGeneric(clean) then return nil end
    local id = normalizeID(clean)
    if id == "" then return nil end
    local existing = byID[id]
    if existing then
        if type(bounds) == "table" and bounds.x1 and bounds.x2 and bounds.y1 and bounds.y2 then
            if existing.x1 == nil then
                existing.x1, existing.y1, existing.x2, existing.y2 = bounds.x1, bounds.y1, bounds.x2, bounds.y2
            else
                existing.x1 = math.min(existing.x1, bounds.x1)
                existing.y1 = math.min(existing.y1, bounds.y1)
                existing.x2 = math.max(existing.x2, bounds.x2)
                existing.y2 = math.max(existing.y2, bounds.y2)
            end
        end
        return existing
    end
    local entry = {
        id = id,
        name = clean,
        source = source or "discovered",
        x1 = bounds and bounds.x1 or nil,
        y1 = bounds and bounds.y1 or nil,
        x2 = bounds and bounds.x2 or nil,
        y2 = bounds and bounds.y2 or nil,
    }
    byID[id] = entry
    list[#list + 1] = entry
    return entry
end

local function discoverFromWorldMap(list, byID, world)
    if not world or type(world.getMap) ~= "function" then return end
    local ok, mapStr = pcall(world.getMap, world)
    if not ok or type(mapStr) ~= "string" or mapStr == "" then return end
    for segment in string.gmatch(mapStr, "[^;]+") do
        addTown(list, byID, segment, nil, "modded_map")
    end
end

local function discoverFromMetaGrid(list, byID, world)
    if not world or type(world.getMetaGrid) ~= "function" then return end
    local okM, metaGrid = pcall(world.getMetaGrid, world)
    if not okM or not metaGrid then return end
    local zones = nil
    if type(metaGrid.getZones) == "function" then
        local okZ, res = pcall(metaGrid.getZones, metaGrid)
        if okZ then zones = res end
    end
    if not zones or type(zones.size) ~= "function" then return end
    local total = math.min(4096, tonumber(zones:size()) or 0)
    for i = 0, total - 1 do
        local z = zones:get(i)
        if z then
            local zt = type(z.getType) == "function" and tostring(z:getType() or "") or ""
            local zm = type(z.getName) == "function" and tostring(z:getName() or "") or ""
            if string.lower(zt) == "townzone" and not isGeneric(zm) then
                local zx = type(z.getX) == "function" and tonumber(z:getX()) or nil
                local zy = type(z.getY) == "function" and tonumber(z:getY()) or nil
                local zw = type(z.getWidth) == "function" and tonumber(z:getWidth()) or nil
                local zh = type(z.getHeight) == "function" and tonumber(z:getHeight()) or nil
                local bounds = (zx and zy and zw and zh) and {
                    x1 = zx, y1 = zy, x2 = zx + zw, y2 = zy + zh,
                } or nil
                addTown(list, byID, zm, bounds, "meta_zone")
            end
        end
    end
end

function Catalog.EnsureDiscovered(worldOverride)
    if discovered ~= nil then return discovered, discoveredByID end
    local list = {}
    local byID = {}

    local world = worldOverride or (getWorld and getWorld()) or nil
    discoverFromMetaGrid(list, byID, world)
    discoverFromWorldMap(list, byID, world)

    for i = 1, #VANILLA_TOWNS do
        local vt = VANILLA_TOWNS[i]
        addTown(list, byID, vt.name, vt, "vanilla")
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    discovered = list
    discoveredByID = byID
    return discovered, discoveredByID
end

function Catalog.GetTowns(worldOverride)
    local list = Catalog.EnsureDiscovered(worldOverride)
    return list
end

function Catalog.FindByName(name, worldOverride)
    local _, byID = Catalog.EnsureDiscovered(worldOverride)
    local id = normalizeID(humanizeMapName(name))
    return id ~= "" and byID[id] or nil
end

function Catalog.ResolveTownAt(x, y, worldOverride)
    x = tonumber(x)
    y = tonumber(y)
    if not x or not y then return nil end
    local list = Catalog.EnsureDiscovered(worldOverride)
    -- Prefer dynamically discovered modded/meta zones over vanilla bounds on overlap.
    local fallback = nil
    for i = 1, #list do
        local t = list[i]
        if t.x1 and t.y1 and t.x2 and t.y2
            and x >= t.x1 and x <= t.x2 and y >= t.y1 and y <= t.y2
        then
            if t.source ~= "vanilla" then return t.name end
            fallback = fallback or t.name
        end
    end
    return fallback
end

function Catalog.NormalizeTownID(name)
    return normalizeID(humanizeMapName(name))
end

function Catalog.Reset()
    discovered = nil
    discoveredByID = nil
end

return Catalog
