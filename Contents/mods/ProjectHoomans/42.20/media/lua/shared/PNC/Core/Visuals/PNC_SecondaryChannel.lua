-- Orthogonal non-interrupting Secondary Layer: coincident-guarded gaze, Build 42 AnimSet vars, priority-gated barks, and domain-delta replication.
PNC = PNC or {}
PNC.SecondaryChannel = PNC.SecondaryChannel or {}

local Secondary = PNC.SecondaryChannel
local ReactionPolicyRegistry = PNC.ReactionPolicy and PNC.ReactionPolicy.Registry
if not ReactionPolicyRegistry and type(require) == "function" then
    ReactionPolicyRegistry = require "PNC/ReactionPolicy/Registry"
end

Secondary.COINCIDENT_DIST_SQ = 0.01 -- (0.1m)^2 avoids IsoGameCharacter.faceLocationF NaN
Secondary.DEFAULT_ALERT_LEVEL = "calm"
Secondary.DEFAULT_POSTURE = "relaxed"
Secondary.MIN_BARK_PLAY_WEIGHT = 0.15
Secondary.BARK_RECOVERY_WINDOW_SEC = 180.0
Secondary.DEFAULT_BARK_DURATION_MS = 2500

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

function Secondary.EnsureState(record)
    if type(record) ~= "table" then return nil end
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local sc = record.runtime.secondaryChannel
    if type(sc) ~= "table" then
        sc = {
            alertLevel = Secondary.DEFAULT_ALERT_LEVEL,
            posture = Secondary.DEFAULT_POSTURE,
            secondaryState = "",
            gazeX = nil,
            gazeY = nil,
            gazeUntil = 0,
            barkSeq = 0,
            lastBarkId = nil,
            lastBarkVoiceEvent = nil,
            activeBarkPriority = -1,
            activeBarkUntil = 0,
            barks = {},
            revision = 0,
        }
        record.runtime.secondaryChannel = sc
    end
    return sc
end

---Requests head/body gaze toward `(tx, ty)` without disturbing any active Tasking lease.
function Secondary.RequestGaze(record, tx, ty, ttlMs, at)
    local x = tonumber(tx)
    local y = tonumber(ty)
    if type(record) ~= "table" or x == nil or y == nil then
        return false, "INVALID_GAZE_TARGET"
    end
    local sc = Secondary.EnsureState(record)
    local current = nowMs(at)
    local duration = math.max(100, tonumber(ttlMs) or 2000)
    sc.gazeX = x
    sc.gazeY = y
    sc.gazeUntil = current + duration
    sc.revision = (tonumber(sc.revision) or 0) + 1
    return true
end

---Applies `faceLocationF(tx, ty)` only when strictly non-coincident with `zombie` position.
function Secondary.ApplyGazeToBody(zombie, tx, ty)
    if not zombie or type(zombie.faceLocationF) ~= "function" then
        return false, "FACE_LOCATION_UNAVAILABLE"
    end
    local x = tonumber(tx)
    local y = tonumber(ty)
    if x == nil or y == nil then
        return false, "INVALID_GAZE_TARGET"
    end
    local zx = tonumber(zombie.getX and zombie:getX()) or nil
    local zy = tonumber(zombie.getY and zombie:getY()) or nil
    if zx == nil or zy == nil then
        return false, "BODY_POSITION_UNAVAILABLE"
    end
    local dx = x - zx
    local dy = y - zy
    if dx * dx + dy * dy <= Secondary.COINCIDENT_DIST_SQ then
        return false, "COINCIDENT_TARGET"
    end
    zombie:faceLocationF(x, y)
    return true
end

function Secondary.ApplyGaze(record, zombie, at)
    local sc = record and record.runtime and record.runtime.secondaryChannel or nil
    if not sc then return false, "NO_SECONDARY_STATE" end
    local current = nowMs(at)
    if sc.gazeX == nil or sc.gazeY == nil or current >= (tonumber(sc.gazeUntil) or 0) then
        sc.gazeX = nil
        sc.gazeY = nil
        sc.gazeUntil = 0
        return false, "GAZE_EXPIRED"
    end
    return Secondary.ApplyGazeToBody(zombie, sc.gazeX, sc.gazeY)
end

function Secondary.ApplyAnimVars(record, zombie)
    local sc = record and record.runtime and record.runtime.secondaryChannel or nil
    if not zombie or type(zombie.setVariable) ~= "function" then return false end
    local alert = sc and tostring(sc.alertLevel or Secondary.DEFAULT_ALERT_LEVEL)
        or Secondary.DEFAULT_ALERT_LEVEL
    local posture = sc and tostring(sc.posture or Secondary.DEFAULT_POSTURE)
        or Secondary.DEFAULT_POSTURE
    local state = sc and tostring(sc.secondaryState or "") or ""
    zombie:setVariable("PNCAlertLevel", alert)
    zombie:setVariable("PNCPosture", posture)
    zombie:setVariable("PNCSecondaryState", state)
    return true
end

function Secondary.ClearAnimVars(zombie)
    if not zombie or type(zombie.setVariable) ~= "function" then return false end
    zombie:setVariable("PNCAlertLevel", Secondary.DEFAULT_ALERT_LEVEL)
    zombie:setVariable("PNCPosture", Secondary.DEFAULT_POSTURE)
    zombie:setVariable("PNCSecondaryState", "")
    return true
end

function Secondary.SetAlertLevel(record, level, zombie)
    local sc = Secondary.EnsureState(record)
    if not sc then return false end
    local nextVal = tostring(level or Secondary.DEFAULT_ALERT_LEVEL)
    if sc.alertLevel ~= nextVal then
        sc.alertLevel = nextVal
        sc.revision = (tonumber(sc.revision) or 0) + 1
    end
    if zombie then
        Secondary.ApplyAnimVars(record, zombie)
    end
    return true
end

function Secondary.SetPosture(record, posture, zombie)
    local sc = Secondary.EnsureState(record)
    if not sc then return false end
    local nextVal = tostring(posture or Secondary.DEFAULT_POSTURE)
    if sc.posture ~= nextVal then
        sc.posture = nextVal
        sc.revision = (tonumber(sc.revision) or 0) + 1
    end
    if zombie then
        Secondary.ApplyAnimVars(record, zombie)
    end
    return true
end

function Secondary.SetSecondaryState(record, state, zombie, ttlMs, at)
    local sc = Secondary.EnsureState(record)
    if not sc then return false end
    local nextVal = tostring(state or "")
    local current = nowMs(at)
    sc.secondaryState = nextVal
    sc.secondaryStateUntil = ttlMs and (current + math.max(0, tonumber(ttlMs) or 0)) or nil
    sc.revision = (tonumber(sc.revision) or 0) + 1
    if zombie then
        Secondary.ApplyAnimVars(record, zombie)
    end
    return true
end

---Requests a compiled bark with speech priority gating and lazy multiplicative line-exhaustion decay.
function Secondary.RequestBark(record, barkId, at, opts)
    if type(record) ~= "table" then return false, "RECORD_REQUIRED" end
    local key = tostring(barkId or "")
    if key == "" then return false, "BARK_ID_REQUIRED" end
    opts = type(opts) == "table" and opts or {}

    local reg = policyRegistry()
    local bark = reg and reg.GetBark and reg.GetBark(key) or nil
    if not bark then return false, "UNKNOWN_BARK" end

    local sc = Secondary.EnsureState(record)
    local current = nowMs(at)
    local priority = tonumber(bark.priority) or 50

    if current < (tonumber(sc.activeBarkUntil) or 0)
        and priority <= (tonumber(sc.activeBarkPriority) or -1)
        and opts.force ~= true
    then
        return false, "LOWER_SPEECH_PRIORITY"
    end

    local entry = sc.barks[key]
    if not entry then
        entry = {
            weight = 1.0,
            lastPlayedAt = -math.huge,
            cooldownUntil = 0,
            playCount = 0,
        }
        sc.barks[key] = entry
    end

    if current < (tonumber(entry.cooldownUntil) or 0) and opts.force ~= true then
        return false, "BARK_COOLDOWN"
    end

    local recovered = entry.weight
    if entry.lastPlayedAt and entry.lastPlayedAt > -math.huge then
        local elapsedSec = math.max(0, (current - entry.lastPlayedAt) / 1000)
        recovered = math.min(1.0, entry.weight + (elapsedSec / Secondary.BARK_RECOVERY_WINDOW_SEC))
    end
    if recovered < Secondary.MIN_BARK_PLAY_WEIGHT and opts.force ~= true then
        entry.weight = recovered
        return false, "BARK_EXHAUSTED"
    end

    local decay = tonumber(bark.exhaustionDecay) or 0.5
    local cooldownMs = tonumber(bark.cooldownMs) or 5000
    entry.weight = math.max(0.05, recovered * decay)
    entry.lastPlayedAt = current
    entry.cooldownUntil = current + math.max(0, cooldownMs)
    entry.playCount = (tonumber(entry.playCount) or 0) + 1

    sc.barkSeq = (tonumber(sc.barkSeq) or 0) + 1
    sc.lastBarkId = key
    sc.lastBarkVoiceEvent = bark.voiceEvent
    sc.activeBarkPriority = priority
    sc.activeBarkUntil = current + Secondary.DEFAULT_BARK_DURATION_MS
    sc.revision = (tonumber(sc.revision) or 0) + 1

    if bark.secondaryAnimVar == "PNCPosture" and sc.posture == Secondary.DEFAULT_POSTURE then
        sc.posture = "alert"
    elseif bark.secondaryAnimVar == "PNCSecondaryState" and sc.secondaryState == "" then
        sc.secondaryState = "warn"
    end

    return true, {
        barkId = key,
        barkSeq = sc.barkSeq,
        voiceEvent = bark.voiceEvent,
        priority = priority,
        weightAfter = entry.weight,
    }
end

function Secondary.ClearForRecord(record, zombie)
    if type(record) == "table" and type(record.runtime) == "table" then
        record.runtime.secondaryChannel = nil
    end
    if zombie then
        Secondary.ClearAnimVars(zombie)
    end
end

function Secondary.BuildDeltaPayload(record, at)
    local sc = type(record) == "table" and record.runtime and record.runtime.secondaryChannel or nil
    if type(sc) ~= "table" then return nil end
    local current = nowMs(at)
    local hasGaze = sc.gazeX ~= nil and sc.gazeY ~= nil and current < (tonumber(sc.gazeUntil) or 0)
    local hasBark = sc.barkSeq ~= nil and sc.barkSeq > 0 and current < (tonumber(sc.activeBarkUntil) or 0)
    local alert = tostring(sc.alertLevel or Secondary.DEFAULT_ALERT_LEVEL)
    local posture = tostring(sc.posture or Secondary.DEFAULT_POSTURE)
    local state = tostring(sc.secondaryState or "")
    if not hasGaze and not hasBark
        and alert == Secondary.DEFAULT_ALERT_LEVEL
        and posture == Secondary.DEFAULT_POSTURE
        and state == ""
    then
        return nil
    end
    return {
        alertLevel = alert,
        posture = posture,
        secondaryState = state,
        gazeX = hasGaze and sc.gazeX or nil,
        gazeY = hasGaze and sc.gazeY or nil,
        barkId = hasBark and sc.lastBarkId or nil,
        barkSeq = sc.barkSeq,
        barkVoiceEvent = hasBark and sc.lastBarkVoiceEvent or nil,
        revision = sc.revision,
    }
end

function Secondary.ApplyClientSnapshot(snapshot, zombie, modData)
    if not zombie then return false end
    local sc = type(snapshot) == "table" and snapshot.secondaryChannel or nil
    if type(sc) ~= "table" then
        if modData and modData.PNC_SecondaryApplied == true then
            Secondary.ClearAnimVars(zombie)
            modData.PNC_SecondaryApplied = nil
        end
        return false
    end
    if zombie.setVariable then
        zombie:setVariable("PNCAlertLevel", tostring(sc.alertLevel or Secondary.DEFAULT_ALERT_LEVEL))
        zombie:setVariable("PNCPosture", tostring(sc.posture or Secondary.DEFAULT_POSTURE))
        zombie:setVariable("PNCSecondaryState", tostring(sc.secondaryState or ""))
    end
    if modData then
        modData.PNC_SecondaryApplied = true
    end
    if sc.gazeX ~= nil and sc.gazeY ~= nil then
        Secondary.ApplyGazeToBody(zombie, sc.gazeX, sc.gazeY)
    end
    local barkSeq = tonumber(sc.barkSeq) or 0
    if barkSeq > 0 and sc.barkVoiceEvent and (not modData or modData.PNC_LastBarkSeq ~= barkSeq) then
        if modData then
            modData.PNC_LastBarkSeq = barkSeq
        end
        local voice = PNC.NPCVoice
        local policy = voice and voice.Catalog and voice.Catalog.Get
            and voice.Catalog.Get(sc.barkVoiceEvent) or nil
        if voice and policy and policy.suffix then
            local options = {
                snapshot = snapshot,
                radius = policy.radius,
                volume = policy.volume,
                stressHumans = policy.stressHumans,
            }
            if policy.mode == voice.MODE_WORLD and type(voice.PlayWorld) == "function" then
                voice.PlayWorld(zombie, policy.suffix, options)
            elseif type(voice.PlayLocal) == "function" then
                voice.PlayLocal(zombie, policy.suffix, options)
            end
        end
    end
    return true
end

return Secondary
