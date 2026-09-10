-- Shared fatigue admission/continuation policy for physical NPC work.
-- Values are NPC-owned need values: zero is rested and one is exhausted.

PNC = PNC or {}
PNC.WorkFatigueGate = PNC.WorkFatigueGate or {}

local Gate = PNC.WorkFatigueGate
Gate.DEFAULT_THRESHOLD = 0.90

local function readFatigue(record)
    local fatigue
    if PNC.IndividualNeeds and PNC.IndividualNeeds.Get then
        local ok, value = pcall(PNC.IndividualNeeds.Get, record, "fatigue")
        if ok then fatigue = tonumber(value) end
    end
    if fatigue == nil and record and type(record.needs) == "table" then
        fatigue = tonumber(record.needs.fatigue)
    end
    if fatigue == nil and record then
        fatigue = tonumber(record.fatigue)
    end
    return fatigue
end

function Gate.Threshold()
    return tonumber(PNC.Const and PNC.Const.WORK_FATIGUE_STOP)
        or Gate.DEFAULT_THRESHOLD
end

function Gate.Read(record)
    return readFatigue(record)
end

function Gate.Check(record)
    local fatigue = readFatigue(record)
    local threshold = Gate.Threshold()
    local details = {
        known = fatigue ~= nil,
        fatigue = fatigue,
        threshold = threshold,
    }
    -- Older/abstract records may not have the Needs repository yet. Preserve
    -- compatibility until a real fatigue value is available.
    if fatigue == nil then return true, nil, details end
    if fatigue >= threshold then
        return false, "WORKER_NEEDS_REST", details
    end
    return true, nil, details
end

return Gate
