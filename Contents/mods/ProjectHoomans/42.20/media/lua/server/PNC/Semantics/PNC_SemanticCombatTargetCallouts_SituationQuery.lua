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

local function isHostileToPlayer(speaker, player)
    if type(speaker) ~= "table" then return false end
    local aud = PNC.Semantics and PNC.Semantics.AudienceContext or nil
    if aud and type(aud.IsHostileToPlayer) == "function" then
        return aud.IsHostileToPlayer(speaker, player) == true
    end
    if speaker.isHostile == true
        or tostring(speaker.tacticalClass or "") == "hostile"
        or tostring(speaker.activeBehavior or speaker.behavior or "") == "hostile"
        or (type(speaker.hostility) == "table"
            and (tostring(speaker.hostility.mode or "") == "hostile"
                or speaker.hostility.attackPlayers == true))
    then
        return true
    end
    local rt = type(speaker.runtime) == "table" and speaker.runtime or nil
    if rt and (rt.hostileToPlayer == true
        or (type(rt.target) == "table" and tostring(rt.target.kind or "") == "player"))
    then
        return true
    end
    return false
end

local function canAddressPlayerAsAlly(speaker, player)
    if type(speaker) ~= "table" then return false end
    local aud = PNC.Semantics and PNC.Semantics.AudienceContext or nil
    if aud and type(aud.CanAddressPlayerAsAlly) == "function" then
        return aud.CanAddressPlayerAsAlly(speaker, player, { requireAlly = true }) == true
    end
    if isHostileToPlayer(speaker, player) then return false end
    return speaker.recruited == true
        or speaker.isCompanion == true
        or speaker.isColonist == true
        or speaker.ownerUsername ~= nil
        or speaker.ownerOnlineID ~= nil
end

function I.FindNearbyPlayerAddressee(rec, radius)
    local core = PNC.Core
    if not (core and type(core.ForEachPlayer) == "function") then return nil end
    local nx, ny, nz = tonumber(rec.x) or 0, tonumber(rec.y) or 0, tonumber(rec.z) or 0
    local rSq, found, bestDist = radius * radius, nil, nil
    core.ForEachPlayer(function(p)
        if not p or (type(p.isDead) == "function" and p:isDead()) then return end
        if isHostileToPlayer(rec, p) then return end
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

-- Actor-agnostic threat counter over the already-bounded ZombieAggro.ActiveSet
-- (zero getCell():getZombieList() world scans). Works identically for players,
-- companion NPCs, and autonomous AI NPCs.
function I.CountThreatsOnActor(actor, isPlayer, now)
    if not actor then return 0 end
    now = I.SituationNow(now)
    local count = 0
    local seen = {}
    local aggro = PNC.ZombieAggro
    local activeSet = aggro and aggro.ActiveSet or nil
    local order = activeSet and activeSet.order or nil
    local byID = activeSet and activeSet.byID or nil
    local npcKey = (not isPlayer and type(actor) == "table" and actor.id ~= nil)
        and tostring(actor.id) or nil

    if type(order) == "table" and type(byID) == "table" then
        for i = 1, #order do
            local zid = order[i]
            local entry = zid and byID[zid] or nil
            local z = entry and entry.zombie or nil
            if z and not (z.isDead and z:isDead()) then
                if isPlayer then
                    local tgt = z.getTarget and z:getTarget() or nil
                    local atk = z.getAttackedBy and z:getAttackedBy() or nil
                    if tgt == actor or atk == actor then
                        seen[z] = true
                        count = count + 1
                    end
                elseif npcKey then
                    local md = z.getModData and z:getModData() or nil
                    if md then
                        local leaseTgt = md.PNC_ZombiePursuitTarget
                        local leaseUntil = tonumber(md.PNC_ZombiePursuitUntil) or 0
                        local forcedId = md.PNC_AggroNPCId
                        local forcedUntil = tonumber(md.PNC_AggroNPCUntil) or 0
                        if (leaseTgt ~= nil and tostring(leaseTgt) == npcKey and leaseUntil > now)
                            or (forcedId ~= nil and tostring(forcedId) == npcKey and forcedUntil > now)
                        then
                            seen[z] = true
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    if npcKey then
        local bites = aggro and aggro.State and aggro.State.bites or nil
        if type(bites) == "table" then
            for _, b in pairs(bites) do
                if b and tostring(b.npcId or "") == npcKey
                    and b.phase ~= "finished" and b.phase ~= "release"
                    and (not b.zombie or not seen[b.zombie])
                then
                    if b.zombie then seen[b.zombie] = true end
                    count = count + 1
                end
            end
        end
        local rt = actor.runtime
        if count == 0 and type(rt) == "table" and type(rt.zombieAttackers) == "table" then
            for _, info in pairs(rt.zombieAttackers) do
                if type(info) == "table" and (tonumber(info.seenAt) or 0) + 4000 >= now then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- Unified actor-agnostic helper selector: evaluates nearby allied players AND
-- nearby allied NPCs together, picking whoever has the fewest zombies on their
-- tail (breaking ties by closest distance).
function I.FindLeastThreatenedHelper(speaker, radius, now)
    if type(speaker) ~= "table" then return nil end
    now = I.SituationNow(now)
    radius = tonumber(radius) or 16
    local rSq = radius * radius
    local sx, sy, sz = tonumber(speaker.x) or 0, tonumber(speaker.y) or 0, tonumber(speaker.z) or 0
    local best = nil

    local function consider(candidate)
        if not best
            or candidate.threatCount < best.threatCount
            or (candidate.threatCount == best.threatCount and candidate.distSq < best.distSq)
        then
            best = candidate
        end
    end

    local core = PNC.Core
    if core and type(core.ForEachPlayer) == "function" then
        core.ForEachPlayer(function(p)
            if not p or (type(p.isDead) == "function" and p:isDead()) then return end
            if not canAddressPlayerAsAlly(speaker, p) then return end
            local px = type(p.getX) == "function" and tonumber(p:getX()) or nil
            local py = type(p.getY) == "function" and tonumber(p:getY()) or nil
            local pz = type(p.getZ) == "function" and tonumber(p:getZ()) or 0
            if px == nil or py == nil or math.abs(pz - sz) >= 1 then return end
            local d = distSq(sx, sy, px, py)
            if d <= rSq then
                local desc = type(p.getDescriptor) == "function" and p:getDescriptor() or nil
                local fore = desc and type(desc.getForename) == "function" and tostring(desc:getForename() or "") or ""
                local uname = type(p.getUsername) == "function" and tostring(p:getUsername() or "") or ""
                local pname = (fore ~= "" and fore) or (uname ~= "" and uname) or "partner"
                local pid = (type(p.getUsername) == "function" and uname ~= "" and ("player:" .. uname)) or "player"
                consider({
                    id = "player",
                    relKey = pid,
                    name = pname,
                    isPlayer = true,
                    player = p,
                    threatCount = I.CountThreatsOnActor(p, true, now),
                    distSq = d,
                })
            end
        end)
    end

    local allies = I.FindSquadmates(speaker, radius)
    for i = 1, #allies do
        local ally = allies[i]
        if type(ally) == "table" and ally.alive ~= false
            and math.abs((tonumber(ally.z) or sz) - sz) < 1
        then
            local d = distSq(sx, sy, tonumber(ally.x) or sx, tonumber(ally.y) or sy)
            if d <= rSq then
                consider({
                    id = ally.id,
                    relKey = "npc:" .. tostring(ally.id),
                    name = tostring(ally.displayName or ally.name or ally.fullName or ally.id),
                    isPlayer = false,
                    record = ally,
                    threatCount = I.CountThreatsOnActor(ally, false, now),
                    distSq = d,
                })
            end
        end
    end

    return best
end

function I.IsActorActivelyFighting(actor, isPlayer, threatCount, now)
    if (tonumber(threatCount) or 0) > 0 then return true end
    if not actor then return false end
    if isPlayer then
        if type(actor.isAttacking) == "function" and actor:isAttacking() == true then return true end
        if type(actor.isAiming) == "function" and actor:isAiming() == true then return true end
        if type(actor.isDoShove) == "function" and actor:isDoShove() == true then return true end
        return false
    end
    if type(actor) ~= "table" then return false end
    local rt = type(actor.runtime) == "table" and actor.runtime or nil
    if rt then
        if rt.inCombat == true or rt.combatTargetId ~= nil then return true end
        if (tonumber(rt.grappleHoldUntil) or 0) > (tonumber(now) or 0) then return true end
    end
    local beh = tostring(actor.behavior or actor.state or ""):lower()
    if beh == "combat" or beh == "engage" or beh == "engaging" or beh == "fighting" then
        return true
    end
    return false
end

-- Actor-agnostic idle bystander finder: when at least 2 allied members are
-- actively fighting, finds the closest nearby ally/player who has 0 threats
-- and is NOT actively fighting/helping (e.g. 3 total, 2 fighting, 1 watching).
function I.FindIdleBystanderHelper(speaker, radius, now)
    if type(speaker) ~= "table" then return nil, 0 end
    now = I.SituationNow(now)
    radius = tonumber(radius) or 16
    local rSq = radius * radius
    local sx, sy, sz = tonumber(speaker.x) or 0, tonumber(speaker.y) or 0, tonumber(speaker.z) or 0

    local speakerThreats = I.CountThreatsOnActor(speaker, false, now)
    if not I.IsActorActivelyFighting(speaker, false, speakerThreats, now) then
        return nil, 0
    end

    local activeFighters = 1
    local best = nil
    local function considerBystander(candidate)
        if not best or candidate.distSq < best.distSq then
            best = candidate
        end
    end

    local core = PNC.Core
    if core and type(core.ForEachPlayer) == "function" then
        core.ForEachPlayer(function(p)
            if not p or (type(p.isDead) == "function" and p:isDead()) then return end
            if not canAddressPlayerAsAlly(speaker, p) then return end
            local px = type(p.getX) == "function" and tonumber(p:getX()) or nil
            local py = type(p.getY) == "function" and tonumber(p:getY()) or nil
            local pz = type(p.getZ) == "function" and tonumber(p:getZ()) or 0
            if px == nil or py == nil or math.abs(pz - sz) >= 1 then return end
            local d = distSq(sx, sy, px, py)
            if d <= rSq then
                local pThreats = I.CountThreatsOnActor(p, true, now)
                if I.IsActorActivelyFighting(p, true, pThreats, now) then
                    activeFighters = activeFighters + 1
                else
                    local desc = type(p.getDescriptor) == "function" and p:getDescriptor() or nil
                    local fore = desc and type(desc.getForename) == "function" and tostring(desc:getForename() or "") or ""
                    local uname = type(p.getUsername) == "function" and tostring(p:getUsername() or "") or ""
                    local pname = (fore ~= "" and fore) or (uname ~= "" and uname) or "partner"
                    local pid = (uname ~= "" and ("player:" .. uname)) or "player"
                    considerBystander({
                        id = "player",
                        relKey = pid,
                        name = pname,
                        isPlayer = true,
                        player = p,
                        threatCount = 0,
                        distSq = d,
                    })
                end
            end
        end)
    end

    local allies = I.FindSquadmates(speaker, radius)
    for i = 1, #allies do
        local ally = allies[i]
        if type(ally) == "table" and ally.alive ~= false
            and math.abs((tonumber(ally.z) or sz) - sz) < 1
        then
            local d = distSq(sx, sy, tonumber(ally.x) or sx, tonumber(ally.y) or sy)
            if d <= rSq then
                local aThreats = I.CountThreatsOnActor(ally, false, now)
                if I.IsActorActivelyFighting(ally, false, aThreats, now) then
                    activeFighters = activeFighters + 1
                else
                    considerBystander({
                        id = ally.id,
                        relKey = "npc:" .. tostring(ally.id),
                        name = tostring(ally.displayName or ally.name or ally.fullName or ally.id),
                        isPlayer = false,
                        record = ally,
                        threatCount = 0,
                        distSq = d,
                    })
                end
            end
        end
    end

    if activeFighters < 2 then
        return nil, activeFighters
    end
    return best, activeFighters
end

I.FindInjuryEncounterNeighbors = injuryNeighbors

return S
