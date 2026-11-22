-- Cone-bypass predicate, recipient application, and LOS-gated alert resolver.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception, Internal = PNC.Perception, PNC.Perception.Internal
local Core, Registry = PNC.Core, PNC.Registry

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return Core and type(Core.Now) == "function" and (tonumber(Core.Now()) or 0) or 0
end

local function distSq(x1, y1, x2, y2)
    if Core and type(Core.DistanceSq) == "function" then return Core.DistanceSq(x1, y1, x2, y2) end
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

local function turnAllyToward(ally, tx, ty, at)
    local dx, dy = tx - (tonumber(ally.x) or tx), ty - (tonumber(ally.y) or ty)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len > 0.05 then ally.runtime.facingDirX, ally.runtime.facingDirY = dx / len, dy / len end
    local sec = PNC.SecondaryChannel
    if not sec then return end
    if sec.SetAlertLevel then sec.SetAlertLevel(ally, "tense") end
    if sec.RequestGaze then sec.RequestGaze(ally, tx, ty, 3500, at) end
    local bodyAlive = Internal.AllyWarningBodyAlive
    if ally.runtime.target == nil and Registry and Registry.GetLiveZombie and sec.ApplyGazeToBody then
        local body = Registry.GetLiveZombie(ally.id)
        if not bodyAlive or bodyAlive(body) then sec.ApplyGazeToBody(body, tx, ty) end
    end
end

function Internal.ApplyAllyThreatAlert(callerKey, item, desc, now, staggerIdx)
    local ally = item.record
    ally.runtime = type(ally.runtime) == "table" and ally.runtime or {}
    local canEngage, worldObj, engageReason = Perception.CanAllyEngageThreat(ally, desc)
    local objForLos = (desc.kind == "foreign_npc" and type(worldObj) == "table") and worldObj.worldObject or worldObj
    local hasLOS = objForLos ~= nil and Perception.CanSeeWorldObject ~= nil and Perception.CanSeeWorldObject(ally, objForLos) == true or false

    ally.runtime.allyThreatAlert = {
        kind = desc.kind, key = desc.key, id = desc.id, zombieId = desc.zombieId,
        onlineID = desc.onlineID, username = desc.username, provider = desc.provider,
        actorId = desc.actorId, generation = desc.generation, x = desc.x, y = desc.y, z = desc.z,
        semanticClass = desc.semanticClass, callerId = callerKey, relationKind = item.relationKind,
        observedAt = now, expiresAt = now + 6000, viaAllyWarning = true,
        canEngage = canEngage, engageReason = engageReason, alertRadius = item.effRadius,
    }
    ally.runtime.allyThreatAlertCheckAt, ally.runtime.allyThreatAlertVisible = 0, hasLOS
    ally.runtime.allyWarnedCooldownUntil = now + 3500
    ally.runtime.lastWarningLink = {
        kind = item.relationKind, role = "recipient", actorId = callerKey, threatKind = desc.kind,
        x = desc.x, y = desc.y, z = desc.z, at = now, expiresAt = now + 2500,
    }
    if PNC.PerceptionService and PNC.PerceptionService.RecordClue then
        PNC.PerceptionService.RecordClue(ally, {
            key = "ally_warn:" .. desc.key, kind = "ally_warning", x = desc.x, y = desc.y, z = desc.z,
            sourceId = callerKey, severity = 78, ttlMs = 8000,
        }, now)
    end
    turnAllyToward(ally, desc.x, desc.y, now)
    if Perception.InvalidateFrame then Perception.InvalidateFrame(ally) end
    local staggerMs = 150 + math.min(300, staggerIdx * 75)
    if ally.nextThinkAt == nil or tonumber(ally.nextThinkAt) > now + staggerMs then
        ally.nextThinkAt = now + staggerMs
    end
    return {
        record = ally, distSq = item.distSq, relationKind = item.relationKind,
        canEngage = canEngage, engageReason = engageReason, hasLOS = hasLOS, staggerMs = staggerMs,
    }
end

function Perception.IsWarnedThreat(record, kind, id, provider, at)
    local alert = type(record) == "table" and record.runtime and record.runtime.allyThreatAlert or nil
    if type(alert) ~= "table" or nowMs(at) >= (tonumber(alert.expiresAt) or 0) then return false end
    if tostring(alert.kind or "") ~= tostring(kind or "") then return false end
    if kind == "zombie" then return tostring(alert.zombieId or "") == tostring(id or "")
    elseif kind == "npc" then return tostring(alert.id or "") == tostring(id or "")
    elseif kind == "player" then
        if alert.onlineID ~= nil and tonumber(id) ~= nil then return tostring(alert.onlineID) == tostring(id) end
        return tostring(alert.username or "") == tostring(id or "")
    elseif kind == "foreign_npc" then
        return tostring(alert.provider or "") == tostring(provider or "")
            and tostring(alert.actorId or alert.id or "") == tostring(id or "")
    end
    return false
end

function Perception.FindAllyThreatAlert(record, radius, allowUnseen)
    local auth = not Core or type(Core.IsAuthority) ~= "function" or Core.IsAuthority() == true
    if not auth or type(record) ~= "table" or record.alive == false then return nil end
    local runtime = type(record.runtime) == "table" and record.runtime or nil
    local alert = runtime and runtime.allyThreatAlert or nil
    if type(alert) ~= "table" then return nil end
    local now = nowMs()
    if now >= (tonumber(alert.expiresAt) or 0) then runtime.allyThreatAlert = nil return nil end

    local canEngage, resolvedObj = Perception.CanAllyEngageThreat(record, alert)
    if not canEngage or not resolvedObj then
        if not resolvedObj then runtime.allyThreatAlert = nil end
        return nil
    end
    local losObj = (alert.kind == "foreign_npc" and type(resolvedObj) == "table") and resolvedObj.worldObject or resolvedObj
    local coord = Internal.AllyWarningCoord
    local tx, ty, tz = coord(losObj, "getX", alert.x), coord(losObj, "getY", alert.y), coord(losObj, "getZ", alert.z) or 0
    if tx == nil or ty == nil or math.abs(tz - (tonumber(record.z) or 0)) >= 1.0 then return nil end
    local dSq = distSq(record.x, record.y, tx, ty)
    local limit = math.max(tonumber(radius) or 0, tonumber(alert.alertRadius) or 16.0)
    if dSq > limit * limit then return nil end

    if now >= (tonumber(runtime.allyThreatAlertCheckAt) or 0) then
        runtime.allyThreatAlertCheckAt = now + 250
        local visible, kind = false, "los_unavailable"
        if Perception.CanSeeWorldObject then visible, kind = Perception.CanSeeWorldObject(record, losObj) end
        runtime.allyThreatAlertVisible, runtime.allyThreatAlertVisibilityKind = visible == true, kind
    end
    if runtime.allyThreatAlertVisible ~= true then
        if allowUnseen ~= true then return nil end
        return nil
    end

    local target = {
        kind = alert.kind, x = tx, y = ty, z = tz, distSq = dSq, visible = true,
        visibilityKind = runtime.allyThreatAlertVisibilityKind or "ally_warning",
        lastSeenAt = now, threatening = true, viaAllyWarning = true, groupAlert = true, alertRadius = limit,
    }
    if alert.kind == "zombie" then target.zombieId = alert.zombieId
    elseif alert.kind == "npc" then target.id = alert.id
    elseif alert.kind == "player" then target.player, target.onlineID, target.username = resolvedObj, alert.onlineID, alert.username
    elseif alert.kind == "foreign_npc" then
        target.provider, target.actorId, target.generation = alert.provider, alert.actorId, alert.generation
        target.worldObject, target.threatClass = losObj, alert.semanticClass
    end
    return target
end

function Perception.ResetAllyThreatWarnings()
    Perception.AllyWarningCallerAt, Perception.AllyWarningTeamThreatAt = {}, {}
    Perception.AllyWarningCallerKeys, Perception.AllyWarningTeamKeys = {}, {}
    Perception.AllyWarningStats = { published = 0, notified = 0, throttled = 0, hopBlocked = 0 }
end

return Perception
