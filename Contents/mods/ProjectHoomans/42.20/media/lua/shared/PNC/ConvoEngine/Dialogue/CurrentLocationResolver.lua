-- O(1) on-demand current location resolver with natural English grammar.
-- Never polls on tick: queries PZ's single-square room/building/zone/metaGrid
-- APIs lazily when asked and caches results in a tiny bounded tile-bucket cache.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Resolver = PNC.ConvoEngine.CurrentLocationResolver or {}
PNC.ConvoEngine.CurrentLocationResolver = Resolver

Resolver.VERSION = 1
Resolver.CACHE_LIMIT = 32

local TownCatalog = PNC.ConvoEngine.WorldMapTownCatalog
    or require "PNC/ConvoEngine/Dialogue/WorldMapTownCatalog"
local BackstoryGen = PNC.ConvoEngine.BackstoryEphemeralGenerator
    or require "PNC/ConvoEngine/Dialogue/BackstoryEphemeralGenerator"

local cache = {}
local cacheOrder = {}
local cacheHead = 1
local cacheCount = 0

-- Known Knox County town bounding boxes (x1, y1, x2, y2) as a zero-allocation
-- fallback when a vanilla map tile has an unnamed TownZone/Vegitation zone.
local KNOX_TOWNS = {
    { name = "Louisville",    x1 = 11900, y1 = 1100,  x2 = 14800, y2 = 4200 },
    { name = "West Point",    x1 = 10700, y1 = 6500,  x2 = 12300, y2 = 7500 },
    { name = "Valley Station",x1 = 12300, y1 = 4200,  x2 = 14600, y2 = 6500 },
    { name = "Muldraugh",     x1 = 10400, y1 = 8700,  x2 = 11100, y2 = 10700 },
    { name = "March Ridge",   x1 = 9700,  y1 = 12500, x2 = 10500, y2 = 13400 },
    { name = "Rosewood",      x1 = 7900,  y1 = 11100, x2 = 8600,  y2 = 12000 },
    { name = "Riverside",     x1 = 5900,  y1 = 5100,  x2 = 6900,  y2 = 5800 },
    { name = "Fall Lake",     x1 = 7000,  y1 = 8100,  x2 = 7600,  y2 = 8600 },
    { name = "Brandenburg",   x1 = 1800,  y1 = 5600,  x2 = 3400,  y2 = 6800 },
    { name = "Ekron",         x1 = 400,   y1 = 9200,  x2 = 1400,  y2 = 10300 },
    { name = "Echo Creek",    x1 = 3300,  y1 = 10700, x2 = 4000,  y2 = 11500 },
    { name = "Irvington",     x1 = 1600,  y1 = 13200, x2 = 3000,  y2 = 14900 },
}

-- Human-readable mapping for PZ room/building IDs with natural preposition & article.
local ROOM_LABELS = {
    kitchen = { prep = "in", label = "the kitchen" },
    livingroom = { prep = "in", label = "the living room" },
    bedroom = { prep = "in", label = "a bedroom" },
    bathroom = { prep = "in", label = "the bathroom" },
    dining = { prep = "in", label = "the dining room" },
    hall = { prep = "in", label = "the hallway" },
    garage = { prep = "in", label = "a garage" },
    garagestorage = { prep = "in", label = "a garage" },
    shed = { prep = "in", label = "a shed" },
    storage = { prep = "in", label = "a storage room" },
    storageunit = { prep = "in", label = "a storage unit" },
    warehouse = { prep = "in", label = "a warehouse" },
    barn = { prep = "in", label = "a barn" },
    greenhouse = { prep = "in", label = "a greenhouse" },
    basement = { prep = "down in", label = "the basement" },
    office = { prep = "in", label = "an office" },
    classroom = { prep = "in", label = "a school" },
    school = { prep = "at", label = "the school" },
    library = { prep = "at", label = "the library" },
    church = { prep = "at", label = "the church" },
    clinic = { prep = "at", label = "the clinic" },
    medical = { prep = "at", label = "the clinic" },
    hospital = { prep = "at", label = "the hospital" },
    pharmacy = { prep = "at", label = "the pharmacy" },
    policestorage = { prep = "at", label = "the police station" },
    policestation = { prep = "at", label = "the police station" },
    firestorage = { prep = "at", label = "the fire station" },
    firestation = { prep = "at", label = "the fire station" },
    fossoil = { prep = "at", label = "the Fossoil station" },
    gasstore = { prep = "at", label = "the gas station" },
    spiffo = { prep = "at", label = "Spiffo's" },
    spiffoskitchen = { prep = "at", label = "Spiffo's" },
    gigamart = { prep = "at", label = "GigaMart" },
    grocery = { prep = "at", label = "the grocery store" },
    cornerstore = { prep = "at", label = "the corner store" },
    bar = { prep = "at", label = "the bar" },
    tavern = { prep = "at", label = "the tavern" },
    motel = { prep = "at", label = "the motel" },
    hotel = { prep = "at", label = "the hotel" },
    restaurant = { prep = "at", label = "a restaurant" },
    diner = { prep = "at", label = "the diner" },
    bakery = { prep = "at", label = "the bakery" },
    cafe = { prep = "at", label = "the cafe" },
    bank = { prep = "at", label = "the bank" },
    post = { prep = "at", label = "the post office" },
    laundromat = { prep = "at", label = "the laundromat" },
    gunstore = { prep = "at", label = "the gun store" },
    bookstore = { prep = "at", label = "the bookstore" },
    clothingstore = { prep = "at", label = "a clothing store" },
    hardware = { prep = "at", label = "the hardware store" },
    toolstore = { prep = "at", label = "the tool store" },
    mechanic = { prep = "at", label = "the auto shop" },
    house = { prep = "inside", label = "a house" },
}

local ZONE_TYPE_LABELS = {
    nav = { prep = "on", label = "the road" },
    road = { prep = "on", label = "the road" },
    trailerpark = { prep = "in", label = "a trailer park" },
    farm = { prep = "out on", label = "farmland" },
    farmland = { prep = "out on", label = "farmland" },
    forest = { prep = "in", label = "the woods" },
    deepforest = { prep = "deep in", label = "the woods" },
    vegitation = { prep = "out in", label = "the brush" },
    vegetation = { prep = "out in", label = "the brush" },
    parkingstall = { prep = "in", label = "a parking lot" },
    townzone = { prep = "in", label = "town" },
    ranch = { prep = "out at", label = "a ranch" },
    campground = { prep = "at", label = "a campground" },
}

local function startsWithVowelSound(word)
    local first = string.lower(string.sub(tostring(word or ""), 1, 1))
    return first == "a" or first == "e" or first == "i" or first == "o" or first == "u"
end

local function humanizeIdentifier(raw)
    local s = tostring(raw or "")
    s = string.gsub(s, "_", " ")
    s = string.gsub(s, "(%l)(%u)", "%1 %2")
    s = string.gsub(s, "%s+", " ")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function isGenericZoneName(name)
    local lower = string.lower(tostring(name or ""))
    if lower == "" or lower == "none" or lower == "unnamed" then return true end
    return ZONE_TYPE_LABELS[lower] ~= nil
end

local function storeCache(key, value)
    if cache[key] == nil then
        if cacheCount >= Resolver.CACHE_LIMIT then
            local oldest = cacheOrder[cacheHead]
            if oldest ~= nil then cache[oldest] = nil end
            cacheOrder[cacheHead] = key
            cacheHead = (cacheHead % Resolver.CACHE_LIMIT) + 1
        else
            local slot = ((cacheHead + cacheCount - 1) % Resolver.CACHE_LIMIT) + 1
            cacheOrder[slot] = key
            cacheCount = cacheCount + 1
        end
    end
    cache[key] = value
end

function Resolver.ResolveTownFromCoords(x, y, worldOverride)
    if TownCatalog and type(TownCatalog.ResolveTownAt) == "function" then
        return TownCatalog.ResolveTownAt(x, y, worldOverride)
    end
    x = tonumber(x)
    y = tonumber(y)
    if not x or not y then return nil end
    for i = 1, #KNOX_TOWNS do
        local t = KNOX_TOWNS[i]
        if x >= t.x1 and x <= t.x2 and y >= t.y1 and y <= t.y2 then
            return t.name
        end
    end
    return nil
end

function Resolver.FormatRoom(roomName)
    local raw = tostring(roomName or "")
    if raw == "" then return nil, nil end
    local lower = string.lower(raw)
    local mapped = ROOM_LABELS[lower]
    if mapped then return mapped.prep, mapped.label end
    -- Strip trailing digits (e.g. "bedroom2" -> "bedroom")
    local stripped = string.gsub(lower, "%d+$", "")
    mapped = ROOM_LABELS[stripped]
    if mapped then return mapped.prep, mapped.label end
    local nice = string.lower(humanizeIdentifier(raw))
    if nice == "" then return nil, nil end
    local article = startsWithVowelSound(nice) and "an " or "a "
    return "in", article .. nice
end

function Resolver.FormatZone(zoneType, zoneName)
    local nameStr = humanizeIdentifier(zoneName)
    local typeLower = string.lower(tostring(zoneType or ""))
    if nameStr ~= "" and not isGenericZoneName(nameStr) then
        if typeLower == "nav" or typeLower == "road"
            or string.find(string.lower(nameStr), "road", 1, true)
            or string.find(string.lower(nameStr), "street", 1, true)
            or string.find(string.lower(nameStr), "ave", 1, true)
            or string.find(string.lower(nameStr), "highway", 1, true)
            or string.find(string.lower(nameStr), "hwy", 1, true)
            or string.find(string.lower(nameStr), "ln", 1, true)
        then
            return "on", nameStr, "road"
        end
        return "in", nameStr, "named_zone"
    end
    local mapped = ZONE_TYPE_LABELS[typeLower]
    if mapped then
        return mapped.prep, mapped.label, typeLower
    end
    return nil, nil, nil
end

function Resolver.ComposePhrase(info)
    info = type(info) == "table" and info or {}
    local settlement = tostring(info.settlementName or "")
    local roomPrep, roomLabel = info.roomPrep, info.roomLabel
    local zonePrep, zoneLabel, zoneKind = info.zonePrep, info.zoneLabel, info.zoneKind
    local town = tostring(info.townName or "")

    -- Avoid redundant "in Muldraugh in Muldraugh" if named zone equals town.
    if zoneLabel and town ~= "" and string.lower(zoneLabel) == string.lower(town) then
        zonePrep, zoneLabel, zoneKind = nil, nil, nil
    end

    if settlement ~= "" then
        if roomPrep and roomLabel then
            return roomPrep .. " " .. roomLabel .. " at " .. settlement
        end
        return "at " .. settlement
    end

    if roomPrep and roomLabel then
        if town ~= "" then
            return roomPrep .. " " .. roomLabel .. " in " .. town
        end
        return roomPrep .. " " .. roomLabel
    end

    if zonePrep and zoneLabel then
        if town ~= "" then
            if zoneKind == "townzone" then
                return "in " .. town
            end
            if zoneKind == "forest" or zoneKind == "deepforest" or zoneKind == "vegitation" or zoneKind == "vegetation" then
                return zonePrep .. " " .. zoneLabel .. " near " .. town
            end
            return zonePrep .. " " .. zoneLabel .. " in " .. town
        end
        return zonePrep .. " " .. zoneLabel
    end

    if town ~= "" then
        return "in " .. town
    end
    return nil
end

function Resolver.ResolveAtCoords(x, y, z, square, extra)
    extra = type(extra) == "table" and extra or {}
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z) or 0

    local roomName = extra.roomName
    local buildingID = extra.buildingID
    if square then
        if not roomName and type(square.getRoom) == "function" then
            local okR, room = pcall(square.getRoom, square)
            if okR and room and type(room.getName) == "function" then
                local okN, rn = pcall(room.getName, room)
                if okN and rn and tostring(rn) ~= "" then roomName = tostring(rn) end
            end
        end
        if not buildingID and type(square.getBuilding) == "function" then
            local okB, bld = pcall(square.getBuilding, square)
            if okB and bld and type(bld.getID) == "function" then
                local okI, bid = pcall(bld.getID, bld)
                if okI and bid then buildingID = tostring(bid) end
            end
        end
    end

    local cacheKey = tostring(x and math.floor(x / 4) or "?")
        .. ":" .. tostring(y and math.floor(y / 4) or "?")
        .. ":" .. tostring(math.floor(z))
        .. ":" .. tostring(roomName or "")
        .. ":" .. tostring(buildingID or "")
        .. ":" .. tostring(extra.settlementName or "")
    if cache[cacheKey] ~= nil then
        return cache[cacheKey]
    end

    local zoneType = extra.zoneType
    local zoneName = extra.zoneName
    local townName = extra.townName

    if (not zoneType or not townName) and x and y then
        local world = getWorld and getWorld() or nil
        local metaGrid = world and type(world.getMetaGrid) == "function" and world:getMetaGrid() or nil
        if metaGrid then
            if type(metaGrid.getZonesAt) == "function" then
                local okZ, zones = pcall(metaGrid.getZonesAt, metaGrid, math.floor(x), math.floor(y), math.floor(z))
                if okZ and zones and type(zones.size) == "function" then
                    local count = math.min(8, tonumber(zones:size()) or 0)
                    for i = 0, count - 1 do
                        local zn = zones:get(i)
                        if zn then
                            local zt = type(zn.getType) == "function" and tostring(zn:getType() or "") or ""
                            local zm = type(zn.getName) == "function" and tostring(zn:getName() or "") or ""
                            if not townName and string.lower(zt) == "townzone" and not isGenericZoneName(zm) then
                                townName = humanizeIdentifier(zm)
                            elseif not zoneName and not isGenericZoneName(zm) then
                                zoneName = zm
                                zoneType = zt ~= "" and zt or zoneType
                            elseif not zoneType and zt ~= "" then
                                zoneType = zt
                            end
                        end
                    end
                end
            elseif type(metaGrid.getZoneAt) == "function" then
                local okZ, zn = pcall(metaGrid.getZoneAt, metaGrid, math.floor(x), math.floor(y), math.floor(z))
                if okZ and zn then
                    zoneType = zoneType or (type(zn.getType) == "function" and tostring(zn:getType() or "") or nil)
                    zoneName = zoneName or (type(zn.getName) == "function" and tostring(zn:getName() or "") or nil)
                end
            end
        end
    end

    if (not townName or townName == "") and x and y then
        townName = Resolver.ResolveTownFromCoords(x, y)
    end

    local roomPrep, roomLabel = Resolver.FormatRoom(roomName)
    local zonePrep, zoneLabel, zoneKind = Resolver.FormatZone(zoneType, zoneName)
    local info = {
        settlementName = extra.settlementName,
        roomName = roomName,
        roomPrep = roomPrep,
        roomLabel = roomLabel,
        zoneType = zoneType,
        zoneName = zoneName,
        zonePrep = zonePrep,
        zoneLabel = zoneLabel,
        zoneKind = zoneKind,
        townName = townName,
    }
    info.phrase = Resolver.ComposePhrase(info)
    if info.roomPrep and info.roomLabel then
        info.immediatePhrase = info.roomPrep .. " " .. info.roomLabel
    elseif info.zonePrep and info.zoneLabel and info.zoneKind ~= "townzone" then
        info.immediatePhrase = info.zonePrep .. " " .. info.zoneLabel
    else
        info.immediatePhrase = nil
    end
    info.known = info.phrase ~= nil and info.phrase ~= ""
    storeCache(cacheKey, info)
    return info
end

function Resolver.ResolveForContext(context)
    context = type(context) == "table" and context or {}
    local actor = context.player
        or (getSpecificPlayer and getSpecificPlayer(0))
        or (getPlayer and getPlayer()) or nil
    local square = nil
    local x, y, z = context.x, context.y, context.z
    if actor then
        if not square and type(actor.getCurrentSquare) == "function" then
            local okS, sq = pcall(actor.getCurrentSquare, actor)
            if okS and sq then square = sq end
        end
        if not x and type(actor.getX) == "function" then
            local okX, vx = pcall(actor.getX, actor)
            if okX then x = vx end
        end
        if not y and type(actor.getY) == "function" then
            local okY, vy = pcall(actor.getY, actor)
            if okY then y = vy end
        end
        if not z and type(actor.getZ) == "function" then
            local okZ, vz = pcall(actor.getZ, actor)
            if okZ then z = vz end
        end
    end
    local extra = {
        settlementName = context.settlementName or (context.worldContext and context.worldContext.settlementName),
        roomName = context.roomName or (context.worldContext and context.worldContext.roomName),
        zoneType = context.zoneType or (context.worldContext and context.worldContext.zoneType),
        zoneName = context.zoneName or (context.worldContext and context.worldContext.zoneName),
        townName = context.townName or (context.worldContext and context.worldContext.townName),
    }
    return Resolver.ResolveAtCoords(x, y, z, square, extra)
end

function Resolver.ResolveForNPC(record, context, worldOverride)
    local loc = Resolver.ResolveForContext(context)
    local fam = BackstoryGen and type(BackstoryGen.ResolveLocationFamiliarity) == "function"
        and BackstoryGen.ResolveLocationFamiliarity(record, loc, worldOverride)
        or { level = "familiar", familiar = true, isHometown = false }
    return loc, fam
end

function Resolver.ResetCache()
    cache = {}
    cacheOrder = {}
    cacheHead = 1
    cacheCount = 0
end

return Resolver
