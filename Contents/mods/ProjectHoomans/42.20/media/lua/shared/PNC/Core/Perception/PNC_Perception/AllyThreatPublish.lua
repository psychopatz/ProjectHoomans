-- Spatial threat-warning broadcast with cooldown, team dedup, and ShockBus telemetry.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception, Internal = PNC.Perception, PNC.Perception.Internal
local Core, Const, Spatial, Registry = PNC.Core, PNC.Const or {}, PNC.SpatialIndex, PNC.Registry
local DEFAULT_WARNING_RADIUS, MAX_WARN_ALLIES, CALLER_COOLDOWN_MS = 16.0, 8, 6000
local TEAM_THREAT_DEDUP_MS, WARNING_LINK_TTL_MS, MAX_DEDUP_KEYS = 9000, 2500, 128

Perception.AllyWarningCallerAt = Perception.AllyWarningCallerAt or {}
Perception.AllyWarningTeamThreatAt = Perception.AllyWarningTeamThreatAt or {}
Perception.AllyWarningCallerKeys = Perception.AllyWarningCallerKeys or {}
Perception.AllyWarningTeamKeys = Perception.AllyWarningTeamKeys or {}
Perception.AllyWarningStats = Perception.AllyWarningStats or { published = 0, notified = 0, throttled = 0, hopBlocked = 0 }

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return Core and type(Core.Now) == "function" and (tonumber(Core.Now()) or 0) or 0
end

local function isAuth() return not Core or type(Core.IsAuthority) ~= "function" or Core.IsAuthority() == true end

local function distSq(x1, y1, x2, y2)
    if Core and type(Core.DistanceSq) == "function" then return Core.DistanceSq(x1, y1, x2, y2) end
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

local function rememberKey(map, order, key, at)
    if map[key] == nil then
        while #order >= MAX_DEDUP_KEYS do
            local old = table.remove(order, 1)
            if old ~= nil then map[old] = nil end
        end
        order[#order + 1] = key
    end
    map[key] = at
end

local function teamKeyOf(caller)
    local fid = Internal.AllyWarningFactionIdOf and Internal.AllyWarningFactionIdOf(caller) or nil
    if fid then return "faction:" .. fid end
    local field = Internal.AllyWarningOwnerField
    local oid = field and field(caller, "ownerOnlineID") or nil
    if oid ~= nil then return "owner:" .. tostring(oid) end
    local ouser = field and field(caller, "ownerUsername") or nil
    if ouser ~= nil then return "owner:" .. tostring(ouser) end
    return "actor:" .. tostring(caller and caller.id or "")
end

local function failRes(reason, teamKey, desc)
    return { emitted = false, reason = reason, descriptor = desc, teamKey = teamKey, notified = {} }
end

function Perception.PublishAllyThreatWarning(caller, target, opts)
    opts = type(opts) == "table" and opts or {}
    if not isAuth() or type(caller) ~= "table" or caller.alive == false or caller.id == nil then
        return failRes("invalid_caller")
    end
    if (type(target) == "table" and target.viaAllyWarning == true)
        or (tonumber(opts.hopDepth) or 0) > 0 or tostring(opts.source or "") == "ally_threat_warning"
    then
        Perception.AllyWarningStats.hopBlocked = Perception.AllyWarningStats.hopBlocked + 1
        return failRes("hop_limit")
    end
    local now, callerKey, teamKey = nowMs(opts.at), tostring(caller.id), teamKeyOf(caller)
    local fastKey = Internal.FastTargetKey and Internal.FastTargetKey(target) or nil
    if opts.ignoreCooldown ~= true and (now < (tonumber(Perception.AllyWarningCallerAt[callerKey]) or 0)
        or (fastKey and now < (tonumber(Perception.AllyWarningTeamThreatAt[teamKey .. "|" .. fastKey]) or 0)))
    then
        Perception.AllyWarningStats.throttled = Perception.AllyWarningStats.throttled + 1
        return failRes("warning_throttled", teamKey)
    end
    local descriptor, resolvedInfo = nil, nil
    if Perception.NormalizeThreatDescriptor then
        descriptor, resolvedInfo = Perception.NormalizeThreatDescriptor(target, now)
    end
    if not descriptor then return failRes("invalid_threat_target") end
    descriptor.callerId = callerKey

    local dedupKey = teamKey .. "|" .. descriptor.key
    if opts.ignoreCooldown ~= true and not fastKey
        and now < (tonumber(Perception.AllyWarningTeamThreatAt[dedupKey]) or 0)
    then
        Perception.AllyWarningStats.throttled = Perception.AllyWarningStats.throttled + 1
        return failRes("warning_throttled", teamKey, descriptor)
    end

    local cx, cy, cz = tonumber(caller.x) or descriptor.x, tonumber(caller.y) or descriptor.y, tonumber(caller.z) or descriptor.z
    local baseRadius = math.max(1, tonumber(opts.radius) or tonumber(Const.ALLY_WARNING_RADIUS) or DEFAULT_WARNING_RADIUS)
    local raw = (Spatial and type(Spatial.QueryNPCs) == "function" and Spatial.QueryNPCs(cx, cy, baseRadius)) or {}
    if not Spatial or type(Spatial.QueryNPCs) ~= "function" then
        for _, rec in pairs(Registry and Registry.Data or {}) do raw[#raw + 1] = rec end
    end
    descriptor.enemyCount = Internal.EstimateThreatCount and Internal.EstimateThreatCount(caller, descriptor, raw) or 1
    descriptor.callerName = tostring(caller.name or caller.fullName or "")

    local sorted = {}
    for i = 1, #raw do
        local cand = raw[i]
        local ok, relKind, tierRad = Perception.AreWarningAllies(caller, cand)
        if ok then
            local prof = PNC.PerceptionService and PNC.PerceptionService.GetProfile and PNC.PerceptionService.GetProfile(cand) or nil
            local effRad = math.min(baseRadius, tonumber(tierRad) or baseRadius, tonumber(prof and prof.hearingRange) or 34.0)
            local dSq = distSq(cx, cy, tonumber(cand.x) or cx, tonumber(cand.y) or cy)
            if dSq <= effRad * effRad then
                sorted[#sorted + 1] = { record = cand, distSq = dSq, relationKind = relKind, effRadius = effRad }
            end
        end
    end
    table.sort(sorted, function(a, b)
        if a.distSq ~= b.distSq then return a.distSq < b.distSq end
        return tostring(a.record.id or "") < tostring(b.record.id or "")
    end)

    local notified = {}
    for i = 1, math.min(MAX_WARN_ALLIES, #sorted) do
        local ally = sorted[i].record
        local nextAt = tonumber(ally.runtime and ally.runtime.allyWarnedCooldownUntil) or 0
        if (opts.ignoreCooldown == true or now >= nextAt) and Internal.ApplyAllyThreatAlert then
            notified[#notified + 1] = Internal.ApplyAllyThreatAlert(callerKey, sorted[i], descriptor, now, #notified, resolvedInfo)
        end
    end

    if #notified > 0 then
        caller.runtime = type(caller.runtime) == "table" and caller.runtime or {}
        caller.runtime.lastWarningLink = {
            kind = descriptor.semanticClass, role = "caller", actorId = tostring(notified[1].record.id or ""),
            threatKind = descriptor.kind, x = notified[1].record.x or descriptor.x,
            y = notified[1].record.y or descriptor.y, z = notified[1].record.z or descriptor.z,
            at = now, expiresAt = now + WARNING_LINK_TTL_MS,
        }
        rememberKey(Perception.AllyWarningCallerAt, Perception.AllyWarningCallerKeys, callerKey, now + CALLER_COOLDOWN_MS)
        rememberKey(Perception.AllyWarningTeamThreatAt, Perception.AllyWarningTeamKeys, dedupKey, now + TEAM_THREAT_DEDUP_MS)
        Perception.AllyWarningStats.published = Perception.AllyWarningStats.published + 1
        Perception.AllyWarningStats.notified = Perception.AllyWarningStats.notified + #notified
        local bus = PsychopatzCore and PsychopatzCore.ShockingEventBus or nil
        if bus and type(bus.Emit) == "function" then
            bus.Emit({
                eventType = "shock.ally_threat_warning", x = cx, y = cy, z = cz,
                radius = baseRadius, severity = 75, sourceId = callerKey, dedupKey = "ally_warn:" .. dedupKey, at = now,
            })
        end
    end
    return {
        emitted = #notified > 0, reason = #notified > 0 and "warned" or "no_eligible_allies",
        descriptor = descriptor, teamKey = teamKey, notified = notified,
    }
end

return Perception
