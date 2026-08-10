-- Shared contracts for player-scoped strategic-world discovery.

PNC = PNC or {}
PNC.WorldDiscoveryTypes = PNC.WorldDiscoveryTypes or {}

local Types = PNC.WorldDiscoveryTypes

Types.SCHEMA_VERSION = 1
Types.MODDATA_KEY = "PNC_WorldDiscovery_v1"
Types.KIND_SETTLEMENT = "settlement"
Types.KIND_MOBILE_GROUP = "mobile_group"
Types.PHASE_UNKNOWN = 0
Types.PHASE_RUMORED = 1
Types.PHASE_LOCATED = 2
Types.PHASE_CONTACTED = 3
Types.PHASE_NAMES = {
    [0] = "UNKNOWN",
    [1] = "RUMORED",
    [2] = "LOCATED",
    [3] = "CONTACTED",
}

function Types.IsKind(kind)
    return kind == Types.KIND_SETTLEMENT
        or kind == Types.KIND_MOBILE_GROUP
end

function Types.ClampPhase(phase)
    return math.max(Types.PHASE_UNKNOWN, math.min(
        Types.PHASE_CONTACTED,
        math.floor(tonumber(phase) or Types.PHASE_UNKNOWN)
    ))
end

function Types.PhaseName(phase)
    return Types.PHASE_NAMES[Types.ClampPhase(phase)] or "UNKNOWN"
end

return Types
