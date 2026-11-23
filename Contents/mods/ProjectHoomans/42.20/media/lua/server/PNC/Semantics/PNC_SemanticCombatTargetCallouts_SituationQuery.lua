-- Spatial addressee and squadmate lookup helpers for combat situation callouts.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_AllyReplies"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local SIT_BARK_OPTS = {
    family = "combat_ally_warn_situation", priority = 68, priorityHoldMs = 800,
    cooldownMs = 1000, familyCooldownMs = 1000, ttlMs = 9000,
    clientCooldowns = { familyMs = 1500, speakerMs = 1800, ambientMs = 400, mergeWindowMs = 0 },
}
I.SituationBarkOpts = SIT_BARK_OPTS

function I.SituationNow(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and (tonumber(PNC.Core.Now()) or 0) or 0
end

local function distSq(x1, y1, x2, y2)
    if PNC.Core and type(PNC.Core.DistanceSq) == "function" then return PNC.Core.DistanceSq(x1, y1, x2, y2) end
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end
I.DistSq = distSq

function I.FindNearbyPlayerAddressee(rec, radius)
    local core = PNC.Core
    if not (core and type(core.ForEachPlayer) == "function") then return nil end
    local nx, ny, nz = tonumber(rec.x) or 0, tonumber(rec.y) or 0, tonumber(rec.z) or 0
    local rSq, found, bestDist = radius * radius, nil, nil
    core.ForEachPlayer(function(p)
        if not p or (type(p.isDead) == "function" and p:isDead()) then return end
        local px = type(p.getX) == "function" and tonumber(p:getX()) or nil
        local py = type(p.getY) == "function" and tonumber(p:getY()) or nil
        local pz = type(p.getZ) == "function" and tonumber(p:getZ()) or 0
        if px == nil or py == nil or math.abs(pz - nz) >= 1 then return end
        local d = distSq(nx, ny, px, py)
        if d <= rSq and (bestDist == nil or d < bestDist) then
            local desc = type(p.getDescriptor) == "function" and p:getDescriptor() or nil
            local fore = desc and type(desc.getForename) == "function" and tostring(desc:getForename() or "") or ""
            local uname = type(p.getUsername) == "function" and tostring(p:getUsername() or "") or ""
            local pname = (fore ~= "" and fore) or (uname ~= "" and uname) or "partner"
            found, bestDist = { id = "player", name = pname, isPlayer = true }, d
        end
    end)
    return found
end

function I.FindSquadmates(rec, radius)
    local perc, sp, reg = PNC.Perception, PNC.SpatialIndex, PNC.Registry
    if not perc or type(perc.AreWarningAllies) ~= "function" then return {} end
    local rx, ry = tonumber(rec.x) or 0, tonumber(rec.y) or 0
    local raw = (sp and type(sp.QueryNPCs) == "function" and sp.QueryNPCs(rx, ry, radius)) or {}
    if not sp or type(sp.QueryNPCs) ~= "function" then
        for _, c in pairs(reg and reg.Data or {}) do raw[#raw + 1] = c end
    end
    local rSq, out = radius * radius, {}
    for i = 1, #raw do
        local c = raw[i]
        if type(c) == "table" and c ~= rec and tostring(c.id or "") ~= tostring(rec.id or "")
            and c.alive ~= false and perc.AreWarningAllies(rec, c) == true
        then
            local d = distSq(rx, ry, tonumber(c.x) or rx, tonumber(c.y) or ry)
            if d <= rSq then out[#out + 1] = { record = c, distSq = d } end
        end
    end
    if #out > 1 then table.sort(out, function(a, b) return a.distSq < b.distSq end) end
    local list = {}
    for i = 1, math.min(8, #out) do list[i] = out[i].record end
    return list
end

local function injuryNeighbors(rec, radius)
    local sp = PNC.SpatialIndex
    if not sp or not sp.QueryNPCs or not rec.x or not rec.y then return {} end
    local raw = sp.QueryNPCs(rec.x, rec.y, radius)
    local limit, regionZ, radiusSq = 24, tonumber(rec.z) or 0, radius * radius
    local out = {}
    for i = 1, math.min(limit, #raw) do
        local candidate = raw[i]
        if candidate.id ~= rec.id and candidate.alive ~= false and candidate.x and candidate.y
            and math.abs((tonumber(candidate.z) or 0) - regionZ) < 1 then
            local distance = distSq(rec.x, rec.y, candidate.x, candidate.y)
            if distance <= radiusSq then out[#out + 1] = { record = candidate, distance = distance } end
        end
    end
    table.sort(out, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return tostring(a.record.id) < tostring(b.record.id)
    end)
    return out
end

function I.CanSeeInjury(observer, injured, body)
    local reg, perc = PNC.Registry, PNC.Perception
    body = body or (reg and reg.GetLiveZombie and reg.GetLiveZombie(injured.id))
    return body ~= nil and perc and perc.CanSeeWorldObject
        and perc.CanSeeWorldObject(observer, body) == true
end

function I.FindNearbyInjuryObservers(rec, radius)
    local reg = PNC.Registry
    local body = reg and reg.GetLiveZombie and reg.GetLiveZombie(rec.id)
    if not body then return {} end
    local nearby, list = injuryNeighbors(rec, radius), {}
    for i = 1, math.min(8, #nearby) do
        local observer = nearby[i].record
        if I.CanSeeInjury(observer, rec, body) then list[#list + 1] = observer end
    end
    return list
end

I.FindInjuryEncounterNeighbors = injuryNeighbors

return S
