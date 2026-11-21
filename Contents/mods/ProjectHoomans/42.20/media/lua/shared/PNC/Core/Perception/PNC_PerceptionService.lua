-- Activity-sensitive perception pipeline, vision azimuth/range filter, budgeted LOS queue, bounded ClueMemory, and WorldSound hook.
PNC = PNC or {}
PNC.PerceptionService = PNC.PerceptionService or {}

local Service = PNC.PerceptionService
local ReactionPolicyRegistry = PNC.ReactionPolicy and PNC.ReactionPolicy.Registry
if not ReactionPolicyRegistry and type(require) == "function" then
    ReactionPolicyRegistry = require "PNC/ReactionPolicy/Registry"
end

Service.MAX_LOS_PER_TICK = 8
Service.DEFAULT_VISION_RANGE = 22.0
Service.DEFAULT_HEARING_RANGE = 34.0
Service.DEFAULT_COS_HALF_FOV = 0.5 -- cos(60 deg) -> 120 deg cone
Service.CLOSE_PERIPHERAL_DIST_SQ = 6.25 -- 2.5m proximity peripheral awareness
Service.DEFAULT_MAX_CLUES = 6
Service.DEFAULT_CLUE_TTL_MS = 20000
Service.MAX_WORLD_SOUND_LISTENERS = 16

Service._losQueue = Service._losQueue or {}
Service._losHead = Service._losHead or 1
Service._losTail = Service._losTail or 0
Service._losPending = Service._losPending or {}
Service._stats = Service._stats or {
    coneRejected = 0,
    losQueued = 0,
    losExecuted = 0,
    cluesRecorded = 0,
    worldSoundsProcessed = 0,
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function policyRegistry()
    if PNC.ReactionPolicy and PNC.ReactionPolicy.Registry then
        return PNC.ReactionPolicy.Registry
    end
    return ReactionPolicyRegistry
end

function Service.GetProfile(record)
    local reg = policyRegistry()
    local profiles = reg and reg.perceptionProfiles or nil
    if type(profiles) ~= "table" then
        return {
            id = "fallback",
            visionRange = Service.DEFAULT_VISION_RANGE,
            hearingRange = Service.DEFAULT_HEARING_RANGE,
            cosHalfFov = Service.DEFAULT_COS_HALF_FOV,
            clueMemoryTtlMs = Service.DEFAULT_CLUE_TTL_MS,
            maxClues = Service.DEFAULT_MAX_CLUES,
            cadenceMs = { combat = 100, alert = 250, moving = 250, idle = 1000 },
        }
    end
    local explicit = record and record.perceptionProfileId
    if explicit and profiles[explicit] then
        return profiles[explicit]
    end
    local orderKind = tostring(record and record.orderSpec and record.orderSpec.kind or "")
    if (orderKind == "guard" or orderKind == "patrol") and profiles["profile.guard_alert"] then
        return profiles["profile.guard_alert"]
    end
    return profiles["profile.colonist_default"] or {
        id = "fallback",
        visionRange = Service.DEFAULT_VISION_RANGE,
        hearingRange = Service.DEFAULT_HEARING_RANGE,
        cosHalfFov = Service.DEFAULT_COS_HALF_FOV,
        clueMemoryTtlMs = Service.DEFAULT_CLUE_TTL_MS,
        maxClues = Service.DEFAULT_MAX_CLUES,
        cadenceMs = { combat = 100, alert = 250, moving = 250, idle = 1000 },
    }
end

function Service.GetCadenceMs(record, profile, at)
    profile = profile or Service.GetProfile(record)
    local cadence = type(profile.cadenceMs) == "table" and profile.cadenceMs or {}
    local runtime = type(record) == "table" and type(record.runtime) == "table" and record.runtime or nil
    local current = nowMs(at)
    if runtime then
        if runtime.combatTarget ~= nil
            or runtime.attackAction ~= nil
            or current < (tonumber(runtime.inCombatUntil) or 0)
        then
            return tonumber(cadence.combat) or 100
        end
        local sc = runtime.secondaryChannel
        if (sc and sc.alertLevel and sc.alertLevel ~= "calm")
            or current < (tonumber(runtime.alertUntil) or 0)
        then
            return tonumber(cadence.alert) or 250
        end
        if runtime.path ~= nil
            or runtime.moving == true
            or tostring(record and record.activeBehavior or ""):find("Travel", 1, true)
        then
            return tonumber(cadence.moving) or 250
        end
    end
    return tonumber(cadence.idle) or 1000
end

function Service.ShouldScan(record, at, profile)
    if type(record) ~= "table" or record.alive == false then return false end
    local current = nowMs(at)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local nextAt = tonumber(record.runtime.nextPerceptionScanAt) or 0
    if current < nextAt then
        return false
    end
    local cadenceMs = Service.GetCadenceMs(record, profile, current)
    record.runtime.nextPerceptionScanAt = current + cadenceMs
    return true
end

local function resolveFacingUnit(record, zombie)
    local runtime = type(record) == "table" and record.runtime or nil
    local fx = runtime and tonumber(runtime.facingDirX) or nil
    local fy = runtime and tonumber(runtime.facingDirY) or nil
    if (fx == nil or fy == nil)
        and PNC.ActorFacing
        and type(PNC.ActorFacing.Resolve) == "function"
    then
        local resolved = PNC.ActorFacing.Resolve(record, { body = zombie })
        if resolved and resolved.x ~= nil and resolved.y ~= nil then
            fx = resolved.x
            fy = resolved.y
        end
    end
    if (fx == nil or fy == nil) and zombie then
        if type(zombie.getForwardDirection) == "function" then
            local dir = zombie:getForwardDirection()
            if dir then
                fx = tonumber(dir.getX and dir:getX() or dir.x)
                fy = tonumber(dir.getY and dir:getY() or dir.y)
            end
        elseif type(zombie.getDirectionAngle) == "function" then
            local rad = tonumber(zombie:getDirectionAngle())
            if rad then
                fx = math.cos(rad)
                fy = math.sin(rad)
            end
        end
    end
    if fx == nil or fy == nil then
        return nil, nil, false
    end
    local lenSq = fx * fx + fy * fy
    if lenSq <= 1e-6 then
        return nil, nil, false
    end
    local inv = 1 / math.sqrt(lenSq)
    return fx * inv, fy * inv, true
end

function Service.ResolveFacing(record, zombie)
    return resolveFacingUnit(record, zombie)
end

function Service.GetHalfFovDegrees(profile)
    local cosHalf = tonumber(profile and profile.cosHalfFov) or Service.DEFAULT_COS_HALF_FOV
    cosHalf = math.max(-1, math.min(1, cosHalf))
    return math.deg(math.acos(cosHalf))
end

function Service.HasPendingLOS()
    return (tonumber(Service._losHead) or 1) <= (tonumber(Service._losTail) or 0)
end

---Local squared-distance + cosine azimuth cone filter prior to any Ray/LOS call.
---Respects 2.5m 360-degree peripheral awareness and optional bypass/fallback flags.
function Service.CheckCombatVisionCone(record, targetX, targetY, targetZ, profile, zombie, opts)
    if type(record) ~= "table" or targetX == nil or targetY == nil then
        return false, math.huge, -1
    end
    opts = type(opts) == "table" and opts or nil
    profile = profile or Service.GetProfile(record)
    local ox = tonumber(record.x) or (zombie and zombie.getX and zombie:getX()) or 0
    local oy = tonumber(record.y) or (zombie and zombie.getY and zombie:getY()) or 0
    local oz = tonumber(record.z) or (zombie and zombie.getZ and zombie:getZ()) or 0
    local tz = tonumber(targetZ) or oz
    if math.abs(tz - oz) >= 1.0 then
        Service._stats.coneRejected = Service._stats.coneRejected + 1
        return false, math.huge, -1
    end
    local dx = (tonumber(targetX) or 0) - ox
    local dy = (tonumber(targetY) or 0) - oy
    local distSq = dx * dx + dy * dy
    local visionRange = (opts and tonumber(opts.radius))
        or tonumber(profile.visionRange)
        or Service.DEFAULT_VISION_RANGE
    if distSq > visionRange * visionRange then
        Service._stats.coneRejected = Service._stats.coneRejected + 1
        return false, distSq, -1
    end
    if distSq <= Service.CLOSE_PERIPHERAL_DIST_SQ or (opts and opts.bypassCone == true) then
        return true, distSq, 1
    end
    local fx, fy, hasHeading = resolveFacingUnit(record, zombie)
    if not hasHeading then
        if opts and opts.enforceHeadingFallback == true then
            fx, fy = 1, 0
        else
            return true, distSq, 1
        end
    end
    local dist = math.sqrt(distSq)
    local dot = (dx * fx + dy * fy) / dist
    local cosHalf = tonumber(profile.cosHalfFov) or Service.DEFAULT_COS_HALF_FOV
    if dot < cosHalf then
        Service._stats.coneRejected = Service._stats.coneRejected + 1
        return false, distSq, dot
    end
    return true, distSq, dot
end

function Service.PassesBodyVisionCone(record, targetObject, profile, zombie, opts)
    if not record or not targetObject or type(targetObject.getX) ~= "function" then
        return false
    end
    return Service.CheckCombatVisionCone(
        record,
        targetObject:getX(),
        targetObject:getY(),
        type(targetObject.getZ) == "function" and targetObject:getZ() or record.z,
        profile,
        zombie,
        opts
    )
end

---Local squared-distance + precomputed cosine azimuth pre-filter prior to any Ray/LOS call.
function Service.CheckVisionCone(record, targetX, targetY, targetZ, profile, zombie)
    return Service.CheckCombatVisionCone(
        record, targetX, targetY, targetZ, profile, zombie,
        { enforceHeadingFallback = true }
    )
end

function Service.PruneClues(record, at)
    local runtime = type(record) == "table" and record.runtime or nil
    local list = runtime and runtime.clueMemory or nil
    if type(list) ~= "table" or #list == 0 then return 0 end
    local current = nowMs(at)
    local removed = 0
    for i = #list, 1, -1 do
        local clue = list[i]
        if type(clue) ~= "table" or (tonumber(clue.expiresAt) or 0) <= current then
            table.remove(list, i)
            removed = removed + 1
        end
    end
    return removed
end

function Service.RecordClue(record, clueSpec, at)
    if type(record) ~= "table" or type(clueSpec) ~= "table" then return nil end
    local current = nowMs(at)
    local profile = Service.GetProfile(record)
    local ttlMs = tonumber(clueSpec.ttlMs) or tonumber(profile.clueMemoryTtlMs) or Service.DEFAULT_CLUE_TTL_MS
    local maxClues = math.max(1, math.floor(tonumber(profile.maxClues) or Service.DEFAULT_MAX_CLUES))

    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime.clueMemory = type(record.runtime.clueMemory) == "table" and record.runtime.clueMemory or {}
    local list = record.runtime.clueMemory
    Service.PruneClues(record, current)

    local key = tostring(clueSpec.key or clueSpec.sourceId or clueSpec.kind or "clue")
    local entry = {
        key = key,
        kind = tostring(clueSpec.kind or "clue"),
        x = tonumber(clueSpec.x) or tonumber(record.x) or 0,
        y = tonumber(clueSpec.y) or tonumber(record.y) or 0,
        z = tonumber(clueSpec.z) or tonumber(record.z) or 0,
        sourceId = clueSpec.sourceId,
        severity = tonumber(clueSpec.severity) or 50,
        recordedAt = current,
        expiresAt = current + math.max(100, ttlMs),
    }

    local replaced = false
    for i = 1, #list do
        if list[i].key == key then
            list[i] = entry
            replaced = true
            break
        end
    end
    if not replaced then
        list[#list + 1] = entry
    end
    while #list > maxClues do
        table.remove(list, 1)
    end
    Service._stats.cluesRecorded = Service._stats.cluesRecorded + 1
    return entry
end

function Service.GetClues(record, at)
    Service.PruneClues(record, at)
    local list = record and record.runtime and record.runtime.clueMemory or nil
    if type(list) ~= "table" then return {} end
    local copy = {}
    for i = 1, #list do
        copy[i] = list[i]
    end
    return copy
end

function Service.GetMostRecentClue(record, kindFilter, at)
    Service.PruneClues(record, at)
    local list = record and record.runtime and record.runtime.clueMemory or nil
    if type(list) ~= "table" then return nil end
    local best = nil
    for i = #list, 1, -1 do
        local c = list[i]
        if kindFilter == nil or c.kind == kindFilter then
            if not best or (tonumber(c.recordedAt) or 0) > (tonumber(best.recordedAt) or 0) then
                best = c
            end
        end
    end
    return best
end

function Service.ClearClues(record)
    if type(record) == "table" and type(record.runtime) == "table" then
        record.runtime.clueMemory = nil
    end
end

local function compactLosQueue()
    if Service._losHead <= 64 or Service._losHead <= Service._losTail / 2 then
        return
    end
    local compacted = {}
    local idx = 0
    for i = Service._losHead, Service._losTail do
        local item = Service._losQueue[i]
        if item ~= nil then
            idx = idx + 1
            compacted[idx] = item
        end
    end
    Service._losQueue = compacted
    Service._losHead = 1
    Service._losTail = idx
end

function Service.QueueLOSCheck(record, targetObject, targetKey, callback, opts)
    if type(record) ~= "table" or not record.id or not targetObject then
        return false, "INVALID_LOS_REQUEST"
    end
    local npcId = tostring(record.id)
    local tKey = tostring(targetKey or tostring(targetObject))
    local compositeKey = npcId .. "|" .. tKey
    if Service._losPending[compositeKey] then
        return false, "ALREADY_QUEUED"
    end
    opts = type(opts) == "table" and opts or {}
    Service._losPending[compositeKey] = true
    Service._losTail = Service._losTail + 1
    Service._losQueue[Service._losTail] = {
        compositeKey = compositeKey,
        npcId = npcId,
        targetKey = tKey,
        record = record,
        targetObject = targetObject,
        callback = callback,
        x = tonumber(opts.x),
        y = tonumber(opts.y),
        z = tonumber(opts.z),
        queuedAt = nowMs(opts.at),
    }
    Service._stats.losQueued = Service._stats.losQueued + 1
    return true
end

function Service.PumpLOSQueue(at, budget)
    local current = nowMs(at)
    local maxBudget = math.max(1, math.floor(tonumber(budget) or Service.MAX_LOS_PER_TICK))
    local executed = 0
    while executed < maxBudget and Service._losHead <= Service._losTail do
        local item = Service._losQueue[Service._losHead]
        Service._losQueue[Service._losHead] = nil
        Service._losHead = Service._losHead + 1
        if item then
            Service._losPending[item.compositeKey] = nil
            local record = item.record
            if record and record.alive ~= false then
                local visible = false
                local reason = "los_blocked"
                if PNC.Perception and type(PNC.Perception.CanSeeWorldObject) == "function" then
                    local vis, r = PNC.Perception.CanSeeWorldObject(record, item.targetObject)
                    visible = vis == true
                    reason = r or (visible and "clear" or "blocked")
                elseif PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function" then
                    local live = PNC.Registry.GetLiveZombie(record.id)
                    if live and type(live.CanSee) == "function" then
                        visible = live:CanSee(item.targetObject) == true
                        reason = visible and "can_see" or "blocked"
                    end
                end
                executed = executed + 1
                Service._stats.losExecuted = Service._stats.losExecuted + 1
                local clue = nil
                if visible then
                    local tx = item.x or (item.targetObject.getX and item.targetObject:getX())
                    local ty = item.y or (item.targetObject.getY and item.targetObject:getY())
                    local tz = item.z or (item.targetObject.getZ and item.targetObject:getZ()) or 0
                    clue = Service.RecordClue(record, {
                        key = "visual:" .. item.targetKey,
                        kind = "visual_lkp",
                        x = tx,
                        y = ty,
                        z = tz,
                        sourceId = item.targetKey,
                        severity = 65,
                    }, current)
                end
                if type(item.callback) == "function" then
                    item.callback(visible, visible and clue or reason, item)
                end
            end
        end
    end
    compactLosQueue()
    return executed
end

local function queryNearbyNPCs(x, y, radius)
    if PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function" then
        local nearby = PNC.SpatialIndex.QueryNPCs(x, y, radius)
        return type(nearby) == "table" and nearby or {}
    end
    local out = {}
    if PNC.Registry and type(PNC.Registry.Data) == "table" then
        for _, rec in pairs(PNC.Registry.Data) do
            if type(rec) == "table" and rec.alive ~= false then
                out[#out + 1] = rec
            end
        end
    end
    return out
end

function Service.OnWorldSound(x, y, z, radius, volume, source)
    if PNC.Core and type(PNC.Core.IsAuthority) == "function" and not PNC.Core.IsAuthority() then
        return 0
    end
    local sx = tonumber(x)
    local sy = tonumber(y)
    if sx == nil or sy == nil then return 0 end
    local sz = tonumber(z) or 0
    local sRadius = math.max(1, tonumber(radius) or 16)
    local sVol = tonumber(volume) or 20
    local current = nowMs()
    Service._stats.worldSoundsProcessed = Service._stats.worldSoundsProcessed + 1

    local listeners = queryNearbyNPCs(sx, sy, sRadius)
    local notified = 0
    local cellKey = tostring(math.floor(sx / 4)) .. ":" .. tostring(math.floor(sy / 4))
    for i = 1, math.min(Service.MAX_WORLD_SOUND_LISTENERS, #listeners) do
        local rec = listeners[i]
        if type(rec) == "table" and rec.alive ~= false and rec.x ~= nil and rec.y ~= nil then
            local rz = tonumber(rec.z) or 0
            if math.abs(rz - sz) <= 1.0 then
                local profile = Service.GetProfile(rec)
                local hearingRange = tonumber(profile.hearingRange) or Service.DEFAULT_HEARING_RANGE
                local effRange = math.min(sRadius, hearingRange)
                local dx = (tonumber(rec.x) or 0) - sx
                local dy = (tonumber(rec.y) or 0) - sy
                if dx * dx + dy * dy <= effRange * effRange then
                    Service.RecordClue(rec, {
                        key = "sound:" .. cellKey,
                        kind = "sound",
                        x = sx,
                        y = sy,
                        z = sz,
                        sourceId = source,
                        severity = sVol >= 60 and 80 or 45,
                    }, current)
                    notified = notified + 1
                end
            end
        end
    end

    local bus = PsychopatzCore and PsychopatzCore.ShockingEventBus or nil
    if bus and type(bus.Emit) == "function" and (sVol >= 15 or sRadius >= 12) then
        local eventType = (sVol >= 60 or sRadius >= 45) and "shock.gunfire" or "shock.suspicious_sound"
        bus.Emit({
            eventType = eventType,
            x = sx,
            y = sy,
            z = sz,
            radius = sRadius,
            severity = math.max(30, math.min(100, sVol)),
            sourceId = source,
            dedupKey = "sound:" .. cellKey,
            at = current,
        })
    end
    return notified
end

function Service.GetStats()
    return {
        coneRejected = Service._stats.coneRejected,
        losQueued = Service._stats.losQueued,
        losExecuted = Service._stats.losExecuted,
        cluesRecorded = Service._stats.cluesRecorded,
        worldSoundsProcessed = Service._stats.worldSoundsProcessed,
    }
end

function Service.Reset()
    Service._losQueue = {}
    Service._losHead = 1
    Service._losTail = 0
    Service._losPending = {}
    Service._stats = {
        coneRejected = 0,
        losQueued = 0,
        losExecuted = 0,
        cluesRecorded = 0,
        worldSoundsProcessed = 0,
    }
end

if Events and Events.OnWorldSound and type(Events.OnWorldSound.Add) == "function"
    and not Service._worldSoundHooked
then
    Service._worldSoundHooked = true
    Events.OnWorldSound.Add(function(x, y, z, radius, volume, source)
        Service.OnWorldSound(x, y, z, radius, volume, source)
    end)
end

return Service
