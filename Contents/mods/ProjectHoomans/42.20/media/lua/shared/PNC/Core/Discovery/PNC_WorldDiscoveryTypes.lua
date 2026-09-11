-- Shared contracts for player-scoped strategic-world discovery.

PNC = PNC or {}
PNC.WorldDiscoveryTypes = PNC.WorldDiscoveryTypes or {}

local Types = PNC.WorldDiscoveryTypes

Types.SCHEMA_VERSION = 2
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
Types.ARRIVAL_UNCHECKED = "unchecked"
Types.ARRIVAL_SEARCHED = "searched"
Types.ARRIVAL_CONTACTED = "contacted"
Types.PRESENCE_UNKNOWN = "unknown"
Types.PRESENCE_PRESENT = "present"
Types.PRESENCE_ABSENT = "absent"

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

function Types.ArrivalState(value)
    value = tostring(value or "")
    if value == Types.ARRIVAL_CONTACTED then
        return Types.ARRIVAL_CONTACTED
    end
    if value == Types.ARRIVAL_SEARCHED then
        return Types.ARRIVAL_SEARCHED
    end
    return Types.ARRIVAL_UNCHECKED
end

function Types.PresenceStatus(value)
    value = tostring(value or "")
    if value == Types.PRESENCE_PRESENT then
        return Types.PRESENCE_PRESENT
    end
    if value == Types.PRESENCE_ABSENT then
        return Types.PRESENCE_ABSENT
    end
    return Types.PRESENCE_UNKNOWN
end

return Types
