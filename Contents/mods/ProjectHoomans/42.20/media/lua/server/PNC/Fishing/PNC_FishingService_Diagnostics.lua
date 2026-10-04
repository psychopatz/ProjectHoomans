-- Bounded fishing execution diagnostics.
--
-- Fishing has two execution modes and a live equipment handoff. This trace is
-- intentionally transition/attempt-based: it is useful when enabled, but it
-- does not retain Java objects or emit one line for every simulation tick.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.FishingService
local Diagnostics = Service.FishingDiagnostics or {}
Service.FishingDiagnostics = Diagnostics

local SETTING_ID = "ProjectHoomans.FishingAudit"
local SOURCE = "ProjectHoomans.Fishing"
local MAX_STRING = 160

local function bounded(value)
    local output = tostring(value or "")
    if #output <= MAX_STRING then return output end
    return string.sub(output, 1, MAX_STRING - 3) .. "..."
end

local function now()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function settingsObject()
    local settings = PsychopatzCore and PsychopatzCore.DebugSettings
    if settings and type(settings.Register) == "function" then
        return settings
    end
    if type(require) == "function" then
        pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
    end
    return PsychopatzCore and PsychopatzCore.DebugSettings or nil
end

Diagnostics.SETTING_ID = SETTING_ID
Diagnostics.Enabled = Diagnostics.Enabled == true

function Diagnostics.IsEnabled()
    return Diagnostics.Enabled == true
end

function Diagnostics.SetEnabled(enabled)
    Diagnostics.Enabled = enabled == true
    return Diagnostics.Enabled
end

local function logTransition(data)
    local fields = {
        "fishing_audit",
        "npc=" .. bounded(data.npcId),
        "job=" .. bounded(data.jobId),
        "mode=" .. bounded(data.executionMode),
        "phase=" .. bounded(data.phase),
        "reason=" .. bounded(data.reason),
    }
    local optional = {
        "event", "zone", "spot", "toolID", "tool", "recordPrimary",
        "recordPrimaryID",
        "nativePrimary", "handReady", "handReason", "claim", "distance",
        "workPoints", "requiredWorkPoints", "attempt", "catches", "chance",
        "roll", "success", "itemType", "output", "outputReason",
        "leaseOwner", "leasePriority", "animationScene", "animationRequest",
        "animationReason", "actionPropAttach",
        "lastFailureReason",
    }
    for _, key in ipairs(optional) do
        if data[key] ~= nil then
            fields[#fields + 1] = key .. "=" .. bounded(data[key])
        end
    end
    local message = table.concat(fields, " ")
    if PNC.Core and type(PNC.Core.LogInfo) == "function" then
        PNC.Core.LogInfo(message)
    elseif type(print) == "function" then
        print("[PNC][INFO] " .. message)
    end
end

function Diagnostics.RecordTransition(record, job, body, reason, details)
    -- Keep the gate before reading runtime/body state. Disabled diagnostics
    -- must be a cheap boolean branch on the hot work path.
    if not Diagnostics.IsEnabled() or type(record) ~= "table"
        or type(job) ~= "table"
    then return false end

    details = type(details) == "table" and details or {}
    local runtime = record.runtime or {}
    local fishing = runtime.fishing or {}
    local lease
    local actionPropAttach
    local animationRequest = runtime.fishingAnimationRequest
    local animationScene = details.animationScene
        or animationRequest and animationRequest.scene
        or runtime.animationScene and runtime.animationScene.id
    local animationReason = details.animationReason
        or animationRequest and animationRequest.reason
    local animationResult = details.animationRequest
    local failureReason = details.lastFailureReason
        or fishing.lastFailureReason or job.lastFailureReason
    if animationResult == nil and type(animationRequest) == "table" then
        animationResult = animationRequest.ok
    end
    if PNC.Equipment
        and type(PNC.Equipment.GetActivePrimaryLease) == "function"
    then
        lease = PNC.Equipment.GetActivePrimaryLease(record)
    end
    actionPropAttach = details.actionPropAttach
        or fishing.actionPropAttach
    if not actionPropAttach and body and body.getModData then
        local bodyData = body:getModData()
        local status = bodyData and bodyData.PNCActionPropStatus or nil
        if status then
            actionPropAttach = status.ok == true
                and "attached" or status.reason
        end
    end
    local tool = details.tool or fishing.activityItemFullType
    local toolID = details.toolID or fishing.activityItemID
    local recordPrimaryID = details.recordPrimaryID
        or fishing.recordPrimaryID
    local phase = tostring(details.phase or job.phase or job.state or "")
    local executionMode = details.executionMode
        or job.executionMode or (body and "LIVE" or "ABSTRACT")
    local key = table.concat({
        tostring(executionMode), phase, tostring(reason or ""),
        tostring(details.event or ""), tostring(toolID or ""),
        tostring(tool or ""), tostring(details.recordPrimary or ""),
        tostring(recordPrimaryID or ""),
        tostring(details.nativePrimary or ""), tostring(details.claim or ""),
        tostring(details.handReason or ""),
        tostring(details.attempt or job.attemptIndex or ""),
        tostring(details.catches or job.catches or ""),
        tostring(details.chance or ""), tostring(details.roll or ""),
        tostring(details.success or ""), tostring(details.output or ""),
        tostring(details.outputReason or ""),
        tostring(details.leaseOwner or lease and lease.owner or ""),
        tostring(details.leasePriority or lease and lease.priority or ""),
        tostring(animationScene or ""), tostring(animationResult or ""),
        tostring(animationReason or ""), tostring(actionPropAttach or ""),
        tostring(failureReason or ""),
    }, "|")
    local audit = runtime.fishingAudit or {}
    if audit.lastKey == key then return false end

    audit.lastKey = key
    audit.lastAt = now()
    audit.transitionCount = (tonumber(audit.transitionCount) or 0) + 1
    record.runtime = record.runtime or {}
    record.runtime.fishingAudit = audit

    local data = {
        npcId = record.id,
        jobId = job.id,
        executionMode = executionMode,
        phase = phase,
        reason = reason or "",
        event = details.event,
        zone = job.zoneId,
        spot = job.spotId,
        toolID = toolID,
        tool = tool,
        recordPrimary = details.recordPrimary,
        recordPrimaryID = recordPrimaryID,
        nativePrimary = details.nativePrimary,
        handReady = details.handReady,
        handReason = details.handReason,
        claim = details.claim,
        distance = details.distance,
        workPoints = job.workPoints,
        requiredWorkPoints = details.requiredWorkPoints,
        attempt = details.attempt or job.attemptIndex,
        catches = job.catches,
        chance = details.chance,
        roll = details.roll,
        success = details.success,
        itemType = details.itemType,
        output = details.output,
        outputReason = details.outputReason,
        leaseOwner = details.leaseOwner or lease and lease.owner,
        leasePriority = details.leasePriority or lease and lease.priority,
        animationScene = animationScene,
        animationRequest = animationResult,
        animationReason = animationReason,
        actionPropAttach = actionPropAttach,
        lastFailureReason = failureReason,
    }
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if trace and type(trace.Record) == "function" then
        trace.Record({ source = SOURCE, event = "fishing.transition",
            requestID = tostring(job.id or record.id or ""), data = data })
    end
    logTransition(data)
    return true
end

function Diagnostics.RecordAttempt(record, job, body, roll, details)
    -- Attempt logging is opt-in and deduplicated by attempt index, so the
    -- normal work tick remains cheap and a storage-full retry cannot flood
    -- the console.
    if not Diagnostics.IsEnabled() or type(roll) ~= "table" then
        return false
    end
    details = type(details) == "table" and details or {}
    details.event = details.event or "attempt"
    details.attempt = roll.attempt or job and job.attemptIndex
    details.chance = roll.chance
    details.roll = roll.roll
    details.success = roll.success == true
    details.requiredWorkPoints = details.requiredWorkPoints
        or job and job.requiredWorkPoints
    local reason = details.reason
        or (details.success and "catch_roll" or "no_catch")
    return Diagnostics.RecordTransition(record, job, body, reason, details)
end

local function registerSetting()
    local settings = settingsObject()
    if not settings or type(settings.Register) ~= "function" then
        return false
    end
    settings.Register({
        id = SETTING_ID,
        source = "Project Hoomans",
        order = 166,
        title = "Fishing execution audit",
        description = "Logs Fishing phases, catch chances, rolls, outcomes, and tool reasons.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SetEnabled(enabled)
        end,
    })
    if type(settings.IsEnabled) == "function" then
        Diagnostics.SetEnabled(settings.IsEnabled(SETTING_ID) == true)
    end
    return true
end

registerSetting()

return Diagnostics
