PNC = PNC or {}
PNC.TaskRequestDefinitions = PNC.TaskRequestDefinitions or {}

local Definitions = PNC.TaskRequestDefinitions

Definitions.STATE = {
    QUEUED = "QUEUED", WAITING_WORKER = "WAITING_WORKER",
    CLAIMED = "CLAIMED", TRAVEL = "TRAVEL", WORKING = "WORKING",
    WAITING_RESOURCE = "WAITING_RESOURCE", BLOCKED = "BLOCKED",
    PAUSED = "PAUSED", CANCELLING = "CANCELLING",
    CANCELLED = "CANCELLED", COMPLETED = "COMPLETED", FAILED = "FAILED",
}
Definitions.OUTCOME = {
    COMPLETED = "COMPLETED", WAITING = "WAITING", BLOCKED = "BLOCKED",
    RETRYABLE_FAILURE = "RETRYABLE_FAILURE", CANCELLED = "CANCELLED",
    TERMINAL_FAILURE = "TERMINAL_FAILURE",
}
Definitions.NON_INTERRUPTIBLE_PHASE = {
    ATOMIC_COMMIT = true, COMPLETING = true,
}

local WORK_STATE = {
    QUEUED = "QUEUED", WAITING_FOR_WORKER = "WAITING_WORKER",
    CLAIMED = "CLAIMED", TRAVEL_TO_STOCKPILE = "TRAVEL",
    TRAVEL_TO_STATION = "TRAVEL", WORKING = "WORKING",
    WAITING_RESOURCE = "WAITING_RESOURCE", BLOCKED = "BLOCKED",
    PAUSED = "PAUSED", CANCELLING = "CANCELLING",
    CANCELLED = "CANCELLED", COMPLETED = "COMPLETED", FAILED = "FAILED",
}

function Definitions.FromWorkStatus(status)
    return WORK_STATE[tostring(status or "")] or Definitions.STATE.BLOCKED
end

function Definitions.IsTerminal(state)
    state = tostring(state or "")
    return state == Definitions.STATE.CANCELLED
        or state == Definitions.STATE.COMPLETED
        or state == Definitions.STATE.FAILED
end

return Definitions
