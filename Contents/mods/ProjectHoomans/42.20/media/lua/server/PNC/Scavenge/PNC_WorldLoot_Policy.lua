-- Actor-agnostic opportunistic looting policy & safe-zone boundary guard.
-- Shared by BOTH player followers (reading PNC.ScavengePolicy) and AI-owned NPCs
-- (mobile scavengers, roamers, raiders/looters).
--
-- Safe-zone rule:
--   * No NPC (player follower OR AI) grabs items inside player settlement/safehouse
--     bounds OR NPC settlement bounds.
--   * Custom override (`allowProtectedZoneTheft = true` or looter/raider variant)
--     explicitly allows stealing from protected zones.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldLoot = PNC.WorldLoot or {}

local WorldLoot = PNC.WorldLoot

local LOOTER_ROLES = {
    looter = true,
    raider = true,
    bandit = true,
    thief = true,
}

local function isOwnedColonist(record)
    if type(record) ~= "table" then return false end
    if record.recruited == true or record.ownerId ~= nil or record.ownerKey ~= nil then
        return true
    end
    local aff = type(record.affiliation) == "table" and record.affiliation or nil
    if aff and (aff.isPlayerFaction == true or aff.factionID == "player") then
        return true
    end
    return false
end

function WorldLoot.IsLooterVariant(record)
    if type(record) ~= "table" then return false end
    if record.allowProtectedZoneTheft == true or record.ignoreSafeZones == true then
        return true
    end
    local variant = string.lower(tostring(record.lootVariant or ""))
    if LOOTER_ROLES[variant] then return true end
    local role = string.lower(tostring(record.role or (record.affiliation and record.affiliation.role) or ""))
    if LOOTER_ROLES[role] then return true end
    return false
end

local function checkPlayerSettlementBounds(x, y, z)
    local repo = PNC.SettlementRepository
    if type(repo) ~= "table" then return false, nil end
    local list = nil
    if type(repo.List) == "function" then
        list = repo.List()
    elseif type(repo.Bases) == "table" then
        list = repo.Bases
    elseif type(repo.Data) == "table" and type(repo.Data.bases) == "table" then
        list = repo.Data.bases
    end
    if type(list) ~= "table" then return false, nil end

    local Zones = PsychopatzCore and PsychopatzCore.ZoneRegistry or nil
    if not Zones then
        local okZ, modZ = pcall(require, "PsychopatzCore/World/PC_ZoneRegistry")
        if okZ then Zones = modZ end
    end
    local GridRegion = PsychopatzCore and PsychopatzCore.GridRegion or nil
    if not GridRegion then
        local okG, modG = pcall(require, "PsychopatzCore/World/PC_GridRegion")
        if okG then GridRegion = modG end
    end

    for id, base in pairs(list) do
        if type(base) == "table" then
            -- 1. Exact PC_ZoneRegistry / PC_GridRegion geometry check
            if base.baseZoneId and Zones and type(Zones.get) == "function" and GridRegion then
                local zone = Zones.get(base.baseZoneId)
                local geom = zone and zone.geometry or nil
                if geom then
                    local inside = (type(GridRegion.containsPoint) == "function"
                        and GridRegion.containsPoint(geom, x, y, z))
                        or (type(GridRegion.containsXY) == "function"
                            and GridRegion.containsXY(geom, x, y))
                    if inside then return true, tostring(base.id or id) end
                end
            end
            -- 2. Bounding-box / center-radius fallback for lightweight settlement records
            local bx, by = tonumber(base.x), tonumber(base.y)
            local br = tonumber(base.radius)
            if bx and by and br and br > 0 then
                local dx, dy = x - bx, y - by
                if (dx * dx + dy * dy) <= (br * br) then
                    return true, tostring(base.id or id)
                end
            end
        end
    end
    return false, nil
end

local function checkNpcSettlementBounds(x, y, z)
    local comms = PNC.Communities
    local cMath = PNC.CommunityMath
    if type(comms) ~= "table" or type(cMath) ~= "table"
        or type(cMath.IsInsideHomeArea) ~= "function"
    then
        return false, nil
    end
    local all = nil
    if type(comms.List) == "function" then
        all = comms.List()
    elseif type(comms.GetAll) == "function" then
        all = comms.GetAll()
    elseif type(comms.Data) == "table" and type(comms.Data.communities) == "table" then
        all = comms.Data.communities
    end
    if type(all) ~= "table" then return false, nil end
    for id, community in pairs(all) do
        if type(community) == "table" and cMath.IsInsideHomeArea(community, x, y, z) then
            return true, tostring(community.id or id)
        end
    end
    return false, nil
end

local function checkVanillaSafeHouse(x, y, z)
    if not SafeHouse or type(SafeHouse.getSafeHouse) ~= "function" then
        return false, nil
    end
    local cell = getCell and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return false, nil
    end
    local sq = cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
    if not sq then return false, nil end
    local ok, sh = pcall(SafeHouse.getSafeHouse, sq)
    if ok and sh ~= nil then
        return true, "safehouse"
    end
    return false, nil
end

-- Returns (isProtected, zoneKind, zoneId) for a world coordinate.
function WorldLoot.IsInProtectedSafeZone(x, y, z)
    x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
    local inPlayer, pId = checkPlayerSettlementBounds(x, y, z)
    if inPlayer then return true, "player_settlement", pId end

    local inNpc, nId = checkNpcSettlementBounds(x, y, z)
    if inNpc then return true, "npc_settlement", nId end

    local inSH, shId = checkVanillaSafeHouse(x, y, z)
    if inSH then return true, "safehouse", shId end

    return false, nil, nil
end

-- Enforces safe-zone protection for BOTH player followers and AI NPCs,
-- unless the policy or NPC carries the looter/raider theft override.
function WorldLoot.CanLootAt(record, x, y, z, policy)
    if type(policy) == "table" and policy.allowProtectedZoneTheft == true then
        return true, nil
    end
    if WorldLoot.IsLooterVariant(record) then
        return true, nil
    end
    local protected, zoneKind, zoneId = WorldLoot.IsInProtectedSafeZone(x, y, z)
    if protected then
        return false, zoneKind, zoneId
    end
    return true, nil
end

-- Resolves a unified loot policy for ANY actor (player follower OR AI-owned NPC).
function WorldLoot.ResolvePolicy(record, ownerPlayer)
    if type(record) ~= "table" or record.alive == false then
        return { enabled = false }
    end
    -- Per-NPC explicit disable always wins
    if record.opportunisticLootEnabled == false then
        return { enabled = false }
    end

    local theftAllowed = WorldLoot.IsLooterVariant(record)

    -- 1. Player-owned follower/colonist: driven by toggleable PNC.ScavengePolicy
    if isOwnedColonist(record) then
        local sp = PNC.ScavengePolicy
        local snap = nil
        if sp and type(sp.Snapshot) == "function" and ownerPlayer then
            snap = sp.Snapshot(ownerPlayer)
        elseif sp and type(sp.Data) == "table" and type(sp.Data.owners) == "table" then
            local key = record.ownerKey or record.ownerId
            snap = key and sp.Data.owners[tostring(key)] or nil
            if not snap then
                for _, entry in pairs(sp.Data.owners) do
                    snap = entry
                    break
                end
            end
        end
        local enabled = (record.opportunisticLootEnabled == true)
            or (snap ~= nil and snap.enabled == true)
        return {
            enabled = enabled,
            preferences = (snap and snap.preferences) or {
                containers = true, floorItems = true, corpses = true,
            },
            categories = (snap and snap.categories) or {
                food = true, water = true, medical = true, ammo = true,
            },
            autoGrab = (snap and snap.autoGrab) or {},
            allowProtectedZoneTheft = theftAllowed,
            actorKind = "colonist",
        }
    end

    -- 2. AI-owned NPC (mobile scavengers, roamers, raiders/looters)
    local isMobile = true
    if PNC.WorldHourNeeds and type(PNC.WorldHourNeeds.HasSettlementBacking) == "function" then
        local backed = PNC.WorldHourNeeds.HasSettlementBacking(record, "hunger")
        if backed and not theftAllowed and record.opportunisticLootEnabled ~= true then
            isMobile = false
        end
    end
    local enabled = isMobile or theftAllowed or (record.opportunisticLootEnabled == true)
    local categories = {
        food = true,
        water = true,
        medical = true,
        ammo = true,
        weapons = theftAllowed,
        tools = false,
        materials = false,
        clothing = false,
    }
    return {
        enabled = enabled,
        preferences = {
            containers = true,
            floorItems = true,
            corpses = true,
        },
        categories = categories,
        autoGrab = {},
        allowProtectedZoneTheft = theftAllowed,
        actorKind = theftAllowed and "looter" or "ai_scavenger",
    }
end

local function readMethod(obj, method)
    if type(obj) ~= "table" and type(obj) ~= "userdata" then return nil end
    local fn = obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj)
    return ok and val or nil
end

-- Classifies a PZ InventoryItem or lightweight item table into ScavengePolicy categories.
function WorldLoot.ClassifyItem(item)
    if not item then return nil end
    local wic = PNC.WorldItemCategories
    if wic and type(wic.ClassifyItem) == "function" then
        local cat = wic.ClassifyItem(item)
        if cat then return cat end
    end
    if type(item) == "table" and type(item.category) == "string" then
        return string.lower(item.category)
    end
    local ft = tostring(readMethod(item, "getFullType") or (type(item) == "table" and item.fullType) or "")
    local ftLow = string.lower(ft)
    local dispCat = string.lower(tostring(readMethod(item, "getDisplayCategory") or ""))
    local hunger = tonumber(readMethod(item, "getHungerChange") or (type(item) == "table" and item.hungerChange)) or 0
    local thirst = tonumber(readMethod(item, "getThirstChange") or (type(item) == "table" and item.thirstChange)) or 0
    local calories = tonumber(readMethod(item, "getCalories") or (type(item) == "table" and item.calories)) or 0

    if thirst < 0 or dispCat == "water" or string.find(ftLow, "water", 1, true) then
        return "water"
    end
    if hunger < 0 or calories > 0 or dispCat == "food" then
        return "food"
    end
    if dispCat == "firstaid" or dispCat == "medical"
        or string.find(ftLow, "bandage", 1, true) or string.find(ftLow, "pills", 1, true)
    then
        return "medical"
    end
    if dispCat == "ammo" or string.find(ftLow, "bullets", 1, true) or string.find(ftLow, "shells", 1, true) then
        return "ammo"
    end
    if dispCat == "weapon" or readMethod(item, "isRanged") == true then
        return "weapons"
    end
    if dispCat == "tool" then return "tools" end
    if dispCat == "material" then return "materials" end
    if dispCat == "clothing" then return "clothing" end
    return nil
end

function WorldLoot.MatchesPolicy(item, policy)
    if not item or type(policy) ~= "table" or policy.enabled ~= true then
        return false, nil
    end
    local ft = tostring(readMethod(item, "getFullType") or (type(item) == "table" and item.fullType) or "")
    if ft ~= "" and type(policy.autoGrab) == "table" and policy.autoGrab[ft] == true then
        return true, "auto_grab"
    end
    local cat = WorldLoot.ClassifyItem(item)
    if cat and type(policy.categories) == "table" and policy.categories[cat] == true then
        return true, cat
    end
    return false, nil
end

return WorldLoot
