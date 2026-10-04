-- Bounded Lumber execution diagnostics.
--
-- This is an opt-in transition trace. It must remain cheap while disabled and
-- must never retain PZ Java objects or emit one log line per work tick.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.LumberService
local Diagnostics = Service.LumberDiagnostics or {}
Service.LumberDiagnostics = Diagnostics

local SETTING_ID = "ProjectHoomans.LumberAudit"
local SOURCE = "ProjectHoomans.Lumber"
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
        "lumber_audit",
        "npc=" .. bounded(data.npcId),
        "job=" .. bounded(data.jobId),
        "mode=" .. bounded(data.executionMode),
        "phase=" .. bounded(data.phase),
        "reason=" .. bounded(data.reason),
    }
    local optional = {
        "treeKey", "treeLoaded", "handoffAttempts", "handoffReason",
        "complete",
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
    -- Keep the gate first: callers may pass live runtime tables.
    if not Diagnostics.IsEnabled() or type(record) ~= "table"
        or type(job) ~= "table"
    then return false end

    details = type(details) == "table" and details or {}
    local runtime = record.runtime or {}
    local handoff = runtime.lumberHandoff or {}
    local executionMode = body and "LIVE" or "ABSTRACT"
    local phase = tostring(job.phase or job.state or "")
    local treeKey = details.treeKey or job.targetKey
        or job.pendingOutput and job.pendingOutput.treeKey or nil
    local key = table.concat({
        tostring(executionMode), phase, tostring(reason or ""),
        tostring(treeKey or ""), tostring(details.treeLoaded),
        tostring(handoff.attempts or 0),
    }, "|")
    local audit = runtime.lumberAudit or {}
    if audit.lastKey == key then return false end

    audit.lastKey = key
    audit.lastAt = now()
    audit.transitionCount = (tonumber(audit.transitionCount) or 0) + 1
    record.runtime = record.runtime or {}
    record.runtime.lumberAudit = audit

    local data = {
        npcId = record.id,
        jobId = job.id,
        executionMode = executionMode,
        phase = phase,
        reason = reason or "",
        treeKey = treeKey,
        treeLoaded = details.treeLoaded,
        handoffAttempts = handoff.attempts,
        handoffReason = handoff.lastReason,
        complete = details.complete == true,
    }
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if trace and type(trace.Record) == "function" then
        trace.Record({ source = SOURCE, event = "lumber.transition",
            requestID = tostring(job.id or record.id or ""), data = data })
    end
    logTransition(data)
    return true
end

local function registerSetting()
    local settings = settingsObject()
    if not settings or type(settings.Register) ~= "function" then
        return false
    end
    settings.Register({
        id = SETTING_ID,
        source = "Project Hoomans",
        order = 165,
        title = "Lumber execution audit",
        description = "Logs bounded Lumber live/abstract transitions and handoff reasons.",
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
