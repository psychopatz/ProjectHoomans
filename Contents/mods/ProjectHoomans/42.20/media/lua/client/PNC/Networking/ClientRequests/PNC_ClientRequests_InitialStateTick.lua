-- Periodic freshness work for the local player's initial client state.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Core = PNC.Core
local KnowledgeInterest = PNC.KnowledgeInterest
    or require "PNC/Knowledge/PNC_KnowledgeInterest"

local function scalarReason(accepted, reason)
    if type(reason) == "string" then return reason end
    if accepted == true then
        return type(reason) == "table" and "service_result" or "accepted"
    end
    return type(reason) == "table" and "service_error" or "unspecified"
end

local function bootstrapRequestIDFor(reason)
    if reason == "current"
        or reason == "throttled"
        or reason == "world_not_ready"
        or reason == "request_api_unavailable"
    then
        return nil
    end
    local network = PNC.Network
    local clientState = network and network.ClientState or nil
    local requestID = clientState
        and clientState.activeBootstrapRequestID or nil
    if type(requestID) == "string" or type(requestID) == "number" then
        return tostring(requestID)
    end
    return nil
end

local function logFailureOnce(diagnostics, service, reason, requestID, forced)
    local lastWarningField = service .. "LastWarningReason"
    if type(reason) ~= "string"
        or reason == "current"
        or reason == "throttled"
        or reason == "world_not_ready"
        or not Core
        or type(Core.LogWarn) ~= "function"
    then
        return
    end
    if diagnostics[lastWarningField] == reason then return end
    diagnostics[lastWarningField] = reason
    Core.LogWarn(
        "initial_state_request service=" .. service
            .. " result=deferred reason=" .. reason
            .. (requestID and " requestID=" .. requestID or "")
            .. (forced and " forcedByKnowledge=true" or "")
    )
end

local function updateDiagnostics(
    now,
    forceKnowledge,
    bootstrapAccepted,
    bootstrapReason,
    worldAccepted,
    worldReason
)
    local diagnostics = Internal.InitialStateRequestDiagnostics
    local bootstrapResult = bootstrapAccepted == true
        and "accepted" or "deferred"
    local bootstrapReasonCode = scalarReason(
        bootstrapAccepted,
        bootstrapReason
    )
    local bootstrapRequestID = bootstrapRequestIDFor(bootstrapReason)
    local worldResult = worldAccepted == true and "accepted" or "deferred"
    local worldReasonCode = scalarReason(worldAccepted, worldReason)
    if type(diagnostics) ~= "table" then
        diagnostics = {}
        Internal.InitialStateRequestDiagnostics = diagnostics
    end
    if diagnostics.playerBootstrapResult == bootstrapResult
        and diagnostics.playerBootstrapReason == bootstrapReasonCode
        and diagnostics.playerBootstrapRequestID == bootstrapRequestID
        and diagnostics.playerBootstrapForcedByKnowledge == (forceKnowledge == true)
        and diagnostics.worldDiscoveryResult == worldResult
        and diagnostics.worldDiscoveryReason == worldReasonCode
    then
        return
    end
    -- Keep only the latest scalar outcomes. Never retain request payloads,
    -- service tables, player objects, or an unbounded event history.
    diagnostics.updatedAt = now
    diagnostics.playerBootstrapResult = bootstrapResult
    diagnostics.playerBootstrapReason = bootstrapReasonCode
    diagnostics.playerBootstrapRequestID = bootstrapRequestID
    diagnostics.playerBootstrapForcedByKnowledge = forceKnowledge == true
    diagnostics.worldDiscoveryResult = worldResult
    diagnostics.worldDiscoveryReason = worldReasonCode
    if bootstrapAccepted == true then
        diagnostics.playerBootstrapLastWarningReason = nil
    else
        logFailureOnce(
            diagnostics,
            "playerBootstrap",
            bootstrapReason,
            bootstrapRequestID,
            forceKnowledge == true
        )
    end
    if worldAccepted == true then
        diagnostics.worldDiscoveryLastWarningReason = nil
    else
        logFailureOnce(
            diagnostics,
            "worldDiscovery",
            worldReason,
            nil,
            false
        )
    end
end

local function isWorldReady()
    if Internal.IsWorldReady then
        return Internal.IsWorldReady()
    end
    return (not isIngameState) or isIngameState()
end

function Internal.PumpInitialStateRequests(now)
    local forceKnowledge = false
    local bootstrapAccepted = false
    local bootstrapReason = "request_api_unavailable"
    local worldAccepted = false
    local worldReason = "request_api_unavailable"
    now = tonumber(now) or Core.Now()
    if not isWorldReady() then
        return false, "world_not_ready"
    end

    if Client.EnsurePlayerBootstrap then
        forceKnowledge = KnowledgeInterest
            and KnowledgeInterest.ConsumeFlush
            and KnowledgeInterest.ConsumeFlush(now)
            or false
        bootstrapAccepted, bootstrapReason =
            Client.EnsurePlayerBootstrap(now, forceKnowledge)
    end
    if Client.EnsureWorldDiscovery then
        worldAccepted, worldReason = Client.EnsureWorldDiscovery(now, false)
    end
    updateDiagnostics(
        now,
        forceKnowledge,
        bootstrapAccepted,
        bootstrapReason,
        worldAccepted,
        worldReason
    )
    return true
end

return Client
