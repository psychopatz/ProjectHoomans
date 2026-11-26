-- Dedicated opt-in audit logger for DialogueBeats.
-- Gated behind PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled so the
-- disabled path stays a single cheap boolean check with zero allocations.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local SNAPSHOT_INTERVAL_MS = 30000
local lastPeriodicSnapshotAt = -SNAPSHOT_INTERVAL_MS

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function diagnostics()
    return PNC.PerformanceScalingDiagnostics
end

function Beats.IsAuditEnabled()
    local diag = diagnostics()
    return diag ~= nil and diag.BeatsAuditEnabled == true
end

function Beats.AuditLog(eventName, fields)
    local diag = diagnostics()
    if not diag or diag.BeatsAuditEnabled ~= true then return false end
    if type(diag.LogBeatsAudit) == "function" then
        return diag.LogBeatsAudit(eventName, fields)
    end
    return false
end

local function formatHookEntries(entries)
    if type(entries) ~= "table" or #entries == 0 then return "none" end
    local parts = {}
    for i = 1, #entries do
        local e = entries[i]
        local rem = math.max(0, math.floor(tonumber(e.cooldownRemainingMs) or 0))
        local ready = rem <= 0 and "ready" or ("cd:" .. tostring(rem) .. "ms")
        parts[#parts + 1] = tostring(e.id) .. "(p=" .. tostring(e.priority or 0) .. "," .. ready .. ")"
    end
    return table.concat(parts, ";")
end

function Beats.LogAuditSnapshot(reason, at)
    if not Beats.IsAuditEnabled() then return false end
    local now = nowMs(at)
    local hookEntries = type(Beats.GetHookAuditEntries) == "function"
        and Beats.GetHookAuditEntries(now) or {}
    local objEntries = type(Beats.GetObjectHookAuditEntries) == "function"
        and Beats.GetObjectHookAuditEntries(now) or {}
    local devEntries = type(Beats.GetDeviceHookAuditEntries) == "function"
        and Beats.GetDeviceHookAuditEntries(now) or {}
    local activeThreads = 0
    if type(Beats.ActiveThreads) == "table" then
        for _ in pairs(Beats.ActiveThreads) do activeThreads = activeThreads + 1 end
    end

    local convoPools = 0
    local convoPending = 0
    local convoErrors = 0
    local cat = PNC.ConvoEngine and PNC.ConvoEngine.ResponseCatalog or nil
    if type(cat) == "table" then
        convoPools = tonumber(cat.POOL_COUNT) or 0
    end
    local dsl = PNC.ConvoEngine and PNC.ConvoEngine.ConvoDSL or nil
    if type(dsl) == "table" then
        if type(dsl.PendingCount) == "function" then
            convoPending = tonumber(dsl.PendingCount()) or 0
        end
        if type(dsl.GetDiagnostics) == "function" then
            local diag = dsl.GetDiagnostics()
            if type(diag) == "table" and type(diag.errors) == "table" then
                convoErrors = #diag.errors
            end
        end
    end

    Beats.AuditLog("snapshot", {
        "reason=" .. tostring(reason or "manual"),
        "now=" .. tostring(math.floor(now)),
        "pendingCount=" .. tostring(tonumber(Beats.PendingCount) or 0),
        "nextDueAt=" .. tostring(Beats.NextDueAt or "nil"),
        "nextEnvCheckAt=" .. tostring(tonumber(Beats.NextEnvCheckAt) or 0),
        "nextFloorAt=" .. tostring(math.floor(tonumber(Beats.NextFloorAt) or 0)),
        "floorRemainingMs=" .. tostring(math.max(0, math.floor((tonumber(Beats.NextFloorAt) or 0) - now))),
        "activeThreads=" .. tostring(activeThreads),
        "lastWeather=" .. tostring(Beats.LastWeather or "nil"),
        "hookCount=" .. tostring(#hookEntries),
        "objectHookCount=" .. tostring(#objEntries),
        "deviceHookCount=" .. tostring(#devEntries),
        "convoPools=" .. tostring(convoPools),
        "convoPending=" .. tostring(convoPending),
        "convoErrors=" .. tostring(convoErrors),
        "thunderHooked=" .. tostring(Beats._ThunderEventHooked == true),
        "worldSoundHooked=" .. tostring(Beats._HouseAlarmWorldSoundHooked == true),
        "ambientSoundHooked=" .. tostring(Beats._HouseAlarmAmbientSoundHooked == true),
        "metaAmbientSoundHooked=" .. tostring(Beats._MetaAmbientSoundHooked == true),
        "electricityHooked=" .. tostring(Beats._UtilitiesElectricityHooked == true),
        "deviceTextHooked=" .. tostring(Beats._WorldObjectDeviceTextHooked == true),
    })

    Beats.AuditLog("possible_beats", {
        "hooks=" .. formatHookEntries(hookEntries),
        "objectHooks=" .. formatHookEntries(objEntries),
        "deviceHooks=" .. formatHookEntries(devEntries),
    })

    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if BC then
        local w = type(BC.GetWorldWeather) == "function" and BC.GetWorldWeather(now) or nil
        local u = type(BC.GetWorldUtilities) == "function" and BC.GetWorldUtilities(now) or nil
        local utilState = type(Beats.GetUtilitiesAuditState) == "function"
            and Beats.GetUtilitiesAuditState() or {}
        Beats.AuditLog("env_state", {
            "weather=" .. tostring(w and w.weather or "nil"),
            "isHarsh=" .. tostring(w and w.isHarshWeather == true),
            "isRaining=" .. tostring(w and w.isRaining == true),
            "rainIntensity=" .. tostring(w and w.rainIntensity or "nil"),
            "isSnowing=" .. tostring(w and w.isSnowing == true),
            "snowIntensity=" .. tostring(w and w.snowIntensity or "nil"),
            "fogIntensity=" .. tostring(w and w.fogIntensity or "nil"),
            "windIntensity=" .. tostring(w and w.windIntensity or "nil"),
            "windKph=" .. tostring(w and w.windSpeedKph or "nil"),
            "isThunder=" .. tostring(w and w.isThunderStorming == true),
            "isBlizzard=" .. tostring(w and w.isBlizzard == true),
            "isTropical=" .. tostring(w and w.isTropicalStorm == true),
            "temp=" .. tostring(w and w.temperature or "nil"),
            "timeOfDay=" .. tostring(w and w.timeOfDay or "nil"),
            "currentDay=" .. tostring(u and u.currentDay or "nil"),
            "powerOn=" .. tostring(u and u.powerOn),
            "waterOn=" .. tostring(u and u.waterOn),
            "powerOutToday=" .. tostring(u and u.powerOutToday == true),
            "waterOutToday=" .. tostring(u and u.waterOutToday == true),
            "lastPowerState=" .. tostring(utilState.lastPowerState),
            "lastWaterState=" .. tostring(utilState.lastWaterState),
            "emittedPowerDay=" .. tostring(utilState.emittedPowerDay or "nil"),
            "emittedWaterDay=" .. tostring(utilState.emittedWaterDay or "nil"),
        })
        if type(BC.GetPlayerExposure) == "function" then
            local exp = BC.GetPlayerExposure(nil, now)
            local wxState = type(Beats.GetWeatherExposureAuditState) == "function"
                and Beats.GetWeatherExposureAuditState(now) or {}
            Beats.AuditLog("exposure_state", {
                "hasPlayer=" .. tostring(exp and exp.hasPlayer == true),
                "isOutside=" .. tostring(exp and exp.isOutside == true),
                "wetLevel=" .. tostring(exp and exp.wetLevel or 0),
                "wetness=" .. tostring(exp and math.floor(tonumber(exp.wetness) or 0) or 0),
                "hypo=" .. tostring(exp and exp.hypoLevel or 0),
                "hyper=" .. tostring(exp and exp.hyperLevel or 0),
                "windchill=" .. tostring(exp and exp.windchillLevel or 0),
                "hasCold=" .. tostring(exp and exp.hasCold == true),
                "isSoakingWet=" .. tostring(exp and exp.isSoakingWet == true),
                "lastCondition=" .. tostring(wxState.lastCondition or "none"),
                "exposureCdMs=" .. tostring(wxState.exposureCooldownRemainingMs or 0),
                "thunderStrikeCdMs=" .. tostring(wxState.thunderStrikeCooldownRemainingMs or 0),
                "thunderRumbleCdMs=" .. tostring(wxState.thunderRumbleCooldownRemainingMs or 0),
                "outdoorRainDwellMs=" .. tostring(wxState.outdoorRainDwellMs or 0),
            })
        end
    end

    if type(Beats.GetHouseAlarmAuditState) == "function" then
        local a = Beats.GetHouseAlarmAuditState(now)
        Beats.AuditLog("alarm_state", {
            "dedupeMs=" .. tostring(a.dedupeMs or 0),
            "retryMs=" .. tostring(a.retryMs or 0),
            "hearRadius=" .. tostring(a.hearRadius or 0),
            "bucketTiles=" .. tostring(a.bucketTiles or 0),
            "seenBucketCount=" .. tostring(a.seenBucketCount or 0),
            "retryBucketCount=" .. tostring(a.retryBucketCount or 0),
        })
    end

    if type(Beats.GetWorldObjectAuditState) == "function" then
        local wo = Beats.GetWorldObjectAuditState(now)
        Beats.AuditLog("world_object_state", {
            "nextObjectScanRemainingMs=" .. tostring(wo.nextObjectScanRemainingMs or 0),
            "globalCooldownRemainingMs=" .. tostring(wo.globalCooldownRemainingMs or 0),
            "deviceTextBucketCount=" .. tostring(wo.deviceTextBucketCount or 0),
        })
    end

    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if Dir and type(Dir.GetAuditState) == "function" then
        local ds = Dir.GetAuditState(now)
        Beats.AuditLog("director_state", {
            "density=" .. tostring(ds.densityName or "cinematic") .. "(" .. tostring(ds.densityLevel or 2) .. ")",
            "cooldownScale=" .. tostring(ds.cooldownScale or 1.0),
            "thresholdScale=" .. tostring(ds.thresholdScale or 1.0),
            "voiceCache=" .. tostring(ds.voiceCacheCount or 0),
            "saturation=" .. tostring(ds.saturationCount or 0),
            "storyGroups=" .. tostring(ds.storyGroupCount or 0),
            "storyMoments=" .. tostring(ds.storyMomentCount or 0),
            "pairBudgets=" .. tostring(ds.pairBudgetCount or 0),
            "evals=" .. tostring(ds.evalCount or 0),
            "admitted=" .. tostring(ds.admittedCount or 0),
            "suppressed=" .. tostring(ds.suppressedCount or 0),
            "relDeltas=" .. tostring(ds.relationshipDeltaCount or 0),
        })
    end

    if type(Beats.GetGroupBanterAuditState) == "function" then
        local gb = Beats.GetGroupBanterAuditState(now)
        Beats.AuditLog("banter_state", {
            "globalCooldownRemainingMs=" .. tostring(gb.globalCooldownRemainingMs or 0),
            "trackedGroups=" .. tostring(gb.trackedGroups or 0),
            "banterSeq=" .. tostring(gb.banterSeq or 0),
        })
    end

    if type(Beats.GetStateWatcherAuditState) == "function" then
        local sw = Beats.GetStateWatcherAuditState()
        Beats.AuditLog("watcher_state", {
            "registered=" .. tostring(sw.registeredCount or 0),
            "tracked=" .. tostring(sw.trackedEntries or 0),
            "transitions=" .. tostring(sw.transitionCount or 0),
            "activeCount=" .. tostring(sw.activeCount or 0),
            "armedCount=" .. tostring(sw.armedCount or 0),
            "armed=" .. tostring(sw.armed or "none"),
        })
    end

    return true
end

function Beats.MaybeLogPeriodicAuditSnapshot(reason, at)
    if not Beats.IsAuditEnabled() then return false end
    local now = nowMs(at)
    if now < (lastPeriodicSnapshotAt + SNAPSHOT_INTERVAL_MS) then
        return false
    end
    lastPeriodicSnapshotAt = now
    return Beats.LogAuditSnapshot(reason or "periodic", now)
end

function Beats.ResetAuditRuntime()
    lastPeriodicSnapshotAt = -SNAPSHOT_INTERVAL_MS
end

return Beats
