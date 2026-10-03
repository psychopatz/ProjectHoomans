PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Diagnostics.IsNetworkPayloadAuditEnabled()
    return Diagnostics.NetworkPayloadAuditEnabled == true
end

function Diagnostics.LogNetworkPayload(eventName, fields)
    local output
    local message
    if Diagnostics.NetworkPayloadAuditEnabled ~= true then return false end
    output = {
        "network_payload",
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

function Diagnostics.NewSeatingSessionId(npcId)
    Diagnostics.SeatingSessionSequence =
        Diagnostics.SeatingSessionSequence + 1
    return "seat:" .. tostring(npcId or "") .. ":"
        .. tostring(Diagnostics.SeatingSessionSequence)
end

function Diagnostics.IsSeatingSceneId(sceneId)
    sceneId = tostring(sceneId or "")
    return sceneId == "facility.living.sitFurniture"
        or sceneId == "facility.living.sit"
        or sceneId == "ambient.roam.sitFurniture"
end

function Diagnostics.IsSeatingRuntime(runtime, scene)
    local facility = runtime and runtime.facilityActivity or nil
    local roaming = runtime and runtime.roamingSeat or nil
    return facility and facility.seating == true
        or roaming and roaming.seating == true
        or Diagnostics.IsSeatingSceneId(scene and scene.id or scene)
end

function Diagnostics.IsFollowerPresenceAuditEnabled()
    return Diagnostics.FollowerPresenceAuditEnabled == true
end

function Diagnostics.IsFollowerAbandonmentAuditEnabled()
    return Diagnostics.FollowerAbandonmentAuditEnabled == true
end

-- Callers guard this function before assembling fields. That keeps the
-- disabled path free of snapshots, clocks, tables, and string concatenation.
function Diagnostics.LogSeatingAudit(eventName, fields)
    local output
    if Diagnostics.SeatingAuditEnabled ~= true then return false end
    output = { "seating_audit", "event=" .. tostring(eventName or "unknown") }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

function Diagnostics.LogSleepAudit(eventName, fields)
    local output
    local message
    if Diagnostics.SleepAuditEnabled ~= true then return false end
    output = { "sleep_audit", "event=" .. tostring(eventName or "unknown") }
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

-- Zombie aggro uses the existing ZombieAggro.* prefixes so server, single
-- player, and multiplayer captures remain searchable with the old filters.
-- Callers should avoid assembling expensive detail fields while disabled;
-- this helper also gates direct callers for isolated tests and compatibility.
function Diagnostics.LogZombieAggroAudit(channel, fields)
    local output
    local message
    if Diagnostics.ZombieAggroAuditEnabled ~= true then return false end
    output = { "ZombieAggro." .. tostring(channel or "pursuit") }
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

function Diagnostics.LogNPCThreatAudit(eventName, fields)
    local output
    local message
    if Diagnostics.NPCThreatAuditEnabled ~= true then return false end
    output = {
        "npc_threat_audit",
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

-- Per-shot firearm tracing follows the seating audit format. Callers should
-- guard expensive field assembly when the channel is disabled; this function
-- itself is also safe for isolated client tests where the central diagnostics
-- module is unavailable.
function Diagnostics.LogFirearmAudit(eventName, fields)
    local output
    local message
    if Diagnostics.FirearmAuditEnabled ~= true then return false end
    output = { "firearm_audit", "event=" .. tostring(eventName or "unknown") }
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

-- Build pipeline tracing. One line per stage, prefixed with build_audit so the
-- whole flow can be filtered out of console.txt with a single search. Callers
-- guard on Diagnostics.BuildAuditEnabled before assembling fields; the helper
-- re-checks so direct callers stay safe.
