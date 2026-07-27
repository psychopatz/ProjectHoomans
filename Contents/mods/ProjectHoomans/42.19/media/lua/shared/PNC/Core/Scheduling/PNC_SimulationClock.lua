-- Independent runtime deadlines keep slow systems such as vitals and
-- presence reconciliation from running at combat/pathing frequency.

PNC = PNC or {}
PNC.SimulationClock = PNC.SimulationClock or {}

local Clock = PNC.SimulationClock

local function ensure(record)
    record.runtime = record.runtime or {}
    record.runtime.simulationClock = record.runtime.simulationClock or {}
    return record.runtime.simulationClock
end

function Clock.IsDue(record, key, now, interval, force)
    local clocks
    local dueAt
    if not record then return false end
    clocks = ensure(record)
    dueAt = tonumber(clocks[key]) or 0
    if force == true or now >= dueAt then
        clocks[key] = now + math.max(1, tonumber(interval) or 1)
        return true
    end
    return false
end

function Clock.Wake(record, key, now)
    local clocks
    if not record then return end
    clocks = ensure(record)
    if key then
        clocks[key] = tonumber(now) or 0
    else
        record.runtime.simulationClock = {}
    end
end

function Clock.Get(record, key)
    local clocks = record and record.runtime
        and record.runtime.simulationClock or nil
    return tonumber(clocks and clocks[key]) or 0
end

