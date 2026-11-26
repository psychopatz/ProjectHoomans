-- Unified world perception for community territories, hostile gang radii,
-- and player/NPC settlement bases. Actor-agnostic: works for both players and
-- AI-controlled NPC groups.
PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception
local GridRegion = nil
if type(require) == "function" then
    local ok, mod = pcall(require, "PsychopatzCore/World/PC_GridRegion")
    if ok and type(mod) == "table" then GridRegion = mod end
end

local DEFAULT_TERRITORY_RADIUS = 28

local function safeCoords(actorOrX, y, z)
    if type(actorOrX) == "number" then
        return actorOrX, tonumber(y) or 0, tonumber(z) or 0
    end
    if type(actorOrX) == "table" then
        if type(actorOrX.getX) == "function" and type(actorOrX.getY) == "function" then
            local okX, ax = pcall(actorOrX.getX, actorOrX)
            local okY, ay = pcall(actorOrX.getY, actorOrX)
            local okZ, az = type(actorOrX.getZ) == "function" and pcall(actorOrX.getZ, actorOrX) or true, 0
            if okX and okY then
                return tonumber(ax) or 0, tonumber(ay) or 0, okZ and (tonumber(az) or 0) or 0
            end
        end
        return tonumber(actorOrX.x) or 0, tonumber(actorOrX.y) or 0, tonumber(actorOrX.z) or 0
    end
    if actorOrX ~= nil and type(actorOrX.getX) == "function" and type(actorOrX.getY) == "function" then
        local okX, ax = pcall(actorOrX.getX, actorOrX)
        local okY, ay = pcall(actorOrX.getY, actorOrX)
        local okZ, az = type(actorOrX.getZ) == "function" and pcall(actorOrX.getZ, actorOrX) or true, 0
        if okX and okY then
            return tonumber(ax) or 0, tonumber(ay) or 0, okZ and (tonumber(az) or 0) or 0
        end
    end
    return nil, nil, nil
end

function Perception.IsInsideCommunityTerritory(community, xOrActor, y, z)
    if type(community) ~= "table" then return false end
    if community.status ~= nil and tostring(community.status) ~= "active" then
        return false
    end
    local px, py, pz = safeCoords(xOrActor, y, z)
    if px == nil or py == nil then return false end

    if PNC.CommunityMath and type(PNC.CommunityMath.IsInsideHomeArea) == "function" then
        return PNC.CommunityMath.IsInsideHomeArea(community, px, py, pz) == true
    end

    local cx = tonumber(community.homeX or community.x or community.centerX)
    local cy = tonumber(community.homeY or community.y or community.centerY)
    local r = tonumber(community.homeRadius or community.radius) or DEFAULT_TERRITORY_RADIUS
    if not cx or not cy or r <= 0 then return false end
    local dx, dy = px - cx, py - cy
    return (dx * dx + dy * dy) <= (r * r)
end

function Perception.IsInsideSettlementBase(base, xOrActor, y, z)
    if type(base) ~= "table" then return false end
    local px, py, pz = safeCoords(xOrActor, y, z)
    if px == nil or py == nil then return false end

    if type(base.territory) == "table" and GridRegion and type(GridRegion.containsTile) == "function" then
        if GridRegion.containsTile(base.territory, math.floor(px), math.floor(py), math.floor(pz)) == true then
            return true
        end
    end

    local cx = tonumber(base.centerX or base.anchorX or base.x)
    local cy = tonumber(base.centerY or base.anchorY or base.y)
    local r = tonumber(base.radius or base.territoryRadius) or DEFAULT_TERRITORY_RADIUS
    if not cx or not cy or r <= 0 then return false end
    local dx, dy = px - cx, py - cy
    return (dx * dx + dy * dy) <= (r * r)
end

local function classifyBaseRelation(actorFactionID, targetFactionID, targetFaction)
    local aFid = tostring(actorFactionID or "")
    local tFid = tostring(targetFactionID or "")
    if aFid ~= "" and tFid ~= "" and aFid == tFid then
        return "own_base"
    end
    local Factions = PNC.Factions
    if Factions and aFid ~= "" and tFid ~= "" then
        if type(Factions.AreHostile) == "function" and Factions.AreHostile(aFid, tFid) == true then
            return "hostile_base"
        end
        if type(Factions.AreAllied) == "function" and Factions.AreAllied(aFid, tFid) == true then
            return "allied_base"
        end
        if type(Factions.GetRelationState) == "function" then
            local st = tostring(Factions.GetRelationState(aFid, tFid) or "")
            if st == "hostile" or st == "war" then return "hostile_base" end
            if st == "allied" or st == "friendly" then return "allied_base" end
        end
    end
    if type(targetFaction) == "table" then
        if targetFaction.isHostile == true or tostring(targetFaction.stance or "") == "hostile"
            or (Factions and type(Factions.IsTerritorialTollFaction) == "function"
                and Factions.IsTerritorialTollFaction(targetFaction) == true)
        then
            return "hostile_base"
        end
    end
    return "neutral_base"
end

-- Unified territory/base query at world coordinates (x, y, z) for any actor or
-- squad faction. Checks both NPC Communities (including hostile gangs) and
-- player/NPC SettlementRepository bases.
function Perception.ResolveTerritoryAt(xOrActor, y, z, actorFactionID)
    local px, py, pz = safeCoords(xOrActor, y, z)
    if px == nil or py == nil then return nil end

    local Factions = PNC.Factions
    local byID = Factions and Factions.Registry and Factions.Registry.byID or nil

    -- 1. Active Communities (hostile gangs, neutral/allied survivor camps)
    local Communities = PNC.Communities
    if Communities and type(Communities.List) == "function" then
        local list = Communities.List() or {}
        for i = 1, #list do
            local comm = list[i]
            if Perception.IsInsideCommunityTerritory(comm, px, py, pz) then
                local fid = tostring(comm.factionID or comm.factionId or "")
                local fac = byID and fid ~= "" and byID[fid] or nil
                local relation = classifyBaseRelation(actorFactionID, fid, fac)
                return {
                    id = tostring(comm.id or ("community:" .. fid)),
                    name = tostring(comm.name or (fac and fac.name) or "the camp"),
                    kind = "community",
                    factionID = fid,
                    relation = relation,
                }
            end
        end
    end

    -- 2. Player-owned & NPC-owned SettlementRepository bases
    local Repo = PNC.SettlementRepository
    local bases = Repo and Repo.State and Repo.State.bases or nil
    if type(bases) == "table" then
        for _, base in pairs(bases) do
            if Perception.IsInsideSettlementBase(base, px, py, pz) then
                local fid = tostring(base.factionId or base.factionID or "")
                local fac = byID and fid ~= "" and byID[fid] or nil
                local relation = classifyBaseRelation(actorFactionID, fid, fac)
                return {
                    id = tostring(base.id or ("base:" .. fid)),
                    name = tostring(base.name or (fac and fac.name) or "the base"),
                    kind = "settlement",
                    factionID = fid,
                    relation = relation,
                }
            end
        end
    end

    return nil
end

return Perception
