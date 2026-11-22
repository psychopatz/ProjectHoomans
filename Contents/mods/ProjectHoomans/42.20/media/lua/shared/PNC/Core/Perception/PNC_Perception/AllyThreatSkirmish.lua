-- Per-team skirmish state, unaware-ally gate, and blindside detection.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception, Internal = PNC.Perception, PNC.Perception.Internal
local Core, Registry = PNC.Core, PNC.Registry

local SKIRMISH_TTL_MS = 18000
local SKIRMISH_RADIUS_SQ = 196 -- 14m cluster radius
local BEAT_SPACING_MS = 8000
local BLINDSIDE_DIST_SQ = 6.25 -- 2.5m close danger behind cone
local MAX_SKIRMISHES = 64

Perception.ActiveSkirmishes = Perception.ActiveSkirmishes or {}
Perception.ActiveSkirmishOrder = Perception.ActiveSkirmishOrder or {}
Perception.SKIRMISH_BEAT_SPACING_MS = BEAT_SPACING_MS

local function distSq(x1, y1, x2, y2)
    if Core and type(Core.DistanceSq) == "function" then return Core.DistanceSq(x1, y1, x2, y2) end
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

local function sameFloor(z1, z2)
    return math.abs((tonumber(z1) or 0) - (tonumber(z2) or 0)) < 1
end

function Perception.GetTeamKey(rec)
    if type(rec) ~= "table" then return "actor:" end
    local fid = Internal.AllyWarningFactionIdOf and Internal.AllyWarningFactionIdOf(rec) or nil
    if fid then return "faction:" .. fid end
    local field = Internal.AllyWarningOwnerField
    local oid = field and field(rec, "ownerOnlineID") or nil
    if oid ~= nil then return "owner:" .. tostring(oid) end
    local ouser = field and field(rec, "ownerUsername") or nil
    if ouser ~= nil and ouser ~= "" then return "owner:" .. tostring(ouser) end
    return "actor:" .. tostring(rec.id or "")
end

function Perception.GetActiveSkirmish(teamKey, now)
    local s = teamKey and Perception.ActiveSkirmishes[teamKey] or nil
    if type(s) ~= "table" then return nil end
    if (tonumber(now) or 0) - (tonumber(s.lastContactAt) or 0) > SKIRMISH_TTL_MS then
        Perception.ActiveSkirmishes[teamKey] = nil
        return nil
    end
    return s
end

function Perception.IsAllyAlreadyAware(ally, desc, now)
    local rt = type(ally) == "table" and ally.runtime or nil
    if type(rt) ~= "table" then return false end
    if type(rt.target) == "table" then return true end
    local alert = type(rt.allyThreatAlert) == "table" and rt.allyThreatAlert or nil
    if alert and (tonumber(now) or 0) < (tonumber(alert.expiresAt) or 0) then
        if sameFloor(alert.z, desc and desc.z)
            and distSq(alert.x or 0, alert.y or 0, desc and desc.x or 0, desc and desc.y or 0) <= SKIRMISH_RADIUS_SQ
        then
            return true
        end
    end
    return false
end

function Perception.CheckBlindsideThreat(ally, desc)
    if type(ally) ~= "table" or ally.alive == false or type(desc) ~= "table" then return false end
    local ax, ay = tonumber(ally.x), tonumber(ally.y)
    local tx, ty = tonumber(desc.x), tonumber(desc.y)
    if not ax or not ay or not tx or not ty or not sameFloor(ally.z, desc.z) then return false end
    local dx, dy = tx - ax, ty - ay
    local dSq = dx * dx + dy * dy
    if dSq <= 0.01 or dSq > BLINDSIDE_DIST_SQ then return false end
    local rt = type(ally.runtime) == "table" and ally.runtime or nil
    local fx, fy = rt and tonumber(rt.facingDirX) or nil, rt and tonumber(rt.facingDirY) or nil
    if not fx or not fy then
        local body = Registry and Registry.GetLiveZombie and ally.id ~= nil and Registry.GetLiveZombie(ally.id) or nil
        local fwd = body and body.getForwardDirection and body:getForwardDirection() or nil
        if fwd and fwd.getX and fwd.getY then
            fx, fy = tonumber(fwd:getX()), tonumber(fwd:getY())
        end
    end
    if not fx or not fy then return false end
    local fLenSq = fx * fx + fy * fy
    if fLenSq <= 0.0001 then return false end
    local dot = ((fx * dx) + (fy * dy)) / math.sqrt(dSq * fLenSq)
    return dot < 0.25
end

function Perception.RecordSkirmishContact(teamKey, desc, now, isNewWave)
    if not teamKey or type(desc) ~= "table" then return nil, "invalid" end
    now = tonumber(now) or 0
    local cnt = math.max(1, math.floor(tonumber(desc.enemyCount) or 1))
    local existing = Perception.GetActiveSkirmish(teamKey, now)
    if not isNewWave and existing and sameFloor(existing.z, desc.z)
        and distSq(existing.anchorX, existing.anchorY, desc.x, desc.y) <= SKIRMISH_RADIUS_SQ
    then
        existing.lastContactAt = now
        existing.lastCount = cnt
        return existing, "in_fight"
    end
    if Perception.ActiveSkirmishes[teamKey] == nil then
        while #Perception.ActiveSkirmishOrder >= MAX_SKIRMISHES do
            local old = table.remove(Perception.ActiveSkirmishOrder, 1)
            if old ~= nil then Perception.ActiveSkirmishes[old] = nil end
        end
        Perception.ActiveSkirmishOrder[#Perception.ActiveSkirmishOrder + 1] = teamKey
    end
    local entry = {
        teamKey = teamKey,
        anchorX = tonumber(desc.x) or 0,
        anchorY = tonumber(desc.y) or 0,
        z = tonumber(desc.z) or 0,
        startedAt = now,
        lastContactAt = now,
        initialCount = cnt,
        lastCount = cnt,
        lastBeatAt = now,
        lastOneSpoken = false,
        checkinSpoken = false,
        hadInjury = false,
    }
    Perception.ActiveSkirmishes[teamKey] = entry
    return entry, "initial_contact"
end

function Perception.MarkSkirmishBeat(teamKey, beatKind, now)
    local s = teamKey and Perception.ActiveSkirmishes[teamKey] or nil
    if type(s) ~= "table" then return end
    s.lastBeatAt = tonumber(now) or s.lastBeatAt or 0
    if beatKind == "last_one" then s.lastOneSpoken = true
    elseif beatKind == "checkin" then s.checkinSpoken = true
    elseif beatKind == "injury" then s.hadInjury = true end
end

function Perception.ResetSkirmishes()
    Perception.ActiveSkirmishes = {}
    Perception.ActiveSkirmishOrder = {}
end

function Internal.AllyRememberKey(map, order, key, at, cap)
    if map[key] == nil then
        while #order >= (cap or 128) do
            local old = table.remove(order, 1)
            if old ~= nil then map[old] = nil end
        end
        order[#order + 1] = key
    end
    map[key] = at
end

function Internal.QueryWarningNPCs(cx, cy, radius)
    local sp = PNC.SpatialIndex
    local raw = (sp and type(sp.QueryNPCs) == "function" and sp.QueryNPCs(cx, cy, radius)) or {}
    if not sp or type(sp.QueryNPCs) ~= "function" then
        for _, rec in pairs(Registry and Registry.Data or {}) do raw[#raw + 1] = rec end
    end
    return raw
end

return Perception
