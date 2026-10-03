PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Diagnostics.BuildAuditNowMs()
    if type(getTimestampMs) ~= "function" then return 0 end
    return tonumber(getTimestampMs()) or 0
end

function Diagnostics.IsBuildAuditEnabled()
    return Diagnostics.BuildAuditEnabled == true
end

function Diagnostics.SetBuildAuditEnabled(enabled)
    Diagnostics.BuildAuditEnabled = enabled == true
    return Diagnostics.BuildAuditEnabled
end

-- Correlation id shared by the client click, the network request and the
-- server-side handling of that request.
function Diagnostics.NextBuildTraceId()
    Diagnostics.BuildTraceSequence = Diagnostics.BuildTraceSequence + 1
    return "build" .. tostring(Diagnostics.BuildTraceSequence)
end

function Diagnostics.MarkBuildRequestSent(requestId)
    if Diagnostics.BuildAuditEnabled ~= true then return false end
    requestId = tostring(requestId or "")
    if requestId == "" then return false end
    Diagnostics.BuildTraceSentAt[requestId] =
        Diagnostics.BuildAuditNowMs()
    return true
end

-- Milliseconds between the client sending a request and the verdict arriving.
function Diagnostics.BuildRequestElapsedMs(requestId)
    requestId = tostring(requestId or "")
    local sentAt = Diagnostics.BuildTraceSentAt[requestId]
    if not sentAt then return nil end
    return Diagnostics.BuildAuditNowMs() - sentAt
end

function Diagnostics.LogBuildAudit(stage, fields)
    local output
    local message
    if Diagnostics.BuildAuditEnabled ~= true then return false end
    output = {
        "build_audit",
        "stage=" .. tostring(stage or "unknown"),
        "t=" .. tostring(Diagnostics.BuildAuditNowMs()),
    }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

function Diagnostics.LogNeedsAudit(eventName, fields)
    local output
    local message
    if Diagnostics.NeedsAuditEnabled ~= true then return false end
    output = {
        "needs_audit",
        "event=" .. tostring(eventName or "unknown"),
    }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

-- Shared state snapshot for the seating trace. Callers should use this for
-- lifecycle boundaries and competing movement authorities so every event can
-- be correlated without each subsystem inventing a different field set.
