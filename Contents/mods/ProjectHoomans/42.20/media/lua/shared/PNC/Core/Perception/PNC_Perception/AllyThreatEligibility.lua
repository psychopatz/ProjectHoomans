-- Shared field extractors and multi-tier ally eligibility rules.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception, Internal = PNC.Perception, PNC.Perception.Internal
local Const, Relationships = PNC.Const or {}, PNC.Relationships
local HOSTILE_PACK_RADIUS = 12.0

local function coord(obj, method, fallback)
    if obj and type(obj[method]) == "function" then
        local v = tonumber(obj[method](obj))
        if v ~= nil then return v end
    end
    return tonumber(fallback)
end

local function bodyAlive(body)
    if not body then return false end
    if type(body.isDead) == "function" and body:isDead() == true then return false end
    if type(body.isAlive) == "function" and body:isAlive() == false then return false end
    return true
end

local function ownerField(record, field)
    if type(record) ~= "table" then return nil end
    local v = record[field]
    if v ~= nil and tostring(v) ~= "" then return v end
    local order = record.orderSpec
    if type(order) == "table" and tostring(order.kind or "") == tostring(Const.ORDER_FOLLOW or "follow") then
        local ov = order[field]
        if ov ~= nil and tostring(ov) ~= "" then return ov end
    end
    return nil
end

local function factionIdOf(record)
    if type(record) ~= "table" then return nil end
    if PNC.Factions and type(PNC.Factions.GetFactionID) == "function" then
        local fid = PNC.Factions.GetFactionID(record)
        if fid ~= nil and tostring(fid) ~= "" then return tostring(fid) end
    end
    local aff = record.affiliation
    local raw = (type(aff) == "table" and aff.factionID) or record.factionID
    if raw ~= nil and tostring(raw) ~= "" then return tostring(raw) end
    return nil
end

local function isHostileTactical(record)
    if PNC.Types and PNC.Types.ResolveTacticalClass then
        return PNC.Types.ResolveTacticalClass(record) == tostring(Const.TACTICAL_CLASS_HOSTILE or "hostile")
    end
    return tostring(record and record.tacticalClass or "") == "hostile"
end

Internal.AllyWarningCoord = coord
Internal.AllyWarningBodyAlive = bodyAlive
Internal.AllyWarningOwnerField = ownerField
Internal.AllyWarningFactionIdOf = factionIdOf
Internal.AllyWarningIsHostile = isHostileTactical

local function sameOwner(left, right)
    local lo, ro = ownerField(left, "ownerOnlineID"), ownerField(right, "ownerOnlineID")
    if lo ~= nil and ro ~= nil and tostring(lo) == tostring(ro) then return true end
    local lu, ru = ownerField(left, "ownerUsername"), ownerField(right, "ownerUsername")
    return lu ~= nil and ru ~= nil and tostring(lu) == tostring(ru)
end

local function npcRelationState(observer, subject)
    if not observer or not subject or observer.id == nil or subject.id == nil then return nil end
    local key = (PNC.EntityRef and type(PNC.EntityRef.ForNPC) == "function"
        and PNC.EntityRef.ForNPC(subject.id)) or ("npc:" .. tostring(subject.id))
    if Relationships and type(Relationships.Get) == "function" then
        local rel = Relationships.Get(observer.id, key)
        if type(rel) == "table" and rel.state then return tostring(rel.state) end
    end
    local social = type(observer.social) == "table" and observer.social.relationships or nil
    local raw = type(social) == "table" and social[key] or nil
    return type(raw) == "table" and raw.state and tostring(raw.state) or nil
end

function Perception.AreWarningAllies(caller, candidate)
    if type(caller) ~= "table" or type(candidate) ~= "table" then return false, "invalid_actor" end
    if caller.id == nil or candidate.id == nil or tostring(caller.id) == tostring(candidate.id) then
        return false, "self"
    end
    if candidate.alive == false then return false, "dead" end
    local liveState = Const.PRESENCE_LIVE or "live"
    if candidate.presenceState ~= nil and tostring(candidate.presenceState) ~= tostring(liveState) then
        return false, "not_live"
    end
    if math.abs((tonumber(candidate.z) or 0) - (tonumber(caller.z) or 0)) >= 1.0 then
        return false, "different_floor"
    end
    if Relationships and type(Relationships.AreNPCsEnemies) == "function" then
        if Relationships.AreNPCsEnemies(caller, candidate, { ignoreAttackNPCPolicy = true })
            or Relationships.AreNPCsEnemies(candidate, caller, { ignoreAttackNPCPolicy = true })
        then
            return false, "enemy"
        end
    end
    if sameOwner(caller, candidate) then return true, "same_owner" end
    local cf, af = factionIdOf(caller), factionIdOf(candidate)
    if cf ~= nil and cf == af then return true, "same_faction" end
    if cf ~= nil and af ~= nil and PNC.Factions and type(PNC.Factions.AreAllied) == "function"
        and PNC.Factions.AreAllied(cf, af) == true
    then
        return true, "allied_faction"
    end
    if npcRelationState(caller, candidate) == "friend" then
        local rev = npcRelationState(candidate, caller)
        if rev ~= "enemy" and rev ~= "rival" then return true, "personal_friend" end
    end
    local cOwn = caller.recruited == true or ownerField(caller, "ownerUsername") ~= nil or ownerField(caller, "ownerOnlineID") ~= nil
    local aOwn = candidate.recruited == true or ownerField(candidate, "ownerUsername") ~= nil or ownerField(candidate, "ownerOnlineID") ~= nil
    if cf == nil and af == nil and not cOwn and not aOwn and isHostileTactical(caller) and isHostileTactical(candidate) then
        return true, "hostile_pack", HOSTILE_PACK_RADIUS
    end
    return false, "unrelated"
end

function Internal.CollectWarningAllies(caller, raw, cx, cy, baseRadius, desc, now, opts, checkBlindside)
    local sorted, blindsideAlly, firstAlly = {}, nil, nil
    local includeAware = opts.includeAware == true
    local dFn = PNC.Core and PNC.Core.DistanceSq
    for i = 1, #raw do
        local cand = raw[i]
        local ok, relKind, tierRad = Perception.AreWarningAllies(caller, cand)
        if ok then
            local prof = PNC.PerceptionService and PNC.PerceptionService.GetProfile and PNC.PerceptionService.GetProfile(cand) or nil
            local effRad = math.min(baseRadius, tonumber(tierRad) or baseRadius, tonumber(prof and prof.hearingRange) or 34.0)
            local ax, ay = tonumber(cand.x) or cx, tonumber(cand.y) or cy
            local dSq = dFn and dFn(cx, cy, ax, ay) or ((ax - cx) * (ax - cx) + (ay - cy) * (ay - cy))
            if dSq <= effRad * effRad then
                if not firstAlly then firstAlly = cand end
                local aware = Perception.IsAllyAlreadyAware and Perception.IsAllyAlreadyAware(cand, desc, now) == true
                if aware then
                    if checkBlindside and not blindsideAlly and Perception.CheckBlindsideThreat(cand, desc) then
                        blindsideAlly = cand
                    end
                    if includeAware then
                        sorted[#sorted + 1] = { record = cand, distSq = dSq, relationKind = relKind, effRadius = effRad }
                    end
                else
                    sorted[#sorted + 1] = { record = cand, distSq = dSq, relationKind = relKind, effRadius = effRad }
                end
            end
        end
    end
    if #sorted > 1 then
        table.sort(sorted, function(a, b)
            if a.distSq ~= b.distSq then return a.distSq < b.distSq end
            return tostring(a.record.id or "") < tostring(b.record.id or "")
        end)
    end
    return sorted, blindsideAlly, firstAlly
end

return Perception
